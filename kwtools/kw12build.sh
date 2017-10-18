#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0

#set -x
if [ -z "$1" ]
then
    echo "Please enter a parameter. The parameters: sim_lc, target_lc, skip_bld"
    exit 1
fi

if [ "`whoami`" != "admin1830" ]
then
   print "Only \"admin1830\" is allowed to start a Klocwork build"
   exit 1
fi

if [ "`hostname`" != "pss1830lx-27" ]
then
   print "You must be logged in on the pss1830lx-27 machine to start a Klocwork 10.4 build"
   exit 1
fi

if [ "`cleartool pwv -s`" == "** NONE **" ]
then
   print "You must be logged in one view to start a Klocwork build"
   exit 1
fi

. $KW12ENV 
which java
java -version

KWPROJ="pss"
NAME=$(cleartool pwv -s |cut -d "-" -f2,3,4)
BNAME=$(echo $NAME |cut -d "-" -f2- |tr -d "-" )
KWINJ_OUT=$KW_PJ_ROOT/projects/pss/kwinject_out/$KWPROJ_$NAME
BUILD_TABLES=/export/kw_bld_tables/build_tables

cd /vobs/pss/node

export NO_WINK=-u

case $1 in
sim_lc)
    ECHO "Now KW building for $KWPROJ ..."
    ($KW_BIN/kwinject -T kwinject.trace $KWTOOLPATH/kw12build_sim.sh) 2>&1 | tee kw_buildall.log
    ;;
target_lc)
    KWPROJ="pss_target"
    ECHO "Now KW building for $KWPROJ ..."
    ($KW_BIN/kwinject -T kwinject.trace $KWTOOLPATH/kw12build_target.sh) 2>&1 | tee kw_buildall.log
    ;;
skip_bld)
    echo "Skip building"
    ;;
*)
    echo "Unkown parameter: \"$1\""
    exit 1
    ;;
esac


ECHO "Prepare KW out file"
$KW_BIN/kwinject -t kwinject.trace -o kwinject_pss.out
rm -rf $KWINJ_OUT
cp kwinject_pss.out $KWINJ_OUT
ls -l $KWINJ_OUT


ECHO "Remove old build table"
rm -rf $KW_PJ_ROOT/projects/build_tables
rm -rf $BUILD_TABLES



ECHO "Build KW project $KWPROJ "
mkdir -p $BUILD_TABLES  2>/dev/null
($KW_BIN/kwbuildproject --url http://$KWSRVIP:$KWSRVPORT/$KWPROJ -o $BUILD_TABLES $KWINJ_OUT) 2>&1 | tee kw_buildproject.log



ECHO "Load KW project $KWPROJ "
($KW_BIN/kwadmin --url http://$KWSRVIP:$KWSRVPORT load --name $BNAME $KWPROJ $BUILD_TABLES) 2>&1 | tee kw_loadproject.log

load=$(cleartool pwv -s |cut -d "-" -f3)
cp $KWINJ_OUT /home/admin1830/code_db/dwdm_1830/$load/buildspec.out

to="jiemingg"
sendmail "$to" "The building report of Klocwork" "Klockwork Build over"
if [ $? -ne 0 ]; then
        echo "Send mail fail"
        exit 1
fi

exit 0

