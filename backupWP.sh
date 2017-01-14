#!/bin/bash
# File: Backup.sh
# Backups wordpress with one click
#
# Author: Keith Rozario <keith@keithrozario.com>
# Usage:    ./backupWP.sh --wpconfpass [encryption_key]
#           Encryption Key will be saved to file and used for each subsequent upload
#           Encryption is mandatory, and a key must be provided for first time use
#
# This work is licensed under the
# Creative Commons Attribution 4.0 International License.
# To view a copy of this license, visit 
# http://creativecommons.org/licenses/by/4.0/ or 
# send a letter to 
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

WPCONFPASSFILE=~/.wpconfpass

#-------------------------------------------------------------------------
# Command Line Arguments
#-------------------------------------------------------------------------
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    --wpconfpass)
    WPCONFPASSARG="$2"
    shift # past argument
    ;;
    --dropboxtoken)
    DROPBOXTOKEN="$2"
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

#-------------------------------------------------------------------------
# Check if WPCONFPASSFILE or WPCONFPASSARG--or both!
#-------------------------------------------------------------------------
if [ -f $WPCONFPASSFILE ]; then
#File exist, Arg not supplied------------------------------------------------
  if [ -z '$WPCONFPASSARG' ]; then 
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
#File exist, Arg supplied----------------------------------------------------  
  else 
    echo "Encryption key provided, but one already exist, over-riding existing key"
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
    rm $WPCONFPASSFILE
    echo "WPCONFPASS=$WPCONFPASSARG" > $WPCONFPASSFILE
  fi
else
#File does not exist, Arg not supplied-------------------------------------
   if [ -z '$WPCONFPASSARG' ]; then 
    echo "Encryption does not exist on system, and is not provided, aborting"
    exit 0
#File does not exist, Arg supplied-----------------------------------------
   else
    echo "First Time setup, saving encryption key"
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
    echo "WPCONFPASS=$WPCONFPASSARG" > $WPCONFPASSFILE #save encryption key to file
   fi
fi


#-------------------------------------------------------------------------
# FileNames
#-------------------------------------------------------------------------
WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILEENC=wp-config.php.enc
APACHECONFIG=apachecfg_dynamic.tar
BACKUPPATH=~/var/backupWP
WPDIR=~/var/www
WPCONFIGDIR = ~/var
DROPBOXUPDIR = ~/var/Dropbox-Uploader

#-------------------------------------------------------------------------
# Delete Previous files if they exist
#-------------------------------------------------------------------------
rm $BACKUPPATH/$WPZIPFILE
rm $BACKUPPATH/$WPSQLFILE
rm $BACKUPPATH/$APACHECONFIG
rm $BACKUPPATH/$WPCONFIGFILEENC

#-------------------------------------------------------------------------
# Copyd MYSQL Database
#-------------------------------------------------------------------------
mysqldump wordpress > $BACKUPPATH/$WPSQLFILE

#-------------------------------------------------------------------------
# Zip /var/wwwfolder
#-------------------------------------------------------------------------
tar czf $BACKUPPATH/$WPZIPFILE $WPDIR #turn off verbos (it's too noisy!!)

#-------------------------------------------------------------------------
# Encrypt wp-config.php file
#-------------------------------------------------------------------------
openssl enc -aes-256-cbc -in $WPCONFIGDIR/wp-config.php -out $BACKUPPATH/$WPCONFIGFILEENC -k $WPCONFIGENCKEY


#-------------------------------------------------------------------------
# Copy all Apache Configurations files
#-------------------------------------------------------------------------
tar cvf $BACKUPPATH/$APACHECONFIG /etc/apache2/sites-enabled
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/sites-available
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/ssl
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/apache2.conf
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/.htpasswd
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/ports.conf

#-------------------------------------------------------------------------
# Upload to Dropbox
#-------------------------------------------------------------------------
$DROPBOXUPDIR/dropbox_uploader.sh upload $BACKUPPATH/$WPSQLFILE /
$DROPBOXUPDIR/dropbox_uploader.sh upload $BACKUPPATH/$WPZIPFILE /
$DROPBOXUPDIR/dropbox_uploader.sh upload $BACKUPPATH/$APACHECONFIG /
$DROPBOXUPDIR/dropbox_uploader.sh upload $BACKUPPATH/$WPCONFIGFILEENC /


