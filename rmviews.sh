#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0


if [ -z "$1" ]; then
        echo "Please build date. (e.g. 1604)"
        exit 1
fi

bld=$1

if [[ "$bld" =~ \d+ ]]; then
        break
else
        echo "Please build date. (e.g. 1604)"
        exit 1
fi


CLEAN_VIEW_QUEUE="$BLDHOMEPATH/clean_view_queue"
IN_CLEAN_QUEUE=100
NO_IN_CLEAN_QUEUE=101
RM_VIEW_SUCCESS=200
RM_VIEW_FAIL=201

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
        _view_name=$1

        ls $VIEW_STORE_PATH | grep $_view_name
        [ $? -ne 0 ] && return $RM_VIEW_SUCCESS

        check_view_is_in_queue $_view_name
        _is_in_queue=$?
        if [ $_is_in_queue = $NO_IN_CLEAN_QUEUE ]; then
                join_view_into_queue $_view_name
                $REMOVEVIEW $_view_name
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
        else
                return $RM_VIEW_FAIL
        fi
}


views=`$CT lsview | grep $BLDADMIN | grep "\-bld" | grep $bld | \
       sed 's/^\*//g' | grep -v "\-kw" | grep -v "\-DR4"    | \
       awk '{print $1}'`


for view in $views
do
        rm_view $view
        if [ $? -eq $RM_VIEW_FAIL ]; then
                warm_msg="Removeview $view fail by rmviews.sh"
                ECHO "$warm_msg"
                subject="$warm_msg"
                body="Removeview $view fail. Please check it."
                sendmail "$TO" "$subject" "$body"
        fi
done










