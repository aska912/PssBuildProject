#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0

#set -x

VIEWNAME=$1

echo
viewname=$VIEWNAME
echo "viewname: $viewname"
is_exist=`is_exist_view $viewname`
if [ $is_exist -eq $VIEW_NOEXIST ]; then
        echo "Error: No matching information found for $viewname"
        exit 1
fi        

uuid=`get_uuid_view $viewname`
echo "uuid: $uuid"
view_path=`get_global_path_view $viewname`
echo "path: $view_path"

unreg_uuid $uuid
if [ $? -ne 0 ]; then
        echo "Error: unreg the uuid failure for $viewname."
else 
        echo "Unregisted the uuid of $viewname"
fi
        
rmtag_view $viewname
if [ $? -ne 0 ]; then
        echo "Error: rmtag the view failure for $Viewname."
else
        echo "Removed the tag of $viewname"
fi

if [ -n $view_path ]; then
        (ls $view_path) > /dev/null 
        if [ $? -eq 0 ]; then
                rm -rf $view_path
                echo "Removed $view_path"
        fi
fi



