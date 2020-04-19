#!/usr/bin/env bash

if [ "$#" == 0 ] || [ "$#" -gt 2 ]
then
    echo "Usage: site_sync.bash [-v] site"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

if [ "$#" == 2 ]; then
    SITE="$2"
    if [ "$1" != "-v" ]; then
        echo "Usage: site_sync.bash [-v] site"
	exit 1
    fi
fi

INVENV=`python -c 'import sys; print (sys.prefix)'`

if [ "$INVENV" == "/usr" ]; then
    echo "You must be a in virtualenv to run this"
    exit 1
fi
    
if [ "$#" == 1 ]; then
    SITE="$1"
fi

SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}"
SITE_ND="/home/iantibble/netdelta_sites/${SITE}/netdelta"
GREEN='\033[0;32m'
NC='\033[0m' # No Color
ND_ROOT="/home/iantibble/jango/netdelta"

if [ ! -d "$SITE_ROOT" ]; then
    echo "Site directory does not exist"
    exit 1
fi

if [ $1 == "-v" ]; then 
    rsync -avzrpl --exclude-from config/exclude-list.txt --progress ${ND_ROOT}/ ${SITE_ROOT}/netdelta/
else
    rsync -azrpl --exclude-from config/exclude-list.txt ${ND_ROOT}/ ${SITE_ROOT}/netdelta/
fi

if [ $? -eq 0 ]; then
    echo -e "Sync completed: [${GREEN}OK${NC}]"
fi 

cd ${SITE_ND}
pwd

echo "Syncing netdelta database for $SITE"
python manage.py makemigrations nd
python manage.py migrate
echo

echo "fixing permissions"
/usr/local/bin/fixperms.bash

echo "REMEMBER - database migration files, settings.py and wsgi.py was not sync'd" 
