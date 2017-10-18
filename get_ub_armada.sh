#!/bin/ksh

. ~/bin/build/build_profile
get_script_name $0
#set -x

UBOOT_PATH="/vobs/linuxdev_armada/local/images/lboot"
USBKEY_PATH="/vobs/linuxdev_armada/local/images/usbkey"
UBOOT_TAR="u-boot.factory.bin.tar"
USBKEY_TAR="usbkey-image.tgz.tar"

cp_uboot_cmd="$BLDHOMEPATH/get_ub_armada.sh cp_uboot"
cp_usbkey_cmd="$BLDHOMEPATH/get_ub_armada.sh cp_usbkey"

copy_file_to_tmp()
{
        src=$1
        cp $src /tmp
        if [ $? -eq 0 ]; then
                return 0
        else
                print_err "Copy $src to /tmp failure"
                report_err
                return 1
        fi
}

clear_rubbish()
{
        rm -rf /tmp/usbkey-image*
        rm -rf /tmp/u-boot-*
        rm -rf "/tmp/$UBOOT_TAR"
        rm -rf "/tmp/$USBKEY_TAR"
}


if [ $# -eq 0 ]; then
        print_err "Not specified the viewtag"
        exit 1
fi

param=$1

case $param in
"cp_uboot")
        copy_file_to_tmp "$UBOOT_PATH/$UBOOT_TAR"
        exit $?
        ;;
"cp_usbkey")
        copy_file_to_tmp "$USBKEY_PATH/$USBKEY_TAR"
        exit $?
        ;;
*)
        #admin1830-dwdm_1830-figbar-150620-sim-bld
        viewtag=$param
        release=`echo $viewtag | cut -d '-' -f 3`
        ;;
esac

clear_rubbish

for cp_cmd in "$cp_uboot_cmd" "$cp_usbkey_cmd"
do
        rtr=`/usr/atria/bin/cleartool setview -exec "${cp_cmd}" $viewtag`
        if [[ $? -ne 0 ]]; then
                print_err $rtr
                report_err
                exit 1
        fi
done

cd /tmp

uboot_file=`tar -tf /tmp/$UBOOT_TAR`
usbkey_file=`tar -tf /tmp/$USBKEY_TAR`

ECHO "The latest uboot:  $uboot_file"
ECHO "The latest usbkey: $usbkey_file"

for tar_file in $UBOOT_TAR $USBKEY_TAR
do
        tar -xf /tmp/$tar_file
        if [ $? -ne 0 ]; then
                print_err "Extract $tar_file failure"
                report_err
                exit 1
        fi
done

rtr="No uboot/usbkey need to be updated"
update=$NOUPDATED

$LOAD_SH_SSH "ls $UBOOT_USBKEY_PATH | grep "$release""
if [ $? -ne 0 ]; then
        ECHO "Created directory $UBOOT_USBKEY_PATH/$release"
        $LOAD_SH_SSH "mkdir $UBOOT_USBKEY_PATH/$release"
        if [ $? -ne 0 ]; then
                print_err "Unable to create directory "$UBOOT_USBKEY_PATH/$release"" 
                report_err
                exit 1
        fi
        ECHO "Created directory $UBOOT_USBKEY_PATH/$release"
fi

for file in $uboot_file $usbkey_file
do

        (ssh $LOADUSER@$LOADSERVER ls $UBOOT_USBKEY_PATH/$release/$file) > /dev/null  2>&1
        if [ $? -eq 0 ]; then
                continue
        fi

        scp /tmp/$file $LOADUSER@$LOADSERVER:$UBOOT_USBKEY_PATH/$release/ 
        if [ $? -ne 0 ]; then
                print_err "Upload $file to $LOADSERVER:$UBOOT_USBKEY_PATH/$release failure"
                report_err
                exit 1
        else
                if [ $update -eq $NOUPDATED ]; then
                        rtr="Uploaded \"$file\" into server($UBOOT_USBKEY_PATH/$release)"
                        update=$UPDATED
                else
                        rtr+="\r\nUploaded \"$file\" into server($UBOOT_USBKEY_PATH/$release)\r\n"
                fi
        fi
done

clear_rubbish


echo -e "$rtr"
exit $update



