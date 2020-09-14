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

# --------------------------------------------------------------------
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
    printf $NOCOLOR
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
# SOCK
# ----------------------------------
function change_sock()
{
    SOCK=$(grep -c "/var/run/php/php7.3-fpm.sock" /etc/php/7.3/fpm/pool.d/www.conf)
    if [[ $SOCK == 0 ]]
    then
        sed -i 's/\/run\/php\/php7.3-fpm.sock/\/var\/run\/php\/php7.3-fpm.sock/g' /etc/php/7.3/fpm/pool.d/www.conf
        printf $BLUE
        echo "[PHP7.3-FPM] Sock path changed in /etc/php/7.3/fpm/pool.d/www.conf"
        printf $NOCOLOR
    fi
    sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
    printf $BLUE
    echo "[PHP7.3-FPM] Pathinfo set to 0 in /etc/php/7.3/fpm/php.ini"
    printf $NOCOLOR
}

# ----------------------------------
# MARIADB INIT
# ----------------------------------
function mariadb_init()
{
    service mysql start > /dev/null
    
    #
    # ROOT PWD
    while true; do
        read -p "Change root password? (y/n)" yn
        case $yn in
            [Yy]*) DB_PWD_CHANGE=true; break;;
            [Nn]*) DB_PWD_CHANGE=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    if [ $DB_PWD_CHANGE == true ]
    then
        while true; do
            read -s -p "Enter the new password: " pwd
            echo
            read -s -p "Please confirm the new password: " confirmPwd
            echo
            if [ $pwd == $confirmPwd ]
            then
                mysql -e "UPDATE mysql.user SET Password=PASSWORD('${pwd}') WHERE User='root';"
                if [ $? == 0 ]
                then
                    printf $GREEN; echo "Password changed for root!"; printf $NOCOLOR;
                    echo
                    break;
                else
                    printf $RED; echo "An error occured! Exiting..."; printf $NOCOLOR; exit;
                fi
            else
                printf $RED; echo "The passwords do not match! Try again."; printf $NOCOLOR
            fi
        done
    fi
    
    #
    # ANONYMOUS USERS
    while true; do
        read -p "Remove anonymous users? (y/n)" yn
        case $yn in
            [Yy]*) DB_RM_ANONYM=true; break;;
            [Nn]*) DB_RM_ANONYM=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    if [ $DB_RM_ANONYM == true ]
    then
        mysql -e "DELETE FROM mysql.global_priv WHERE User='';"
        if [ $0 == 0 ]
        then
            printf $GREEN; echo "Anonymous users removed!"; printf $NOCOLOR;
        else
            printf $RED; echo "An error occured!"; printf $NOCOLOR;
        fi
        echo
    fi
    
    #
    # DISALLOW REMOTE ROOT LOGIN
    while true; do
        read -p "Disallow root login remotely? (y/n)" yn
        case $yn in
            [Yy]*) DB_DIS_ROOT=true; break;;
            [Nn]*) DB_DIS_ROOT=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    if [ $DB_DIS_ROOT == true ]
    then
        mysql -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        if [ $? == 0 ]
        then
            printf $GREEN; echo "Remote root login disabled!"; printf $NOCOLOR;
        else
            printf $RED; echo "An error occured!"; printf $NOCOLOR;
        fi
        echo
    fi
    
    #
    # REMOVE TEST DATABASE
    while true; do
        read -p "Remove test database and access to it? (y/n)" yn
        case $yn in
            [Yy]*) DB_RM_TST=true; break;;
            [Nn]*) DB_RM_TST=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR
        esac
    done
    if [ $DB_RM_TST == true ]
    then
        mysql -e "DROP DATABASE test;"
        if [ $? == 0 ]
        then
            printf $GREEN; echo "Test database removed!"; printf $NOCOLOR;
        else
            printf $RED; echo "An error occured!"; printf $NOCOLOR;
        fi
        echo
    fi
    
    #
    # INSTALL BLACKHOLE
    while true; do
        read -p "Install BLACKHOLE engine? (y/n)" yn
        case $yn in
            [Yy]*) DB_BLACKHOLE=true; break;;
            [Nn]*) DB_BLACKHOLE=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    if [ $DB_BLACKHOLE == true ]
    then
        mysql -e "INSTALL SONAME 'ha_blackhole';"
        if [ $? == 0 ]
        then
            printf $GREEN; echo "BLACKHOLE Engine installed!"; printf $NOCOLOR;
        else
            printf $RED; echo "An error occured!"; printf $NOCOLOR;
        fi
        echo
    fi
    
    mysql -e "FLUSH PRIVILEGES;"
    if [ $? == 0 ]
    then
        printf $GREEN; echo "MySQL was securely installed"; printf $NOCOLOR;
    else
        printf $RED; echo "Critical error... please create an issue on github!"; printf $NOCOLOR; exit;
    fi
    service mysql start > /dev/null
}

# ----------------------------------
# TEMPLATE
# ----------------------------------
function createTemplate()
{
    result = false
    while true; do
        printf $WHITE
        read -p "[TEMPLATE] Do you want to initialize a fake website to see how NGINX works? (y/n)" yn
        case $yn in
            [Yy]*) TEMPLATE=true; break;;
            [Nn]*) TEMPLATE=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    if [ $TEMPLATE == true ] 
    then
        result=true
        if [[ ! -d "/var/www/html" ]]
        then
            mkdir /var/www/html
        fi
        mkdir /var/www/html/lempsgo/; cp src/files/index.php /var/www/html/lempsgo/index.php; cp src/files/info.php /var/www/html/lempsgo/info.php;
        chown -R www-data:www-data /var/www/html/lempsgo

        cp src/files/lempsgo /etc/nginx/sites-available/lempsgo; ln -s /etc/nginx/sites-available/lempsgo /etc/nginx/sites-enabled/

        nginx -t
        if [[ $? -ne 0 ]]
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
        
        echo
        printf $GREEN
        echo "LEMP'S GO! Go to the server URL like this: http://lempsgo.localhost/"
        printf $NOCOLOR
    fi
    
    local $result
}

# ----------------------------------
# CERTIFICATE
# ----------------------------------
function generateCertificate()
{
    printf $WHITE
    while true; do
        read -p "[CERTIFICATE] Do you want to generate a certificate for the fake website to see how NGINX and HTTPS works? (y/n)" yn
        case $yn in
            [Yy]*) CERT=true; break;;
            [Nn]*) CERT=false; break;;
            *) printf $RED; echo "Please answer yes or no."; printf $NOCOLOR;;
        esac
    done
    
    # Country
    CountryRegex='^[A-Z]{2}$'
    while true; do
        printf $WHITE
        read -p "[CERTIFICATE] Country name (2 letter code): " Country
        if [[ ${Country^^} =~ $CountryRegex ]]
        then
            break
        else
            printf $RED; echo "Please enter a correct country."; printf $NOCOLOR;
        fi
    done
    
    # State
    StateRegex='^([a-zA-Z]+|[a-zA-Z]+\s[a-zA-Z]+)$'
    while true; do
        printf $WHITE
        read -p "[CERTIFICATE] State or province name (full name): " State
        if [[ ${State} =~ $StateRegex ]]
        then
            break
        else
            printf $RED; echo "Please enter a correct state."; printf $NOCOLOR;
        fi
    done
    
    # City
    CityRegex='^([a-zA-Z]+|[a-zA-Z]+\s[a-zA-Z]+)$'
    while true; do
        printf $WHITE
        read -p "[CERTIFICATE] Locality name (eg, city): " City
        if [[ $City =~ $City ]]
        then
            break
        else
            printf $RED; echo "Please enter a correct city."; printf $NOCOLOR;
        fi
    done
    
    # Organization
    OrgRegex='|(^([a-zA-Z]+|[a-zA-Z]+\s[a-zA-Z]+)$)'
    while true; do
        printf $WHITE
        read -p "[CERTIFICATE] Organization name (eg, company): " Organization
        if [[ $Organization =~ $OrgRegex ]]
        then
            if [[ -z $Organisation ]]
            then
                Organization="None"
            fi
            break
        else
            printf $RED; echo "Please enter a correct organization."; printf $NOCOLOR;
        fi
    done
    
    # Website
    WebRegex='^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$'
    while true; do
        printf $WHITE
        read -p "[CERTIFICATE] Website URL (eg, FQDN): " Website
        if [[ $Website =~ $WebRegex ]]
        then
            break
        else
            printf $RED; echo "Please enter an correct URL."; printf $NOCOLOR;
        fi
    done
    
    openssl req -new -subj "/C=${Country^^}/ST=$State/L=$City/O=$Organization/CN=$Website" -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/lempsgo.key -out /etc/ssl/certs/lempsgo.crt
    
    if [ $? -ne 0 ]
    then
        printf $RED; echo "A fatal error occured..."; printf $NOCOLOR
    fi
    
    echo
    printf $PURPLE
    printf "Generate a Diffie-Hellman key"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf ".";
    echo
    printf $WHITE
    openssl dhparam -dsaparam -out /etc/nginx/dhp_key.pem 4096
    
    cp src/files/certificate.conf /etc/nginx/snippets/certificate.conf
    cp src/files/ssl-params.conf /etc/nginx/snippets/ssl-params.conf
    cat src/files/lempsgo-ssl > /etc/nginx/sites-available/lempsgo
    
    printf $GREEN
    echo "LEMP'S GO! Go to the server URL like this: https://lempsgo.localhost/"
    printf $NOCOLOR
}

# ----------------------------------
# PERMISSIONS
# ----------------------------------
if [ "$EUID" -ne 0 ]
  then
    printf $RED
    echo -e "Please run as root or execute with the sudo command"
    printf $NOCOLOR
  exit
fi

# --------------------------------------------------------------------
# BEGIN SCRIPT
# ----------------------------------
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
# UNINSTALLATIONS
# ----------------------------------
uninstall nginx result
NGINX=$result
uninstall mariadb-server result
MARIADB=$result
uninstall php7.3-fpm result
PHPFPM=$result
uninstall php7.3-mysql result
PHPMYSQL=$result

# ----------------------------------
# INSTALLATIONS
# ----------------------------------
if [ $NGINX == true ]
then
    printf $GREEN
    printf "Initialization of the NGINX step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
    printf $NOCOLOR
    echo
    install nginx
fi
if [ $MARIADB == true ]
then
    printf $ORANGE
    printf "Initialization of the MARIADB step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
    printf $NOCOLOR
    echo
    install mariadb-server
fi
if [ $PHPFPM == true ]
then
    printf $BLUE
    printf "Initialization of the PHP-FPM step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
    printf $NOCOLOR
    echo
    install php7.3-fpm
fi
if [ $PHPMYSQL == true ]
then
    printf $BLUE
    printf "Initialization of the PHP-MYSQL step"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
    printf $NOCOLOR
    echo
    install php7.3-mysql
fi

# ----------------------------------
# SOCK
# ----------------------------------
printf $BLUE
printf "FPM SOCK PATH"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
change_sock
echo

# ----------------------------------
# MARIADB
# ----------------------------------
printf $ORANGE
printf "Initialization of Mariadb"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
mariadb_init
echo

# ----------------------------------
# TEMPLATE
# ----------------------------------
printf $GREEN
printf "Initialization of template"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
printf $NOCOLOR
echo
createTemplate templateCreation
echo

# ----------------------------------
# CERTIFICATE
# ----------------------------------
if [[ $templateCreation == true ]]
then
    printf $PURPLE
    printf "Initialization of certificate"; sleep .2; printf "."; sleep .2; printf "."; sleep .2; printf "."
    printf $NOCOLOR
    echo
    generateCertificate
fi
# --------------------------------------------------------------------