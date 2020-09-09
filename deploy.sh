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

printf $WHITE
echo -e " +--------------------------------------------+"
sleep .2
echo -e " |   _   \033[0;32m ___\033[0;33m __  __\033[0;34m ___\033[1;37m _ ___  \033[0;36m  ___  ___  \033[1;37m  |"
sleep .2
echo -e " |  | |  \033[0;32m| __\033[0;33m|  \/  \033[0;34m| _ \033[1;37m( ) __| \033[0;36m / __|/ _ \ \033[1;37m  |"
sleep .2
echo -e " |  | |__\033[0;32m| _|\033[0;33m| |\/| \033[0;34m|  _\033[1;37m//\__ \ \033[0;36m| (_ | (_) |\033[1;37m  |"
sleep .2
echo -e " |  |____\033[0;32m|___\033[0;33m|_|  |_\033[0;34m|_|\033[1;37m   |___/ \033[0;36m \___|\___/ \033[1;37m  |" 
sleep .2
echo -e " |                                            |"
sleep .2
echo -e " +--------------------------------------------+"
echo -e " \\- - - - - - - - - - -  - - - - - - - - - - -/"
sleep .2
echo -e " +--------------------------------------------+"
sleep .2
echo -e " |  Author: _______$GREEN Jonas Hügli$WHITE               |"
sleep .2
echo -e " |  Description: __$GREEN Usefull LEMP deployment$WHITE   |"
sleep .2
echo -e " |  Git: __________$GREEN github.com/huglijonas/$WHITE    |"
sleep .2
echo -e " |  License: ______$GREEN AGPL-3.0$WHITE                  |"
sleep .2
echo -e " +--------------------------------------------+"
printf $NOCOLOR

# ----------------------------------
# Verify permission
# ----------------------------------
if [ "$EUID" -ne 0 ]
  then
    printf $RED
    echo -e "Please run as root or execute with the sudo command"
    printf $NOCOLOR
  exit
fi

while true; do
    read -p "Are you sure to perform the LEMP installation? (y/n)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
    esac
done

# ----------------------------------
# NGINX
# ----------------------------------
printf $GREEN
printf "Initialization of the NGINX step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
bash src/scripts/nginx.sh

# ----------------------------------
# PHP
# ----------------------------------
printf $ORANGE
printf "Initialization of the MARIADB step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
bash src/scripts/mariadb.sh

# ----------------------------------
# PHP
# ----------------------------------
printf $BLUE
printf "Initialization of the PHP step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
bash src/scripts/php.sh

# ----------------------------------
# HTML
# ----------------------------------
while true; do
    read -p "Do you want to initialize a fake website to see how NGINX works? (y/n)" yn
    case $yn in
        [Yy]* ) WEBSITE=true; break;;
        [Nn]* ) WEBSITE=false; break;;
        * ) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
    esac
done
if [ $WEBSITE == true ]
then
    if [[ ! -d "/var/www/" ]]
    then
        mkdir /var/www
    fi
    mkdir /var/www/lempsgo/; cp src/files/index.php /var/www/lempsgo/index.php; cp src/files/info.php /var/www/lempsgo/info.php;
    chown -R www-data:www-data /var/www/lempsgo
    
    cp src/files/lempsgo /etc/nginx/sites-available/lempsgo; ln -s /etc/nginx/sites-available/lempsgo /etc/nginx/sites-enabled/
    
    nginx -t
    if [[ $! -ne 0 ]]
    then
        printf $RED
        echo "An error occured!"
        printf $NOCOLOR
        exit
    fi
    
    if [ command -v systemctl &> /dev/null ]
    then
        systemctl restart nginx
        systemctl start php7.3-fpm && systemctl restart php7.3-fpm
        systemctl restart mysql
    else
        service nginx restart
        service php7.3-fpm start && service php7.3-fpm restart
        service mysql restart
    fi
fi

echo
printf $GREEN
echo "LEMP'S GO! Go to the server URL like this: 127.0.0.1/lempsgo"
printf $NOCOLOR