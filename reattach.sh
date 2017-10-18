#!/bin/ksh

. ~/bin/build/build_profile 

if [ -z "$1" ]; then
        name="building"
        pid=`bld_screen_pid`
else
        name="$1"
        pid=`screen_pid $1`
fi

if [ $pid -eq $NO_PID ]; then
        echo "Error: No screen pid for $name"
        echo
        screen -ls 
        exit
fi

screen -r $pid
