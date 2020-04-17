#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: fix-settings.bash site"
    exit 1
fi

SITE="$1"
SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Adjusting settings.py database name"
cp -v /home/iantibble/netdelta_sites/scripts/config/settings.py /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta
sed -i -e "s/SITENAME/$SITE/g" /home/iantibble/netdelta_sites/${SITE}/netdelta/netdelta/settings.py

if [ "$?" == 0 ]; then
    echo -e "settings.py adjusted successfully for site: [${GREEN}OK${NC}]"
else
    echo "settings.py adjustment failed"
    exit 1
fi
