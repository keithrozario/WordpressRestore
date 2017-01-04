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
<li><b>--dbrootpass</b> [database_root_password]<br>
The password for root on the database you're about to create, this can be set to anything, but use strong passwords <br>
<li><b>--dbname</b> [database_name] <br>
The database name for storing wordpress <br>
<li><b>--wpdbuser</b> [database_wordpress_user] <br>
The database user assigned to wordpress, refer to wp-config.php <br>
<li><b>--wpdbpass</b> [database_wordpress_user_password] <br>
</ul>
