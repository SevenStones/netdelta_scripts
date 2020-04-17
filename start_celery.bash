#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
SITES="/home/iantibble/netdelta_sites/SITES"
RETVAL=0
USER=`cat /etc/passwd | grep iantibble | awk -F ":" '{print $3}'`

#
#me=`basename "$0"`
#
#echo "$#"
#
#if [ "$#" -gt 1 ]
#then
#    echo "Usage: start=celery.bash start|stop|status"
#    exit 1
#fi
#
#VIRTUALENV=`python -c 'import sys; print (sys.real_prefix)' 2>/dev/null`

VIRTUALENV_DIR=/home/iantibble/jango/netdelta304

if [ ! -d "$VIRTUALENV_DIR" ]; then
    echo "Virtualenv not found at specified location"
    exit 1
fi

if [ ! -f "$SITES" ]; then
    echo "No SITES file found"
    exit 1
fi

if [ ! -s $SITES ]; then
    echo "Sites file empty"
    exit 1
fi

GOOF=0
CELERY_COUNT=0

if [[ $EUID -ne "$USER" ]]; then
    echo "You must be iantibble to run this script"
    exit 1
fi

me=`basename "$0"`
#CELERY_COUNT=`ps aux | grep -i celery | grep -v ${me} | grep -v grep | grep -v "v[i,im]" | grep -v "systemctl" | grep -v "tail" | wc -l`
CELERY_COUNT=`ps aux | grep -i celery | grep -i worker | grep -v "${me}" | grep -Ev 'grep | vi | vim | systemctl | tail' | wc -l`

if [ $CELERY_COUNT -gt 0 ]; then
    echo -e "INFORMATION ONLY [sort of a warning but kind of not, ish]: ${RED}Celeries already found running ${NC}"
    #ops aux | grep -i celery | grep -Ev 'grep | v[i,im] | systemctl | tail'
    ps aux | grep -i celery | grep -i worker | grep -v "${me}" | grep -Ev 'grep | vi | vim | systemctl | tail'
fi

for SITE in `cat ${SITES}`
do
    SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}/netdelta"
    SITE_LOGS="/home/iantibble/netdelta_sites/${SITE}/logs"

    if [ ! -d "$SITE_ROOT" ]; then
        echo "Site ${SITE} does not exist"
        continue
    fi

    cd ${SITE_ROOT}
    nohup $VIRTUALENV_DIR/bin/celery worker -E -A nd -n ${SITE} -Q ${SITE} --loglevel=info -B --logfile=${SITE_LOGS}/celery.log >/dev/null 2>&1 &

    if [ "$?" -eq 0 ]; then
        echo -e "Celery launched successfully for ${SITE} : [${GREEN}OK${NC}]"
    else
        echo "Celery launch failed for ${SITE}"
        GOOF=1
    fi
done
