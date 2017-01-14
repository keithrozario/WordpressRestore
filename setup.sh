#!/bin/bash
# Wordpress Restorer v1.0
# Backups and restores wordpress with one click
#
# file: setup.sh
# usage: setup.sh --dropboxtoken <xxx> --wpconfpass <xxx>
#       --dropboxtoken : Access Token For Dropbox [MANDATORY]
#       --wpconfpass   : Encryption Key for backup files [MANDATORY]
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
# 

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
   --dropboxtoken)
    DROPBOXTOKEN="$2"
    shift # past argument
    ;;
	--wpconfpass)
    WPCONFPASS="$2"
    shift # past argument
    ;;
	--default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z "$DROPBOXTOKEN" ] || [ -z "$WPCONFPASS" ]; then  #Check Parameters
echo "Please provide access token for Dropbox and Encryption Key, both are mandatory"
exit 0
else #both parameters provided, proceed
echo "Dropbox Token : Good"
echo "WP-Config Key : Good"
fi

#---------------------------------------------------------------------------------------
# Global Constants
#---------------------------------------------------------------------------------------

DROPBOXUPLOADERFILE=~/.dropbox_uploader
URLDROPBOXDOWNLOADER="https://github.com/andreafabrizi/Dropbox-Uploader.git" #Github for Dropbox Uploader
DROPBOXPATH=/var/Dropbox-Uploader

WPCONFPASSFILE=~/.wpconfpass

BACKUPSHDIR=/var
BACKUPSHNAME=backupWP.sh

#---------------------------------------------------------------------------------------
# Download DropboxUploader and Setup
#---------------------------------------------------------------------------------------
echo "Saving Token : $DROPBOXTOKEN to file"
echo "OAUTH_ACCESS_TOKEN=$DROPBOXTOKEN" > $DROPBOXUPLOADERFILE
chmod 440 $DROPBOXUPLOADERFILE
echo "Downloading DropboxDownloader from $URLDROPBOXDOWNLOADER"
git clone $URLDROPBOXDOWNLOADER $DROPBOXPATH
chmod +x $DROPBOXPATH/dropbox_uploader.sh

#---------------------------------------------------------------------------------------
# Setup Encryption Key file
#---------------------------------------------------------------------------------------
echo "WPCONFPASS=$WPCONFPASS" > ~/.wpconfpass #store wpconfigpass in config file

#---------------------------------------------------------------------------------------
# Download Backup Script and create CRON job
#---------------------------------------------------------------------------------------
echo "Downloading Backup Script"
chmod 440 $BACKUPSHNAME
echo "Backup Script Downloaded -- creating CRON Job"
mv $BACKUPSHNAME $BACKUPSHDIR
( crontab -l ; echo "0 23 * * * $BACKUPSHDIR/$BACKUPSHNAME" ) | crontab - #cron-job the backup-script
echo "Setup Complete"

