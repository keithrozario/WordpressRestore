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

WPCONFPASSFILE=~/.wpconfpass

#-------------------------------------------------------------------------
# Check if WPCONFPASSFILE or WPCONFPASSARG--or both!
#-------------------------------------------------------------------------
if [ -f $WPCONFPASSFILE ]; then
    source "$WPCONFPASSFILE" 2>/dev/null #file exist, load variables
else 
    echo "Unable to find $WPCONFPASSFILE, please run setup.sh for first time setup"
fi

#-------------------------------------------------------------------------
# FileNames
#-------------------------------------------------------------------------
WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILEENC=wp-config.php.enc
APACHECONFIG=apachecfg_dynamic.tar
BACKUPPATH=/var/backupWP
WPDIR=/var/www/html
WPCONFIGDIR=/var/html
DROPBOXUPDIR=/var/Dropbox-Uploader

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
WPDBNAME=`cat $WPDIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPDIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPDIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

mysqldump -u $WPDBUSER -p$WPDBPASS $WPDBNAME > $BACKUPPATH/$WPSQLFILE

#-------------------------------------------------------------------------
# Zip /var/www folder
#-------------------------------------------------------------------------
tar czf $BACKUPPATH/$WPZIPFILE $WPDIR #turn off verbose (it's too noisy!!)

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

#-------------------------------------------------------------------------
# Delete Backups (for security purposes)
#-------------------------------------------------------------------------
rm $BACKUPPATH/$WPZIPFILE
rm $BACKUPPATH/$WPSQLFILE
rm $BACKUPPATH/$APACHECONFIG
rm $BACKUPPATH/$WPCONFIGFILEENC


