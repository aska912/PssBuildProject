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

ECHO "Building sim_lc"
$BLDALLPATH/buildall.sh sim_lc

ECHO "Building sima9_lc"
$BLDALLPATH/buildall.sh sima9_lc


