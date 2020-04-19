#!/usr/bin/env bash


if [ "$#" -gt 2 ] || [ "$#" -eq 0 ]; then
    echo "Usage: netd_delete.bash site [-p]"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

if [ "$2" != "-p" ]; then
    echo "unknown option supplied"
    echo "Usage: netd_delete.bash site [-p]"
    exit 1
fi

SITE=$1
SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ -d "${SITE_ROOT}" ]; then
  echo "Site root directory does not exist"
  exit 1
fi

if [ "$2" != "-p" ] || [ "$#" == 1 ]; then
  echo "Delete database"
  mysql -e "DROP DATABASE IF EXISTS netdelta_${SITE};" --user=root --password=ankSQL4r4

  if [ "$?" == 0 ]; then
      echo -e "Site netdelta database netdelta_${SITE} deleted: [${GREEN}OK${NC}]"
  else
      echo "Site database deletion failed"
      exit 1
  fi
fi

echo "Delete site root directory"
rm -r "${SITE_ROOT}"

if [ "$?" == 0 ]; then
    echo -e "Site root deleted: [${GREEN}OK${NC}]"
else
    echo "Site root directory deletion failed"
    exit 1
fi

echo "Deleting site web root"
rm -r /var/www/html/$SITE

if [ "$?" == 0 ]; then
    echo -e "Site web root deleted: [${GREEN}OK${NC}]"
else
    echo "Site web root deletion failed"
    exit 1
fi

echo "Adjusting Apache site files for ${SITE}"
rm /etc/apache2/sites-available/${SITE}.conf

echo "Apache: disable site"
a2dissite ${SITE}.conf

if [ "$?" == 0 ]; then
    echo -e "Disabled Apache site: [${GREEN}OK${NC}]"
else
    echo "Apache site disablement failed"
    exit 1
fi

echo "Restart Apache server"
service apache2 restart


echo
echo "Don't forget to adjust ports.conf for Apache"
echo "Script ended at `date`"
echo "---------------------------"
