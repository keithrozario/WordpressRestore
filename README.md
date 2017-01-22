# WordpressRestore
Automated script to backup wordpress daily or restore from backup

<h2>Pre-requisites</h2>

1. Wordpress site (to backup and restore)<br>
2. Dropbox account (to save backups and restore from)<br>
3. Optional Cloudflare account (with token key) if you wish to update DNS<br>
4. Root access to box you wish to restore to (or backup from)<br>

<h2>Assumptions</h2>

1. Wordpress site is stored on Ubuntu 16.04 or 16.10 (only tested versions) <br>
2. Database is MYSQL and running on the same machine (localhost) <br>

<h2>To Backup Wordpress:</h2><br>
git clone https://github.com/keithrozario/WordpressRestore/ <br>
cd WordpressRestore <br>
chmod +x *.sh <br><br>
./setup.sh --dropboxtoken [xxx] --enckey [xxxx] --wpdir [xxx] --wpconfdir [xxx] <br>
<ul>
<li><b>--dropboxtoken</b> DROPBOX ACCESS TOKEN <b>[MANDATORY]</b><br>
The access token for your dropbox account, refer to http://bit.ly/2it95it to get one<br>
<li><b>--enckey</b> ENCRYPTION KEY FOR BACKUPS <b>[MANDATORY]</b><br>
A user supplied encryption key to encrypt backups (all filed uploaded to backup dir are encrypted)<br>
<li><b>--wpdir</b> WORDPRESS DIRECTORY <i>[OPTIONAL]</i><br>
Directory of the Wordpress installations, defaults to /var/www/html if not supplied<br>
<li><b>--wpconfdir</b> WORDPRESS CONFIGURATION DIRECTORY <i>[OPTIONAL]</i><br>
Directory of the Wordpress wp-config.php file, defaults to Wordpress Directory if not supplied<br>
</ul><br><i>
*setup.sh automatically setups backups to run once a day, uploading relevant files to Dropbox Directory
*all files are encrypted with --enckey, stored in /var/.enckey. This file isn't backed-up. Don't lose the encryption key!!
</i>

<h2>To Restore Wordpress:</h2><br>
git clone https://github.com/keithrozario/WordpressRestore/ <br>
cd WordpressRestore <br>
chmod +x *.sh <br><br>
./setup.sh --dbrootpass [xxx] --dropboxtoken [xxx] --enckey [xxxx] --cfemail [xxx] --cfzone [xxx] --cfkey [xxx] --cfrecord [xxx] <br>
<ul>
<li><b>--dbrootpass</b> DATABASE_ROOT_PASSWORD <b>[MANDATORY]</b><br>
The password for root on the database you're about to create, this can be set to anything, but use strong passwords <br>
<li><b>--dropboxtoken</b> DROPBOX_ACCESS_TOKEN <b>[MANDATORY]</b><br>
The access token for your dropbox account, refer to http://bit.ly/2it95it to get one<br>
<li><b>--enckey</b> ENCRYPTION_KEY_FOR_BACKUPS <b>[MANDATORY]</b><br>
A user supplied encryption key to encrypt backups (all filed uploaded to backup dir are encrypted)<br>
<li><b>--cfemail</b> CLOUDFLARE_EMAIL_ADDRESS <i>[OPTIONAL]</i><br>
<i>Optional:</i> Email Address for your cloudflare account <br>
<li><b>--cfzone</b> CLOUDFLARE_URL_ZONE <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare zone (e.g. keithrozario.com)
<li><b>--cfrecord</b> CLOUDFLARE_RECORD <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare record to update (e.g. www.keithrozario.com)
<li><b>--cfkey</b> CLOUDFLARE_ACCESS_TOKEN <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare access token, refer to http://bit.ly/2hTadAg to get one<br>
</ul>
