#!/bin/bash

# Update the package lists for upgrades and new package installations
sudo apt-get update 

# Install MySQL server and client, Expect, Apache2, PHP, and various PHP extensions
sudo apt install -y mysql-server mysql-client expect apache2 php libapache2-mod-php 
php-mysql php8.2 php8.2-curl php8.2-dom php8.2-xml php8.2-mysql php8.2-sqlite3 php8.3 
php8.3-curl php8.3-dom php8.3-xml php8.3-mysql php8.3-sqlite3

# Add the PPA repository for PHP maintained by Ondřej Surý
sudo add-apt-repository -y ppa:ondrej/php

# Update the package lists again to include packages from the new repository
sudo apt-get update


echo "Done with installations"

# Start the MySQL service
sudo systemctl start mysql.service

# Start the Apache2 service
sudo systemctl start apache2.service

# Start the MySQL secure installation process
# The expect command is used to automate responses to interactive prompts
sudo expect <<EOF
spawn mysql_secure_installation

# Set the timeout for expect commands
set timeout 1

# Handle the password validation prompt. If not present, skip.
expect {
    "Press y|Y for Yes, any other key for No:" {
        send "y\r"
        expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
        send "0\r"
    }
    "The 'validate_password' component is installed on the server." {
        send_user "Skipping VALIDATE PASSWORD section as it is already installed.\n"
    }
}

expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
send "0\r"

expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "n\r"

expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) 
:"
send "y\r"

expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"

expect eof
EOF

echo "MySQL secure installation setup complete."

# Ensure MySQL service is started
sudo systemctl start mysql

# Execute MySQL commands to create the database, user, and grant privileges
sudo mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS webserver;
CREATE USER IF NOT EXISTS 'User1'@'localhost' IDENTIFIED BY 'Password123';
GRANT ALL PRIVILEGES ON webserver.your_table TO 'User1'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Database and user created."

# Enable the Apache mod_rewrite module
sudo a2enmod rewrite

# Create the directory for the new virtual host
sudo mkdir -p /var/www/demo.com

# Change the ownership of the directory to the current user
sudo chown -R $USER:$USER /var/www/demo.com

# Set permissions for the directory
sudo chmod -R 755 /var/www/demo.com

# Create an index.html file with a simple HTML content and save it in the relevant file
sudo bash -c 'cat <<EOF > /var/www/demo.com/index.html
<html>
    <head>
        <title>Welcome to Your_domain!</title>
    </head>
    <body>
        <h1>Success! The your_domain virtual host is working!</h1>
    </body>
</html>
EOF'

echo "HTML file created at /var/www/demo.com/index.html"

# Create the virtual host configuration file for 'demo.com'
sudo bash -c 'cat <<EOF > /etc/apache2/sites-available/demo.com.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName demo.com
    ServerAlias www.demo.com
    DocumentRoot /var/www/demo.com
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF'

echo "Virtual hosting configured"

# Enable the new virtual host configuration
sudo a2ensite demo.com.conf

# Disable the default virtual host configuration
sudo a2dissite 000-default.conf

# Restart Apache2 service to apply the changes
sudo systemctl restart apache2
