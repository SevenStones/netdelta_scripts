#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: fix_apache_config.bash site"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi


SITE="$1"
SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Adjusting settings.py database name"
cp -v /home/iantibble/netdelta_sites/scripts/config/new.conf /etc/apache2/sites-available/${SITE}.conf
sed -i -e "s/SITE/$SITE/g" /etc/apache2/sites-available/${SITE}.conf

echo "Apache: enable new site"
a2ensite ${SITE}.conf

if [ "$?" == 0 ]; then
    echo -e "Enabled new Apache site: [${GREEN}OK${NC}]"
else
    echo "Apache new site enablement failed"
    exit 1
fi

echo "Restart Apache server"
service apache2 restart

if [ "$?" == 0 ]; then
    echo -e "apache config adjusted successfully for site: [${GREEN}OK${NC}]"
else
    echo "apache config adjustment failed"
    exit 1
fi

echo "check Apache port settings - the port number was not adjusted here"
