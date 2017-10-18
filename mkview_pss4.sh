#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0

BUILD=$1

PRODUCT="pss4"
USERNAME=`whoami`

#set -x

rule="$MVL"

for bld_name in $rule
do
        if [ $bld_name = $SIM ]; then
                viewname="$USERNAME-$PRODUCT-$BUILD-$bld_name-bld"
                makeview -p $PRODUCT -b $BUILD $viewname
                if [[ $? -ne 0 ]]
                then
                        warm_msg="Makeview $viewname fail"
                        ECHO "$warm_msg"
                        subject="$warm_msg"
                        body="Makeview $viewname fail. Please check it."
                        sendmail "$TO" "$subject" "$body"
                        exit $MAKEVIEW_FAIL
                fi
        else
                viewname="$USERNAME-$PRODUCT-$BUILD-$bld_name-bld"
                mkview=". /home/admin1830/profile.1830;/home/admin1830/manage/bin/makeview -p $PRODUCT -b $BUILD $viewname"
                ssh ${USERNAME}@${WRBLDSERVER} "$mkview"
                if [[ $? -ne 0 ]]
                then
                        warm_msg="Makeview $viewname fail"
                        ECHO "$warm_msg"
                        subject="$warm_msg"
                        body="Makeview $viewname fail. Please check it."
                        sendmail "$TO" "$subject" "$body"
                        exit $MAKEVIEW_FAIL
                fi
        fi
done


exit 0
