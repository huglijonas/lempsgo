#!/bin/bash
# ----------------------------------
#    Debian Deployment: Nginx, Php, Mariadb
#    Copyright (C) 2020  Jonas Hügli
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ----------------------------------

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# ----------------------------------
# PHP
# ----------------------------------
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
            [Yy]* ) printf $GREEN; echo "[PHP7.3-FPM] Uninstall in progress"; printf $WHITE; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Erase the php.log file
                > src/log/php.log
                # Remove & purge (Redirection to php.log)
                apt remove php7.3-fpm -y --no-install-recommends apt-utils &> src/log/php.log
                apt purge php7.3-fpm -y --no-install-recommends apt-utils &> src/log/php.log
                apt autoremove -y --no-install-recommends apt-utils &> src/log/php.log
                kill $!; trap 'kill $!' SIGTERM
                printf $GREEN
                echo "[PHP7.3-FPM] Successfully uninstalled!"
                printf $NOCOLOR
            break;;
            [Nn]* ) printf $RED; echo "[PHP7.3-FPM] Deployment canceled"; printf $NOCOLOR; PHP_FPM=false; break;;
            * ) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
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
            [Yy]* ) printf $GREEN; echo "[PHP7.3-MYSQL] Uninstall in progress"; printf $WHITE; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Remove & purge (Redirection to php.log)
                apt remove php7.3-mysql -y --no-install-recommends apt-utils &> src/log/php.log
                apt purge php7.3-mysql -y --no-install-recommends apt-utils &> src/log/php.log
                apt autoremove -y --no-install-recommends apt-utils &> src/log/php.log
                kill $!; trap 'kill $!' SIGTERM
            printf $GREEN
            echo "[PHP7.3-MYSQL] Successfully uninstalled!"
            printf $NOCOLOR
            break;;
            [Nn]* ) printf $RED; echo "[PHP7.3-MYSQL] Deployment canceled"; printf $NCOLOR; PHP_MYSQL=false; break;;
            * ) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
fi

if [ $PHP_FPM == true ]
then
    # ----------------------------------
    # Install php7.3-fpm
    # ----------------------------------
    printf $GREEN
    echo "[PHP7.3-FPM] Installation in progress"
    printf $WHITE
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to php.log)
        apt install php7.3-fpm -y --no-install-recommends apt-utils &> src/log/php.log
        kill $!; trap 'kill $!' SIGTERM
    dpkg -s php7.3-fpm &> /dev/null
    if [ $? -ne 0 ]
    then
        printf $RED
        echo "[PHP7.3-FPM] An error occured! Please see the php log file in src/log/php.log"
        printf $NOCOLOR
        exit
    fi
    printf $GREEN
    echo "[PHP7.3-FPM] Successfully installed!"
    printf $NOCOLOR
fi

if [ $PHP_MYSQL == true ]
then
    # ----------------------------------
    # Install php7.3-mysql
    # ----------------------------------
    printf $GREEN
    echo "[PHP7.3-MYSQL] Installation in progress"
    printf $WHITE
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to php.log)
        apt install php7.3-mysql -y --no-install-recommends apt-utils &> src/log/php.log
        kill $!; trap 'kill $!' SIGTERM
    dpkg -s php7.3-mysql &> /dev/null
    if [ $? -ne 0 ]
    then
        printf $RED
        echo "[PHP7.3-MYSQL] An error occured! Please see the php log file in src/log/php.log"
        printf $NOCOLOR
        exit
    fi
    printf $GREEN
    echo "[PHP7.3-MYSQL] Successfully installed!"
    printf $NOCOLOR
fi

SOCK=$(grep -c "/var/run/php/php7.3-fpm.sock" /etc/php/7.3/fpm/pool.d/www.conf)
if [[ $SOCK == 0 ]]
then
    sed -i 's/\/run\/php\/php7.3-fpm.sock/\/var\/run\/php\/php7.3-fpm.sock/g' /etc/php/7.3/fpm/pool.d/www.conf
    printf $ORANGE
    echo "[PHP7.3-FPM] Sock path changed in /etc/php/7.3/fpm/pool.d/www.conf"
    printf $NOCOLOR
fi
sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
printf $ORANGE
echo "[PHP7.3-FPM] Pathinfo set to 0 in /etc/php/7.3/fpm/php.ini"
printf $NOCOLOR
