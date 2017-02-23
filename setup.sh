#!/bin/bash
# Wordpress Restorer v1.0 
# Backups and restores wordpress with one click
#
# file: setup.sh
# usage: setup.sh --dropboxtoken <xxx> --wpconfpass <xxx>
#       --dropboxtoken 	: Access Token For Dropbox [MANDATORY]
#       --enckey   	: Encryption Key for backup files [MANDATORY]
#	--wpdir		: directory of the wordpress php files [OPTIONAL, default = "/var/www/html"]
#	--wpconfdir	: directory of the wordpress wp-config.php file [OPTIONAL, default = "var/ww/html"]
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

#-------------------------------------------------------------------------
# Check if seetings and functions file exist
#-------------------------------------------------------------------------
FUNCTIONSFILE=functions.sh
if [ -f $FUNCTIONSFILE ]; then
	echo "Loading $FUNCTIONSFILE"
	source "$FUNCTIONSFILE" #file exist, load variables
else 
	echo "Unable to find $FUNCTIONSFILE, please run setup.sh for first time"
    	exit 0
fi


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
   --dropboxtoken)
    DROPBOXTOKEN="$2"
    shift # past argument
    ;;
    --enckey)
    ENCKEY="$2"
    shift # past argument
    ;;
    --wpdir)
    WPDIR="$2"
    shift # past argument
    ;;
    --wpconfdir)
    WPCONFDIR="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z "$DROPBOXTOKEN" ] || [ -z "$ENCKEY" ]; then  #Check Parameters
	echo "Please provide access token for Dropbox and Encryption Key, both are mandatory"
	exit 0
else #both parameters provided, proceed
	echo "Dropbox Token : Good"
	echo "WP-Config Key : Good"
fi

if [ -z "$WPDIR" ]; then
	echo "Wordpress Directory not provided, assuming /var/www/html"
	WPDIR=/var/www/html
else
	echo "Wordpress Directory set to $WPDIR"
fi

if [ -z "$WPCONFDIR" ]; then
	echo "Wordpress config directory not provided, setting to wordpress directory: $WPDIR"
	WPCONFDIR=$WPDIR
else
	echo "Wordpress config directory set to $WPCONFDIR"
fi

#---------------------------------------------------------------------------------------
# Global Constants
#---------------------------------------------------------------------------------------

BACKUPSHDIR=/var
BACKUPSHNAME=backupWP.sh
WPSETTINGSFILE=$BACKUPSHDIR/.wpsettings
ENCKEYFILE=$BACKUPSHDIR/.enckey
DROPBOXPATH=/var/Dropbox-Uploader

#---------------------------------------------------------------------------------------
# Download DropboxUploader and Setup
#---------------------------------------------------------------------------------------
GetDropboxUploader $DROPBOXTOKEN $DROPBOXPATH #in functions.sh

#---------------------------------------------------------------------------------------
# Setup .wpsettings file & .enckey file
#---------------------------------------------------------------------------------------


SetWPSettings $WPDIR $WPCONFDIR $DROPBOXPATH
SetEncKey $ENCKEY #in functions.sh

#---------------------------------------------------------------------------------------
# Download Backup Script and create CRON job
#---------------------------------------------------------------------------------------

SetCronJob #in functions.sh

echo "Setup Complete"

