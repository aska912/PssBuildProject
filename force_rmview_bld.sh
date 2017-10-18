#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0

#set -x

BUILD=$1
PRODUCT="dwdm_1830"
USERNAME=`whoami`

for bld_name in $SIM $MVL $WR
do
        echo
        viewname="$USERNAME-$PRODUCT-$BUILD-$bld_name-bld"
        echo "viewname: $viewname"
        is_exist=`is_exist_view $viewname`
        if [ $is_exist -eq $VIEW_NOEXIST ]; then
                echo "No matching information found for $viewname"
                continue
        fi        

        uuid=`get_uuid_view $viewname`
        echo "uuid: $uuid"
        view_path=`get_global_path_view $viewname`
        echo "path: $view_path"

        unreg_uuid $uuid
        if [ $? -ne 0 ]; then
                echo "unreg the uuid of view failure."
        else 
                echo "Unregisted the uuid of $viewname"
        fi
        
        rmtag_view $viewname
        if [ $? -ne 0 ]; then
                echo "rmtag the view failure."
        else
                echo "Removed the tag of $viewname"
        fi

        if [ -n $view_path ]; then
                (ls $view_path) >/dev/null
                if [ $? -eq 0 ]; then
                        rm -rf $view_path
                        echo "Removed $view_path"
                fi
        fi
done



