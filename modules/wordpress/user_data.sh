#!/bin/bash
set -eu -o pipefail

# 1. Update the system
dnf update -y

# 2. Install Apache, PHP, MariaDB and tools
dnf install -y httpd php php-fpm php-mysqlnd php-gd php-xml php-mbstring php-intl mariadb105-server wget

# 3. Start the services now and on every reboot
systemctl enable --now mariadb
systemctl enable --now php-fpm
systemctl enable --now httpd

# 4. Create the database and user
mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS ${db_name};
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
SQL

# 5. Download and unpack WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/

# 6. Configure WordPress
cd /var/www/html
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/${db_name}/" wp-config.php
sed -i "s/username_here/${db_user}/" wp-config.php
sed -i "s|password_here|${db_password}|" wp-config.php

# 7. Replace the placeholder security keys with real ones
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/salts
sed -i "/put your unique phrase here/d" wp-config.php
sed -i "/#@-/r /tmp/salts" wp-config.php

# 8. Allow pretty permalinks (.htaccess)
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# 9. Set ownership and permissions
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# 10. Restart so everything picks up the changes
systemctl restart php-fpm
systemctl restart httpd