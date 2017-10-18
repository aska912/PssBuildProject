#!/bin/bash

tmpfile='/tmp/space'
viewspace='/tmp/viewspace'
viewstore="/export/viewstore"

rm -rf $viewspace

#echo "------------------------------------" >>  $viewspace
#df -h /export |awk '{print $5 " " $2 " " $3 " " $4 "  " }' >>  $viewspace
#echo "------------------------------------" >>  $viewspace
#echo " "
#echo " "
#du -h 2>/dev/null > $tmpfile 
du -h $viewstore > $tmpfile 2>&1


views=`cat $tmpfile | egrep '[0-9]G'| egrep 'vws$'`
if [ -n "$views" ]; then
    cat $tmpfile | egrep '[0-9]G'| egrep 'vws$' >> $viewspace
    #echo "-------------------" >>  $viewspace
fi

views=`cat $tmpfile | egrep '[0-9][0-9][0-9]M'| egrep 'vws$'`
if [ -n "$views" ]; then
    echo "-------------------" >>  $viewspace
    cat $tmpfile | egrep '[0-9][0-9][0-9]M'| egrep 'vws$' >> $viewspace
    #echo "-------------------" >>  $viewspace
fi

#ls -l $viewstore |awk '{print $9}' >> $viewspace

cat $viewspace

rm -rf $tmpfile

cd ~
