#!/usr/bin/env xonsh
import signal
import time

def doNothing():
	pass

signal.signal(signal.SIGTERM,doNothing)

import os

echo 'Shutting down Sync Docs...'
tmpDir = '/tmp/syncDocs'
tmpDirTERM = tmpDir + '/TERM'
if os.path.exists(tmpDirTERM) == True:
	echo TERM > @(tmpDirTERM)
while os.path.exists(tmpDir):
	time.sleep(1)
echo 'Sync Docs successfully shut down'
