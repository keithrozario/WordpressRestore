#!/bin/bash
# Wordpress Restorer v1.0
# Backups and restores wordpress with one click
#
# file: setup.sh
# usage: setup.sh --dropboxtoken <xxx> --wpconfpass <yyy>
#       --dropboxtoken : Access Token For Dropbox
#       --wpconfpass   : Encryption Key for backup files
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

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
   --dropboxtoken)
    DROPBOXTOKEN="$2"
    shift # past argument
    ;;
	--wpconfpass)
    WPCONFPASS="$2"
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

if [ -z "$DROPBOXTOKEN" ] || [ -z "$WPCONFPASS" ]; then  #Check Parameters
echo "Please provide access token for Dropbox and Encryption Key, both are mandatory"
exit 0
else
echo "Dropbox Token : Good"
echo "WP-Config Key : Good"
fi

