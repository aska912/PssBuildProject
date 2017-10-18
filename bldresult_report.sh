#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0

BUILD=$1
PRODUCT="dwdm_1830"
USERNAME=`whoami`
BLDHOMEPATH="/home/admin1830/bin/build"
SCRIPT="get_bld_result.py"

result=""
#set -x

for target in $SIM $MVL $WR 
do
        viewname="$USERNAME-$PRODUCT-$BUILD-$target-bld"
        #result+=`cleartool setview -exec $BLDHOMEPATH/$SCRIPT $viewname`
        result+=`$BLDHOMEPATH/bldresult.sh $viewname`
        if [[ $? -ne 0 ]]
        then
                ECHO "Get the building result of $viewname fail"
                continue
		#exit 1
        fi
done


#echo -e "$result"

to="jiemingg,xiaodoya"
sendmail "$to" "The building report of $BUILD" "$result"
if [[ $? -ne 0 ]]
then
        ECHO "Send mail fail"
        exit 1
fi

exit 0



