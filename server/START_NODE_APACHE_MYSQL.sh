#!/bin/bash
sudo apt-get update 


# install apache2 mysql server 
sudo apt install -y mysql-server mysql-client expect apache2 

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
echo "Enter the MySql username : " 
read mysql_username

echo "Enter the MySql password : " 
read mysql_password

echo "Create Database : " 
read database_name

sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $database_name;
CREATE USER IF NOT EXISTS '$mysql_username'@'localhost' IDENTIFIED BY '$mysql_password';
GRANT ALL PRIVILEGES ON $database_name.* TO '$mysql_username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Database and user created."



set timeout 1 

echo "The project enviroments setup start!" 


# install nodejs and npm 
sudo apt install -y nodejs npm

# install pm2 with npm 
sudo npm install -g pm2

echo "NodeJS And Npm Pm2 installation was done!" 


echo "Enter project build folder path : " 
read build_folder_path

echo "Enter your app name for pm2 : " 
read app_name

sudo pm2 start $build_folder_path --name $app_name


# save the app and open the pm2 when system startup 
sudo pm2 save
sudo pm2 startup systemd
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME

# get the server public  ip 
server_ip=$(curl ifconfig.me)

# VirtualHost configuration with placeholders replaced
virtualhost_config="
<VirtualHost $server_ip:80>
    ServerName $app_name

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/

    ErrorLog ${APACHE_LOG_DIR}/$app_name-error.log
    CustomLog ${APACHE_LOG_DIR}/$app_name-access.log combined
</VirtualHost>"


sudo echo "$virtualhost_config" >> /etc/apache2/sites-available/$app_name.conf

sudo a2ensite $app_name.conf

sudo a2dissite 000-default.conf

sudo systemctl restart apache2
