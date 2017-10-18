#!/bin/ksh

#================================================
#
# Total space: 1800G
# Used 75%: free 450G
# Used 80%: free 360G
# Used 90%: free 180G
# Used 95%: free 90G => red_1
# Used 98%: free 36G => red_2
# Used 99%: free 18G => red_3
#
#
#================================================



. /home/admin1830/bin/build/build_profile
get_script_name $0

if [ `hostname` != "$BLD_HOSTNAME"  -o `hostname` != "pss1830lx-27" ]; then
        print_err "$SCRIPT_NAME just can be executed under "$BLD_HOSTNAME" or pss1830lx-27"
        exit 1
fi

if [ "$1" == "dbg" ]; then
        set -x
        dbg=1
else
        dbg=0
fi

#Error code
RM_VIEW_SUCCESS=200
RM_VIEW_FAIL=201

CLEAN_VIEW_QUEUE="$BLDHOMEPATH/clean_view_queue"
IN_CLEAN_QUEUE=100
NO_IN_CLEAN_QUEUE=101

VIEW_STORE_DISK="/dev/md0"
VIEW_STORE_PATH="/export/viewstore"
VIEW_NAME_SUFFIX="bld"


BLD_REMOVE_GREEN_THRESHOLD=80
GREEN_FILTER_VIEW_DAYS_AGO=15

BLD_REMOVE_YELLOW_THRESHOLD=90
YELLOW_FILTER_VIEW_DAYS_AGO=8

BLD_REMOVE_RED_1_THRESHOLD=95
RED_1_FILTER_VIEW_DAYS_AGO=5

BLD_REMOVE_RED_2_THRESHOLD=98
RED_2_FILTER_VIEW_DAYS_AGO=3

BLD_REMOVE_RED_3_THRESHOLD=99
RED_3_FILTER_VIEW_DAYS_AGO=2

BLD_DEFAULT_REMOVE_THRESHOLD=$BLD_REMOVE_GREEN_THRESHOLD
DEFAULT_FILTER_VIEW_DAYS_AGO=$GREEN_FILTER_VIEW_DAYS_AGO
#BLD_DEFAULT_REMOVE_THRESHOLD=70
#DEFAULT_FILTER_VIEW_DAYS_AGO=10

REMOVED_VIEWS=""


function get_used_space_pct_view {
        #   1                  2     3     4     5    6
        #/dev/md0              1.8T  1.4T  385G  78% /export
        echo `df -h | grep "$VIEW_STORE_DISK" | awk '{print $5}' | cut -d "%" -f 1`
        if [ $? -ne 0 ]; then
                echo "0"
        fi
}

function get_mtime_by_used_space {
        if [ -z "$1" ]; then
                echo $DEFAULT_FILTER_VIEW_DAYS_AGO
                return
        fi

        _used_space=$1
        if [ $_used_space -ge $BLD_REMOVE_GREEN_THRESHOLD -a \
             $_used_space -lt $BLD_REMOVE_YELLOW_THRESHOLD ]; then

                echo $GREEN_FILTER_VIEW_DAYS_AGO

        elif [ $_used_space -ge $BLD_REMOVE_YELLOW_THRESHOLD -a \
               $_used_space -lt $BLD_REMOVE_RED_1_THRESHOLD ]; then

                echo $YELLOW_FILTER_VIEW_DAYS_AGO

        elif [ $_used_space -ge $BLD_REMOVE_RED_1_THRESHOLD -a \
               $_used_space -lt $BLD_REMOVE_RED_2_THRESHOLD ]; then

                echo $RED_1_FILTER_VIEW_DAYS_AGO

        elif [ $_used_space -ge $BLD_REMOVE_RED_2_THRESHOLD -a \
               $_used_space -lt $BLD_REMOVE_RED_3_THRESHOLD ]; then

                echo $RED_2_FILTER_VIEW_DAYS_AGO

        elif [ $_used_space -ge $BLD_REMOVE_RED_3_THRESHOLD ]; then

                echo $RED_3_FILTER_VIEW_DAYS_AGO

        else
                echo $DEFAULT_FILTER_VIEW_DAYS_AGO
        fi
}

function get_support_bldname_list {
        [ $dbg -eq 1 ] && set -x
        _bldname_list=""
        for _task in `cat $BLD_TASK_FILES`
        do
                [[ $_task =~ ^\x23 ]] && continue
        
                #/home/yangx/svt/dwdm_1830_pss8.2_load
                _rel=`echo $_task | cut -d '/' -f 5 | cut -d '_' -f 3 | sed 's/pss//g'`
                if [ -n "$_rel" ]; then
                        _bldname_list+="`release_to_build_name $_rel` "
                fi
        done
        echo $_bldname_list
}

function get_legacy_view_list {
        [ $dbg -eq 1 ] && set -x
        if [ -z "$1" ]; then
                echo ""
                return
        fi
         
        _mtime=$1
        _legacy_views_list=""
        for _bld_name in `get_support_bldname_list`
        do
               [ -z "$_bld_name" ] && continue
                _legacy_views_list+=`find $VIEW_STORE_PATH -maxdepth 1 ! -name ".*" -mtime +$_mtime -type d | \
                                     grep "$BLDADMIN" | grep "$VIEW_NAME_SUFFIX" | grep "$_bld_name" | \
                                     cut -d '/' -f 4 | cut -d '.' -f 1`
                _legacy_views_list+=" "
        done
        echo $_legacy_views_list
}

function join_view_into_queue {
        [ -z "$1" ] && return 1
        #[ `check_view_is_in_queue $1` -eq $IN_CLEAN_QUEUE ] && return 0
        echo "$1" >> $CLEAN_VIEW_QUEUE
}


function remove_view_from_queue {
        [ -z "$1" ] && return 1
        sed -i "/$1/d" $CLEAN_VIEW_QUEUE
}

function check_view_is_in_queue {
        [ -z "$1" ] && return $NO_IN_CLEAN_QUEUE
        grep "$1" $CLEAN_VIEW_QUEUE
        if [ $? -eq 0 ]; then
                return $IN_CLEAN_QUEUE
        else
                return $NO_IN_CLEAN_QUEUE
        fi
}


function rm_view {
        [ $dbg -eq 1 ] && set -x
        [ -z "$1" ] && return $RM_VIEW_FAIL

        _view_name=$1

        ls $VIEW_STORE_PATH | grep $_view_name
        [ $? -ne 0 ] && return $RM_VIEW_SUCCESS

        check_view_is_in_queue $_view_name
        _is_in_queue=$?
        if [ $_is_in_queue = $NO_IN_CLEAN_QUEUE ]; then
                join_view_into_queue $_view_name
                /home/admin1830/manage/bin/removeview $_view_name
                rmview_rtr=$?
                remove_view_from_queue $_view_name
                if [ $rmview_rtr -ne 0 ]; then
                        print_err "Removed $_view_name fail"
                        REMOVED_VIEWS+=`echo -e "Remove Fail  $_view_name\\r\\n"`
                        return $RM_VIEW_FAIL
                else
                        ECHO "Removed $_view_name"
                        REMOVED_VIEWS+=`echo -e "Removed      $_view_name\\r\\n"`
                        return $RM_VIEW_SUCCESS
                fi
        fi
}

#####################################################################
#
#
#
#
#####################################################################

mail_subject="Clean the legacy views in $BLD_HOSTNAME"

[ ! -f $CLEAN_VIEW_QUEUE ] && touch $CLEAN_VIEW_QUEUE

view_used_space_pct=`get_used_space_pct_view`
[ $view_used_space_pct -le $BLD_DEFAULT_REMOVE_THRESHOLD ] && exit


mtime=`get_mtime_by_used_space $view_used_space_pct`
legacy_view_list=`get_legacy_view_list $mtime`
if [ "$legacy_view_list" == "" ]; then
        warm_msg="Not found any legacy views of "$mtime"days ago. The percent of used space is $view_used_space_pct% now."
        ECHO $warm_msg
        if [ $view_used_space_pct -ge $BLD_REMOVE_YELLOW_THRESHOLD ]; then
                sendmail "$TO" "$mail_subject" "$warm_msg"
        fi
        exit
fi


for view in $legacy_view_list
do
        rm_view $view
        if [ $view_used_space_pct -ge $BLD_REMOVE_RED_1_THRESHOLD ]; then
                [ `get_used_space_pct_view` -lt $BLD_REMOVE_RED_1_THRESHOLD ] && break
        fi
done


sendmail "$TO" "$mail_subject" "$REMOVED_VIEWS"






