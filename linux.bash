#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Update system
sudo apt update && sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Install MySQL
echo "mysql-server mysql-server/root_password password Welkom01!" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password Welkom01!" | sudo debconf-set-selections
sudo apt install mysql-server -y

# Install PHP
sudo apt install php libapache2-mod-php php-mysql php-imagick php-dompdf php-xml php-mbstring php-gd php-pdo php-json php-curl php-zip php-gmp php-bcmath -y

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache service
sudo systemctl restart apache2

# Install phpMyAdmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password Welkom01!" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password Welkom01!" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password Welkom01!" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo apt install phpmyadmin -y

# Owncloud installation
# Download and extract Owncloud
wget https://download.owncloud.org/community/owncloud-complete-latest.zip
unzip owncloud-complete-latest.zip
sudo mv owncloud /var/www/

# Set appropriate permissions
sudo chown -R www-data:www-data /var/www/owncloud/
sudo chmod -R 755 /var/www/owncloud/

# Create database for Owncloud
mysql -uroot -pWelkom01! <<QUERY_INPUT
CREATE DATABASE owncloud;
GRANT ALL ON owncloud.* to 'owncloud'@'localhost' IDENTIFIED BY 'Welkom01!';
FLUSH PRIVILEGES;
QUERY_INPUT

# Apache configuration for reverse proxy
sudo bash -c "cat > /etc/apache2/sites-available/owncloud.conf <<EOF
<VirtualHost *:80>
    ServerName owncloud.jahmmfm.de
    DocumentRoot /var/www/owncloud/

    <Directory /var/www/owncloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/owncloud_error.log
    CustomLog \${APACHE_LOG_DIR}/owncloud_access.log combined
</VirtualHost>

<VirtualHost *:80>
    ServerName real.jahmmfm.de
    DocumentRoot /usr/share/phpmyadmin
</VirtualHost>
EOF"

# Enable site and restart Apache
sudo a2ensite owncloud.conf
sudo systemctl restart apache2

echo "phpMyAdmin and Owncloud installation completed"
