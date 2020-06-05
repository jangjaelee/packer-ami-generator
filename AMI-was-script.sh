#!/bin/bash

sudo amazon-linux-extras install -y epel
sudo yum -y update
sudo yum -y install httpd httpd-devel
sudo yum -y install make gcc
sudo yum -y install rdate
sudo yum -y install python3
sudo rdate -s time.bora.net
sudo pip3 install pip --upgrade
sudo pip install setuptools --upgrade
sudo pip install ansible
sudo yum -y install nginx
sudo yum -y install git
sudo amazon-linux-extras install -y php7.2
git clone https://github.com/gnif/mod_rpaf
cd mod_rpaf
sudo apxs -i -c -n mod_rpaf.so mod_rpaf.c
cd ..
sudo sed -i 's/Listen 80/Listen 81/g' /etc/httpd/conf/httpd.conf
sudo sed -i 's/^    LogFormat \"\%h/    LogFormat \"\%\{X\-Forwarded\-For\}i - \%h/g' /etc/httpd/conf/httpd.conf
git clone https://github.com/jangjaelee/deploytest.git
cd deploytest
sudo cp index.php /var/www/html/index.php
sudo cp rpaf.conf /etc/httpd/conf.d/rpaf.conf
cd ..
sudo systemctl enable httpd
sudo systemctl enable php-fpm
sudo rpm -ivh https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm
sudo timedatectl set-timezone Asia/Seoul
