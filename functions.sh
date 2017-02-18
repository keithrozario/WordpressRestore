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

FUNCTIONSFILEMESSAGE="INFO: Functions file loaded" #message to load to prove functions.sh was loaded correctly

#---------------------------------------------------------------------------------------
# delete file / dir if exist
#---------------------------------------------------------------------------------------
function delFile {
if [ -f $1 ]; then
	echo "WARNING: Found old $1--deleting to prevent conflicts"
	sudo rm $1
else
	echo "GOOD: No previous versions of $1 detected"
fi
}

function delDir {
if [ -d $1 ]; then
	echo "WARNING: Found old $1--deleting to prevent conflicts"
	sudo rm -r $1
else
	echo "GOOD: No previous versions of $1 detected"
fi
}



#---------------------------------------------------------------------------------------
# GetDropboxUploader
#---------------------------------------------------------------------------------------
function GetDropboxUploader {

DROPBOXTOKEN=$1 #passing argument

DROPBOXUPLOADERFILE=~/.dropbox_uploader
URLDROPBOXDOWNLOADER="https://github.com/andreafabrizi/Dropbox-Uploader.git" #Github for Dropbox Uploader
DROPBOXPATH=/var/Dropbox-Uploader

if [ -d $DROPBOXPATH ]; then
  echo "WARNING: Dropbox downloader may have been downloaded before, removing directory $DROPBOXPATH"
  delDir rm -r $DROPBOXPATH
  delFile rm $DROPBOXUPLOADERFILE
fi  
  
echo "INFO: Saving Token : $DROPBOXTOKEN to file"
echo "OAUTH_ACCESS_TOKEN=$DROPBOXTOKEN" > $DROPBOXUPLOADERFILE
chmod 440 $DROPBOXUPLOADERFILE
echo "INFO: Downloading DropboxDownloader from $URLDROPBOXDOWNLOADER"
sudo git clone $URLDROPBOXDOWNLOADER $DROPBOXPATH
sudo chmod +x $DROPBOXPATH/dropbox_uploader.sh

}

#---------------------------------------------------------------------------------------
# SetCronJob
#---------------------------------------------------------------------------------------

function SetCronJob {

BACKUPSHDIR=/var
BACKUPSHNAME=backupWP.sh

echo "INFO: Setting cronjobs for $BACKUPSHNAME in $BACKUPSHDIR"

sudo cp $BACKUPSHNAME $BACKUPSHDIR
sudo chmod 775 $BACKUPSHDIR/$BACKUPSHNAME
( crontab -l ; echo "0 23 * * * $BACKUPSHDIR/$BACKUPSHNAME" ) | crontab - #cron-job the backup-script

}

#---------------------------------------------------------------------------------------
# setup .enckey file
#---------------------------------------------------------------------------------------

function SetEncKey {
ENCKEYFILE=/var/.enckey
ENCKEY=$1

if [ -f $ENCKEYFILE ]; then
  echo "WARNING: Removing old $ENCKEYFILE, (probably from old installation)"
  sudo rm $ENCKEYFILE #remove older one if exists
  echo "INFO: $ENCKEYFILE removed"
else
  echo "GOOD: No $ENCKEYFILE found, looks like this is the first install"
fi


sudo echo "ENCKEY=$ENCKEY" > $ENCKEYFILE #store wpconfigpass in config file
}

#---------------------------------------------------------------------------------------
# setup .wpsettings file
#---------------------------------------------------------------------------------------

function SetWPSettings {
WPSETTINGSFILE = /var/.wpsettings
WPDIR=$1
WPCONFDIR=$2
DROPBOXPATH=$3

if [ -f $WPSETTINGSFILE ]; then
	echo "WARNING: Older $WPSETTINGSFILE detected, deleting it" 
	sudo rm $WPSETTINGSFILE
else 
	echo "GOOD: no $WPSETTINGSFILE found --- creating one"
  	sudo echo "INFO: WPDIR=$WPDIR" >> $WPSETTINGSFILE #store wordpress directory in config file
  	sudo echo "INFO: WPCONFDIR=$WPCONFDIR" >> $WPSETTINGSFILE #store wordpress config (wp-config.php) directory in config file
  	sudo echo "INFO: DROPBOXPATH=$DROPBOXPATH" >> $WPSETTINGSFILE #store dropbox uploader path in directory
fi
}

