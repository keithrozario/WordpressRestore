# WordpressRestore
Automated script to backup wordpress daily or restore from backup

<h2>Pre-requisites</h2>

1. Wordpress site (to backup and restore)<br>
2. Dropbox account (to save backups and restore from)<br>
3. Cloudflare account (to update DNS record after restoration)<br>
4. Root access to box you wish to restore to (or backup from)<br>

<h2>Assumptions</h2>

1. Wordpress site is stored on Ubuntu 16.04 or 16.10 (only tested versions) <br>
2. Wordpress files are stored in /var/www (or some sub-directory beneath) <br>
3. Wordpress wp-config.php is stored in /var folder <br>
4. Apache has been configured properly on the original site <br>
5. Database is MYSQL and running on the same machine (localhost) <br>

<h2>Available Commands</h2>

<h3>restoreWP.sh</h3>
<ul>
<li><b>--dbrootpass</b> DATABASE_ROOT_PASSWORD<br>
The password for root on the database you're about to create, this can be set to anything, but use strong passwords <br>
<li><b>--dbname</b> DATABASE_NAME <br>
The database name for storing wordpress, refer to wp-config (DB_NAME) <br>
<li><b>--wpdbuser</b> WORDPRESS_DATABASE_USER <br>
The database user assigned to wordpress, refer to wp-config.php (DB_USER)<br>
<li><b>--wpdbpass</b> WORDPRESS_DATABASE_USER_PASSWORD <br>
The password for the database user assigned to wordpress, refer to wp-config.php (DB_PASSWORD) <br>
<li><b>--dropboxtoken</b> DROPBOX_ACCESS_TOKEN <br>
THe access token for your dropbox account, refer to http://bit.ly/2it95it to get one<br>
<li><b>--wpconfpass</b> ENCRYPTION_KEY_FOR_WPCONFIG <br>
A randomly generated encryption key to encrypt the wordpress wp-config.php file<br>
<li><b>--cfemail</b> CLOUDFLARE_EMAIL_ADDRESS <br>
OPTIONAL: Email Address for your cloudflare account <br>
<li><b>--cfzone</b> CLOUDFLARE_URL_ZONE <br>
OPTIONAL: Cloudflare zone (e.g. keithrozario.com)
<li><b>--cfrecord</b> CLOUDFLARE_RECORD <br>
OPTIONAL: Cloudflare record to update (e.g. www.keithrozario.com)
<li><b>--cfkey</b> CLOUDFLARE_ACCESS_TOKEN <br>
OPTIONAL: Cloudflare access token
</ul>
