#!/bin/ksh

. /home/admin1830/bin/build/build_profile

if [ -z "$1" ]
then
    echo "Please enter a parameter. The parameters: sim_lc, skip_bld"
    exit 1
fi

if [ "`whoami`" != "admin1830" ]
then
   print "Only \"admin1830\" is allowed to start a Klocwork build"
   exit 1
fi

if [ "`hostname`" != "pss1830lx-27" ]
then
   print "You must be logged in on the pss1830lx-27 machine to start a Klocwork build"
   exit 1
fi

if [ "`cleartool pwv -s`" == "** NONE **" ]
then
   print "You must be logged in one view to start a Klocwork build"
   exit 1
fi

KWPROJ="pss"

. /home/admin1830/kwenv

cd /vobs/pss/node

export NO_WINK=-u

case $1 in
sim_lc)
    ECHO "Now KW building ..."
    $KW_BIN/kwinject -T kwinject.trace ./buildall.sh $1
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

NAME=$(cleartool pwv -s |cut -d "-" -f2,3,4)
BNAME=$(echo $NAME |cut -d "-" -f2- |tr -d "-" )
KWINJ_OUT=$KW_PJ_ROOT/projects/pss/kwinject_out/$KWPROJ_$NAME
BUILD_TABLES=$KW_PJ_ROOT/var/tmp/kw/build_tables

cp kwinject_pss.out $KWINJ_OUT
ls -l $KWINJ_OUT

ECHO "Remove old build table"
rm -rf  $KW_PJ_ROOT/projects/build_tables
rm -rf $BUILD_TABLES

ECHO "Build KW project $KWPROJ "
mkdir -p $BUILD_TABLES  2>/dev/null
$KW_BIN/kwbuildproject --tables-directory $BUILD_TABLES --url http://$KWSRVIP:$KWSRVPORT/$KWPROJ $KWINJ_OUT

# mv /pssnfs/klocwork/projects_root/projects/build_tables /pssnfs/klocwork/build_tmp

ECHO "Load KW project $KWPROJ "
#/pssnfs/klocwork/bin/kwadmin load -name $BNAME $KWPROJ /pssnfs/klocwork/build_tmp/build_tables 
$KW_BIN/kwadmin load -name $BNAME $KWPROJ $BUILD_TABLES



to="jiemingg"
sendmail "$to" "The building report of Klocwork" "Klockwork Build over"
if [ $? -ne 0 ]; then
        echo "Send mail fail"
        exit 1
fi

exit 0

