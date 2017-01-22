#!/bin/bash
# Wordpress Restorer v1.0
# Backups and restores wordpress with one click
#
# file: functions.sh
#
# Author: Keith Rozario <keith@keithrozario.com>
#
# This work is licensed under the
# Creative Commons Attribution 4.0 International License.
# To view a copy of this license, visit 
# http://creativecommons.org/licenses/by/4.0/ or 
# send a letter to 
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#

#---------------------------------------------------------------------------------------
# GetDropboxUploader
#---------------------------------------------------------------------------------------
function GetDropboxUploader {

DROPBOXTOKEN=$1 #passing argument

DROPBOXUPLOADERFILE=~/.dropbox_uploader
URLDROPBOXDOWNLOADER="https://github.com/andreafabrizi/Dropbox-Uploader.git" #Github for Dropbox Uploader
DROPBOXPATH=/var/Dropbox-Uploader

if [ -d $DROPBOXPATH ]; then
  echo "Dropbox downloader may have been downloaded before, removing directory $DROPBOXPATH"
  rm -r $DROPBOXPATH
  rm $DROPBOXUPLOADERFILE
fi  
  
echo "Saving Token : $DROPBOXTOKEN to file"
echo "OAUTH_ACCESS_TOKEN=$DROPBOXTOKEN" > $DROPBOXUPLOADERFILE
chmod 440 $DROPBOXUPLOADERFILE
echo "Downloading DropboxDownloader from $URLDROPBOXDOWNLOADER"
git clone $URLDROPBOXDOWNLOADER $DROPBOXPATH
chmod +x $DROPBOXPATH/dropbox_uploader.sh

}

#---------------------------------------------------------------------------------------
# SetCronJob
#---------------------------------------------------------------------------------------

function SetCronJob {

BACKUPSHDIR=/var
BACKUPSHNAME=backupWP.sh

chmod 775 $BACKUPSHNAME
mv $BACKUPSHNAME $BACKUPSHDIR
( crontab -l ; echo "10 * * * * $BACKUPSHDIR/$BACKUPSHNAME" ) | crontab - #cron-job the backup-script

}

#---------------------------------------------------------------------------------------
# setup .enckey file
#---------------------------------------------------------------------------------------

function SetEncKey {

ENCKEY=$1

ENCKEYFILE=/var/.enckey
rm ENCKEYFILE #remove older one if exists
echo "ENCKEY=$ENCKEY" > $ENCKEYFILE #store wpconfigpass in config file
}
