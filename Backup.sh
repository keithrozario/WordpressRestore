#!/bin/bash
WPCONFPASSFILE=~/.wpconfpass

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    --wpconfpass)
    WPCONFPASSARG="$2"
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

if [ -f $WPCONFPASSFILE ]; then
  if [ -z '$WPCONFPASSARG' ]; then #File exist, Arg not supplied
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
  else #File exist, Arg supplied
    echo "Encryption key provided, but one already exist, over-riding existing key"
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
    rm $WPCONFPASSFILE
    echo "WPCONFPASS=$WPCONFPASSARG" > $WPCONFPASSFILE
  fi
else
   if [ -z '$WPCONFPASSARG' ]; then #File does not exist, Arg not supplied
    echo "Encryption does not exist on system, and is not provided, aborting"
    exit 0
   else #File does not exist, Arg supplied
    echo "First Time setup, saving encryption key"
    $(cat $WPCONFPASSFILE | grep -v ^# | xargs)
    rm $WPCONFPASSFILE
    echo "WPCONFPASS=$WPCONFPASSARG" > $WPCONFPASSFILE
   fi
fi


##Filenames#########################
WPSQLFILE=wordpress.sql
WPZIPFILE=wordpress.tgz
WPCONFIGFILEENC=wp-config.php.enc
WPCONFIGENCKEY=a34jzuhw5cc78yhfys
APACHECONFIG=apachecfg_dynamic.tar

####################################

rm /var/$WPZIPFILE
rm /var/$WPSQLFILE
rm /var/$APACHECONFIG
rm /var/$WPCONFIGFILEENC

#Mysql data dump
mysqldump wordpress > /var/$WPSQLFILE

#Zip www folder
tar cvzf /var/$WPZIPFILE /var/www

#Encrypt wp-config.php (wordpress files with passwords)
openssl enc -aes-256-cbc -in /var/wp-config.php -out /var/$WPCONFIGFILEENC -k $WPCONFIGENCKEY

#Copy all Apache configurations
tar cvf /var/$APACHECONFIG /etc/apache2/sites-enabled
tar -rvf /var/$APACHECONFIG /etc/apache2/sites-available
tar -rvf /var/$APACHECONFIG /etc/apache2/ssl
tar -rvf /var/$APACHECONFIG /etc/apache2/apache2.conf
tar -rvf /var/$APACHECONFIG /etc/apache2/.htpasswd
tar -rvf /var/$APACHECONFIG /etc/apache2/ports.conf

#Upload into dropbox
/var/Dropbox-Uploader/dropbox_uploader.sh upload /var/$WPSQLFILE /
/var/Dropbox-Uploader/dropbox_uploader.sh upload /var/$WPZIPFILE /
/var/Dropbox-Uploader/dropbox_uploader.sh upload /var/$APACHECONFIG /
/var/Dropbox-Uploader/dropbox_uploader.sh upload /var/$WPCONFIGFILEENC /


