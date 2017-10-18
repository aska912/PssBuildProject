#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0

#set -x


BUILDLOGE="$BLDHOMEPATH/build.log"

days_ago=90

date_ago=`date -d -${days_ago}days +%Y-%m-%d`

line=`cat $BUILDLOGE | awk -v DATE="$date_ago" '{if($2==DATE) print NR}'| tail -n 1`
if [ "$line" == "" ]; then
        exit
fi 

#ln=`expr $line + 1`
ln=$line
sed -i "1,$ln"d $BUILDLOGE
if [ $? -eq 0 ]; then
        ECHO "Removed the log records of "$days_ago"days ago"
fi




