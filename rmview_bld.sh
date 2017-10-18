#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0

set -x

if [ -z "$1" ]; then
        print_err "Missing the build name"
        exit 1
fi

BUILD=$1
PRODUCT=$PRODUCT
USERNAME=$BLDADMIN



for bld_name in $SIM $MVL $WR
do
        viewname="$USERNAME-$PRODUCT-$BUILD-$bld_name-bld"
        /home/admin1830/manage/bin/removeview $viewname
        if [ $? -ne 0 ]; then
                warm_msg="Removeview $viewname fail for BLD"
                ECHO "$warm_msg"
                subject="$warm_msg"
                body="Removeview $viewname fail. Please check it."
                sendmail "$TO" "$subject" "$body"
                continue
        fi
done


$BLDHOMEPATH/clean_completed_queue.sh $BUILD


