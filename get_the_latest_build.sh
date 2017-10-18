#!/bin/ksh

. /home/admin1830/bin/build/build_profile


if [ $# -ne 1 ]; then
    echo "Please enter the release"
    exit 1 
else
    RELEASE=$1
fi

#set -x

#PRODUCT="dwdm_1830"


#prod="/home/admin1830/manage/config_specs/$PRODUCT"
#basebuild=`ls $prod | grep "$RELEASE-" | tail -n 1 | cut -d"-" -f 2,3`
echo `get_the_latest_build $RELEASE`

