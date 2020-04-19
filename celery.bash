#!/usr/bin/env bash


SITES="/home/iantibble/netdelta_sites/SITES"
GREEN='\033[0;32m'
NC='\033[0m' # No Color
USER=`cat /etc/passwd | grep iantibble | awk -F ":" '{print $3}'`
RETVAL=0


me=`basename "$0"`

if [ "$#" -gt 2 ]
then
    echo "Usage: celery.bash start|stop|status all|site"
    exit 1
fi

if [[ $EUID -ne "$USER" ]]; then
    echo "You must be iantibble to run this script"
    exit 1
fi

INVENV=`python -c 'import sys; print (sys.prefix)'`

if [ "$INVENV" == "/usr" ]; then
    echo "You must be a in virtualenv to run this"
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

start_celery(){

    GOOF=0

    if [ "$#" -ne 1 ]
    then
        echo "Usage: celery.bash start|stop|status all|site"
        exit 1
    fi

    if [ "$1" == "all" ]; then
        for SITE in `cat ${SITES}`
        do
            SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}/netdelta"
            SITE_LOGS="/home/iantibble/netdelta_sites/${SITE}/logs"

            if [ ! -d "$SITE_ROOT" ]; then
                echo "Site ${SITE} does not exist"
            fi

            cd $SITE_ROOT
            nohup celery worker -E -A nd -n ${SITE} -Q ${SITE} --loglevel=info -B --logfile=${SITE_LOGS}/celery.log >/dev/null 2>&1 &

            if [ "$?" -eq 0 ]; then
                echo -e "Celery launched successfully for ${SITE} : [${GREEN}OK${NC}]"
            else
                echo "Celery launch failed for ${SITE}"
                GOOF=1
            fi
        done

        if [ "$GOOF" -gt 0 ]; then
            echo "at least one site failed to launch"
            exit 1
        else
            echo "all sites launched successfully"
            exit 0
        fi
    fi


    if grep -q "$1" ${SITES}; then

        SITE=$1
        SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}/netdelta"
        SITE_LOGS="/home/iantibble/netdelta_sites/${SITE}/logs"

        if [ ! -d "$SITE_ROOT" ]; then
            echo "Site root for ${SITE} does not exist"
            exit 1
        fi

        cd $SITE_ROOT
        nohup celery worker -A nd -n ${SITE} -Q ${SITE} --loglevel=info -B --logfile=${SITE_LOGS}/netdelta-${SITE}-celery.log >/dev/null 2>&1 &

        if [ "$?" -ne 0 ]; then
            echo -e "Celery launched successfully for ${SITE} : [${GREEN}OK${NC}]"
        else
            echo "Celery launch failed for ${SITE}"
            exit 1
        fi
    else
        echo "site not registered"
        exit 1
    fi
}

stop_celery(){

    if [ "$#" -ne 1 ]; then
        echo "Usage: celery.bash start|stop|status all|site"
        exit 1
    fi

    if [ "$1" == "all" ]; then

        me=`basename "$0"`
        PROCESS_COUNT=`ps aux | grep -E 'celery' | grep -v grep | grep -v $me | wc -l`

        if [ $PROCESS_COUNT -eq 0 ]; then
            echo "No active celery instances found"
            exit 1
        fi
        echo "process listing before"
        ps aux | grep -i celery
        kill -9 `ps aux | grep -i celery | grep -v $me | grep -v grep | awk '{print $2}'`

        if [ "$?" == 0 ]; then
            echo -e "kill command returned 0: [${GREEN}OK${NC}]"
            echo "process listing after"
            ps aux | grep -i celery | grep -v grep | grep -v $me
            exit 0
        else
            echo "kill command returned error status: $?"
            exit 1
        fi
    fi

    if grep -q "$1" ${SITES}; then

        SITE=$1
        SITE_ROOT="/home/iantibble/netdelta_sites/${SITE}/netdelta"

        if [ ! -d "$SITE_ROOT" ]; then
            echo "Site root for ${SITE} does not exist"
            exit 1
        fi

        kill -9 `ps aux | grep -E $1 | grep -E 'celery' | grep -v grep | grep -v $me | awk '{print $2}'`

        if [ "$?" == 0 ]; then
            echo -e "Celery killed successfully for ${SITE} : [${GREEN}OK${NC}]"
        else
            echo "Celery kill failed for ${SITE}"
            exit 1
        fi

    else
        echo "site not registered"
        exit 1
    fi


}

status(){

    echo "checking process status(es) for registered sites"

    for SITE in `cat ${SITES}`
    do
        PROCESS_COUNT=`ps aux | grep -E $SITE | grep -E 'celery' | grep -v grep | grep -v $me | wc -l`

        if [ $PROCESS_COUNT -eq "0" ]; then
            echo " - Celery for site ${SITE} is not running"
        else
            echo -e "Celery for site ${SITE} is running : [${GREEN}OK${NC}]"
        fi
     done
}

case "$1" in
    start)
        start_celery $2
        ;;
    stop)
        stop_celery $2
        ;;
    restart)
        stop_celery $2
        start_celery $2
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: celery.bash start|stop|status site|all" >&2
        RETVAL=1
        ;;
esac

exit $RETVAL
