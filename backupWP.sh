#!/bin/bash
# File: Backup.sh
# Backups wordpress with one click
#
# Author: Keith Rozario <keith@keithrozario.com>
# Usage:./backupWP.sh 
#       Ensure you've run ./setup.sh first, to setup the encryption key and download Dropbox-Uploader           
#
# This work is licensed under the
# Creative Commons Attribution 4.0 International License.
# To view a copy of this license, visit 
# http://creativecommons.org/licenses/by/4.0/ or 
# send a letter to 
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#


WPSETTINGSFILE=/var/.wpsettings
ENCKEYFILE=/var/.enckey

#-------------------------------------------------------------------------
# Check if WPCONFPASSFILE or WPCONFPASSARG--or both!
#-------------------------------------------------------------------------
if [ -f $WPSETTINGSFILE ]; then
    source "$WPSETTINGSFILE" 2>/dev/null #file exist, load variables
else 
    echo "Unable to find $WPSETTINGSFILE, please run setup.sh for first time"
    exit 0
fi

if [ -f $ENCKEYFILE ]; then
    source "$ENCKEYFILE" 2>/dev/null #file exist, load variables
else 
    echo "Unable to find $ENCKEYFILE, please run setup.sh for first time"
    exit 0
fi

#-------------------------------------------------------------------------
# Global Constants
#-------------------------------------------------------------------------
WPSQLFILE=wordpress.sql 
WPZIPFILE=wordpress.tgz
WPCONFIGFILE=wp-config.php
APACHECONFIG=apachecfg.tar
WPSETTINGSFILENAME=.wpsettings
APACHEDIR=/etc/apache2
BACKUPPATH=/var/backupWP

# WPDIR=/var/www/html #taken from .wpsettings file
# WPCONFDIR=/var/www/html #taken from .wpsettings file
# DROPBOXPATH=/var/Dropbox-Uploader #taken from .wpsettings file
# ENCKEY=<xxxx> #taken from .wpsettings file

#-------------------------------------------------------------------------
# Delete Previous files if they exist (ensure idempotency)
#-------------------------------------------------------------------------
if [ -d $BACKUPPATH ]; then
echo "Removing older version of $BACKUPPAT"
rm -r $BACKUPPATH #remove current directory (to avoid conflicts)
mkdir $BACKUPPATH
else 
echo "$BACKUPPATH not found, proceeding to extraction"
fi

#-------------------------------------------------------------------------
# mysqldump the MYSQL Database
#-------------------------------------------------------------------------
WPDBNAME=`cat $WPCONFDIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFDIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFDIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

echo "Dumping MYSQL Files"
mysqldump -u $WPDBUSER -p$WPDBPASS $WPDBNAME > $BACKUPPATH/$WPSQLFILE

echo "MYSQL successfully backed up to $BACKUPPATH/$WPSQLFILE"

#-------------------------------------------------------------------------
# Zip $WPDIR folder
#-------------------------------------------------------------------------
echo "Zipping the Wordpress Directory in : $WPDIR"
tar -czf $BACKUPPATH/$WPZIPFILE -C $WPDIR . #turn off verbose and don't keep directory structure
echo "Wordpress Directory successfully zipped to $BACKUPPATH/$WPZIPFILE"


#-------------------------------------------------------------------------
# Copy all Apache Configurations files
#-------------------------------------------------------------------------
tar czf $BACKUPPATH/$APACHECONFIG $APACHEDIR

#-------------------------------------------------------------------------
# Encrypting files before uploading
#-------------------------------------------------------------------------
echo "Encrypting MYSQL FIles"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPSQLFILE -out $BACKUPPATH/$WPSQLFILE.enc -k $ENCKEY
rm $BACKUPPATH/$WPSQLFILE #remove unencrypted file

echo "Encrypting TAR file:"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPZIPFILE -out $BACKUPPATH/$WPZIPFILE.enc -k $ENCKEY
rm $BACKUPPATH/$WPZIPFILE #remove unencrypted file

echo "encrypting Apache Configuration"
openssl enc -aes-256-cbc -in $BACKUPPATH/$APACHECONFIG -out $BACKUPPATH/$APACHECONFIG.enc -k $ENCKEY
rm $BACKUPPATH/$APACHECONFIG #remove unencrypted file

# Encrypt wp-config.php file
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    echo "Encrypting wp-config.php file in $WPCONFDIR"   
    openssl enc -aes-256-cbc -in $WPCONFDIR/$WPCONFIGFILE -out $BACKUPPATH/$WPCONFIGFILE.enc -k $ENCKEY
else
    echo "wp-config.php file is in the wordpress directory, no separate zipping necessary"
fi

openssl enc -aes-256-cbc -in $WPSETTINGSFILE -out $BACKUPPATH/$WPSETTINGSFILENAME.enc -k $ENCKEY

#-------------------------------------------------------------------------
# Upload to Dropbox
#-------------------------------------------------------------------------
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPSQLFILE.enc /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPZIPFILE.enc /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$APACHECONFIG.enc /
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    $DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPCONFIGFILE.enc /
fi
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPSETTINGSFILENAME.enc /
