# syncDocsV2
My xonsh script for synchronizing documents to my local drive and google drive

## Why?
Before I migrated to Linux I used a software called SyncBackPro to synchronize my files with my USB flash drive and google drive. I couldn't find anything that does the same thing when I migrated, so I made this script using xonsh (python and shell combined, makes calling subprocess much easier syntactically than just with python).

## How does it work?
It uses a combination of OS level applications including Rclone to synchronize files to a google drive as well as a specified location in the user's filesystem. It is set up to synchronnize according to the following rules:

* Never delete files automatically (call deleteScript.xsh manually for that)
* Files are copied from one side to another if they don't exist on the other and are replaced if they are older on the other
* Never change the left location automatically (where left is the user's machine), and prompt the user in an opened terminal window (xfce4-terminal) to confirm a potential change there
* Run every 5 minutes

The application uses threading and named pipes (FIFOs) to do IPC with the opened terminal, as well as to allow the user to easily shut the script down.

## How to use
Enter the disk UUID for the drive you want to sync to as well as the directory you want synced in config.xsh, set up rclone to interface with your google drive, and run syncDocsV2.xsh. To shut down, you can send a TERM signal to the application, write TERM to the FIFO at /tmp/syncDocs/TERM (ex. echo TERM > /tmp/syncDocs/TERM), or run shutDown.xsh. A logfile "syncDocsLog" is generated if it doesn't already exist, and the status of the script is constantly appended to it.

## Requirements
* A linux (unix?) machine
* Rclone
* xfce4-terminal, as well as an environment (desktop environment/window manager) capable of displaying it
* Any other command line applications the script uses and is not included by default within your disribution, I recommend skimming through the code just to be sure

## DISCLAIMER
I made this version of the script by chaning the one I use. The changes include changing file extensions and adding a config file for a more DRY approach. You can let me know if it doesn't work and I'll fix it.
