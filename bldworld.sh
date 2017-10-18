#!/bin/ksh
#
# Build *all* targets.  This is particularly important for developers before
# submitting code.
# wfr: ptlmble_lc has to be at the end of the line because this target 
# cannot be compiled on EL4 machines
#

#
# Get scripte name
#
sf=$0
if [[ $sf =~ \.\/ ]]; then
        sf=`echo $sf | sed 's/\.\///g'`
fi

if [[ $sf =~ ^\/ ]]; then
        sf=`echo $sf | awk -F '/' '{print $NF}'`
fi

. /home/admin1830/bin/build/build_profile
. /home/admin1830/muxvob/bin/ksh_functions/usage.kshf 
. /home/admin1830/pint/bin/utags

function check_bld_world_log {
        worldlog_file=$1
        if [[ ! $worldlog_file =~ ^(world)\..*\.(log)$ ]]; then
                return 1
        fi
        world=`echo $worldlog_file | cut -d "." -f 1`
        rule=`echo $worldlog_file | cut -d "." -f 2`
        log=`echo $worldlog_file | cut -d "." -f 3`
        tail -n 10 $worldlog_file | grep "abort_check" >> /dev/null
        if [ $? -eq 0 ]; then
            mv "$world.$rule.$log" "$world.$rule.fail.$log"
            ECHO "Build $rule failure for $viewname"
        else
            mv "$world.$rule.$log" "$world.$rule.ok.$log"
            ECHO "Build $rule success for $viewname"
        fi

}


# with set -x here, you can check progress 
# using grep "^+ ./buildall" <build_output_file>
#set -x

# If a build fails, or there are any other errors, stop
#set -e

SCRIPT_NAME=$sf

rules=$*
vobs="/vobs/pss/node"

clearcase_root=`echo $CLEARCASE_ROOT`
viewname=`echo $clearcase_root|awk -F "/" '{print $3}'`

for rule in $rules   
do
        cd $vobs
        ls $vobs
        if [ $? -ne 0 ]; then
                print_err "$vobs No such file or directory"
                report_error
                exit 1
        fi
        if [ ! $rule == "uscope" ]; then
            rm -rf world.${rule}*.log
            (time ./buildall.sh  $rule) 2>&1 | tee world.${rule}.log
            check_bld_world_log world.${rule}.log
        else
            # Remove the old code archive 
            #admin1830-dwdm_1830-figcake-150812-85xx-bld
            release=`echo $viewname | awk -F "-" '{print $3}'`
            code_lib_path="$CODE_LIB/$release"
            cd $code_lib_path
            ECHO "cd " `pwd`
            for tgz in `find -name "*.tgz" -type f -mtime +30`
            do
                    tgz=`echo $tgz | sed 's/\.\///g'`
                    ECHO "Found $tgz"
                    rm -f $tgz
                    if [ $? -eq 0 ]; then
                        ECHO "Removed $tgz"
                    else
                        print_err "Removed $tgz failure"
                    fi
            done
            cd $vobs
            (time /home/admin1830/pint/bin/uscope -b -f) 2>&1 | tee world.uscope.log
            if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
                    mv world.uscope.log world.uscope.fail.log
                    ECHO "Build uscope failure for $viewname"
            else
                    mv world.uscope.log world.uscope.ok.log
                    ECHO "Build uscope success for $viewname"
                    #cd $code_lib_path
                    #sc=`ls -ltrh|tail -n 1|awk '{print $9}'`
                    
            fi
        fi
done






