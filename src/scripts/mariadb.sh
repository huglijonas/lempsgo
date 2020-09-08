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
# MARIADB
##
MARIADB=true

# Verify if the mariadb command is available
dpkg -s mariadb-server &> /dev/null
if [ $? == 0 ]
then
    # Loop to ask if the user want to reinstall mariadb
    while true; do
        read -p "MariaDB seems to be already installed. Would you reinstall the package? (y/n)" yn
        case $yn in
            [Yy]* ) echo "Uninstall in progress"; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Erase the nginx.log file
                > ../../log/mariadb.log
                # Remove & purge (Redirection to mariadb.log)
                apt remove mariadb-server -y --no-install-recommends apt-utils &> ../../log/mariadb.log
                apt purge mariadb-server -y --no-install-recommends apt-utils &> ../../log/mariadb.log
                apt autoremove -y --no-install-recommends apt-utils &> ../../log/mariadb.log
                kill $!; trap 'kill $!' SIGTERM
            echo "mariadb was uninstalled!"
            break;;
            [Nn]* ) echo "Mariadb deployment is canceled"; MARIADB=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

if [ $MARIADB == true ]
then
    #
    ##
    # Install MariaDB
    ##
    echo "Installation in progress"; 
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to nginx.log)
        apt install mariadb-server -y --no-install-recommends apt-utils &> ../../log/mariadb.log
        kill $!; trap 'kill $!' SIGTERM
    if !command -v mariadb &> /dev/null
    then
        echo "an error occured! Please see the mariadb log file in log/mariadb.log"
        exit
    fi
    echo "mariadb was installed!"
fi