#!/usr/bin/env bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
PROCESS_COUNT=`pgrep -c celery`
SCRIPT_ROOT="/home/iantibble/netdelta_sites/scripts"

if [ $PROCESS_COUNT -eq 0 ]; then
    echo "No active celery instances found"
else
   pkill celery
fi

if [ "$?" == 0 ]; then
    echo -e "kill command returned 0: [${GREEN}OK${NC}]"
    echo
    exit 0
else
    echo "pkill command returned error status: $?"
    exit 1
fi

echo "waiting for processes to exit"
sleep 10

echo
echo "Starting celery processes for Netdelta sites"

${SCRIPT_ROOT}/start_celery.bash
