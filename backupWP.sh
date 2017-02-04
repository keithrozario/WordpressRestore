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
# Check if WPSETTINGSFILE and ENCKEY are present
#-------------------------------------------------------------------------
echo "\\n\\n######### Checking for .wpsettings and enckey #########\\n\\n"

if [ -f $WPSETTINGSFILE ]; then
    source "$WPSETTINGSFILE" 2>/dev/null #file exist, load variables
    echo "GOOD: .wpsettings file found"
else 
    echo "ERROR: Unable to find $WPSETTINGSFILE, please run setup.sh for first time"
    exit 0
fi

if [ -f $ENCKEYFILE ]; then
    source "$ENCKEYFILE" 2>/dev/null #file exist, load variables
    cho "GOOD: .enckey found"
else 
    echo "ERROR: Unable to find $ENCKEYFILE, please run setup.sh for first time"
    exit 0
fi

echo "\\n\\n######### Check end #########\\n\\n"
#-------------------------------------------------------------------------
# Global Constants
#-------------------------------------------------------------------------
WPSQLFILE=wordpress.sql 
WPZIPFILE=wordpress.tgz
WPCONFIGFILE=wp-config.php
APACHECONFIG=apachecfg.tar
LETSENCRYPTCONFIG=letsencrypt.tar
WPSETTINGSFILENAME=.wpsettings

APACHEDIR=/etc/apache2
BACKUPPATH=/var/backupWP
LETSENCRYPTDIR=/etc/letsencrypt

# WPDIR=/var/www/html #taken from .wpsettings file
# WPCONFDIR=/var/www/html #taken from .wpsettings file
# DROPBOXPATH=/var/Dropbox-Uploader #taken from .wpsettings file
# ENCKEY=<xxxx> #taken from .wpsettings file

#-------------------------------------------------------------------------
# Delete Previous files if they exist (ensure idempotency)
#-------------------------------------------------------------------------
echo "\\n\\n######### Creating Backup Path #########\\n\\n"
if [ -d $BACKUPPATH ]; then
    echo "WARNING: Removing older version of $BACKUPPATH"
    rm -r $BACKUPPATH #remove current directory (to avoid conflicts)
    mkdir $BACKUPPATH
else 
    echo "$BACKUPPATH not found, creating path"
    mkdir $BACKUPPATH
fi
echo "\\n\\n######### Backup Path created #########\\n\\n"
#-------------------------------------------------------------------------
# mysqldump the MYSQL Database
#-------------------------------------------------------------------------
echo "\\n\\n######### Backing Up Mysql Database #########\\n\\n"
WPDBNAME=`cat $WPCONFDIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFDIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFDIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

if [ -z $WPDBNAME ]; then
    echo "ERROR: unable to extract DB NAME from $WPCONFDIR/wp-config.php"
    exit 0
else
    echo "INFO: Dumping MYSQL Files"
    mysqldump -u $WPDBUSER -p$WPDBPASS $WPDBNAME > $BACKUPPATH/$WPSQLFILE
    echo "GOOD: MYSQL successfully backed up to $BACKUPPATH/$WPSQLFILE"
fi
echo "\\n\\n######### Database Backup Complete #########\\n\\n"

#-------------------------------------------------------------------------
# Zip $WPDIR folder
#-------------------------------------------------------------------------
echo "\\n\\n######### Zipping Wordpress #########\\n\\n"

echo "INFO: Zipping the $WPDIR to : $BACKUPPATH/$WPZIPFILE"
tar -czf $BACKUPPATH/$WPZIPFILE -C $WPDIR . #turn off verbose and don't keep directory structure
echo "INFO: $WPDIR successfully zipped to $BACKUPPATH/$WPZIPFILE"

echo "\\n\\n######### Zipping Wordpress END #########\\n\\n"
#-------------------------------------------------------------------------
# Copy all Apache Configurations files
#-------------------------------------------------------------------------
echo "\\n\\n######### Zipping APACHE BEGIN #########\\n\\n"
echo "INFO: Zipping $APACHEDIR"
tar -czf $BACKUPPATH/$APACHECONFIG -C $APACHEDIR . #turn off verbose and don't keep directory structure
echo "INFO: $APACHEDIR successfully zipped to $BACKUPPATH/$WPZIPFILE"
echo "\\n\\n######### Zipping APACHE BEGIN #########\\n\\n"

#-------------------------------------------------------------------------
# Encrypting files before uploading
#-------------------------------------------------------------------------
echo "\\n\\n######### Encrypting files BEGIN #########\\n\\n"

echo "INFO: Encrypting MYSQL FIles"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPSQLFILE -out $BACKUPPATH/$WPSQLFILE.enc -k $ENCKEY
rm $BACKUPPATH/$WPSQLFILE #remove unencrypted file

echo "INFO: Encrypting Wordpress Backup file:"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPZIPFILE -out $BACKUPPATH/$WPZIPFILE.enc -k $ENCKEY
rm $BACKUPPATH/$WPZIPFILE #remove unencrypted file

echo "INFO: Encrypting Apache Configuration"
openssl enc -aes-256-cbc -in $BACKUPPATH/$APACHECONFIG -out $BACKUPPATH/$APACHECONFIG.enc -k $ENCKEY
rm $BACKUPPATH/$APACHECONFIG #remove unencrypted file



# Encrypt wp-config.php file
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    echo "INFO: Encrypting wp-config.php file in $WPCONFDIR"   
    openssl enc -aes-256-cbc -in $WPCONFDIR/$WPCONFIGFILE -out $BACKUPPATH/$WPCONFIGFILE.enc -k $ENCKEY
else
    echo "INFO: wp-config.php file is in the wordpress directory, no separate zipping necessary"
fi

openssl enc -aes-256-cbc -in $WPSETTINGSFILE -out $BACKUPPATH/$WPSETTINGSFILENAME.enc -k $ENCKEY
echo "WARNING: The encryption key in $ENCKEYFILE will not be uploaded to Dropbox"
echo "WARNING: Store $ENCKEYFILE in a safe place"
echo "\\n\\n######### Encrypting files END #########\\n\\n"

#-------------------------------------------------------------------------
# Upload to Dropbox
#-------------------------------------------------------------------------
echo "\\n\\n######### Upload to Dropbox BEGIN #########\\n\\n"

echo "INFO: Uploading Files to Dropbox"
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPSQLFILE.enc /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPZIPFILE.enc /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$APACHECONFIG.enc /
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    $DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPCONFIGFILE.enc /
fi
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPSETTINGSFILENAME.enc /

echo "\\n\\n######### Upload to Dropbox END #########\\n\\n"

#-------------------------------------------------------------------------
# Lets Encrypt
#-------------------------------------------------------------------------
echo "\\n\\n######### LetsEncrypt BEGIN #########\\n\\n"
if [ -d $LETSENCRYPTDIR ]; then
    echo "INFO: LetsEncrypt detected, backing up files"
    tar -czf $BACKUPPATH/$LETSENCRYPTCONFIG -C $LETSENCRYPTDIR .
    echo "INFO: Encrypting Letsencrypt Configuration"
    openssl enc -aes-256-cbc -in $BACKUPPATH/$LETSENCRYPTCONFIG -out $BACKUPPATH/$LETSENCRYPTCONFIG.enc -k $ENCKEY
    rm $BACKUPPATH/$LETSENCRYPTCONFIG #remove unencrypted file
    echo "INFO: Uploading Letsencrypt to Dropbox"
    $DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$LETSENCRYPTCONFIG.enc
else
    echo "LetsEncrypt not found"
fi
echo "\\n\\n######### LetsEncrypt BEGIN #########\\n\\n"

echo "END"
