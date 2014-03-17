#!/bin/sh

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

# @name_file:   boot.sh
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.02.11
# --
# @brief_description: this script starts the simulation framework and checks if all
#                     module (APP,NET,MAC, NSC) are running. When some module fall down
#                     the START_Framework.sh script restores whole control framework.

RECORDS_ROOT=$(pwd)

IPMODEM=""
PORTNS=""
PORTCTRLFW=""
START_MODPORT=""
OPT_CHECKPORT="1"

SLEEP_TIME=2
SLEEP_CHECK=1
STRESS_TEST=0
REALTEST_FLAG=0
DEBUGTEST_FLAG=0
DEBUGTEST_PAR=""
ONE_V=1
ZERO_V=0

SCRIPT_FILE_NAME="boot.sh"
LOG_FILE="boot_init"

IP_FW="127.0.0.1"

NSC_PID=
NSCAPP_PORT=
NSCNS2_PORT=
USR_PID=
APPUSR_PORT=
APP_PID=
NETAPP_PORT=
NET_PID=
MACNET_PORT=
MAC_PID=


CHECK_NSC_PID=1

check_dataCmd() {
    expr $(date +"%s%N") + 0 2> /dev/null > /dev/null
    err_checkvalue=$?
    case ${err_checkvalue} in
        0)
            DATE_N=1
            ;;
        *)
            DATE_N=0
            ;;
    esac
}

check_netstatCmd() {
    which netstat > /dev/null
    err_checkvalue=$?
    case ${err_checkvalue} in
        0)
            NETSTAT_CMD=1
            ;;
        1)
            NETSTAT_CMD=0
            ;;
    esac
}

check_ncCmd() {
    which nc > /dev/null
    err_checkvalue=$?
    case ${err_checkvalue} in
        0)
            NC_CMD=1
            ;;
        1)
            NC_CMD=0
            ;;
    esac
}

log() {
    case ${DATE_N} in
        0)
            echo "$(expr `date +"%s"` \* 1000000)  $$    $*" >> "${LOG_FILE}.log"
            ;;
        1)
            echo "$(expr `date +"%s%N"` / 1000)  $$    $*" >> "${LOG_FILE}.log"
            ;;
        *)
            echo "Something strange happened in the check_dataCmd() function."
            echo "Exiting ... "
            sleep 1
            exit 1
            ;;
    esac
}

log_check_ask() {
    case ${DATE_N} in
        0)
            echo -n "$(expr `date +"%s"` \* 1000000)  $$    $*" >> "${LOG_FILE}.log"
            ;;
        1)
            echo -n "$(expr `date +"%s%N"` / 1000)  $$    $*" >> "${LOG_FILE}.log"
            ;;
    esac
}

log_check_return() {
    echo " $*" >> "${LOG_FILE}.log"
}

startLayer() {
    tmpParameters=""
    case ${1} in
        APP)
            tmpParameters="${2} ${3} ${4} ${5} ${6} ${7}"
            ;;
        NET)
            tmpParameters="${2} ${3} ${4} ${5}"
            ;;
        MAC)
            tmpParameters="${2} ${3} ${4} ${5}"
            ;;
        NSC)
            tmpParameters="${2} ${3} ${4} ${5} ${6} ${7}"
            ;;
        USR)
            tmpParameters="${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9}"
            ;;
        *)
            exit 1
            ;;
    esac
    ./${1}.tcl ${tmpParameters} >> "${LOG_FILE}.out" 2>> "${LOG_FILE}.err" &
    eval ${1}_PID=$!
    ../utilities/profiler.sh $(eval echo \$${1}_PID) ${1}_stat.log > /dev/null 2> /dev/null &
    tmpLog="start the ${1} layer: ${1}_PID: $! input_parameters: ${tmpParameters}"
    log ${tmpLog}
}

killLayer() {
    eval tmp_pid=\${${1}_PID}
    if [ -d /proc/${tmp_pid} ]; then
        kill -9 ${tmp_pid}
        tmpLog="kill the ${1} layer: ${1}_PID: ${tmp_pid}"
        log ${tmpLog}
    fi
}

resetModem() {
    ./USR.tcl ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8} >> "${LOG_FILE}.out" 2>> "${LOG_FILE}.err" &
    USRPID=$!
    sleep ${SLEEP_TIME}
    if [ -d /proc/${USRPID} ]; then
        kill -9 ${USRPID}
    fi
}

checkTcp_fwPort() {
    err_checkNetstat=""
    err_checkvalue=""
    port_server=""
    pid_server=""
    namePid_server=""
    port_client=""
    pid_client=""
    namePid_client=""

    if [ ! ${NETSTAT_CMD} -eq 1 ] && [ ${OPT_CHECKPORT} -eq 1 ]; then
        echo "netstat is not installed in the system!"
        echo "ATTENTION: it is not possible to check if the ports of the RECORDS framework are busy!"
        echo "           it is important that no more than one instance of ${SCRIPT_FILE_NAME} is running at the same time."
        echo -e "\n you can launch the following command in order to bypass this check:"
        echo -e "\n ./${SCRIPT_FILE_NAME} ${IPMODEM} ${PORTNS} ${PORTCTRLFW} ${START_MODPORT} --no-check-port.\n"
        log "netstat is not installed in the system. Exiting ..."
        echo "Exiting ..."
        exit 1
    elif [ ${NETSTAT_CMD} -eq 1 ] && [ ${OPT_CHECKPORT} -eq 1 ]; then
        log_check_ask "checking *:${2} port ... "
        netstat -tulpna 2> /dev/null | grep ${2} > /dev/null
        err_checkvalue=$?
        if [ ${err_checkvalue} -eq 1 ]; then
            log_check_return "NO"
            log "    ** ATTENTION: the ${2} port is not matched! Is possible that the tcp server linked to this port is down."
            echo "Exiting ..."
            exit 1
        else
            #netstat -tulpn 2> /dev/null | grep ${1}
            log_check_return "OK"
            port_server=`netstat -tulpna 2> /dev/null | grep ${2} | grep "LISTEN" | awk '{print $4}'`
            pid_server=`netstat -tulpna 2> /dev/null | grep ${2} | grep "LISTEN" | awk '{print $7}' | awk -F "/" '{print $1}'`
            namePid_server=`netstat -tulpna 2> /dev/null | grep ${2} | grep "LISTEN" | awk '{print $7}' | awk -F "/" '{print $2}'`
            log "   ** server_addr:  ${port_server}"
            log "   ** server_PID:   ${pid_server}/${namePid_server}"

            port_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" | grep -v "${pid_server}/${namePid_server}" | awk '{print $4}'`
            pid_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" | grep -v "${pid_server}/${namePid_server}" | awk '{print $7}' | awk -F "/" '{print $1}'`
            namePid_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" | grep -v "${pid_server}/${namePid_server}" | awk '{print $7}' | awk -F "/" '{print $2}'`

            if [ ! -z ${port_client} ]; then
                log "   ** server_state: ESTABLISHED"
                log "   ** ATTENTION: the server is already used by:"
                log "      + client_addr: ${port_client}"
                log "      + client_PID:  ${pid_client}/${namePid_client}"
                return 1
            else
                log "   ** server_state: LISTEN"
            fi

        fi
    fi
    return 0
}

checkTcp_modemPort() {
    if [ ! ${NC_CMD} -eq 1 ] && [ ${OPT_CHECKPORT} -eq 1 ]; then
        echo "nc is not installed in the system!"
        echo "ATTENTION: it is not possible to check if the ports of the RECORDS framework are busy!"
        echo "           it is important that no more than one instance of ${SCRIPT_FILE_NAME} is running at the same time."
        echo -e "\n you can launch the following command in order to bypass this check:"
        echo -e "\n ./${SCRIPT_FILE_NAME} ${IPMODEM} ${PORTNS} ${PORTCTRLFW} ${START_MODPORT} --no-check-port.\n"
        log "netcat is not installed in the system. Exiting ..."
        echo "Exiting ..."
        #TODO: replace "exit 1" with "return 1"
        exit 1
    elif [ ${NC_CMD} -eq 1 ] && [ ${OPT_CHECKPORT} -eq 1 ]; then
        log_check_ask "checking ${1}:${2} ... "
        netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" > /dev/null
        err_checkvalue=$?
        if [ ${err_checkvalue} -eq 1 ]; then
            nc -w4 -z ${1} ${2} > /dev/null
            err_checkvalue=$?
            if [ ${err_checkvalue} -eq 1 ]; then
                log_check_return "NO"
                log "   ** ATTENTION: the ${1}:${2} port is not matched. Is possible that the tcp server linked to this port is down."
                log "      + CHECK IF THE MODEM IS RUNNING!"
                echo "Exiting ..."
                #TODO: replace "exit 1" with "return 1"
                exit 1
            else
                log_check_return "OK"
                return 0
            fi
        else
            log_check_return "OK"
            port_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" | awk '{print $4}'`
            pid_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT"  | awk '{print $7}' | awk -F "/" '{print $1}'`
            namePid_client=`netstat -tulpna 2> /dev/null | grep "${1}:${2}" | grep -v "TIME_WAIT" | awk '{print $7}' | awk -F "/" '{print $2}'`

            if [ ! -z ${port_client} ]; then
                log "   ** ATTENTION: the server is already used by:"
                log "      + client_addr:   ${port_client}"
                log "      + client_PID:    ${pid_client}/${namePid_client}"
                log "      + proc checking: `cat /proc/${pid_client}/cmdline | tr '\000' ' '`"
                return 1
            fi
        fi
    fi
}

#- Create the folder ---
mkdir_node() {
if [ ! -d "${1}" ]; then
    mkdir ${1}
fi
FILES_TO_CP="\
             COMMON_proc.tcl \
             NSC.tcl         \
             NSC_config.tcl  \
             NSC_proc.tcl    \
             APP.tcl         \
             APP_config.tcl  \
             APP_proc.tcl    \
             NET.tcl         \
             NET_config.tcl  \
             NET_proc.tcl    \
             MAC.tcl         \
             MAC_config.tcl  \
             MAC_proc.tcl    \
             USR.tcl         \
             USR_config.tcl  \
             USR_proc.tcl    \
             ns_start.sh     \
             env_ns          \
             tcl_experiments \
             "
# Copy the files
for FILE_NAME in ${FILES_TO_CP}; do
    cp -rf ${FILE_NAME} ${1}
done

cd ${1}
find . -name "*.tcl" -exec chmod +x {} \;
find . -name "*.sh" -exec chmod +x {} \;
cd - > /dev/null
#---
}

check_dataCmd
log "> init and system checks ..."
log "${SCRIPT_FILE_NAME} $@"
log "checking nanoseconds for the date command ... ${DATE_N}"
check_netstatCmd
log "checking netstat command ... ${NETSTAT_CMD}"
check_ncCmd
log "checking nc command ... ${NC_CMD}"
log "setting sleep_time ... ${SLEEP_TIME}"
log "setting sleep_check ... ${SLEEP_CHECK}"

echo " __ _  __                          _    "
echo "(_  _)/      _  _ __ |_ _  _ |   _|_    "
echo "__)/__\__ __(_ (_)| ||_ |'(_)| __ | \^/ "
echo "------------------------------------------"
echo "PID: $$"
if [ ! $# -ge 5 ]; then
    echo "ERROR: the number of the input parameters is not correct."
    echo -e "\n  ./${SCRIPT_FILE_NAME} ip_modem ns_port control_port start_port_fw label_modem [--no-check-port|--check-port]"
    echo -e "\n--no-check-port is optional. Use it when you want to bypass the ports check."
    log "the number of the input parameters is wrong, its number is $#."
    echo "Exiting ..."
    exit 1
else
    IPMODEM=${1}
    PORTNS=${2}
    PORTCTRLFW=${3}
    START_MODPORT=${4}
    MACNET_PORT=`expr ${START_MODPORT} + 0`
    NETAPP_PORT=`expr ${START_MODPORT} + 1`
    APPUSR_PORT=`expr ${START_MODPORT} + 2`
    NSCAPP_PORT=`expr ${START_MODPORT} + 3`
    NSCNS2_PORT=`expr ${START_MODPORT} + 4`
    ID=${5}
    if [ $# -eq 6 ]; then
        case ${6} in
            --no-check-port)
                OPT_CHECKPORT=0
                ;;
            --check-port)
                OPT_CHECKPORT=1
                ;;
            *)
                echo "ERROR: the last parameter is not matched."
                echo -e "\n  ./${SCRIPT_FILE_NAME} ip_modem ns_port control_port start_port_fw label_modem [--no-check-port|--check-port]"
                echo -e "\n--no-check-port is optional. Use it when you want to bypass the ports check."
                log "the last parameter was not matched: ${6}."
                echo "Exiting ..."
                exit 1
        esac
    fi
fi

mkdir_node ${ID}
log "setting the node label as: ${ID}"
cd ${ID}

LOG_FILE="boot_${ID}"

# Start the framework
echo "> the control framework for the acustic-modem is running in:"
echo "  $(pwd)/${ID}"
log "> the control framework is running in: [REALTEST mode]"
log "${SCRIPT_FILE_NAME} $@"

log "setting MAC-NET port = ${MACNET_PORT} ... OK"
log "setting NET-APP port = ${NETAPP_PORT} ... OK"
log "setting APP-USR port = ${APPUSR_PORT} ... OK"
log "setting NSC-APP port = ${NSCAPP_PORT} ... OK"
log "setting NSC-NS2 port = ${NSCNS2_PORT} ... OK"

checkTcp_modemPort ${IPMODEM} ${PORTNS}
err_checkvalue=$?
case ${err_checkvalue} in
    1)
        log "exit before to reset modem"
        exit 1
        ;;
esac
checkTcp_modemPort ${IPMODEM} ${PORTCTRLFW}
err_checkvalue=$?
case ${err_checkvalue} in
    1)
        log "exit before to reset modem"
        exit 1
        ;;
esac

resetModem ${IPMODEM} ${PORTCTRLFW} 1 0 0 0 1 0

#- NSC_MODULE --
sleep ${SLEEP_TIME}
checkTcp_modemPort ${IPMODEM} ${PORTNS}
err_checkvalue=$?
if [ ! ${err_checkvalue} -eq 1 ]; then
    startLayer NSC ${IPMODEM} ${PORTNS} ${IP_FW} ${NSCAPP_PORT} ${IP_FW} ${NSCNS2_PORT}
else
   exit 1
fi

#- MAC_MODULE --
sleep ${SLEEP_TIME}
checkTcp_modemPort ${IPMODEM} ${PORTCTRLFW}
err_checkvalue=$?
if [ ! ${err_checkvalue} -eq 1 ]; then
    startLayer MAC ${IPMODEM} ${PORTCTRLFW} ${IP_FW} ${MACNET_PORT}
else
    exit 1
fi

#- NET_MODULE --
sleep ${SLEEP_TIME}
checkTcp_fwPort ${IP_FW} ${MACNET_PORT}
err_checkvalue=$?
if [ ! ${err_checkvalue} -eq 1 ]; then
    startLayer NET ${IP_FW} ${MACNET_PORT} ${IP_FW} ${NETAPP_PORT}
else
    exit 1
fi

#- APP_MODULE --
sleep ${SLEEP_TIME}
checkTcp_fwPort ${IP_FW} ${NETAPP_PORT}
err_checkvalue_1=$?
checkTcp_fwPort ${IP_FW} ${NSCAPP_PORT}
err_checkvalue_2=$?
if [ ! ${err_checkvalue_1} -eq 1 ] && [ ! ${err_checkvalue_2} -eq 1 ]; then
    startLayer APP ${IP_FW} ${NETAPP_PORT} ${IP_FW} ${NSCAPP_PORT} ${IP_FW} ${APPUSR_PORT}
else
    exit 1
fi

#- USR_MODULE --
sleep ${SLEEP_TIME}
checkTcp_fwPort ${IP_FW} ${APPUSR_PORT}
err_checkvalue=$?
if [ ! ${err_checkvalue} -eq 1 ]; then
    startLayer USR ${IP_FW} ${APPUSR_PORT} 0 1 1 1 0 ${STRESS_TEST}
else
    exit 1
fi

log "> the RECORDS framework is running!"

while [ ${CHECK_NSC_PID} -eq 1 ]; do

    if [ ! -d /proc/${NSC_PID} ] || [ ! -d /proc/${MAC_PID} ] || [ ! -d /proc/${NET_PID} ] || [ ! -d /proc/${APP_PID} ]; then
        log "WARNING: one or more layer went down"
        log "> the control framework is starting up again in: [REALTEST mode]"
        killLayer APP
        killLayer NET
        killLayer MAC
        killLayer USR

        resetModem ${IPMODEM} ${PORTCTRLFW} 1 0 0 0 1 0
        sleep ${SLEEP_TIME}
        startLayer NSC ${IPMODEM} ${PORTNS} ${IP_FW} ${NSCAPP_PORT} ${IP_FW} ${NSCNS2_PORT}
        sleep ${SLEEP_TIME}
        startLayer MAC ${IPMODEM} ${PORTCTRLFW} ${IP_FW} ${MACNET_PORT}
        sleep ${SLEEP_TIME}
        startLayer NET ${IP_FW} ${MACNET_PORT} ${IP_FW} ${NETAPP_PORT}
        sleep ${SLEEP_TIME}
        startLayer APP ${IP_FW} ${NETAPP_PORT} ${IP_FW} ${NSCAPP_PORT} ${IP_FW} ${APPUSR_PORT}
        sleep ${SLEEP_TIME}
        startLayer USR ${IP_FW} ${APPUSR_PORT} 0 1 1 1 0 ${STRESS_TEST}

        log "> the RECORDS framework is running up again!"
    fi
    sleep ${SLEEP_CHECK}
done

