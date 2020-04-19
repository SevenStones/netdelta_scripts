#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: netd_deploy.bash site port"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

INVENV=`python -c 'import sys; print (sys.prefix)'`

if [ "$INVENV" == "/usr" ]; then
    echo "You must be a in virtualenv to run this"
    exit 1
fi

SITE="$1"
SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}"
SITES_ROOT="/home/iantibble/netdelta_sites"
GREEN='\033[0;32m'
NC='\033[0m' # No Color
PORT="$2"
VENV_ROOT="/home/iantibble/jango/netdelta304"
MYSQL_DIR="${VENV_ROOT}/lib/python3.6/site-packages/django/db/backends/mysql"
LIBNMAP_DIR="${VENV_ROOT}/lib/python3.6/site-packages/libnmap"


function patch_MySQL_base(){
  echo "Applying patch for base.py (MySQL Django framework)"
  cp -v ${MYSQL_DIR}/base.py ${MYSQL_DIR}/base.orig
  patch ${MYSQL_DIR}/base.py -i /home/iantibble/netdelta_sites/scripts/patches/base.patch \
  -o ${MYSQL_DIR}/base.patched
  if [ "$?" == 0 ]; then
      echo -e "Successfully patched base.py file: [${GREEN}OK${NC}]"
      cp -v ${MYSQL_DIR}/base.patched ${MYSQL_DIR}/base.py
      rm ${MYSQL_DIR}/base.patched
      echo "backup of original file is at ${MYSQL_DIR}/base.orig"
  else
      echo "Patching of Django MySQL base.py failed"
      exit 1
  fi
}

function patch_libnmap(){
  echo "Applying patch for libnmap"
  cp -v ${LIBNMAP_DIR}/process.py ${LIBNMAP_DIR}/process.orig
  patch ${LIBNMAP_DIR}/process.py -i /home/iantibble/netdelta_sites/scripts/patches/libnmap-process.patch \
  -o ${LIBNMAP_DIR}/process.patched
  if [ "$?" == 0 ]; then
      echo -e "Successfully patched libnmap process.py: [${GREEN}OK${NC}]"
      cp -v ${LIBNMAP_DIR}/process.patched ${LIBNMAP_DIR}/process.py
      rm -v ${LIBNMAP_DIR}/process.patched
      echo "backup of original file is at ${LIBNMAP_DIR}/process.orig"
  else
      echo "Patching of libnmap process.py failed"
      exit 1
  fi
}



echo "Creating database"
mysql -e "CREATE DATABASE IF NOT EXISTS netdelta_$SITE CHARACTER SET utf8 COLLATE utf8_unicode_ci;" \
    --user=root --password=ankSQL4r4

if [ "$?" == 0 ]; then
    echo -e "Site netdelta database netdelta-$SITE created: [${GREEN}OK${NC}]"
else
    echo "Site database creation failed"
    exit 1
fi


echo "Making site root directory"
mkdir -v ${SITE_ROOT}

if [ "$?" == 0 ]; then
    echo -e "Site root created: [${GREEN}OK${NC}]"
else
    echo "Site root directory creation failed"
    exit 1
fi

echo "Making site logs directory"
mkdir -v ${SITE_ROOT}/logs
touch ${SITE_ROOT}/logs/netdelta.log
touch ${SITE_ROOT}/logs/debug.log
touch ${SITE_ROOT}/logs/crash.log


if [ "$?" == 0 ]; then
    echo -e "Site logs directory created: [${GREEN}OK${NC}]"
else
    echo "Site logs directory creation failed"
    exit 1
fi

echo "Making site web root"
mkdir -v /var/www/html/$SITE

if [ "$?" == 0 ]; then
    echo -e "Site web root created: [${GREEN}OK${NC}]"
else
    echo "Site web root creation failed"
    exit 1
fi

# shellcheck disable=SC2164
cd "${SITE_ROOT}"

echo "Setting up Django project"

django-admin startproject netdelta

if [ "$?" == 0 ]; then
    echo -e "netdelta project created: [${GREEN}OK${NC}]"
else
    echo "netdelta project creation failed"
    exit 1
fi

cd ${SITE_ROOT}/netdelta

echo "Setting up Django application"
django-admin startapp nd

if [ "$?" == 0 ]; then
    echo -e "netdelta app created: [${GREEN}OK${NC}]"
else
    echo "netdelta app creation failed"
    exit 1
fi

echo "Syncing netdelta source with new site"
rsync -azpr --exclude-from=${SITES_ROOT}/scripts/config/deploy-excludes.txt /home/iantibble/jango/netdelta/ /home/iantibble/netdelta_sites/${SITE}/netdelta/

if [ "$?" == 0 ]; then
    echo -e "netdelta source code sync completed: [${GREEN}OK${NC}]"
else
    echo "netdelta source code sync failed"
    exit 1
fi

echo "Adjusting settings.py database name"
cp -v /home/iantibble/netdelta_sites/scripts/config/settings.py /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta
sed -i -E "s/SITENAME/$SITE/g" /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta/settings.py

echo "Adjusting directory and ownership permissions"
/usr/local/bin/fixperms.bash

if [ "$?" == 0 ]; then
    echo -e "netdelta directory and ownership adjustments completed: [${GREEN}OK${NC}]"
else
    echo "directory and ownership adjustments failed"
    exit 1
fi

echo
echo "checking patches for MySQL and Libnmap frameworks"
cmp /home/iantibble/netdelta_sites/scripts/patches/base.py.modified ${MYSQL_DIR}/base.py \
&& echo -e "Django MySQL base.py already patched: [${GREEN}OK${NC}]" \
|| patch_MySQL_base

cmp /home/iantibble/netdelta_sites/scripts/patches/process.py.modified ${LIBNMAP_DIR}/process.py \
&& echo -e "libnmap process.py already patched: [${GREEN}OK${NC}]" \
|| patch_libnmap
echo

echo "Setting up tables for $SITE netdelta database"
python manage.py makemigrations nd
python manage.py migrate
echo

echo "Add administrative user for $SITE's netdelta"
echo "from django.contrib.auth.models import User; User.objects.filter(email='itibble@gmail.com').delete(); \
    User.objects.create_superuser('admin', 'itibble@gmail.com', 'octl1912')" | python manage.py shell

if [ "$?" == 0 ]; then
    echo -e "netdelta admin account added: [${GREEN}OK${NC}]"
else
    echo "netdelta admin account setup failed"
    exit 1
fi


echo "Adjusting Apache site files for ${SITE}"
cp -v /home/iantibble/netdelta_sites/scripts/config/new.conf /etc/apache2/sites-available/${SITE}.conf
sed -i -E "s/SITE/$SITE/g" /etc/apache2/sites-available/${SITE}.conf
sed -i -E "s/PORT/$PORT/g" /etc/apache2/sites-available/${SITE}.conf

echo "Adjusting wsgi.py to enable virtualenv"
cp -v /home/iantibble/netdelta_sites/scripts/config/wsgi.py /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta
sed -i -E "s/SITE/$SITE/g" /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta/wsgi.py

if [ "$?" == 0 ]; then
    echo -e "wsgi.py adjusted successfully: [${GREEN}OK${NC}]"
else
    echo "wsgi.py adjustment failed"
    exit 1
fi

echo "Adjusting celery_app.py for celery queue configuration"
cp -v /home/iantibble/netdelta_sites/scripts/config/celery_app.py /home/iantibble/netdelta_sites/${SITE}/netdelta/nd
sed -i -E "s/SITE/$SITE/g" /home/iantibble/netdelta_sites/${SITE}/netdelta/nd/celery_app.py

if [ "$?" == 0 ]; then
    echo -e "celery_app.py adjusted successfully: [${GREEN}OK${NC}]"
else
    echo "celery_app.py adjustment failed"
    exit 1
fi

echo "Adjusting nd/__init__.py for celery queue configuration"
cp -v /home/iantibble/netdelta_sites/scripts/config/innit.py /home/iantibble/netdelta_sites/${SITE}/netdelta/nd/__init__.py

if [ "$?" == 0 ]; then
    echo -e "nd/__init__.py adjusted successfully: [${GREEN}OK${NC}]"
else
    echo "nd/__init__.py adjustment failed"
    exit 1
fi

echo "Modifying base site template to cater for custom site name"
cp -v /home/iantibble/netdelta_sites/scripts/config/base_site.html /home/iantibble/netdelta_sites/${SITE}/netdelta/templates/admin/base_site.html
sed -i -E "s/SITE/$SITE/g" /home/iantibble/netdelta_sites/${SITE}/netdelta/templates/admin/base_site.html

if [ "$?" == 0 ]; then
    echo -e "base site template file adjusted successfully: [${GREEN}OK${NC}]"
else
    echo "base site template adjustment failed"
    exit 1
fi

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


echo "Adjusting directory and ownership permissions"
/usr/local/bin/fixperms.bash

echo
echo "Don't forget to adjust ports.conf for Apache, and get a web cert"
echo "Script ended at `date`"
echo "---------------------------"
