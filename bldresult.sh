#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0
#set -x

if [ $# -ne 1 ]; then
        echo "Please enter the view name."
        exit 1
fi

build=$1

bldfiles=`ct setview -exec "ls $ECPATH" $build`
if [ $? -ne 0 ]; then
        exit 1
fi

results=""
for fn in $bldfiles
do
        if [[ $fn =~ ^(world).*(log)$ ]]; then
                real_time=`ct setview -exec "tail $ECPATH/$fn | grep "real"" $build`
                real_time=`echo $real_time | awk '{print $2}'`
                log_result=`echo $fn | awk -F"." '\
                                         NF == 4 {printf $2 "\t" $3 "\\\n"}; 
                                         NF == 3 {printf $2 "\t unknown \\\n"}'` 
                results+="$real_time      $log_result \\n"
        fi
done

if [ `strlen "$results"` -gt 0 ]; then
        echo -e $results | column -t
        echo -e "\r\n"
        exit 0
else
        exit 1
fi
