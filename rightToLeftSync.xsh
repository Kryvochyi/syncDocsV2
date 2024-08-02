#!/usr/bin/env xonsh

import time
#from multiprocessing import Thread
from threading import Thread
leftLocation = $ARGS[1]
rightLocation = $ARGS[2]
fifoFile = $ARGS[3]
pingMsg = $ARGS[4]

thisProcAlive = True
def pingMainProc():
	global thisProcAlive
	global fifoFile
	global pingMsg
	while thisProcAlive:
#		echo RtoLisAlive > @(fifoFile)
		with open(fifoFile, 'a') as the_file:
			the_file.write(pingMsg + '\n')
		time.sleep(1)

pingMainProcThread = Thread(target=pingMainProc)
pingMainProcThread.start()

rclone sync @(rightLocation) @(leftLocation) --exclude "{Not Synced/**}" -i --max-delete 0 -u

thisProcAlive = False
pingMainProcThread.join()
