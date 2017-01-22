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
WPCONFIGFILEENC=wp-config.php
APACHECONFIG=apachecfg_static.tar
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
# Main-Initilization
#---------------------------------------------------------------------------------------

sudo apt-get update 
export DEBIAN_FRONTEND=noninteractive #Silence all interactions


#---------------------------------------------------------------------------------------
#Setup DropboxUploader
#---------------------------------------------------------------------------------------

GetDropboxUploader $DROPBOXTOKEN

#---------------------------------------------------------------------------------------
#Download .wpsettings file
#---------------------------------------------------------------------------------------

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSETTINGSFILE #Wordpress.sql file
openssl enc -aes-256-cbc -d -in $WPSETTINGSFILE -out $WPSETTINGSFILEDIR/$WPSETTINGSFILE -k $ENCKEY 

if [ -f $WPSETTINGSFILEDIR/$WPSETTINGSFILE ]; then
	echo "Loading $WPSETTINGSFILE"
	source "$WPSETTINGSFILE" 2>/dev/null #file exist, load variables
	
	if [ "$WPDIR" = "$WPCONFDIR" ]; then
		WPSINGLEDIR=True
	else
		WPSINGLEDIR=False
	fi
else 
	echo "Unable to find $WPSETTINGSFILE, check dropbox location to see if the file exists"
    	exit 0
fi

#---------------------------------------------------------------------------------------
#Download files from dropbox
#---------------------------------------------------------------------------------------

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSQLFILE.enc #Wordpress.sql file
openssl enc -aes-256-cbc -d -in $WPSQLFILE.enc -out $WPSQLFILE -k $ENCKEY 

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPZIPFILE #zip file with all wordpress contents
openssl enc -aes-256-cbc -d -in $WPZIPFILE.enc -out $WPZIPFILE -k $ENCKEY

if [ "$WPDIR" = "$WPCONFDIR" ]; then
	echo "wp-config is a separate file, downloading $WPCONFIGFILEENC from Dropbox"
	/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPCONFIGFILEENC #encrypted Wp-config.php file
else
	echo "wp-config is in $WPZIPFILE"
fi

###temporary breakpoint
exit 0

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
echo "Creating Database with name $DBNAME"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DBNAME;"
echo "Granting Permission to $WPDBUSER with password: $WPDBPASS"
mysql -u root -e "GRANT ALL ON *.* TO '$WPDBUSER'@'localhost' IDENTIFIED BY '$WPDBPASS';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Setup permission for my.cnf propery----------------------------------------------------
chmod 644 /etc/mysql/my.cnf

#Extract mysqlfiles---------------------------------------------------------------------
mysql wordpress < $WPSQLFILE -u $WPDBUSER -p$WPDBPASS #load .sql file into newly created DB

#---------------------------------------------------------------------------------------
# Apache Setup and Depdencies
#---------------------------------------------------------------------------------------

sudo apt-get -y install apache2 #non-interactive apache2 install

tar xvf $APACHECONFIG #extract apache2 configuration as downloaded
sudo service apache2 restart

#---------------------------------------------------------------------------------------
# Wordpress and PHP setup
#---------------------------------------------------------------------------------------

sudo apt-get -y install php 
sudo apt-get -y install libapache2-mod-php
sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-mysql

rm -r /var/www #remove current directory (to avoid conflicts)
tar xzf $WPZIPFILE
rm $WPZIPFILE

#Decrypt and extract wp-config.php file-------------------------------------------------
openssl enc -aes-256-cbc -d -in $WPCONFIGFILEENC -out /var/wp-config.php -k $WPCONFPASS 
rm $WPCONFIGFILEENC
echo "WPCONFPASS=$WPCONFPASS" > ~/.wpconfpass #store wpconfigpass in config file

sudo service apache2 restart #restart apache for php to take effect

#---------------------------------------------------------------------------------------
# Download backup script
#---------------------------------------------------------------------------------------
mv Backup.sh /var
( crontab -l ; echo "0 23 * * * /var/Backup.sh" ) | crontab - #cron-job the backup-script


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


