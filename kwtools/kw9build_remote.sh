#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0


if [ ! `whoami` == $BLDADMIN ]; then
        echo "Please use admin1830 account to execute the script."
        exit 1
else
        USERNAME=$BLDADMIN
fi

set -x

KWBLDSERVER=$MVLBLDSERVER
BLDSCRIPT="${BLDHOMEPATH}/kwbuild.sh sim_lc"
KWBLD_SRV=$BLD_KW_SSH

if [ -n "$1" ]; then
        BUILD=$1
else
        rel=$kw_build_rel

        #################################################
        # Get the latest base build with the specified 
        #release
        ################################################
        prod="/home/admin1830/manage/config_specs/dwdm_1830"
        basebuild=`ls $prod | grep $rel | tail -n 1 | cut -d"-" -f 2,3`
        BUILD=$basebuild
fi

#################################################
# Make view for Klocwork
#################################################
viewname="$USERNAME-$PRODUCT-$BUILD-kw"
mkview_cmd=". /home/admin1830/profile.1830;/home/admin1830/manage/bin/makeview -p $PRODUCT -b $BUILD $viewname"
$KWBLD_SRV "$mkview_cmd"
#if [ $? -ne 0 ]; then
#        print_err "make $viewname fail"
#        report_err
#        exit 1
#fi


#################################################
# Check the created view
#################################################
view=`/usr/atria/bin/cleartool lsview -short "${viewname}" 2>/dev/null`
if [ $? -ne 0 ]; then
        print_err "no matching views found for "$viewname""
        report_err
        exit 1
fi


#################################################
# Trigger KW building in screen 
#################################################
screen_name="Klocwork build"
bld_cmd=". /home/admin1830/profile.1830;/usr/atria/bin/cleartool setview -exec \"$BLDSCRIPT\" $viewname"
screen -dmS "$screen_name" $KWBLD_SRV "$bld_cmd"
pid=`screen_pid $screen_name`
if [ $pid -eq $NO_PID ]; then
        print_err "Create the screen for KW building failure"
        report_error
        exit $SCREEN_FAIL
fi






