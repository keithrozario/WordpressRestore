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

#Get the command-line arguments

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

#check if mandatory parameters are supplied
if [ -z "$DBPASS" ] || [ -z "$DBNAME" ]; 
then echo "Please provide all Database Parameters: --dbpass, --dbname ";
exit 0
else
echo "Database parameteres : Good"
fi

if [ -z "$WPDBUSER" ] || [ -z "$WPDBPASS" ] || [ -z "$WPCONFPASS" ]; 
then echo "Unable to proceed, insufficient wordpress parameters: --wpdbuser, --wpdbpass & --wpconfpass. Check your wp-config.php file"; 
exit 0
else
echo "Wordpress parameteres : Good"
fi

if [ -z "$DROPBOXTOKEN" ]; 
then echo "Please provide the Dropbox Token, refer to http://bit.ly/2it95it to get one"
exit 0
else
echo "Dropbox parameteres : Good"
fi

if [ -z "$CFEMAIL" ] || [ -z "$CFKEY" ] || [ -z "$CFZONE" ] || [ -z "$CFRECORD" ];
then echo "Insufficient Cloudflare parameters, DNS record will not be updated"
DNSUPDATE=false
else
echo "Cloudflare Parameters : Good"
DNSUPDATE=true
fi

echo "DNSUPDATE = $DNSUPDATE"

####Filenames##########################################################
PRODUCTIONCERT=false

WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILEENC=wp-config.php.enc
APACHECONFIG=apachecfg_static.tar

URLDROPBOXDOWNLOADER="https://github.com/andreafabrizi/Dropbox-Uploader.git"
URLBACKUPSHELLSCRIPT="https://www.dropbox.com/s/0z3erarvfhaq8gy/Backup.sh"
URLCLOUDFLARESHELLSCRIPT="https://www.dropbox.com/s/l713o9dq5fq00cn/cloudflare.sh"
####Filenames##########################################################

#Apt-get Update (best practice :))
sudo apt-get update

#Silence all interactions
export DEBIAN_FRONTEND=noninteractive


####Download Files from Dropbox#########################################


#Setup Dropbox Uploader
#Special Thanks to AndreaFabrizi
sudo apt-get -y install git
echo "Saving Token : $DROPBOXTOKEN to file"
echo "OAUTH_ACCESS_TOKEN=$DROPBOXTOKEN" > ~/.dropbox_uploader
echo "Downloading DropboxDownloader from $URLDROPBOXDOWNLOADER"
git clone $URLDROPBOXDOWNLOADER /var/Dropbox-Uploader
chmod +x /var/Dropbox-Uploader/dropbox_uploader.sh

#Download Files from Dropbox
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPSQLFILE
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPZIPFILE
/var/Dropbox-Uploader/dropbox_uploader.sh download /$APACHECONFIG
/var/Dropbox-Uploader/dropbox_uploader.sh download /$WPCONFIGFILEENC
	
####End Dropbox Download###############################################



####MYSQL Setup######################################################


#Install mysql
sudo -E apt-get -q -y install mysql-server

#Some security cleaning up on mysql
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
echo "Setting password for root user to $DBPASS"
mysql -u root -e "UPDATE mysql.user SET authentication_string=PASSWORD('$DBPASS') WHERE User='root';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DROP DATABASE IF EXISTS test;"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Create DB for Wordpress with user
echo "Creating Database with name $DBNAME"
mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DBNAME;"
echo "Granting Permission to $WPDBUSER with password: $WPDBPASS"
mysql -u root -e "GRANT ALL ON *.* TO '$WPDBUSER'@'localhost' IDENTIFIED BY '$WPDBPASS';"
mysql -u root -e "FLUSH PRIVILEGES;"

#Setup permission for my.cnf properly (defaults to 777)
chmod 644 /etc/mysql/my.cnf

#Extract mysqlfiles
mysql wordpress < $WPSQLFILE -u $WPDBUSER -p$WPDBPASS
rm $WPSQLFILE

####END MYSQL Setup################################################



####APACHE2 Setup##################################################

#Setup Apache#
sudo apt-get -y install apache2

#Extract and Setup Apache
tar xvf $APACHECONFIG
sudo service apache2 restart
rm $APACHECONFIG

####END APACHE2 Setup##############################################



####WORDPRESS & PHP Setup##########################################
#Install all other depedencies (PHP and GIT)

sudo apt-get -y install php 
sudo apt-get -y install libapache2-mod-php
sudo apt-get -y install php-mcrypt
sudo apt-get -y install php-mysql


#Extract Wordpress files/
rm -r /var/www
tar xzf $WPZIPFILE
rm $WPZIPFILE

#decrypt wp-config.php
openssl enc -aes-256-cbc -d -in $WPCONFIGFILEENC -out /var/wp-config.php -k $WPCONFPASS
rm $WPCONFIGFILEENC
#store wpconfigpass in config file
echo "WPCONFPASS=$WPCONFPASS" > ~/.wpconfpass

#restart apache for php to take effect
sudo service apache2 restart

####END WORDPRESS & PHP Setup####################################



#######Download Backup Script####################################
#download backup-script
wget $URLBACKUPSHELLSCRIPT
mv Backup.sh /var
chmod +x /var/Backup.sh

#cron-job the backup-script
( crontab -l ; echo "0 23 * * * /var/Backup.sh" ) | crontab -
#######END Download Backup Script################################



####DNS Update for Cloudflare AND LetsEncrypt####################################
if [ "$DNSUPDATE" = true ]; then

####DNS##########################################################
#Update cloudflare API to point to new address
echo "Getting Cloudflare script from $URLCLOUDFLARESHELLSCRIPT"
wget $URLCLOUDFLARESHELLSCRIPT
chmod +x /cloudflare.sh
echo "Updating cloudflare record $CFRECORD in zone $CFZONE using credentials $CFEMAIL , $CFKEY "
./cloudflare.sh --email $CFEMAIL --key $CFKEY --zone $CFZONE --record $CFRECORD
echo "Removing Cloudflare script"
rm cloudflare.sh

####END DNS######################################################

#add let's encrypt cron jobs before hand (leaving the user entry for the end)
( crontab -l ; echo "0 6 * * * letsencrypt renew" ) | crontab -
( crontab -l ; echo "0 23 * * * letsencrypt renew" ) | crontab -

#Install Lets Encrypts and get a new Cert
sudo apt-get -y install python-letsencrypt-apache 

if [ "$PRODUCTIONCERT" = true ] ; then 
echo "WARNING: Obtaining production certs, these are rate-limited so be sure this is a Production server"
letsencrypt --apache 
else
echo "Obtaining staging certs (for test)"
letsencrypt --apache --staging
fi
####DNS and Lets Encrypt#########################################

else
echo "DNS wasn't updated, certs can't be obtained if DNS isn't updated"
fi
####DNS Update for Cloudflare AND LetsEncrypt####################################

