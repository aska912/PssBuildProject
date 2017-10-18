#!/bin/ksh

. /home/admin1830/bin/build/build_profile
get_script_name $0
#set -x

[ "$1" = "dbg" ] && set -x

cd $BLDHOMEPATH

ECHO ""
ECHO "------------------------------------- "
ECHO " Start to execute the daily building  " 
ECHO "------------------------------------- "

if [ ! `whoami` = "$BLDADMIN" ]; then
        print_err "Please use \"$BLDADMIN\" to execute the script."
        report_error
        exit 1
fi

[ ! -f $BLD_QUEUE ] && touch $BLD_QUEUE
[ ! -f $BLD_COMPLETE_QUEUE ] && touch $BLD_COMPLETE_QUEUE


#-------------------------------------------------
# clean log from clean_build_log
$BLDHOMEPATH/clean_build_log.sh 
#-------------------------------------------------

#-------------------------------------------------
# Clean the old record from clean_completed_queue
if [ `cat $BLDHOMEPATH/bld_completed_queue | wc -l` -gt 100 ]; then
        $BLDHOMEPATH/clean_completed_queue.sh
fi
#-------------------------------------------------


for task_mh in `cat $BLD_TASK_FILES`
do

        if [[ $task_mh =~ ^\x23 ]]; then
                continue
        fi

        bld_task_mh=`$MH_SVR_SSH tail -n 1 $task_mh`
        if [ $? -ne 0 ]; then
                print_err "Can't get the building task list from MH"
                report_error
                break
        else
                platform=`echo $bld_task_mh | cut -d / -f 4`
                if [ $platform = "pss4" ]; then
                        #ECHO "Add $bld_task_mh into the download queue."
                        $BLDHOMEPATH/download/add_download_queue.sh $bld_task_mh
                        continue
                fi
                if [ -z $bld_task_mh ]; then
                        print_err "The task is null"
                        report_error
                        exit 1
                fi
                build_product=`get_product_from_task $bld_task_mh`
                bld_id=`get_basebuild_from_task $bld_task_mh`
                build_name=$bld_id
                rel=`echo $build_name | cut -d - -f 1`
                load_name=`get_loadname_from_task $bld_task_mh`
                ECHO "Fonud the new task: $bld_task_mh"
        fi
        
        check_completed_task $bld_task_mh
        if [ $? -eq $RTR_COMPLETED_TASK ]; then
                ECHO "The $build_name($build_product) has been compiled."
                continue
        fi


        is_recorded=false
        for task_line in `cat $BLD_QUEUE`
        do
                if [ "$bld_task_mh" == "$task_line" ]; then
                        is_recorded=true
                        break
                fi
        done

        if [ $is_recorded = false ]; then
                if [ ! $build_product == "pss4" ]; then
                        join_task_into_bld_queue $bld_task_mh
                        ECHO "\"$bld_task_mh\" is added into bld_queue"
                        if [ $rel == "grapeape" ]; then
                                pss4_task="/pssnfs/bldcn/pss4/$build_name/swp/EC/$load_name"
                                ECHO "Fonud the new task: $pss4_task"
                                check_completed_task $pss4_task
                                if [ $? -eq $RTR_UNCOMPLETED_TASK ]; then
                                        #join_task_into_bld_queue $pss4_task
                                        ECHO "\"$pss4_task\" is added into bld_queue"
                                else
                                        ECHO "The `get_basebuild_from_task $pss4_task`("pss4") has been compiled."
                                fi
                        fi
                fi
               
                view_product=`convert_to_view_product $build_product` 
                view_num=`/usr/atria/bin/cleartool lsview $BLDADMIN-${view_product}*-bld | grep $bld_id | wc -l`
                if [[ $view_num -eq 0 ]]; then
                        $MKVIEW $bld_id
                        if [ $? -ne 0 ]; then
                                print_err "Makeview fail"
                                report_error
                                exit 1
                        fi
                elif [[ $view_num -ne 3 ]]; then
                        print_err "Please remove the rubbish view"
                        report_error
                        exit 1
                fi

                $BLDHOMEPATH/download/add_download_queue.sh $bld_task_mh
                ECHO "Add $bld_task_mh into the download queue."
                
                viewtag=`/usr/atria/bin/cleartool lsview $BLDADMIN-${view_product}-*-bld|grep $bld_id|head -n 1|awk -F " " '{print $2}'`
                #/usr/atria/bin/cleartool setview -exec \"ls /vobs/pss/node\" $viewtag
                #if [ $? -ne 0 ]; then
                #        print_err "vobs directory is invalid"
                #        report_error
                #        exit 1
                #fi
                #$BLDHOMEPATH/get_ub_armada.sh $viewtag
                #rtr=$?
                #if [ $rtr -eq $UPDATED ]; then
                #        ECHO "Found the latest uboot & usbkey"
                #        subject="Found the latest uboot & usbkey"
                #        to="jiemingg,weisheli,xinghubl"
                #        $SENDMAIL "$to" "$subject" "$body"
                #elif [ $rtr -eq $NOUPDATED ]; then
                #        ECHO "No uboot/usbkey is updated."
                #else
                #        err="An unknown error has occurred in get_ub_armada"
                #        print_err "$err"
                #        subject="$err"
                #        to="$TO"
                #        sendmail "$to" "$subject" "$body"
                #fi
        fi
done



if [ `cat $BLD_QUEUE | wc -l` -eq 0 ]; then
        ECHO "No building task in bld_queue."
        exit 0
fi

running_pid=`bld_screen_pid`
if [ $running_pid -ne 0 ]; then
        ECHO "\"`bld_screen_name`($running_pid)\" screen is running."
        exit 0
fi

if [ -f kw_will_bld ]; then
        ECHO "Pause daily building."
        exit 0
fi 


bld_task=""
for task in `cat $BLD_QUEUE |sort -r -t '/' -k 6`
do
        check_completed_task $task
        if [ $? -eq $RTR_COMPLETED_TASK ]; then
                continue
        else
                bld_task=$task
                ECHO "The script is going to build $bld_task"
                break
        fi
done

if [ -z $bld_task ]; then
        print_err "No building task in bld_queue."
        report_error
        exit 1
fi


bld_id=`get_basebuild_from_task $bld_task`
build_product=`get_product_from_task $bld_task`
view_product=`convert_to_view_product $build_product`
if [ $build_product == "pss4" ]; then
        view_num=`/usr/atria/bin/cleartool lsview $BLDADMIN-${view_product}*-bld | grep $bld_id | wc -l`
        if [ $view_num -eq 0 ]; then
                #$MKVIEW_PSS4 $bld_id
                if [ $? -ne 0 ]; then
                        print_err "Makeview fail for PSS4"
                        report_error
                        exit 1
                fi
        elif [ $view_num -gt 1 ]; then
                print_err "Please remove the rubbish view with $bld_id for PSS4"
                report_error
                exit 1
        fi
else
        view_num=`/usr/atria/bin/cleartool lsview $BLDADMIN-${view_product}*-bld | grep $bld_id | wc -l`
        if [ $view_num -eq 0 ]; then
                $MKVIEW $bld_id
                if [ $? -ne 0 ]; then
                        print_err "Makeview fail for $build_product"
                        report_error
                        exit 1
                fi
        elif [ $view_num -ne 3 ]; then
                print_err "Please remove the rubbish view with $bld_id"
                report_error
                exit 1
        fi
fi

$BLDVIEW $bld_id $build_product

sleep 15
running_pid=`bld_screen_pid`
if [ $running_pid ]; then
        subject="Created the screen of $bld_id for $build_product"
        body="Building $bld_id"
        sendmail "$TO" "$subject" "$body"
else
        print_err "Created the screen of $bld_id for $build_product failure"
        report_error
        exit $SCREEN_FAIL
fi


exit 0
