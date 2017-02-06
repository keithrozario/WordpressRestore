# WordpressRestore v1.0
Automated script to backup wordpress daily or restore from backup

<h2>Pre-requisites</h2>

1. Wordpress site (to backup and restore)<br>
2. Dropbox account (to save backups and restore from)<br>
3. Optional Cloudflare account (with token key) if you wish to update DNS<br>
4. Root access to box you wish to restore to (backup doesn't require root access)<br>

<h2>Assumptions</h2>

1. Wordpress site is stored on Ubuntu 16.04 or 16.10 (only tested versions) <br>
2. Database is MYSQL and running on the same machine (localhost) <br>
3. Apache config files are ALL in /etc/apache2--no certs stored elsewhere <br>

<h2>To Backup Wordpress:</h2>
git clone https://github.com/keithrozario/WordpressRestore/ <br>
cd WordpressRestore <br>
chmod +x *.sh <br><br>
./setup.sh --dropboxtoken [xxx] --enckey [xxx] --wpdir [xxx] --wpconfdir [xxx] <br>
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
*setup.sh automatically sets up backups to run once a day, uploading relevant files to Dropbox Directory <br>
*all files are encrypted with --enckey, stored in /var/.enckey. This file isn't backed-up. Don't lose the encryption key!!
</i><br>

<h2>To Restore Wordpress:</h2>
git clone https://github.com/keithrozario/WordpressRestore/ <br>
cd WordpressRestore <br>
chmod +x *.sh <br><br>
./restoreWP.sh --dropboxtoken [xxx] --enckey [xxxx] --aprestore [x] --domain [xxx] --cfemail [xxx] --cfzone [xxx] --cfkey [xxx] --cfrecord [xxx] --dbrootpass [xxx] 
<ul>
<li><b>--dropboxtoken</b> DROPBOX_ACCESS_TOKEN <b>[MANDATORY]</b><br>
The access token for your dropbox account, refer to http://bit.ly/2it95it to get one<br>
<li><b>--enckey</b> ENCRYPTION_KEY_FOR_BACKUPS <b>[MANDATORY]</b><br>
A user supplied decryption key to decrypt backups (all files uploaded to backup dir are encrypted)<br>
<li><b>--aprestore</b>APACHE Restore Flag <i>[OPTIONAL]</i><br>
<i>Optional:</i> Set to 1 to restore Apache from backup, leave empty to allow script to configure apache automatically<br>
<li><b>--domain</b>APACHE Restore Flag <i>[CONDITIONAL]</i><br>
<i>Conditional:</i>Set to domain (e.g. www.example.com) if aprestore is not set <br>
<li><b>--cfemail</b> CLOUDFLARE_EMAIL_ADDRESS <i>[OPTIONAL]</i><br>
<i>Optional:</i> Email Address for your cloudflare account <br>
<li><b>--cfzone</b> CLOUDFLARE_URL_ZONE <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare zone (e.g. keithrozario.com)
<li><b>--cfrecord</b> CLOUDFLARE_RECORD <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare record to update (e.g. www.keithrozario.com)
<li><b>--cfkey</b> CLOUDFLARE_ACCESS_TOKEN <i>[OPTIONAL]</i><br>
<i>Optional:</i> Cloudflare access token, refer to http://bit.ly/2hTadAg to get one<br>
<li><b>--prodcert</b>Production Certificate Flag <i>[OPTIONAL]</i><br>
<i>Optional:</i> set to 1 for production certificate from Let's Encrypt, 0 for non-prod, leave blank to skip Let's encrypt<br>
<li><b>--dbrootpass</b> DATABASE_ROOT_PASSWORD <b>[OPTIONAL]</b><br>
The password for root on the database you're about to create, script will generate random pass if not supplied with one <br>
</ul>
<br><i>
*if --prodcert is set to 1, Cronjobs will be creates for letsencrypt renew to run twice a day (6am and 11pm) <br>
*if --prodcert is set to 0, lets encrypt will call on test certificates, cronjobs will still be created <br>
*if --prodcert is not set, let's encrypt step is bypassed <br>
</i>

<h2>Special Thanks</h2>
Thanks to <a href="https://github.com/andreafabrizi">Andrea Fabrizi</a> for the awesome <a href="https://github.com/andreafabrizi/Dropbox-Uploader">DropboxUploader script</a>  <br>
Thanks to <a href="https://gist.github.com/benkulbertis">Ben Kulbertis</a> for the awesome <a href="https://gist.github.com/benkulbertis/fff10759c2391b6618dd/">Cloudflare update script</a>  <br>

