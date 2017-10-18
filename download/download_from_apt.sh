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

load=$1
download_pkg=$load

if [ -z "$2" ]; then
        if [ "$2" == "check" ]; then
                run_method="check"
        else
                run_method="download"
        fi
else
        run_method="download"
fi 

SHSRV=$LOAD_SH_SSH
APTSRV=$LOAD_APT_SSH
LOADROOTPATH_APT=$APTDLPATH


to="jiemingg,weisheli,xinghubl"
subject="Download $loadname from APT Server"

#        bldtype  platform         basebuild       ectype   loadname
#  2      3       4                5           6   7        8
#/pssnfs/roadm/dwdm_1830_switch/figbar-150622/swp/ARMADA/1830PSSECX-18.22-30
#/pssnfs/roadm/dwdm_1830/figcake-150808/swp/EC/figcake-20.8-50
#/pssnfs/bldcn/pss4/figjam-160121/swp/EC/1830PSS4-13.21-60
#  2      3     4                5    6       7      8
#/pssnfs/bldcn/dwdm_1830_switch/swp/figbar/ARMADA/1830PSSECX-19.4-35
#/pssnfs/pat/dwdm_1830_switch/swp/figbar/ARMADA/1830PSSECX-0.18-30
#
#  2       3      4   5  6
#/pssnfs/FACTORY/swp/EC/1830PSS-0.70-1


bldtype=`echo $load | awk -F'/' '{print $3}'`
if [ "$bldtype" == "FACTORY" ]; then
        #       platform  rel ectype   loadname
        #  2       3      4   5        6
        #/pssnfs/FACTORY/swp/EC/1830PSS-0.70-1
        platform="factory"
        basebuild=""
        ectype=`echo $load | awk -F'/' '{print $5}'`
        release=`echo $load | awk -F'/' '{print $4}'`
        loadname=`echo $load |awk -F'/' '{print $6}'`
else
        platform=`echo $load | awk -F'/' '{print $4}'`
        basebuild=`echo $load | awk -F'/' '{print $5}'`
        ectype=`echo $load | awk -F'/' '{print $7}'`
        loadname=`echo $load |awk -F'/' '{print $8}'`
        if [ "$basebuild" == "swp" ]; then
                release=`echo $load | awk -F'/' '{print $6}'`
        else
                release=`echo $basebuild | awk -F'-' '{print $1}'`
        fi
fi

if [ "$release" == "9.0.5" ]; then
        release="grapebar96"
fi

rel=`build_name_to_release $release`


case $platform in
'dwdm_1830_switch')
        if [ "$ectype" == "ARMADA" ]; then
                loadpath_sh="/pssnfs/$LOADUSER/$platform/ARMADA_EC/$release/EC/$ectype"
                loadpath_apt="$LOADROOTPATH_APT/pss8_load/$rel/EC/$ectype"
        else
                loadpath_sh="/pssnfs/$LOADUSER/$platform/16G_EC/$release/EC"
                rel=$rel"_16g"
                loadpath_apt="$LOADROOTPATH_APT/pss32_load/$rel/EC"
        fi
        ;;
'dwdm_1830')
        loadpath_sh="/pssnfs/$LOADUSER/$platform/$release/EC"
        rel=$rel"_4g"
        loadpath_apt="$LOADROOTPATH_APT/pss32_load/$rel/EC"
        ;;
'pss4')
        loadpath_sh="/pssnfs/$LOADUSER/$platform/$release"
        loadpath_apt="$LOADROOTPATH_APT/pss4_load/$rel"
        ;;
*)
        print_err "Unkown platform: $platform"
        exit 1
        ;;
esac

load="$loadpath_apt/$loadname"

ECHO "Platform:  $platform"
ECHO "Build:     $basebuild"
ECHO "Release:   $release"
ECHO "Product:   $ectype"
ECHO "Load:      $loadname"
ECHO "In APT, the load name: $load"
ECHO "In SH,  the load path: $loadpath_sh"


# Step 1
#In APT, Check load
($APTSRV ls $load) 2>&1 >/dev/null
if [ $? -ne 0 ]; then
        ECHO "No such $load in APT server"
        exit 1
fi

rtr=`$APTSRV du -s $load`
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

if [ $run_method == "check" ]; then
        exit 0
fi

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


#In APT, Check load
($APTSRV ls $load) 2>&1 >/dev/null
if [ $? -ne 0 ]; then
        ECHO "No such $load in APT server"
        exit 1
fi

rtr=`$APTSRV du -s $load`
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
# In APT, create archive of load 
ECHO "Creating the archive with $loadname"
load_tar="/home/$APTDLUSER/$loadname.tar"
$APTSRV "cd $load/..;tar -cf $load_tar $loadname/*"
if [ $? -ne 0 ]; then
        print_err "Created $load_tar failure"
        exit 1
fi
rtr=`$APTSRV md5sum $load_tar`
md5_apt=`echo $rtr | awk '{print $1}'`
ECHO "Created the archive with $loadname."

# Step 4
# Download the archive from APT
ECHO "Downloading $load_tar from APT"
$APTSRV "scp $load_tar $LOADUSER@$LOADSERVER:$loadpath_sh"
if [ $? -ne 0 ]; then
        print_err "Downloaded $load_tar from APT failure"
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
if [ ! "$md5_sh" == "$md5_apt" ]; then
        print_err "The MD5 of package is mismatch. MH_MD5: $md5_mh; SH_MD5: $md5_sh"
        $SHSRV  rm -rf $load_tar_sh
        $APTSRV rm -rf $load_tar
        body="Download Status: failure \r\n"
        body+="The MD5 of package is mismatch. MH_MD5: $md5_mh; SH_MD5: $md5_sh"
        $SENDMAIL "$to" "$subject" "$body"
        exit 1
fi

$SHSRV "cd $loadpath_sh;tar -xf $load_tar_sh"
if [ $? -eq 0 ]; then
        ECHO "Extracted $load_tar_sh"
        if [ "$basebuild" != "swp" -o "$platform" != "factory" ]; then
                $SHSRV "cd $loadpath_sh;ln -s $loadname $basebuild"
                ECHO "Created a link to $loadname with $basebuild"
        fi

        body=`echo -e "Download Status: success\r\nDownload Path: $loadpath_sh/$loadname"`
        remove_rec_from_download_queue $loadname
        add_downloaded_list "$download_pkg"
else
        print_err "Extracted $load_tar_sh failure"
        body="Download Status: failure"
fi

# Step 6
# Removed archive from server
$SHSRV  rm -rf $load_tar_sh
$APTSRV rm -rf $load_tar

# Notice by Email
$SENDMAIL "$to" "$subject" "$body"


