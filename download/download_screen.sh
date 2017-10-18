#!/bin/ksh 

. /home/admin1830/bin/build/build_profile
get_script_name $0
#set -x

APTDOWNLOAD="$BLDHOMEPATH/download/download_from_apt.sh"
MHDOWNLOAD="$BLDHOMEPATH/download/download_from_mh.sh"

pid=`screen -ls | grep "Download" | cut -d "." -f 1 | sed s/[[:space:]]//g`
if [[ $pid =~ ^[0-9]+$ ]]; then
        ECHO "The script is being excuted."
        exit
fi


if [ $# -gt 0 ]; then
        load_path=$1
else
        load_path=`head $DOWNLOAD_QUEUE -n 1`
        if [ -z "$load_path" ]; then
                ECHO "No downloading task in download_queue"
                exit 0
        fi
fi


loadname=`echo $load_path | awk -F'/' '{print $8}'`
#$APTDOWNLOAD $load_path "check"
#check_rtr=$?
check_rtr=1
if [ $check_rtr -ne 0 ]; then
        ECHO "The load is not in APT"
        if [ `is_download_time` -eq $NOWORKTIME ]; then
                ECHO "Going to download from MH "
                screen -dmS "Download $loadname image from MH" $MHDOWNLOAD $load_path
        else
                ECHO "Now is working time, can't download from MH"
                remove_rec_from_download_queue $loadname
                sleep 1
                $BLDHOMEPATH/download/add_download_queue.sh $load_path
        fi
else
        ECHO "Going to download from APT"
        screen -dmS "Download $loadname image from APT" $APTDOWNLOAD $load_path 
fi


