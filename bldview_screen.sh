#!/bin/ksh

. /home/admin1830/bin/build/build_profile > /dev/null
get_script_name $0

if [ $# -ne 2 ]; then
        echo "Please enter the buildid & build_product."
        exit 1
else
        BUILD=$1
        BUILD_PRODUCT=$2
fi


if [ ! `whoami` == $BLDADMIN ]; then
        echo "Please use admin1830 account to execute the script."
        exit 1
else
        USERNAME=$BLDADMIN
fi


#set -x

BLDSCRIPT="$BLDHOMEPATH/bldview_remote.sh"
VIEW_PRODUCT=`convert_to_view_product $BUILD_PRODUCT`
SCREEN_NAME="Building $BUILD for $BUILD_PRODUCT"

is_run_pid=`bld_screen_pid`
if [ $is_run_pid -eq $NO_PID ]; then
        screen -dmS "$SCREEN_NAME" $BLDSCRIPT $BUILD $VIEW_PRODUCT
else
        ECHO "($is_run_pid)`bld_screen_name`($BUILD_PRODUCT) screen is running."
        exit 1
fi

sleep 15

bld_pid=`bld_screen_pid`
if [ $bld_pid -eq $NO_PID ]; then
    ECHO "Generated the building screen fail"
    exit 1
else
    ECHO "Created `bld_screen_name`($BUILD_PRODUCT)"
fi


exit 0
