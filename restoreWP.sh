#!/bin/bash
# Wordpress Restorer v1.0
# Backups and restores wordpress with one click
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
	source "$FUNCTIONSFILE" 2>/dev/null #file exist, load variables
else 
	echo "Unable to find $FUNCTIONSFILE, please run setup.sh for first time"
    	exit 0
fi

#---------------------------------------------------------------------------------------
# Command line parameters
#---------------------------------------------------------------------------------------

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    --dbrootpass)
    DBPASS="$2"
    shift # past argument
    ;;
    --dropboxtoken)
    DROPBOXTOKEN="$2"
    shift # past argument
    ;;
    --enckey)
    ENCKEY="$2"
    shift # past argument
    ;;
	--cfemail)
    CFEMAIL="$2"
    shift # past argument
    ;;
	--cfkey)
    CFKEY="$2"
    shift # past argument
    ;;
	--cfzone)
    CFZONE="$2"
    shift # past argument
    ;;
	--cfrecord)
    CFRECORD="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z "$DBPASS" ]; then #Check DB Parameters
echo "Please provide a root password for the Database";
exit 0
else
echo "Database parameteres : Good"
fi

if [ -z "$DROPBOXTOKEN" ]; #Check for Dropboxtoken
then echo "Please provide the Dropbox Token, refer to http://bit.ly/2it95it to get one"
exit 0
else
echo "Dropbox parameteres : Good"
fi

if [ -z "$CFEMAIL" ] || [ -z "$CFKEY" ] || [ -z "$CFZONE" ] || [ -z "$CFRECORD" ]; #Check for Dropboxtoken
then echo "Insufficient Cloudflare parameters, DNS record will not be updated"
DNSUPDATE=false
else
echo "Cloudflare Parameters : Good"
DNSUPDATE=true
fi

#---------------------------------------------------------------------------------------
# Global Constants
#---------------------------------------------------------------------------------------
PRODUCTIONCERT=false

WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILE=wp-config.php
APACHECONFIG=apachecfg.tar
WPSETTINGSFILE=.wpsettings
WPSETTINGSFILEDIR=/var

#---------------------------------------------------------------------------------------
# DNS Update with Cloudflare - (done first because it takes time to propagate)
#---------------------------------------------------------------------------------------

if [ "$DNSUPDATE" = true ]; then

	echo "Getting Cloudflare script from $URLCLOUDFLARESHELLSCRIPT"
	echo "Updating cloudflare record $CFRECORD in zone $CFZONE using credentials $CFEMAIL , $CFKEY "
	./cloudflare.sh --email $CFEMAIL --key $CFKEY --zone $CFZONE --record $CFRECORD
	echo "Removing Cloudflare script"
	rm cloudflare.sh #you only need it once
	
else

	echo "WARNING: DNS wasn't updated"
	
fi


#---------------------------------------------------------------------------------------
#Setup DropboxUploader
#---------------------------------------------------------------------------------------

GetDropboxUploader $DROPBOXTOKEN

#---------------------------------------------------------------------------------------
#Download .wpsettings file
#---------------------------------------------------------------------------------------

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSETTINGSFILE.enc #Wordpress.sql file
openssl enc -aes-256-cbc -d -in $WPSETTINGSFILE.enc -out $WPSETTINGSFILEDIR/$WPSETTINGSFILE -k $ENCKEY 

if [ -f $WPSETTINGSFILEDIR/$WPSETTINGSFILE ]; then
	echo "Loading $WPSETTINGSFILE"
	source "$WPSETTINGSFILEDIR/$WPSETTINGSFILE" 2>/dev/null #file exist, load variables
else 
	echo "Unable to find $WPSETTINGSFILE, check dropbox location to see if the file exists"
    	exit 0
fi

#---------------------------------------------------------------------------------------
#Download files from dropbox
#---------------------------------------------------------------------------------------

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSQLFILE.enc #Wordpress.sql file
openssl enc -aes-256-cbc -d -in $WPSQLFILE.enc -out $WPSQLFILE -k $ENCKEY 

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPZIPFILE.enc #zip file with all wordpress contents
openssl enc -aes-256-cbc -d -in $WPZIPFILE.enc -out $WPZIPFILE -k $ENCKEY

/var/Dropbox-Uploader/dropbox_uploader.sh download /$APACHECONFIG.enc #zip file with all wordpress contents
openssl enc -aes-256-cbc -d -in $APACHECONFIG.enc -out $APACHECONFIG -k $ENCKEY

if [ "$WPDIR" = "$WPCONFDIR" ]; then
	echo "wp-config is in $WPZIPFILE, no further downloads required"
else
	echo "wp-config is a separate file, downloading $WPCONFIGFILE from Dropbox"
	/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPCONFIGFILE.enc #encrypted Wp-config.php file
	openssl enc -aes-256-cbc -d -in $WPCONFIGFILE.enc -out $WPCONFIGFILE -k $ENCKEY
fi

rm *.enc #remove encrypted files after decryption

#---------------------------------------------------------------------------------------
# Extracting Wordpress Files
#---------------------------------------------------------------------------------------

if [ -d $WPDIR ]; then
echo "Removing older version of $WPDIR"
rm -r $WPDIR #remove current directory (to avoid conflicts)
else 
echo "$WPDIR not found, proceeding to extraction"
fi

mkdir -p $WPDIR
tar -xzf $WPZIPFILE -C $WPDIR .

if [ "$WPDIR" = "$WPCONFDIR" ]; then
	echo "wp-config file is part of $WPDIR, no further action required"
else
	echo "wp-config is a separate file, moving it to $WPCONFDIR"
	mv $WPCONFIGFILE $WPCONFDIR
	echo "wp-config file moved to $WPCONFDIR"
fi

echo "Wordpress Files extracted"

#---------------------------------------------------------------------------------------
# Get DB Parameters from wp-config.php
#---------------------------------------------------------------------------------------

echo "Obtaining configuration parameters from wp-config.php"

WPDBNAME=`cat $WPCONFDIR/wp-config.php | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFDIR/wp-config.php | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFDIR/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`

#---------------------------------------------------------------------------------------
# Main-Initilization
#---------------------------------------------------------------------------------------

sudo apt-get update 
export DEBIAN_FRONTEND=noninteractive #Silence all interactions

#---------------------------------------------------------------------------------------
# Install MySQL and Dependencies
#---------------------------------------------------------------------------------------

sudo -E apt-get -q -y install mysql-server #non-interactive mysql installation

#Some security cleaning up on mysql-----------------------------------------------------
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
echo "Setting password for root user to $DBPASS"
mysql -u root -e "UPDATE mysql.user SET authentication_string=PASSWORD('$DBPASS') WHERE User='root';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DROP DATABASE IF EXISTS test;"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Create DB for Wordpress with user------------------------------------------------------
echo "Creating Database with name $WPDBNAME"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS $WPDBNAME;"
echo "Granting Permission to $WPDBUSER with password: $WPDBPASS"
mysql -u root -e "GRANT ALL ON *.* TO '$WPDBUSER'@'localhost' IDENTIFIED BY '$WPDBPASS';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Setup permission for my.cnf propery----------------------------------------------------
chmod 644 /etc/mysql/my.cnf

#Extract mysqlfiles---------------------------------------------------------------------
echo "Loading $WPSQLFILE into database $WPDBNAME"
mysql $WPDBNAME < $WPSQLFILE -u $WPDBUSER -p$WPDBPASS #load .sql file into newly created DB

#---------------------------------------------------------------------------------------
# Apache Setup and Dependencies
#---------------------------------------------------------------------------------------

sudo apt-get -y install apache2 #non-interactive apache2 install
echo "Apache Installed, loading Apache configuration"
tar -xvf $APACHECONFIG -C / #untar to correct location
sudo service apache2 restart
exit 0

#---------------------------------------------------------------------------------------
# Wordpress and PHP setup
#---------------------------------------------------------------------------------------

sudo apt-get -y install php 
sudo apt-get -y install libapache2-mod-php
sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-mysql

sudo service apache2 restart

#---------------------------------------------------------------------------------------
# Setup backup script
#---------------------------------------------------------------------------------------
SetCronJob #from functions.sh

#---------------------------------------------------------------------------------------
# Lets encrypt
#---------------------------------------------------------------------------------------
( crontab -l ; echo "0 6 * * * letsencrypt renew" ) | crontab -
( crontab -l ; echo "0 23 * * * letsencrypt renew" ) | crontab -

sudo apt-get -y install python-letsencrypt-apache #silent installation of letsencrypt

if [ "$PRODUCTIONCERT" = true ] ; then 
	echo "WARNING: Obtaining production certs, these are rate-limited so be sure this is a Production server"
	letsencrypt --apache 
else
	echo "Obtaining staging certs (for test)"
	letsencrypt --apache --staging
fi


