#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Update system
sudo apt update && sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Install MySQL
echo "mysql-server mysql-server/root_password password yourpassword" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password yourpassword" | sudo debconf-set-selections
sudo apt install mysql-server -y

# Install PHP
sudo apt install php libapache2-mod-php php-mysql -y

# Install phpMyAdmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password yourpassword" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password yourpassword" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password yourpassword" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo apt install phpmyadmin -y

# Owncloud installation
# Install dependencies
sudo apt install -y php7.2-gd php7.2-json php7.2-mysql php7.2-curl php7.2-mbstring php7.2-intl php-imagick php7.2-xml php7.2-zip

# Download and extract Owncloud
wget https://download.owncloud.org/community/owncloud-complete-20200731.zip
unzip owncloud-complete-20200731.zip
sudo mv owncloud /var/www/

# Set appropriate permissions
sudo chown -R www-data:www-data /var/www/owncloud/
sudo chmod -R 755 /var/www/owncloud/

# Create database for Owncloud
mysql -uroot -pyourpassword <<QUERY_INPUT
CREATE DATABASE owncloud;
GRANT ALL ON owncloud.* to 'owncloud'@'localhost' IDENTIFIED BY 'yourpassword';
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
sudo a2ensite owncloud
sudo systemctl restart apache2

echo "phpMyAdmin and Owncloud installation completed"
