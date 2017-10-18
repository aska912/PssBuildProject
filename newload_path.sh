#!/bin/ksh

. ./build_profile
#set -x

release=$1

loadpath=`release_to_load_file $release`

get_new_load_path $loadpath

exit 0
