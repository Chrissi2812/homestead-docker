#!/usr/bin/env bash

# Laravel homestead original provisioning script
# https://github.com/laravel/settler

export DEBIAN_FRONTEND=noninteractive

# Update Package List
apt-get update
apt-get upgrade -y

# Force Locale
apt-get -y install locales
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8

apt-get install -y software-properties-common curl
# Fixes: delaying package configuration, since apt-utils is not installed
apt-get install -y --no-install-recommends apt-utils

# Install ssh server
apt-get install -y --no-install-recommends openssh-server pwgen openssl
mkdir -p /var/run/sshd
sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# Basic packages
apt-get install -y --no-install-recommends build-essential dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip \
make python2.7-dev python-pip re2c unattended-upgrades whois vim libnotify-bin \
pv cifs-utils libpng16-16

# PPA
apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

curl -s https://packagecloud.io/gpg.key | apt-key add -

# Update Package Lists
apt-get update

# Create homestead user
adduser homestead
usermod -p $(echo secret | openssl passwd -1 -stdin) homestead
# Add homestead to the sudo group and www-data
usermod -aG sudo homestead
usermod -aG www-data homestead

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# PHP
apt-get install -y --no-install-recommends --allow-downgrades --allow-remove-essential --allow-change-held-packages \
php7.2-cli php7.2-dev \
php7.2-pgsql php7.2-sqlite3 php7.2-gd \
php7.2-curl php7.2-memcached \
php7.2-imap php7.2-mysql php7.2-mbstring \
php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
php7.2-intl php7.2-readline php-fpm

# Enable mcrypt
phpenmod mcrypt
phpenmod mbstring
phpenmod memcached
phpenmod mysql
phpenmod soap
phpenmod readline
phpenmod curl

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"/home/homestead/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/homestead/.profile

# Laravel Envoy
su homestead <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Set Some PHP CLI Settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini

sed -i "s/.*daemonize.*/daemonize = no/" /etc/php/7.2/fpm/php-fpm.conf
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini

mkdir -p /run/php
touch /run/php/php7.2-fpm.sock
sed -i "s/user = www-data/user = homestead/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = homestead/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/listen.owner = homestead/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = homestead/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf

# Install Node
curl --silent --location https://deb.nodesource.com/setup_10.x | bash -
apt-get install -y --no-install-recommends nodejs
# npm install -g npm
npm install -g node-gyp
npm install -g node-pre-gyp
npm install -g cross-env

# Memcached
apt-get install -y --no-install-recommends memcached

# Minimize The Disk Image
echo "Minimizing disk image..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
