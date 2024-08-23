#!/usr/bin/env xonsh

from config import *
import datetime
from pathlib import Path
from threading import Thread
import signal
import os
import time
import secrets
import string

#setup

tmpDir = '/tmp/syncDocs'
if os.path.exists(tmpDir) == True:
	print(tmpDir + ' already exists, another instance might already be running.') 
	exit(1)
mkdir @(tmpDir)
fifoTERMloc = tmpDir + '/TERM'
mkfifo @(fifoTERMloc)
scriptDir = Path(__file__).resolve().parent.as_posix()
termStr = 'TERM'

#important functions

def printAndAppendToFile(appendText):
	logFileName = 'syncDocsLog'
	logPath = scriptDir + '/' + logFileName
	outText = appendText + ' | TIME: ' + datetime.datetime.now().strftime("%Y-%m-%d %I:%M:%S %p")
	print(outText)
	with open(logPath, 'a') as the_file:
		the_file.write(outText + '\n')

def sendTERMsig():
	global termStr
	global fifoTERMloc
	with open(fifoTERMloc, 'a') as the_file:
		the_file.write(termStr + '\n')
#        echo @(termStr) >  @(fifoTERMloc)

trmnteThreads = []

def trmnte(signal,frame):
	printAndAppendToFile('TERM signal received, cleaning up')
	thrd = Thread(target = sendTERMsig)
	thrd.start()
	trmnteThreads.append(thrd)

def doNothing():
	pass

def setSIGTERM(func):
	signal.signal(signal.SIGTERM,func)

setSIGTERM(trmnte)

# def fifoCapture(fifoLoc,holdMsg_:
#         echo @(holdMsg) > @(fifoLoc)
intervalTime = 6 
def fifoCapture(fifoLoc,holdMsg,fifoReadAll):
        while (holdMsg in fifoReadAll) == False:
		with open(fifoLoc) as f:
			contentString = f.read()
			content = contentString.splitlines()
			fifoReadAll.extend(content)

def keyGen():
	return ''.join(secrets.choice(string.ascii_uppercase + string.ascii_lowercase) for i in range(7))

def fifoCheck(fifoCommLoc,desiredMsg): #includes location for the fifo and the desired message for continuing
	fifoReadAll = []
	holdMsg = keyGen()
        fifoThread = Thread(target=fifoCapture,args=[fifoCommLoc,holdMsg,fifoReadAll])
        fifoThread.start()
	sleepTime = intervalTime/2
        while True:
		time.sleep(sleepTime)
		with open(fifoCommLoc, 'a') as the_file:
			the_file.write(holdMsg + '\n')
		time.sleep(sleepTime)
		if fifoThread.is_alive()  == False:
			fifoThread.join()
			break
        if desiredMsg in fifoReadAll:
                return True
	return False


def syncLeftWithRight(leftLocation, rightLocation):
	printAndAppendToFile('Syncing ' + leftLocation + ' with ' + rightLocation)
        #sync from left to right
	printAndAppendToFile('Updating left to right')
        rclone sync @(leftLocation) @(rightLocation) --exclude "{Not Synced/**}" --max-delete 0 -u
	printAndAppendToFile('Finished updating left to right')
        transferredLine = $(rclone sync @(rightLocation) @(leftLocation) --exclude "{Not Synced/**}" --dry-run --max-delete 0 -u 2>&1 | grep 'Transferred:' | grep '0 B / 0 B')
        if transferredLine == '': # string is empty if files need to be transferred
		printAndAppendToFile('Updating right to left')
		windowTitle = 'Rclone Sync: ' + rightLocation + ' to ' + leftLocation
		#create pingFIFO
		pingFIFO = tmpDir + '/RtoLsyncPing'
		mkfifo @(pingFIFO) 
		windowCreated = False
		RtoLsyncScript = scriptDir + '/rightToLeftSync.xsh'
		msgKey = keyGen()
                while True: #keep track of the created window by monitoring its polling
			if fifoCheck(pingFIFO,msgKey) == False: #if no ping is received: if window is not created: create, else: break
				if windowCreated:
					break
				else:
					xfce4-terminal --window --title=@(windowTitle) --hold -x @(RtoLsyncScript) @(leftLocation) @(rightLocation) @(pingFIFO) @(msgKey)
			else: #else: mark window as created
				windowCreated = True
		printAndAppendToFile('Finished updating right to left')
		rm @(pingFIFO)
	printAndAppendToFile('Finished syncing ' + leftLocation + ' with ' + rightLocation)

def checkTERM():
#	setSIGTERM(doNothing) 
	isTERMed = fifoCheck(fifoTERMloc,termStr)
#	setSIGTERM(trmnte)
	return isTERMed

while True:
	deviceLocation = $(blkid --uuid @(diskUUID)).strip() # location of device in /dev
	if deviceLocation != '':
		# check mount point, if not mounted, mount
		mountPoint = $(findmnt -n -S UUID=@(diskUUID) --output TARGET).strip()
		if mountPoint == '':
			udisksctl mount -b @(deviceLocation)
			mountPoint = $(findmnt -n -S UUID=@(diskUUID) --output TARGET).strip()
			printAndAppendToFile('Drive just mounted to ' + mountPoint)
		if mountPoint != '':
			syncLeftWithRight(syncDir,mountPoint)
	if checkTERM():
		break
	if $(curl -Is https://www.google.com | head -n 1).strip() == 'HTTP/2 200':
		syncLeftWithRight(syncDir,'googleDrive:/')
	sleepTime = 300
	continueRun = True
	printAndAppendToFile('Sleeping for ' + str(sleepTime) + ' seconds')
	for i in range(int(sleepTime/intervalTime)):
		if checkTERM():
			continueRun = False
			break
	printAndAppendToFile('Finished sleeping')
	if continueRun == False:
		break 
for thrd in trmnteThreads:
	thrd.join() 
#rm @(fifoTERMloc)
rm -r @(tmpDir)
printAndAppendToFile('Terminated')
