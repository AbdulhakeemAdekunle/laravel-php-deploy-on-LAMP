#!/bin/bash

# INSTALL AMP (APACHE, MYSQL, PHP)

# Update package repository
  sudo apt update -y
# Install Apache, MySQL, and PHP
  sudo apt install -y apache2
# Install MySQL
  sudo apt install -y mysql-server
# Add ppa:ondrej/php repository
  echo -e "\n" | add-apt-repository ppa:ondrej/php

# Install PHP, Apache PHP Module, and PHP-MySQL
  sudo apt install -y php libapache2-mod-php php-mysql

# Install additional php modules that Laravel requires
  sudo apt install -y php8.2-curl php8.2-dom php8.2-xml php8.2-mbstring zip unzip

# Enable URL rewriting
  sudo a2enmod rewrite

# Restart Apache to make the changes take effect
  sudo systemctl restart apache2

# Install GIT version control
  sudo apt install -y git

# Move into /usr/bin directory, a common location to put command line executable programs
  cd /usr/bin && sudo apt install -y composer

# Move into /var/www/html, the document root for apache
  mkdir /var/www/laravel

# Clone the laravel git repository
  sudo git clone https://github.com/laravel/laravel.git /var/www/laravel
  README=/var/www/laravel/README.md
  if [[ -a ${README} ]]; then
	echo "Repository cloned successfully"
  else
	sudo git clone https://github.com/laravel/laravel.git /var/www/laravel
  fi

# Get dependencies
# Pull application's Composer dependencies (i.e.our vendor/ directory).
# Move into the project directory "laravel"
  cd /var/www/laravel && echo "yes" | sudo composer update

# Build .env file
# Every laravel application needs a .env file with environment-specific configurations.
# To do this you can copy the provided .env.example file and edit it appropriately
  cd /var/www/laravel && sudo cp .env.example .env

# Editing the .env file
  sed -i 's/APP_NAME=Laravel/APP_NAME=laravel/' /var/www/laravel/.env
  sed -i 's/APP_ENV=local/APP_ENV=production/' /var/www/laravel/.env # I want to assume that this is a production environment
  sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' /var/www/laravel/.env # Here I change this to false because in a prod env, when there's an error in my app, I want users to only see generic error rather ...
# sed -i 's/APP_URL=http://localhost/APP_URL=http://192.168.56.100/' /var/www/laravel/.env # Master node IP address. The ip address can be your domain name or you host ip address
  sed -i 's/APP_URL=http://localhost/APP_URL=http://192.168.56.101/' /var/www/laravel/.env # Slave node IP address. #Comment this line out if you want to run the script on your master node. 

# Generate the APP_KEY value within your .env file: Run the following command
  cd /var/www/laravel && sudo php artisan key:generate

# Set permissions
# There are two directories within a Laravel application that need to be writable by the server: storage and bootstrap/cache.
# Within these directories, the server will write application-specific files such as cache info, session data, error logss, etc.
# To Know which user apache is running as, you can use the following command: ps aux | grep "apache" | awk '{print $1}' | grep -v root | head -n 1
# On my server apache is running as: www-data so I can change the permissions now
  sudo chown -R www-data /var/www/laravel/storage
  sudo chown -R www-data /var/www/laravel/bootstrap/cache

# The last step is to configure our site in apache directory by creating a new config file for our site.
  sudo touch /etc/apache2/sites-available/laravel.conf
  sudo cat>/etc/apache2/sites-available/laravel.conf<<'EOF'
<VirtualHost *:80>
   ServerName laravel.master.com
   DocumentRoot /var/www/laravel/public

   <Directory /var/www/laravel/public>
      Options Indexes FollowSymLinks
      AllowOverride All
      Require all granted
   </Directory>

   ErrorLog ${APACHE_LOG_DIR}/laravel-error.log
   CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined
</VirtualHost>
EOF

# Enable the site configuration with the following command
  sudo a2ensite laravel.conf

# Dissable the default apache web page
  sudo a2dissite 000-default.conf # This is because I did not use a domain name for my laravel app. If I had a domain name for this, I wouldn't need to dissable the default page.

# Restart Apache to make the changes take effect
  sudo systemctl restart apache2

# Yay! Our Laravel application has been deployed

# Exit from the root user
  exit
