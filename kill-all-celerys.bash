#!/usr/bin/env bash
me=`basename "$0"`

echo "process listing before"
ps aux | grep -i celery 
kill -9 `ps aux | grep -i celery | grep -v $me | grep -v grep | awk '{print $2}'`
echo "process listing after"
ps aux | grep -i celery

