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
    --dbname)
    DBNAME="$2"
    shift # past argument
    ;;
    --wpdbuser)
    WPDBUSER="$2"
    shift # past argument
    ;;
    --wpdbpass)
    WPDBPASS="$2"
    shift # past argument
    ;;
    --dropboxtoken)
    DROPBOXTOKEN="$2"
    shift # past argument
    ;;
	--wpconfpass)
    WPCONFPASS="$2"
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
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z "$DBPASS" ] || [ -z "$DBNAME" ];  #Check DB Parameters
then echo "Please provide all Database Parameters: --dbpass, --dbname ";
exit 0
else
echo "Database parameteres : Good"
fi

if [ -z "$WPDBUSER" ] || [ -z "$WPDBPASS" ] || [ -z "$WPCONFPASS" ]; #Check Wordpress Parameters
then echo "Unable to proceed, insufficient wordpress parameters: --wpdbuser, --wpdbpass & --wpconfpass. Check your wp-config.php file"; 
exit 0
else
echo "Wordpress parameteres : Good"
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
WPCONFIGFILEENC=wp-config.php.enc
APACHECONFIG=apachecfg_static.tar

URLDROPBOXDOWNLOADER="https://github.com/andreafabrizi/Dropbox-Uploader.git" #Github for Dropbox Uploader

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
# Download backup files from dropbox
# Special Thanks to AndreaFabrizi https://github.com/andreafabrizi
#---------------------------------------------------------------------------------------

echo "Saving Token : $DROPBOXTOKEN to file"
echo "OAUTH_ACCESS_TOKEN=$DROPBOXTOKEN" > ~/.dropbox_uploader
echo "Downloading DropboxDownloader from $URLDROPBOXDOWNLOADER"
git clone $URLDROPBOXDOWNLOADER /var/Dropbox-Uploader
chmod +x /var/Dropbox-Uploader/dropbox_uploader.sh

/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSQLFILE #Wordpress.sql file
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPZIPFILE #zip file with all wordpress contents
/var/Dropbox-Uploader/dropbox_uploader.sh download /$APACHECONFIG #Apache configurations
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPCONFIGFILEENC #encrypted Wp-config.php file
	
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


