# WordpressRestore
Automated script to backup wordpress daily or restore from backup

<h2>Pre-requisites</h2>

1. Wordpress site (to backup and restore)<br>
2. Dropbox account (to save backups and restore from)<br>
3. Optional Cloudflare account (with token key) if you wish to update DNS<br>
4. Root access to box you wish to restore to (or backup from)<br>

<h2>Assumptions</h2>

1. Wordpress site is stored on Ubuntu 16.04 or 16.10 (only tested versions) <br>
2. Apache has been configured properly on the original site <br>
3. Database is MYSQL and running on the same machine (localhost) <br>

<h2>Usage</h2>
<h3>Backup Wordpress</h3>

To Backup Wordpress: 

git clone https://github.com/keithrozario/WordpressRestore/
cd WordpressRestore
chmod +x *.sh
./setup.sh --dropboxtoken [x1] --enckey [x2] --wpdir [x3] --wpconfdir [x4]

[x1]: The access token for your dropbox account, refer to http://bit.ly/2it95it to get one<br>
[x2]: A user supplied encryption key to encrypt backups (all filed uploaded to backup dir are encrypted)<br>
[x3]: Directory of Wordpress Installation (defaults to /var/www/html)
[x4]: Directory of Wordpress wp-config.php file (defaults to [x3] if not supplied)



<h2>Available Commands</h2>

<h3>restoreWP.sh</h3>
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
