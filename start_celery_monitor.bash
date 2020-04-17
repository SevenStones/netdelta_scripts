#!/usr/bin/env bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
SITES="/home/iantibble/netdelta_sites/SITES"
USER=`cat /etc/passwd | grep iantibble | awk -F ":" '{print $3}'`
MONITOR_SCRIPT="/home/iantibble/jango/netdelta/celery-monitor.py"
VIRTUALENV_DIR="/home/iantibble/jango/netdelta304"

if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "Monitoring script not found"
    exit 1
fi

if [ ! -d "$VIRTUALENV_DIR" ]; then
    echo "Virtualenv not found at specified location"
    exit 1
fi

if [ ! -f "$VIRTUALENV_DIR/bin/python" ]; then
    echo "Python not found in specified virtualenv"
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

RETVAL=0

if [[ $EUID -ne "$USER" ]]; then
    echo "You must be iantibble to run this script"
    exit 1
fi

nohup $VIRTUALENV_DIR/bin/python ${MONITOR_SCRIPT} >/dev/null 2>&1 &

if [ "$?" -eq 0 ]; then
echo -e "Celery monitoring service launched successfully : [${GREEN}OK${NC}]"
else
echo "Celery monitoring launch failed for ${SITE}"
RETVAL=1
fi
exit ${RETVAL}
