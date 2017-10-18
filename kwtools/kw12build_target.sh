#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0

. $KW12ENV
BLDALLPATH="/vobs/pss/node"

if [ -d $BLDALLPATH ]; then
    cd $BLDALLPATH
else
    print_err "No such as $BLDALLPATH for klockwork"
    report_error
    exit 1
fi

cd $BLDALLPATH

ECHO "Building wr_armada"
$BLDALLPATH/buildall.sh wr_armada

ECHo "Building wra9_lc"
$BLDALLPATH/buildall.sh wra9_lc

ECHO "Building wrp10xx_lc"
$BLDALLPATH/buildall.sh wrp10xx_lc

