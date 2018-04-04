#!/bin/bash

#Installing the minimum required for ansible
apt-get update -y
apt-get install -y python-minimal python-simplejson
#apt-get install -y ansible
#apt-get install -y apache2
#apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-cli php7.0-common php7.0-mbstring php7.0-gd php7.0-intl php7.0-xml php7.0-mysql php7.0-mcrypt php7.0-zip
#tee /var/www/html/hello.html  <<FF1
#<html><h2>Hello from outer space!!</h2></html>
#FF1
#tee /var/www/html/hello.php <<FF2
#<?php
#phpinfo();
#?>
#FF2

#systemctl enable apache2
#systemctl restart apache2

