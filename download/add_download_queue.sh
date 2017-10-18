#!/bin/ksh

if [ $# -eq 0 ]; then
        echo "Please enter the full package path."
        exit 1
fi

if [ $# -gt 1 ]; then
        echo "The parameters are incorrect."
        exit 1
fi

if [ `echo $1 | wc -c` -lt 45 ]; then
        echo "The parameters are incorrect."
        exit 1
fi

package=$1

download_queue="/home/admin1830/bin/build/download/download_queue"
downloaded_list="/home/admin1830/bin/build/download/downloaded_list"

for pkg in `cat $downloaded_list`
do
        if [ "$package" == "$pkg" ]; then
            echo "The package has been downloaded into the load server."
            exit 1
        fi
done

is_exist=0
for pkg in `cat $download_queue`
do
        if [ "$package" == "$pkg" ]; then
            is_exist=1
            break
        fi
done 

if [ $is_exist -eq 0 ]; then
        echo $package >> $download_queue
fi

echo "The package has been added into the download queue."
echo 
echo "-------- Download Queue --------"
cat $download_queue
echo



