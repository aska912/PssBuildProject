#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0


#if [ `hostname` != "$BLD_HOSTNAME"  -a `hostname` != "pss1830lx-27" ]; then
#        print_err "$SCRIPT_NAME just can be executed under "$BLD_HOSTNAME" or pss1830lx-27"
#        exit 1
#fi

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


CLEARTOOL="/usr/atria/bin/cleartool"

REMOVED_VIEWS=""

function get_seconds_of_last_month {
        d=`date +%Y%m%d --date="-1 month"`
        echo `date -d "$d" +%s`
}

function get_seconds_of_current_month {
        d=`date +%Y%m%d`
        echo `date -d "$d" +%s`
}

function get_daily_build_views {
        _lsviews=`$CLEARTOOL lsview -short | grep "admin"  | grep -v "DR4"| grep "bld"`
        echo $_lsviews
}

function get_bld_second_from_view {
        _view=$1
        _date=`echo $_view | cut -d "-" -f 4`
        echo `date -d "$_date" +"%s"`
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

        check_view_is_in_queue $_view_name
        _is_in_queue=$?
        if [ $_is_in_queue = $NO_IN_CLEAN_QUEUE ]; then
                join_view_into_queue $_view_name
                ECHO "Removing $_view_name"
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

[ ! -f $CLEAN_VIEW_QUEUE ] && touch $CLEAN_VIEW_QUEUE
mail_subject="Cleanup the legacy views in $BLD_HOSTNAME"

current_second=`get_seconds_of_current_month`
current_last_month_second=`get_seconds_of_last_month`
views=`get_daily_build_views`

ECHO "I am going to cleanup the legacy views."
#ECHO "Current Second:       $current_second"
#ECHO "Second Of Last Month: $current_last_month_second"
for view in `echo $views`
do
        view_second=`get_bld_second_from_view $view`
        ECHO "Second Of $view: $view_second($current_last_month_second)"
        [ $view_second -ge $current_last_month_second ] && continue
        rm_view $view
done

if [ ! "$REMOVED_VIEWS" == "" ]; then
        sendmail "$TO" "$mail_subject" "$REMOVED_VIEWS"
else
        ECHO "No one view need to be removed."
fi






