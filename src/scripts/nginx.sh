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
# NGINX
##
NGINX=true

# Verify if the nginx command is available
dpkg -s nginx &> /dev/null
if [ $? == 0 ]
then
    # Loop to ask if the user want to reinstall nginx
    while true; do
        read -p "Nginx seems to be already installed. Would you reinstall the package? (y/n)" yn
        case $yn in
            [Yy]* ) echo "Uninstall in progress"; 
            # Loading bar
            while true;do echo -n .;sleep 1;done &
                # Erase the nginx.log file
                > ../../log/nginx.log
                # Remove & purge (Redirection to nginx.log)
                apt remove nginx nginx-common -y --no-install-recommends apt-utils &> ../../log/nginx.log
                apt purge nginx nginx-common -y --no-install-recommends apt-utils &> ../../log/nginx.log
                apt autoremove -y --no-install-recommends apt-utils &> ../../log/nginx.log
                kill $!; trap 'kill $!' SIGTERM
            echo "nginx was uninstalled!"
            break;;
            [Nn]* ) echo "Nginx deployment is canceled"; NGINX=false break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

if [ $NGINX == true ]
then
    #
    ##
    # Install Nginx
    ##
    echo "Installation in progress"; 
    # Loading bar
    while true;do echo -n .;sleep 1;done &
        # Installation (Redirection to nginx.log)
        apt install nginx nginx-common -y --no-install-recommends apt-utils &> ../../log/nginx.log
        kill $!; trap 'kill $!' SIGTERM
    if !command -v nginx &> /dev/null
    then
        echo "an error occured! Please see the nginx log file in log/nginx.log"
        exit
    fi
    echo "nginx was installed!"
fi