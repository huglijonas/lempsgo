#!/bin/bash
#
##
# Verify permissions
##
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or execute with the sudo command"
  exit
fi
#
##
# PHP
##
PHP_FPM=true
PHP_MYSQL=true

# Verify if the php7.3-fpm command is available
dpkg -s php7.3-fpm &> /dev/null
if [ $? == 0 ]
then
    # Loop to ask if the user want to reinstall php7.3-fpm
    while true; do
        read -p "php7.3-fpm seems to be already installed. Would you reinstall the package? (y/n)" yn
        case $yn in
            [Yy]* ) echo "Uninstall in progress"; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Erase the php.log file
                > ../log/php.log
                # Remove & purge (Redirection to php.log)
                apt remove php7.3-fpm -y --no-install-recommends apt-utils &> ../log/php.log
                apt purge php7.3-fpm -y --no-install-recommends apt-utils &> ../log/php.log
                apt autoremove -y --no-install-recommends apt-utils &> ../log/php.log
                kill $!; trap 'kill $!' SIGTERM
                echo "php7.3-fpm was uninstalled!"
            break;;
            [Nn]* ) echo "php7.3-fpm deployment is canceled"; PHP_FPM=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi
# Verify if the php7.3-mysql command is available
dpkg -s php7.3-mysql &> /dev/null
if [ $? == 0 ]
then
    # Loop to ask if the user want to reinstall php7.3-mysql
    while true; do
        read -p "php7.3-mysql seems to be already installed. Would you reinstall the package? (y/n)" yn
        case $yn in
            [Yy]* ) echo "Uninstall in progress"; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Remove & purge (Redirection to php.log)
                apt remove php7.3-mysql -y --no-install-recommends apt-utils &> ../log/php.log
                apt purge php7.3-mysql -y --no-install-recommends apt-utils &> ../log/php.log
                apt autoremove -y --no-install-recommends apt-utils &> ../log/php.log
                kill $!; trap 'kill $!' SIGTERM
            echo "php7.3-mysql was uninstalled!"
            
            break;;
            [Nn]* ) echo "php7.3-mysql deployment is canceled"; PHP_MYSQL=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

if [ $PHP_FPM == true ]
then
    #
    ##
    # Install php7.3-fpm
    ##
    echo "Installation in progress"; 
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to php.log)
        apt install php7.3-fpm -y --no-install-recommends apt-utils &> ../log/php.log
        kill $!; trap 'kill $!' SIGTERM
    dpkg -s php7.3-fpm &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "an error occured! Please see the php log file in log/php.log"
        exit
    fi
    echo "php7.3-fpm was installed!"
fi

if [ $PHP_MYSQL == true ]
then
    #
    ##
    # Install php7.3-mysql
    ##
    echo "Installation in progress"; 
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to php.log)
        apt install php7.3-mysql -y --no-install-recommends apt-utils &> ../log/php.log
        kill $!; trap 'kill $!' SIGTERM
    dpkg -s php7.3-mysql &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "an error occured! Please see the php log file in log/php.log"
        exit
    fi
    echo "php7.3-mysql was installed!"
fi

SOCK=$(grep -c "/var/run/php/php7.3-fpm.sock" /etc/php/7.3/fpm/pool.d/www.conf)
if [[ $SOCK == 0 ]]
then
    sed -i 's/\/run\/php\/php7.3-fpm.sock/\/var\/run\/php\/php7.3-fpm.sock/g' /etc/php/7.3/fpm/pool.d/www.conf
    echo "Sock path changed in /etc/php/7.3/fpm/pool.d/www.conf"
fi