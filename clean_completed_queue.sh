#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0

#set -x

PRODUCT=$PRODUCT
USERNAME=$BLDADMIN

BCQFILE="$BLDHOMEPATH/bld_completed_queue"

REMOVED=100
UNREMOVED=200

sim_view=$UNREMOVED
mvl_view=$UNREMOVED
wr_view=$UNREMOVED


BUILDLIST=""
if [ -n "$1" ]; then
        BUILDLIST=$1
else
        for rcd in `cat $BCQFILE`
        do
                bld=`echo $rcd | cut -d "/" -f 5`
                BUILDLIST+="$bld "
        done
fi

for bld in $BUILDLIST
do
        
        sim_view=$UNREMOVED
        mvl_view=$UNREMOVED
        wr_view=$UNREMOVED

        for bld_target in $SIM $MVL $WR
        do
                viewname="$USERNAME-$PRODUCT-$bld-$bld_target-bld"
                ct lsview | grep $viewname  > /dev/null
                if [ $? -ne 0 ]; then
                        case $bld_target in
                            $SIM)
                                sim_view=$REMOVED
                                ;;
                            $MVL)
                                mvl_view=$REMOVED
                                ;;
                            $WR)
                                wr_view=$REMOVED
                                ;;
                            *)
                                continue
                                ;;
                        esac
                fi
        done

        if [ $sim_view -eq $REMOVED -a \
             $mvl_view -eq $REMOVED -a \
             $wr_view -eq $REMOVED ]; then
                sed -i "/$bld/d" $BCQFILE
                [ $? -eq 0 ] && ECHO "Removed the record of $bld from bld_completed_queue"
        fi
done




