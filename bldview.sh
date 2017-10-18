#!/bin/ksh


case $2 in
sim)
    BLDTYPE="sim"
    ;;
mvl)
    BLDTYPE="85xx"
    ;;
wr)
    BLDTYPE="wr"
    ;;
*)
    echo "The supported parameters: sim, mvl, wr"
    exit 1
    ;;
esac

BUILD=$1
PRODUCT="dwdm_1830"
USERNAME=`whoami`
BLDHOMEPATH="/home/admin1830/bin/build"
BLDSCRIPT=$BLDTYPE"_bld.sh"

set -x

viewname="$USERNAME-$PRODUCT-$BUILD-$BLDTYPE-bld"
cleartool setview -exec $BLDHOMEPATH/$BLDSCRIPT $viewname         

if [[ $? -ne 0 ]]
then
   echo "siew & build $viewname fail"
   exit 1
fi


echo "##########  Build $viewname success  ##########"
exit 0



