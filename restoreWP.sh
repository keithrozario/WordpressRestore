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

echo -e "\\n\\n######### COMMAND LINE PARAMETERS BEGIN #########\\n\\n"

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    --dbpass) #database password for root user (not wordpress user!)
    DBPASS="$2"
    shift # past argument
    ;;
    --dropboxtoken)
    DROPBOXTOKEN="$2" #dropbox token for API connection
    shift # past argument
    ;;
    --enckey)
    ENCKEY="$2" #encryption/decryption key for sending/receiving files to/from dropbox
    shift # past argument
    ;;
    --cfemail)
    CFEMAIL="$2" #email of Cloudflare account
    shift # past argument
    ;;
    --cfkey)
    CFKEY="$2" #Cloudflare token for API connection
    shift # past argument
    ;;
    --cfzone)
    CFZONE="$2" #ZONE for the domain updated e.g. example.com
    shift # past argument
    ;;
    --cfrecord)
    CFRECORD="$2" #Actual record for domain updated e.g. www.example.com
    shift # past argument
    ;;
    --prodcert)
    PRODCERT="$2" #set to 1 to call production cert, any other value to call test
    shift # past argument
    ;;
    --domain)
    DOMAIN="$2" #Domain of site, used for Apache configurations 
    shift # past argument
    ;;
    --aprestore)
    APRESTORE="$2" #apache restore, set to 1 to restore apache
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z "$DBPASS" ]; then #Check DB Parameters
	echo "INFO: DB Password not provided...creating one"

	sudo apt-get install pwgen >>log.txt  #generate password using pwgen
	DBPASS="$(pwgen -1 -s 64)" >>log.txt

	echo "GOOD: Database parameters generated"
else
	echo "GOOD: Database parameters received"
fi

if [ -z "$DROPBOXTOKEN" ]; then #Check for Dropboxtoken
	echo "ERROR: Please provide the Dropbox Token, refer to http://bit.ly/2it95it to get one"
	exit 0
else
	echo "GOOD: Dropbox Parameters found"
fi

if [ -z "$CFEMAIL" ] || [ -z "$CFKEY" ] || [ -z "$CFZONE" ] || [ -z "$CFRECORD" ]; then #Check for Dropboxtoken
	echo "WARNING: Insufficient Cloudflare parameters, DNS record will not be updated"
	DNSUPDATE=false
else
	echo "GOOD: Cloudflare parameters received"
	DNSUPDATE=true
fi

if [ -z "$PRODCERT" ]; then #Check for Dropboxtoken
	echo "WARNING: --prodcert not set, let's encrypt certificate calling switched off"
else
	if [ $PRODCERT = 1 ]; then
		echo "GOOD: --prodcert set to 1, calling Let's Encrypt in Production mode"
	else
		echo "WARNING: --prodcert not set to 1, calling Let's Encrypt in test mode"
	fi
fi

if [ -z "$APRESTORE" ]; then #Restore Apache or build from scratch
	echo "INFO: Apache Settings will be built from scratch"
	if [ -z "$DOMAIN" ]; then
		echo "ERROR: No Domain provided, unable to proceed. Either set --apacherestore or provide a --domain"
		exit 0
	else
		echo "GOOD: Apache Domain set to $DOMAIN"
	fi
else
	if [ $APRESTORE = 1 ]; then
		echo "GOOD: --aprestore set to 1, restoring apache from backup files "
	else
		echo "ERROR: --aprestore set to value other than 1. Unknown setting, exiting..."
		exit 0
	fi
fi

echo -e "\\n\\n######### COMMAND LINE PARAMETERS END #########\\n\\n"

#---------------------------------------------------------------------------------------
# Global Constants
#---------------------------------------------------------------------------------------
LOGFILE=log.txt

WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILE=wp-config.php
WPSETTINGSFILE=.wpsettings
WPSETTINGSFILEDIR=/var

DEFAULTDROPBOXPATH=/var/Dropbox-Uploader

APACHECONFIG=apachecfg.tar
APACHEDIR=/etc/apache2
SITESAVAILABLEDIR=/etc/apache2/sites-available
DEFAULTAPACHECONF=000-default.conf
EIGHTSPACES="        " #used for tab-ing the $DOMAIN.conf file, literally 8 spaces

SWAPFILE=/swap #swapfile

#---------------------------------------------------------------------------------------
# DNS Update with Cloudflare - (done first because it takes time to propagate)
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### CLOUDFLARE UPDATE #########\\n\\n"

if [ "$DNSUPDATE" = true ]; then
	
	echo "INFO: Updating cloudflare record $CFRECORD in zone $CFZONE using credentials $CFEMAIL , $CFKEY "
	./cloudflare.sh --email $CFEMAIL --key $CFKEY --zone $CFZONE --record $CFRECORD
	echo "INFO: Removing Cloudflare script"
	rm cloudflare.sh #you only need it once
	echo "GOOD: Cloudflare update complete"
	
else
	echo "WARNING: DNS wasn't updated"
fi

echo -e "\\n\\n######### CLOUDFLARE UPDATE END#########"

#---------------------------------------------------------------------------------------
# Main-Initilization
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### REPO UPDATE #########\\n\\n"

echo "INFO: Updating REPO"
sudo apt-get update >>$LOGFILE
#we will upgrade after deletion of unwanted packages
export DEBIAN_FRONTEND=noninteractive #Silence all interactions

#---------------------------------------------------------------------------------------
# Remove previous installations if necessary
#---------------------------------------------------------------------------------------
echo "INFO: Attempting to delete older packages if they exist -- idempotency"
sudo apt-get --purge -y remove mysql* >>$LOGFILE #remove all mysql packages
sudo apt-get --purge -y remove apache2 >>$LOGFILE 
sudo apt-get --purge -y remove php >>$LOGFILE
sudo apt-get --purge -y remove libapache2-mod-php >>$LOGFILE
sudo apt-get --purge -y remove php-mcrypt >>$LOGFILE
sudo apt-get --purge -y remove php-mysql >>$LOGFILE
sudo apt-get --purge -y remove python-letsencrypt-apache >>$LOGFILE

sudo apt-get -y autoremove >>$LOGFILE
sudo apt-get -y autoclean >>$LOGFILE

echo "INFO: Upgrading installed packages" #do this after deletion to avoid upgrading packages set for deletion
sudo apt-get upgrade >>$LOGFILE

echo -e "\\n\\n######### REPO UPDATE COMPLETE #########\\n\\n"

#---------------------------------------------------------------------------------------
#Setup DropboxUploader
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Downloading from Dropbox #########\\n\\n"

GetDropboxUploader $DROPBOXTOKEN #in functions.sh

#---------------------------------------------------------------------------------------
#Download .wpsettings file
#---------------------------------------------------------------------------------------
rm *.enc #remove any old encrypted files
rm $WPSETTINGSFILEDIR/$WPSETTINGSFILE #remove old wpsettings file

echo "INFO: Checking if $WPSETTINGSFILE exist on Dropbox"
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSETTINGSFILE.enc #wpsettings file

if [ -f $WPSETTINGSFILE.enc ]; then
	echo "GOOD: $WPSETTINGSFILE exist, decrypting and loading"
	openssl enc -aes-256-cbc -d -in $WPSETTINGSFILE.enc -out $WPSETTINGSFILEDIR/$WPSETTINGSFILE -k $ENCKEY 
	echo "INFO: Loading $WPSETTINGSFILE"
	source "$WPSETTINGSFILEDIR/$WPSETTINGSFILE" 2>/dev/null #file exist, load variables
else 
	echo "ERROR: unable to find $WPSETTINGSFILE, check dropbox location to see if the file exists"
	exit 0
fi


#---------------------------------------------------------------------------------------
#Download files from dropbox
#---------------------------------------------------------------------------------------
rm $WPSQLFILE #remove old files if they exist
rm $APACHECONFIG
rm $WPZIPFILE
rm $WPCONFIGFILE

echo "INFO: Downloading and decrypting SQL backup file"
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSQLFILE.enc #Wordpress.sql file
openssl enc -aes-256-cbc -d -in $WPSQLFILE.enc -out $WPSQLFILE -k $ENCKEY 

echo "INFO: Downloading and decrypting Wordpress zip file"
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPZIPFILE.enc #zip file with all wordpress contents
openssl enc -aes-256-cbc -d -in $WPZIPFILE.enc -out $WPZIPFILE -k $ENCKEY

echo "INFO: Downloading and decrypting Apache configuration"
/var/Dropbox-Uploader/dropbox_uploader.sh download /$APACHECONFIG.enc #zip file with all wordpress contents
openssl enc -aes-256-cbc -d -in $APACHECONFIG.enc -out $APACHECONFIG -k $ENCKEY


if [ "$WPDIR" = "$WPCONFDIR" ]; then
	echo "INFO: wp-config is in $WPZIPFILE, no further downloads required"
else
	echo "INFO: wp-config is a separate file, downloading $WPCONFIGFILE from Dropbox"
	/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPCONFIGFILE.enc #encrypted Wp-config.php file
	openssl enc -aes-256-cbc -d -in $WPCONFIGFILE.enc -out $WPCONFIGFILE -k $ENCKEY
fi

rm *.enc #remove encrypted files after decryption
echo -e "\\n\\n######### Downloaded backup files from Dropbox #########\\n\\n"

#---------------------------------------------------------------------------------------
# Extracting Wordpress Files
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Extracting Wordpress Files #########\\n\\n"

if [ -d $WPDIR ]; then
	echo "WARNING: Removing older version of $WPDIR"
	rm -r $WPDIR #remove current directory (to avoid conflicts)
else 
	echo "GOOD: $WPDIR not found, proceeding to extraction"
fi

echo "INFO: Extracting $WPDIR"
mkdir -p $WPDIR
tar -xzf $WPZIPFILE -C $WPDIR .

if [ "$WPDIR" = "$WPCONFDIR" ]; then
	echo "INFO: wp-config file is part of $WPDIR, no further action required"
else
	echo "INFO: wp-config is a separate file, moving it to $WPCONFDIR"
	mv $WPCONFIGFILE $WPCONFDIR
	echo "INFO: wp-config file moved to $WPCONFDIR"
fi

echo "GOOD: Wordpress Files extracted"


#---------------------------------------------------------------------------------------
# Get DB Parameters from wp-config.php
#---------------------------------------------------------------------------------------

echo "INFO: Obtaining configuration parameters from wp-config.php"

WPDBNAME=`cat $WPCONFDIR/$WPCONFIGFILE | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFDIR/$WPCONFIGFILE | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFDIR/$WPCONFIGFILE | grep DB_PASSWORD | cut -d \' -f 4`

echo -e "\\n\\n######### Wordpress Extractiong Complete #########\\n\\n"
#---------------------------------------------------------------------------------------
# Install MySQL and Dependencies
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Installing mysql Server #########\\n\\n"
echo "INFO: Installing mysql-server"
sudo -E apt-get -q -y install mysql-server >>$LOGFILE  #non-interactive mysql installation

#Some security cleaning up on mysql-----------------------------------------------------
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
echo "INFO: Setting password for root user to $DBPASS"
mysql -u root -e "UPDATE mysql.user SET authentication_string=PASSWORD('$DBPASS') WHERE User='root';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DROP DATABASE IF EXISTS test;"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Create DB for Wordpress with user------------------------------------------------------
echo "INFO: Creating Database with name $WPDBNAME"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS $WPDBNAME;"
echo "INFO: Granting Permission to $WPDBUSER with password: $WPDBPASS"
mysql -u root -e "GRANT ALL ON *.* TO '$WPDBUSER'@'localhost' IDENTIFIED BY '$WPDBPASS';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Setup permission for my.cnf propery----------------------------------------------------
chmod 644 /etc/mysql/my.cnf

#Extract mysqlfiles---------------------------------------------------------------------
echo "INFO: Loading $WPSQLFILE into database $WPDBNAME"
mysql $WPDBNAME < $WPSQLFILE -u $WPDBUSER -p$WPDBPASS #load .sql file into newly created DB

echo -e "\\n\\n######### MYSQL Server Installed #########\\n\\n"
#---------------------------------------------------------------------------------------
# Basic Apache and PHP Installations
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Installing APACHE & PHP #########\\n\\n"
echo "INFO: Installing Apache2"
sudo apt-get -y install apache2 >>$LOGFILE #non-interactive apache2 install
echo "GOOD: Apache Installed"

echo "INFO: Installing PHP and libapache2-mod-php"
sudo apt-get -y install php >>$LOGFILE
sudo apt-get -y install libapache2-mod-php >>$LOGFILE
sudo apt-get -y install php-mcrypt >>$LOGFILE
sudo apt-get -y install php-mysql >>$LOGFILE
echo "GOOD: PHP Installed"

#---------------------------------------------------------------------------------------
# Loading Apache Configurations
#---------------------------------------------------------------------------------------

echo "INFO: Stopping Apache Service to load configurations"
sudo service apache2 stop

if [ $APRESTORE = 1 ]; then

	echo "INFO: Removing configurations file--to prevent conflicts"
	rm -r $APACHEDIR
	mkdir $APACHEDIR
	tar -xzf $APACHECONFIG -C $APACHEDIR .
	
else
	echo "INFO: Setting up Apache default values"
	echo "### WARNING: Apache config files will not be secured ###"
	echo "### Consider modifying the config files post-install ###"
	echo "INFO: Copying 000-default config for $DOMAIN.conf"
	cp $SITESAVAILABLEDIR/$DEFAULTAPACHECONF $SITESAVAILABLEDIR/$DOMAIN.conf #create a temporary Apache Configuration
	
	echo "INFO: Updating $DOMAIN.conf"	
	sed -i "/ServerAdmin*/aServerName $DOMAIN" $SITESAVAILABLEDIR/$DOMAIN.conf #insert ServerName setting
	sed -i "/ServerAdmin*/aServerAlias $DOMAIN" $SITESAVAILABLEDIR/$DOMAIN.conf #insert ServerAlias setting
	sed -i "s|\("DocumentRoot" * *\).*|\1$WPDIR|" $SITESAVAILABLEDIR/$DOMAIN.conf #change DocumentRoot to $WPDIR
	sed -i "/DocumentRoot*/a<Directory $WPDIR>\nAllowOverride All\nOrder allow,deny\nallow from all\n</Directory>" $SITESAVAILABLEDIR/$DOMAIN.conf
	sed -i "/ServerAdmin*/aServerAlias $DOMAIN" $SITESAVAILABLEDIR/$DOMAIN.conf #insert ServerAlias setting
	
	#Format $DOMAIN.conf file
	sed -i "s|\(^ServerName*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^ServerAlias*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^<Directory*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^AllowOverride*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^Order*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^allow*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i "s|\(^</Directory*\)|$EIGHTSPACES\1|" $SITESAVAILABLEDIR/$DOMAIN.conf #tab-ing
	sed -i '/#.*/ d' $SITESAVAILABLEDIR/$DOMAIN.conf #remove all comments in file (nice & clean!)
	
	echo "INFO: Enabling $DOMAIN on Apache"
	a2ensite $DOMAIN >>log.txt
	echo "GOOD: $DOMAIN enabled, restarting Apache2 service"
fi

rm $APACHECONFIG #remove downloaded Apache configurations
sudo a2enmod rewrite >>$LOGFILE #enable rewrite for permalinks to work
sudo service apache2 start

echo "GOOD: LAMP Stack Installed!!"
echo -e "\\n\\n######### APACHE & PHP INSTALLED #########\\n\\n"
#---------------------------------------------------------------------------------------
# Setup backup script & Cron jobs
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Setting CRON Job, Swap File and Firewall #########\\n\\n"

SetCronJob #from functions.sh
SetEncKey $ENCKEY
ENCKEY=0 #for security reasons set back to 0

#---------------------------------------------------------------------------------------
# Swap File creation (1GB) thanks to peteris.rocks for this code: http://bit.ly/2kf7KQm
#---------------------------------------------------------------------------------------
swapoff -a #switch of swap -- idempotency
rm $SWAPFILE
sudo fallocate -l 1G $SWAPFILE
sudo chmod 0600 $SWAPFILE
sudo mkswap $SWAPFILE
sudo swapon $SWAPFILE
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

#---------------------------------------------------------------------------------------
# Setup uncomplicated firewall rules for SSH, Http and Https: http://bit.ly/2kf7KQm
#---------------------------------------------------------------------------------------
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
echo y | sudo ufw enable
echo -e "\\n\\n######### CRON jobs, firewall and swap file COMPLETE #########\\n\\n"
#---------------------------------------------------------------------------------------
# Lets encrypt
#---------------------------------------------------------------------------------------
echo -e "\\n\\n######### Let's encrypt #########\\n\\n"
#Future Feature to ping $Domain and check if IP=this machine, only then proceed
#While possible to do this automatically, I prefer to use letsencrypt supported script
sudo apt-get -y install python-letsencrypt-apache >>$LOGFILE

if [ -z "$PRODCERT" ]; then #Check for prodcert
	echo "Let's encrypt not called, no certificate will be set"
else
	echo -e "\\n\\n######### Getting Certs #########"
	
	( crontab -l ; echo "0 6 * * * letsencrypt renew" ) | crontab -
	( crontab -l ; echo "0 23 * * * letsencrypt renew" ) | crontab -
	
	if [ $PRODCERT = 1 ]; then
		echo "WARNING: Obtaining production certs, these are rate-limited so be sure this is a Production server"
		letsencrypt --apache 
	else
		echo "Obtaining staging certs (for test)"
		letsencrypt --apache --staging
	fi
fi
echo -e "\\n\\n######### Let's encrypt COMPLETE #########\\n\\n"
#---------------------------------------------------------------------------------------
# All Done
#---------------------------------------------------------------------------------------
echo "GOOD: All Done"
