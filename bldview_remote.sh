#!/bin/ksh

. /home/admin1830/bin/build/build_profile > /dev/null
get_script_name $0

if [ $# -ne 2 ]; then
        echo "Please enter the buildid & view_product."
        exit 1
else
        BUILD=$1
        VIEW_PRODUCT=$2
fi

if [ ! `whoami` == $BLDADMIN ]; then
        echo "Please use admin1830 account to execute the script."
        exit 1
else
        USERNAME=$BLDADMIN
fi

set -x

BLDSRV_SIM=$SIMBLDSERVER
BLDSRV_MVL=$MVLBLDSERVER
BLDSRV_WR=$WRBLDSERVER

# Select grapeape from grapeape-160811
bldname=`echo $BUILD | cut -d - -f 1`

[ $VIEW_PRODUCT == "pss4" ] && targets="$MVL" || targets="$SIM $MVL $WR"

for target in $targets
do
        viewname="$USERNAME-$VIEW_PRODUCT-$BUILD-$target-bld"
        view=`/usr/atria/bin/cleartool lsview -short "${viewname}" 2>/dev/null`
        if [[ $? -ne 0 ]]
        then
               print_err "no matching views found for pattern '$viewname'"
               exit 1
        fi 

        case $target in
        $SIM)
                remote_srv=$BLDSRV_SIM
                rules="sim_lc sim440_lc sim_armada sima9_lc"
                ;;
        $MVL)
                continue
                remote_srv=$BLDSRV_MVL
                if [ $VIEW_PRODUCT == "pss4" ]; then
                        rules="mvl_pss4"
                else
                        rules="mvl_ec mvl_lc mvl440_lc"
                fi
                ;;
        $WR)
                remote_srv=$BLDSRV_WR
                if [ "$bldname" == "grapeape" ]; then
                        rules="wr_armada wrp10xx_lc wra9_lc uscope"
                else
                        rules="wr_armada wrp10xx_lc wra9_lc uscope mvl_pss4"
                fi
                ;;
        *)
                print_err "Unknown the building type: $target"
                report_error
                exit 1
                ;;
        esac

        bldworld="${BLDHOMEPATH}/bldworld.sh $rules"
        bld_cmd=". /home/admin1830/profile.1830;/usr/atria/bin/cleartool setview -exec \"$bldworld\" $viewname"
        
        (ssh ${USERNAME}@${remote_srv} "$bld_cmd")
        #sleep 900
done 

#wait

[ $VIEW_PRODUCT == "dwdm_1830" ] && build_product="dwdm_1830_switch"
work_queue="$BLDHOMEPATH/bld_queue"
completed_queue="$BLDHOMEPATH/bld_completed_queue"
bld_task=`cat $work_queue | grep "$build_product" | grep "$BUILD"`
echo "$bld_task" >> $completed_queue 
sed -i "/$build_product\/$BUILD/d" $work_queue
if [ $? -eq 0 ]; then
        ECHO "Removed $bld_task from bld_queue"
fi

# Send mail to the building admin
$BLDHOMEPATH/bldresult_report.sh $BUILD

exit 0



