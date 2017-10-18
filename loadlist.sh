#!/bin/ksh

. ./build_profile
#set -x

if [ $# -lt 1 ]; then
        echo "Please enter the release"
        exit 1
fi
release=$1

loadpath=`release_to_load_file $release`

get_load_path_list $loadpath

exit 0
