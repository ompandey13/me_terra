# mysql
# root
# PpDz4DATTFjrMRfd

sudo apt-get update && apt-get upgrade -y
sudo apt install nginx -y
systemctl enable nginx
systemctl start nginx
sudo apt-get install mysql-server mysql-client -y
systemctl enable mysql
add-apt-repository ppa:ondrej/php
apt-get install software-properties-common -y
apt-get install python-software-properties -y
sudo apt-get autoremove
apt-get update
apt-get -y install unzip zip nginx php7.4 php7.4-mysql php7.4-fpm php7.4-mbstring php7.4-xml php7.4-curl
apt-get -y install composer
