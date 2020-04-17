#!/usr/bin/env bash

GREEN='\033[0;32m'
NC='\033[0m' # No Color
me=`basename $0`
PROCESS_COUNT=`ps aux | grep -i celery | grep -i worker | grep -v $me | grep -v grep | wc -l`

if [ $PROCESS_COUNT -eq 0 ]; then
    echo "No active celery instances found"
    exit 1
fi
echo "process listing before"
ps aux | grep -i celery | grep -i worker | grep -v $me | grep -v grep

kill -9 `ps aux | grep -i celery | grep -i worker | grep -v "${me}" | grep -v grep | awk '{print $2}'`

if [ "$?" == 0 ]; then
    echo -e "kill command returned 0: [${GREEN}OK${NC}]"
    echo
    echo "process listing after"
    ps aux | grep -i celery | grep -i worker | grep -v $me | grep -v grep
else
    echo "kill command returned error status: $?"
    exit 1
fi
