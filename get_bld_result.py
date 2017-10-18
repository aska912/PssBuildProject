#!/usr/bin/env python

import os, os.path, sys
import re

VOBS_PATH = "/vobs/pss/node"

def get_file_list_from_vobs():
    global VOBS_PATH
    if os.path.exists(VOBS_PATH):
        return os.listdir(VOBS_PATH)
    else:
        return []

def get_log_list():
    match_log_file=re.compile(r"^(world).*(log)$")
    file_list = get_file_list_from_vobs()
    log_list = []
    if len(file_list):
        for logfile in file_list:
            if re.search(match_log_file, logfile):
                log_list.append(logfile)
    return log_list

def get_bld_result_from_log_list(log_list):
    bld_result = ""    
    if not len(log_list):
        return ""
    
    for log_file in log_list:
        log_field_list = log_file.split('.')
        if len(log_field_list) == 4:
            ss = r"%-10s%15s"%(log_field_list[1], log_field_list[2])
            bld_result += "%s\n"%(ss)
        else:
            ss = r"%-10s%15s"%(log_field_list[1], "unknown")
            bld_result += "%s\n"%(ss)
    return bld_result

    
if __name__ == '__main__':
    log_list = get_log_list()
    sys.stdout.write( "%s\r\n"%(get_bld_result_from_log_list(log_list)) )
    



