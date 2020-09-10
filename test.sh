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
# Install function
# ----------------------------------
function install() 
{
    PACKAGE=$1
    LOG="src/log/"
    case $PACKAGE in
        [nginx]* ) LOG+="nginx.log";;
        [php7.3]* ) LOG+="php.log";;
        [mariadb]* ) LOG+="mariadb.log";;
    esac
    
    printf $GREEN;
    echo "[${PACKAGE^^}] Installation in progress"; 
    printf $WHITE
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to nginx.log)
        apt install $PACKAGE -y --no-install-recommends apt-utils &> $LOG
        kill $!; trap 'kill $!' SIGTERM
    if [ !dpkg -s $PACKAGE &> /dev/null ]
    then
        printf $RED
        echo "[${PACKAGE^^}] An error occured! Please see the mariadb log file in $LOG"
        printf $NOCOLOR
        exit
    fi
    printf $GREEN
    echo "[${PACKAGE^^}] Successfully installed!"
    printf $NOCOLOR
    echo
}

# ----------------------------------
# Uninstall function
# ----------------------------------
function uninstall()
{
    PACKAGE=$1
    LOG="src/log/"
    result=true

    case $PACKAGE in
        [nginx]* ) LOG+="nginx.log";;
        [php7.3]* ) LOG+="php.log";;
        [mariadb]* ) LOG+="mariadb.log";;
    esac
    
    dpkg -s $PACKAGE &> /dev/null
    if [ $? == 0 ] 
    then
        # Loop to ask if the user want to reinstall mariadb
        while true; do
            read -p "[${PACKAGE^^}] seems to be already installed. Would you reinstall the package? (y/n)" yn
            case $yn in
                [Yy]* ) printf $GREEN; echo -e "[${PACKAGE^^}] Uninstall in progress"; printf $WHITE;
                # Loading bar
                while true;do echo -n .;sleep 1;done &
                    # Erase the nginx.log file
                    > $LOG
                    # Remove & purge (Redirection to mariadb.log)
                    apt remove $PACKAGE -y --no-install-recommends apt-utils &> $LOG
                    apt purge $PACKAGE -y --no-install-recommends apt-utils &> $LOG
                    apt autoremove -y --no-install-recommends apt-utils &> $LOG
                    kill $!; trap 'kill $!' SIGTERM
                printf $GREEN
                echo -e "[${PACKAGE^^}] Successfully uninstalled!"
                printf $NOCOLOR
                break;;
                [Nn]* ) printf $RED; echo "[${PACKAGE^^}] Deployment canceled"; printf $NOCOLOR; result=false; break;;
                * ) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
            esac
        done
    fi
    echo
    local $result
}

# ----------------------------------
# HTML
# ----------------------------------
function createTemplate()
{

}

# ----------------------------------
# SOCK
# ----------------------------------


# ----------------------------------
# UNINSTALLATIONS
# ----------------------------------
uninstall nginx result
NGINX=$result
uninstall php7.3-fpm result
PHPFPM=$result
uninstall php7.3-mysql result
PHPMYSQL=$result
uninstall mariadb-server result
MARIADB=$result

# ----------------------------------
# INSTALLATIONS
# ----------------------------------
if [ $NGINX == true ]
then
    install nginx
fi
if [ $PHPFPM == true ]
then
    install php7.3-fpm
fi
if [ $PHPMYSQL == true ]
then
    install php7.3-mysql
fi
if [ $MARIADB == true ]
then
    install mariadb-server
fi