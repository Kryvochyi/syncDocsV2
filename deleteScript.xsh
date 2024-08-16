#!/usr/bin/env xonsh

from config import *

mountPoint = $(findmnt -n -S UUID=@(diskUUID) --output TARGET).strip()
for i in range(1,len($ARGS),1):
	print('removing ' + $ARGS[i])
	rm -rv @(syncDir + $ARGS[i])
	rm -rv @(mountPoint + '/' + $ARGS[i])
	rclone purge -v googleDrive:/@($ARGS[i])
