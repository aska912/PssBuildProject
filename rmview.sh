#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0

if [ -z "$1" ]; then
        warm_msg="The viewname is null. Please enter the view name."
        ECHO "$warm_msg"
        subject="$warm_msg"
        body="$warm_msg"
        sendmail "$TO" "$subject" "$body"
        exit 1
fi

viewname=$1

/home/admin1830/manage/bin/removeview $viewname
if [ $? -ne 0 ]; then
        warm_msg="Removeview $viewname fail"
        ECHO "$warm_msg"
        subject="$warm_msg"
        body="Removeview $viewname fail. Please check it."
        sendmail "$TO" "$subject" "$body"
        exit 1
fi



