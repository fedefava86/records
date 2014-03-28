#!/bin/sh
#
# Copyright (c) 2014 Regents of the SIGNET lab, University of Padova.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University of Padova (SIGNET lab) nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# @name_file:   profiler.sh
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.03.28
# --
# @brief_description: this script manage the execution of ns

SAMPLING_PERIOD=1
RAM_USAGE_KB="0"
RAM_USAGE_MB="0"
PROCESS_PID=$1
LOG_FILENAME=$2
BC_CMD="0"

check_process_pid() {
    if [ ! -f /proc/${PROCESS_PID}/stat ]; then
        echo "$(date +"%s")    ERR_PROC    EXITING" >> ${LOG_FILENAME}
        exit -1
    fi
}

check_bc() {
    which bc> /dev/null
    err_checkvalue=$?
    case ${err_checkvalue} in
        0)
            BC_CMD=1
            ;;
        *)
            BC_CMD=0
            ;;
    esac
}

get_vmrss_kb() {
    check_process_pid
    RAM_USAGE_KB=$(cat /proc/${PROCESS_PID}/statm | awk '{print $2}')
}

get_vmrss_mb() {
    check_process_pid
    get_vmrss_kb $1
    RAM_USAGE_MB=`echo "${RAM_USAGE_KB} / 1024" | bc -l`
}

get_cpu_percentage() {
    check_process_pid
    CPU_TIME=`cat /proc/uptime | cut -f1 -d " " | sed 's/\.//'`
    PROC_TIME=`cat /proc/${PROCESS_PID}/stat | awk '{t = $14 + $15;print t}'`
    sleep ${SAMPLING_PERIOD}

    CPU_TIME2=`cat /proc/uptime | cut -f1 -d " " | sed 's/\.//'`
    PROC_TIME2=`cat /proc/${PROCESS_PID}/stat | awk '{t = $14 + $15;print t}'`

    CPU_TIME_DIFF=$(expr ${CPU_TIME2} - ${CPU_TIME})
    PROC_TIME_DIFF=$(expr ${PROC_TIME2} - ${PROC_TIME})

    if [ ${CPU_TIME_DIFF} -eq 0 ]; then
        CPU_USAGE=0
    else
        if [ ${BC_CMD} -eq 1 ]; then
            CPU_USAGE=$(echo "scale=3; ${PROC_TIME_DIFF} * 100 / ${CPU_TIME_DIFF}" | bc -l | sed 's,^\.,0.,')
        else
            CPU_USAGE=$(expr ${PROC_TIME_DIFF} \* 100 / ${CPU_TIME_DIFF})
        fi
    fi
}

check_bc

while :; do
    RAM_USAGE_KB="0"
    TIMESTAMP=$(date +"%s")
    get_vmrss_kb
    get_cpu_percentage
    echo "${TIMESTAMP}    ${RAM_USAGE_KB}    ${CPU_USAGE}" >> ${LOG_FILENAME}
done
