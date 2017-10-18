#!/bin/ksh 

. /home/admin1830/bin/build/build_profile
cd $BLDHOMEPATH
get_script_name $0

#if [ -z "$1" ]; then
#        if [ `is_download_time` = 1 ]; then
#                load=`tail $DOWNLOAD_QUEUE -n 1`
#                [ -z "$load" ] && exit
#        else
#                ECHO "Not working time, can't download"
#                exit 1
#        fi
#else
#        load=$1
#fi

#set -x

load=$1
download_pkg=$load

SHSRV=$LOAD_SH_SSH
MHSRV="ssh -o ServerAliveInterval=30 tropxnms@135.121.44.110 "
PSSNFS_MH="/pssnfs"


#        platform           release ectype   loadname
#  2      3                4   5     6        7        
#/pssnfs/dwdm_1830_switch/swp/pkt2/ARMADA/1830PSSECX-22.6-80

release=`echo $load | awk -F'/' '{print $5}'`
platform=`echo $load | awk -F'/' '{print $3}'`
ectype=`echo $load | awk -F'/' '{print $6}'`
loadname=`echo $load |awk -F'/' '{print $7}'`
loadpath_sh="/pssnfs/$LOADUSER/$platform/ARMADA_EC/$release/EC/$ectype"


to="jiemingg,weisheli,zongquat"
subject="Download $loadname from CD"


ECHO "Platform:  $platform"
ECHO "Release:   $release"
ECHO "Product:   $ectype"
ECHO "Load:      $loadname"
ECHO "In CD, the load path: $load"
ECHO "In SH, the load path: $loadpath_sh"


# Step 1
# Check the space of the load server
LOAD_DISK_SH="/dev/sda2"
WARM_THRESHOLD=85
load_space_sh=`$SHSRV df -h 2>/dev/null|grep "$LOAD_DISK_SH"|awk '{print $5}'|cut -d "%" -f 1`
if [ $load_space_sh -gt $WARM_THRESHOLD ]; then
        mail_subject="The load space is low in Shanghai"
        warm_msg="The avlid space is less than `expr 100 - $load_space_sh`%, Please check it as soon as possible."
        ECHO $warm_msg
        sendmail "$TO" "$mail_subject" "$warm_msg"
fi


# Step 2
# In SH, check load
($SHSRV ls $loadpath_sh) 2>&1 >/dev/null
if [ $? -ne 0 ]; then
        $SHSRV mkdir -p $loadpath_sh
fi
        
($SHSRV ls $loadpath_sh/$loadname) 2>&1 >/dev/null 
if [ $? -eq 0 ]; then
        ECHO "$loadname has been downloaded in Server"
        remove_rec_from_download_queue $loadname
        sleep 2
        exit
fi


#In CD, Check load
($MHSRV ls $load) 2>&1 >/dev/null
if [ $? -ne 0 ]; then
        ECHO "No such $load in CD server"
        exit 1
fi

rtr=`$MHSRV du -s $load`
if [ $? -eq 0 ]; then
        size=`echo $rtr | awk '{print $1}'`
        size=`expr $size / 1024`
        if [ $size -le 300 ]; then
                if [ $platform != "dwdm_1830_encryption" ]; then
                        print_err "The load size($size) is invalid."
                        exit 1
                fi
        fi
else
        echo "Can't get the size of load"
        exit 1
fi


# Step 3
# In MH, create archive of load in /pssnfs
ECHO "Creating the archive with $loadname"
load_tar="/tmp/$loadname.tar"
$MHSRV "cd $load/..;tar -cf $load_tar $loadname/*"
if [ $? -ne 0 ]; then
        print_err "Created $load_tar failure"
        exit 1
fi
rtr=`$MHSRV md5sum $load_tar`
md5_mh=`echo $rtr | awk '{print $1}'`
ECHO "Created the archive with $loadname"

# Step 4
# Download the archive from MH
ECHO "Downloading $load_tar from CD"
$MHSRV "scp $load_tar $LOADUSER@$LOADSERVER:$loadpath_sh"
if [ $? -ne 0 ]; then
        print_err "Downloaded $load_tar from CD failure"
        exit 1
fi
ECHO "Downloaded $load_tar"


# Step 5
# Extract this archive into /pssnfs of SH server
# Generated the link of the load
load_tar_sh="$loadpath_sh/$loadname.tar"
ECHO "Extracting $load_tar_sh"
rtr=`$SHSRV md5sum $load_tar_sh`
md5_sh=`echo $rtr | awk '{print $1}'`
if [ ! "$md5_sh" == "$md5_mh" ]; then
        print_err "The MD5 of package is mismatch. MH_MD5: $md5_mh; SH_MD5: $md5_sh"
        $SHSRV rm -rf $load_tar_sh
        $MHSRV rm -rf $load_tar
        body="Download Status: failure \r\n"
        body+="The MD5 of package is mismatch. MH_MD5: $md5_mh; SH_MD5: $md5_sh"
        $SENDMAIL "$to" "$subject" "$body"
        exit 1
fi

$SHSRV "cd $loadpath_sh;tar -xf $load_tar_sh"
if [ $? -eq 0 ]; then
        ECHO "Extracted $load_tar_sh"
        #if [ "$basebuild" != "swp" -o "$platform" != "factory" ]; then
        #        $SHSRV "cd $loadpath_sh;ln -s $loadname $basebuild"
        #        ECHO "Created a link to $loadname with $basebuild"
        #fi

        body=`echo -e "Download Status: success\r\nDownload Path: $loadpath_sh/$loadname"`
        remove_rec_from_download_queue $loadname
        add_downloaded_list "$download_pkg"
else
        print_err "Extracted $load_tar_sh failure"
        body="Download Status: failure"
fi


# Step 6
# Removed archive from server
$SHSRV rm -rf $load_tar_sh
$MHSRV rm -rf $load_tar

# Notice by Email
$SENDMAIL "$to" "$subject" "$body"


