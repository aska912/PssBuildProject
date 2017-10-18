#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0


if [ ! `whoami` == $BLDADMIN ]; then
        echo "Please use admin1830 to execute the script."
        exit 1
else
        USERNAME=$BLDADMIN
fi

#set -x

#if [ -n "$1" ]; then
#        BUILD=$1
#else
#        echo "Please "
#        rel=$kw_build_rel
#
#        #################################################
#        # Get the latest base build with the specified 
#        #release
#        ################################################
#        prod="/home/admin1830/manage/config_specs/dwdm_1830"
#        basebuild=`ls $prod | grep $rel | tail -n 1 | cut -d"-" -f 2,3`
#        BUILD=$basebuild
#fi

if [ $# -lt 2 -o $# -ge 3 ]; then
    ECHO "Invalid number of parameters."
    echo "kw12build_screen kiwibar-170103 sim_lc|target_lc|skip_lc"
    exit 1 
fi

basebuild="labelledbld_dwdm_1830-$1"
if [ -f /home/admin1830/manage/config_specs/dwdm_1830/$basebuild ]; then
    BUILD=$1
else
    ECHO "$1 is not the supported build id."
    exit 1
fi


if [ -z "$2" ]
then
    echo "Please enter a parameter. e.g. sim_lc, target_lc, skip_bld"
    exit 1
else
    bld_param="$2"
fi
case $bld_param in
sim_lc)
    ECHO "For sim LC building ..."
    ;;
target_lc)
    ECHO "For target LC building ..."
    ;;
skip_bld)
    ECHO "Skip building"
    ;;
*)
    ECHO "Unkown parameter: \"$bld_param\""
    echo "Only supported: sim_lc, target_lc, skip_bld"
    exit 1
    ;;
esac

. $KW12ENV
KWBLDSERVER=$MVLBLDSERVER
KWBLD_SRV=$BLD_KW_SSH
BLDSCRIPT="$KW_TOOLS_PATH/kw12build.sh $bld_param"


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
ECHO "Made view $viewname"

#################################################
# Trigger KW building in screen 
#################################################
screen_name="Klocwork Building"
bld_cmd=". /home/admin1830/profile.1830;/usr/atria/bin/cleartool setview -exec \"$BLDSCRIPT\" $viewname"
screen -dmS "$screen_name" $KWBLD_SRV "$bld_cmd"
pid=`screen_pid $screen_name`
if [ $pid -eq $NO_PID ]; then
        print_err "Create the screen for KW building failure"
        report_error
        exit $SCREEN_FAIL
fi

rm -rf $BLDHOMEPATH/kw_will_bld

ECHO "KW Building PID: $pid "






