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
WPSQLFILE=wordpress.sql.enc #.enc is the encrypted file
WPZIPFILE=wordpress.tgz.enc #.enc is the encrypted file

APACHECONFIG=apachecfg.tar.enc
BACKUPPATH=/var/backupWP

# WPDIR=/var/www/html #taken from .wpsettings file
# WPCONFDIR=/var/www/html #taken from .wpsettings file
# DROPBOXPATH=/var/Dropbox-Uploader #taken from .wpsettings file
# ENCKEY=<xxxx> #taken from .wpsettings file

#-------------------------------------------------------------------------
# Delete Previous files if they exist (ensure idempotency)
#-------------------------------------------------------------------------
rm -r $BACKUPPATH
mkdir $BACKUPPATH

#-------------------------------------------------------------------------
# mysqldump the MYSQL Database
#-------------------------------------------------------------------------
WPDBNAME=`cat $WPCONFDIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFDIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFDIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

echo "Dumping MYSQL Files"
mysqldump -u $WPDBUSER -p$WPDBPASS $WPDBNAME > $BACKUPPATH/$WPSQLFILE.temp
echo "Encrypting MYSQL FIles"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPSQLFILE.temp -out $BACKUPPATH/$WPSQLFILE -k $ENCKEY
rm $BACKUPPATH/$WPSQLFILE.temp #remove unencrypted file
echo "MYSQL successfully backed up to $BACKUPPATH/$WPSQLFILE"

#-------------------------------------------------------------------------
# Zip $WPDIR folder
#-------------------------------------------------------------------------
echo "Zipping the Wordpress Directory in : $WPDIR"
tar -czf $BACKUPPATH/$WPZIPFILE.temp -C $WPDIR #turn off verbose and don't keep directory structure
echo "Encrypting TAR file:"
openssl enc -aes-256-cbc -in $BACKUPPATH/$WPZIPFILE.temp -out $BACKUPPATH/$WPZIPFILE -k $ENCKEY
rm $BACKUPPATH/$WPZIPFILE.temp
echo "Wordpress Directory successfully zipped to $BACKUPPATH/$WPZIPFILE"

#-------------------------------------------------------------------------
# Encrypt wp-config.php file
#-------------------------------------------------------------------------
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    echo "Encrypting wp-config.php file in $WPCONFDIR"   
    openssl enc -aes-256-cbc -in $WPCONFDIR/wp-config.php -out $BACKUPPATH/wp-config.php -k $ENCKEY
else
    echo "wp-config.php file is in the wordpress directory, no separate zipping necessary"
fi

#-------------------------------------------------------------------------
# Copy all Apache Configurations files
#-------------------------------------------------------------------------
tar cvf $BACKUPPATH/$APACHECONFIG /etc/apache2/sites-enabled
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/sites-available
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/apache2.conf
tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/ports.conf

#copy the following files only if they exist
if [ -f /etc/apache2/ssl ]; then
    tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/ssl
fi

if [ -f /etc/apache2/.htpasswd ]; then
    tar -rvf $BACKUPPATH/$APACHECONFIG /etc/apache2/.htpasswd
fi

#-------------------------------------------------------------------------
# Upload to Dropbox
#-------------------------------------------------------------------------
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPSQLFILE /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPZIPFILE /
$DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$APACHECONFIG /
if [ "$WPCONFDIR" != "$WPDIR" ]; then #already copied, don't proceed
    $DROPBOXPATH/dropbox_uploader.sh upload $BACKUPPATH/$WPCONFIGFILE /
fi
$DROPBOXPATH/dropbox_uploader.sh upload $WPSETTINGSFILE /
