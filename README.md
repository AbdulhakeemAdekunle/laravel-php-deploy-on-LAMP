## Laravel-PHP Deployment on a LAMP Stack

### Project Objective

- Automation of two Ubuntu-based servers, using `Vagrant`.
- To create an executable `Bash script` that will automate the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack on one of the server, and also deployment of a `PHP` application cloned from a GitHub repo.
- To create an `Ansible playbook` that will make use of the script in step 2 to deploy LAMP on the second server and also set a cronjob to check the server's uptime.

### Requirements

- A Linux based system: laptop, desktop, workstation, virtual machine etc.
- SSH access between the host system and the servers.
- A laravel application that exists in a repository on GitHub.

**To start with;** you will need to have an Ubuntu based system. For this project, I wrote a simple `Vagrantfile` which I used to setup my virtual machine. If you don't have an Ubuntu based system yet, you can spin up one, using the [Vagrantfile](./Vagrantfile) I created. Make sure that you have [Vagrant](https://developer.hashicorp.com/vagrant/downloads?product_intent=vagrant) installed on your machine, and also a virtualization tool: [VirtualBox](https://www.virtualbox.org/), or other virtualization tool.  
 Create a project directory, copy the Vagrantfile into that directory, from the directory, do: `vagrant up` from your shell terminal.

Now that you have your Ubuntu installation completed successfully, the next step is to install other components that makes up the LAMP server, and also deploy your Laravel application.

I have also created a bash script that you can **re-use** to achieve the steps which I am about to outline. But, let's look into the script and go through each steps one after the other, to have an understanding of how the script works.

**Shebang preprocessing command**  
`#!/bin/bash`

**Update package repository:** To fetch the updated package list from repositories.  
`sudo apt update -y`

**Install Apache:** A web server for hosting and managing web applications.  
`sudo apt install -y apache2`

**Install MySQL:** The MySQL server provides a database management
system with querying and connectivity capabilities.  
`sudo apt install -y mysql-server`

**Add PHP repository:** This repository provides updated PHP packages for Ubuntu.  
`echo -e "\n" | add-apt-repository ppa:ondrej/php`

**Install PHP, Apache PHP Module, and PHP-MySQL:** This line installs PHP, and then installs the necessary PHP modules to work with Apache. Our PHP application also needs a database to work with, I installed MySQL earlier, hence I have to include the necessary PHP components for MySQL connectivity.  
`sudo apt install -y php libapache2-mod-php php-mysql`

**Install additional php modules that Laravel requires:** There are other PHP modules that are required by Laravel specicically. But they don't get installed by default when you install PHP. So we have to install those modules manually, and that's what the next line does.  
 `sudo apt install -y php8.2-curl php8.2-dom php8.2-xml php8.2-mbstring zip unzip`

**Enable URL rewriting:** This enables Apache `rewrite` module to allow Laravel's routing system to work.  
 `sudo a2enmod rewrite`

**Restart Apache to make the changes take effect**  
 `sudo systemctl restart apache2`

**Install GIT version control**  
 `sudo apt install -y git`

**Install Composer:** Composer helps us to manage dependencies in a Laravel project. I intentionally decided to move into the `/usr/bin` directory because it is a common location to put command line executables. You can install it without moving into the `/usr/bin` directory.  
 `cd /usr/bin && sudo apt install -y composer`

**Move into /var/www/, the document root for apache:** Apache loads is documents from the `/var/www/html` directory. In the directory, there is an `index.html` file (Apache2 Default page).  
So, I want to create a new directory for my Laravel project in `/var/www/` directory, and inside that same directory is where I will clone the laravel project from github.  
 `mkdir /var/www/laravel`

**Clone the laravel git repository**  
 `sudo git clone https://github.com/laravel/laravel.git /var/www/laravel`  
 
 Create a variable to keep track of the default README file  
 `README=/var/www/laravel/README.md`  
 
 Check if the README file exists  
 `if [[ -a ${README} ]]; then`  
 `echo "Repository cloned successfully"`  
 `else`  
 Repeat the process of cloning the laravel repository again;  
 `sudo git clone https://github.com/laravel/laravel.git /var/www/laravel`
`fi`  
The essence of the `if` statement above is to allow the script handle situation where there is a network issue and the repository does not get cloned successfully. I don't want that to happen because the remaining parts of the script will either be uselees or not get executed. Since it doesn't have any file to work on.

**Get dependencies:** Install the necessary dependencies for our Laravel project  
Move into the project directory "laravel" and run composer update.  
`cd /var/www/laravel && echo "yes" | sudo composer update`

**Build .env file:** Every laravel application needs a .env file with environment-specific configurations.  
To do this I will copy the provided .env.example file and edit it appropriately  
`cd /var/www/laravel && sudo cp .env.example .env`

**Editing the .env file**  
`sed -i 's/APP_NAME=Laravel/APP_NAME=laravel/' /var/www/laravel/.env`  
`sed -i 's/APP_ENV=local/APP_ENV=production/' /var/www/laravel/.env` _I want to assume that this is a production environment._  

`sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' /var/www/laravel/.env`  
_Here I change `APP_DEBUG` option to false because in a prod env, when there's an error in my app, I want users to only see generic error message rather than a full error message with debugging information. But, for the first time, I can set it to `true` so that if it doesn't work as expected, I will get information about what went wrong._  
`sed -i 's/APP_URL=http://localhost/APP_URL=http://192.168.56.100/' /var/www/laravel/.env`  
_The ip address can be a domain name or the host ip address. Here the ip address is for the Master node._

`sed -i 's/APP_URL=http://localhost/APP_URL=http://192.168.56.101/' /var/www/laravel/.env` _Slave node IP address. Comment this line out if you want to run the script on your master node._

**Generate the APP_KEY value within your .env file:** Run the following command  
`cd /var/www/laravel && sudo php artisan key:generate`

**Set permissions:** There are two directories within a Laravel application that need to be writable by the server: `storage` and `bootstrap/cache`.  
Within these directories, the server will write application-specific files such as cache info, session data, error logss, etc.  
To Know which user apache is running as, you can use the following command:  
`ps aux | grep "apache" | awk '{print $1}' | grep -v root | head -n 1`

On my server apache is running as: `www-data` user so I can change the permissions now  
`sudo chown -R www-data /var/www/laravel/storage`  
`sudo chown -R www-data /var/www/laravel/bootstrap/cache`

**The last step is to configure our site in apache directory by creating a new config file for our site**  
`sudo touch /etc/apache2/sites-available/laravel.conf`  
`sudo cat>/etc/apache2/sites-available/laravel.conf<<'EOF'`  
`<VirtualHost \*:80>`  
`ServerName laravel.master.com`  
`DocumentRoot /var/www/laravel/public`

`<Directory /var/www/laravel/public>`  
`Options Indexes FollowSymLinks`  
`AllowOverride All`  
`Require all granted`  
`</Directory>`

`ErrorLog ${APACHE_LOG_DIR}/laravel-error.log`  
`CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined`  
`</VirtualHost>`  
`EOF`

**Enable the site configuration with the following command**  
`sudo a2ensite laravel.conf`

**Dissable the default apache web page**  
`sudo a2dissite 000-default.conf`  
This is because I did not use a domain name for my laravel app. If I had a domain name for this, I wouldn't need to dissable the default page.

**Restart Apache to make the changes take effect**  
`sudo systemctl restart apache2`

**Exit from the root user**  
`exit`

**To test the application:** I entered the VM's IP address in the browser, and I got the following webpage loaded.  

![](./master%20web%20page.png)

_Yay! Our Laravel application has been deployed_

The complete script file is accessible [here](./lamp-deploy.sh).  

I have also written an ansible playbook which will help me run the script on the slave node. The playbook is accessible [here](./lamp-deploy.yml).  

**To test the application on the slave node,** after running the Ansible playbook, I enter the slave IP address on my web browser, and I got the Laravel web page.  

![](slave%20web%20page.png)

Comments, suggestions, and feedback are welcomed to better improve this project.  
*Thank you*
