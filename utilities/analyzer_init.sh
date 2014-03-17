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

# @name_file:   analyzer_init.sh
# @author:      
# @last_update: 
# --
# @brief_description: 
#                     
#                     

cd `dirname "$0"`
DEV_ROOT="$(pwd)/../../../"

if [ -f analyzer.env ]; then
    rm analyzer.env
fi

EXP_FILE="$(pwd)/analyzer.env"
MYNAME="records"
INDEX_MOD=0


device_check() {
    COL_DEVICE_LIST=\$${1}
    eval DEVICE_NAME=$(echo ${DEVICE_LIST} | eval awk \'{ print ${COL_DEVICE_LIST} }\')
    eval PATH_DEVICE="\${DEVICE_${1}}/\${MYNAME}/"
    if [ -d ${PATH_DEVICE} ]; then
        cd ${PATH_DEVICE}
        MODEMS_NAME=$(grep "boot.sh" boot_init.log | awk '{print $8}') >> /dev/null
        for modem in ${MODEMS_NAME}; do
            #echo ${modem}
            if [ -d ${modem} ]; then
                #TODO: remove the tmp var
                eval mod_counter=\${DEVICE_${1}_${modem}_START_NUM}
                if [ -z ${mod_counter} ]; then
                    mod_counter=0
                    INDEX_MOD=$(expr ${INDEX_MOD} + 1)
                    eval DEVICE_${1}_MOD_NAME_LIST="\${DEVICE_${1}_MOD_NAME_LIST}\${modem}' '"

                    #-modemPath---
                    eval MODEM_${INDEX_MOD}=${PATH_DEVICE}${modem}
                    #echo "export MODEM_${INDEX_MOD}=${PATH_DEVICE}${modem}" >> ${EXP_FILE}

                    echo -n "${modem}: merge log ..."
                    cat ${PATH_DEVICE}${modem}/S2C_APP.log > ${PATH_DEVICE}${modem}/tmpS2C.log
                    cat ${PATH_DEVICE}${modem}/S2C_NET.log >> ${PATH_DEVICE}${modem}/tmpS2C.log
                    cat ${PATH_DEVICE}${modem}/S2C_MAC.log >> ${PATH_DEVICE}${modem}/tmpS2C.log
                    echo "OK!"
                    echo -n "${modem}: sort log ..."
                    sort ${PATH_DEVICE}${modem}/tmpS2C.log > ${PATH_DEVICE}${modem}/S2C.log
                    rm ${PATH_DEVICE}${modem}/tmpS2C.log
                    echo "OK!"

                    echo "set MODEM(${INDEX_MOD}) \"${PATH_DEVICE}${modem}\"" >> ${EXP_FILE}
                fi
                mod_counter=$(expr ${mod_counter} + 1)
                eval DEVICE_${1}_${modem}_START_NUM=${mod_counter}
                #eval echo "${modem}_START_NUM=\${${modem}_START_NUM}"
            fi
        done
        DEV_OFFSET_MOD="${DEV_OFFSET_MOD}${INDEX_MOD} "
    else
        echo "the DEVICE ${DEVICE_NAME} is not found. Check its name."
    fi
    cd - > /dev/null
}

print_var() {
    COL_DEVICE_LIST=\$${1}
    eval echo "$(echo ${DEVICE_LIST} | eval awk \'{ print ${COL_DEVICE_LIST} }\') __________"

    eval tmp_DEV_NAME_MOD_NAME_LIST=\${DEVICE_${1}_MOD_NAME_LIST}
    for modem in ${tmp_DEV_NAME_MOD_NAME_LIST}; do
        echo " :: ${modem}"
        eval CMD="\${DEVICE_${1}}/${MYNAME}/boot_init.log"
        echo "$(grep ${modem} ${CMD} | grep "boot.sh" | awk '{print "    > ["strftime("%c",$1 / 1000000)"]  "$2"\t-->", $3, $4, $5, $6, $7, $8}')"
        eval echo "'    '\> number of start from scratch= \${DEVICE_${1}_${modem}_START_NUM}"
    done
}

echo " _______               __                         "
echo "|   _   |.-----.---.-.|  |.--.--.-----.-----.----."
echo "|       ||     |  _  ||  ||  |  |-- __|  -__|   _|"
echo "|___|___||__|__|___._||__||___  |_____|_____|__|  "
echo "                          |_____|                 "
echo "-------------------------------------------------------"
echo "TOOL for post-processing the RECORDS's log"

if [ ! $# -ge 2 ]; then
    echo "ERROR: the number of the input parameters isn't correct."
    echo "\n  ./analyzer.sh <device-1_name> ··· <device-N_name> <dest-folder_log-results>"
    echo "\nATTENTION: the ${0} script requires at least two parameters:"
    echo "            - one device name"
    echo "            - destination folder for the log results"
    echo "Exiting ..."
    exit 1
else
    index_1=1
    for inPar in $@; do
        if [ ${index_1} -eq $# ]; then
            DEST_FOLDER=${inPar}
            #echo "export DEST_FOLDER=${inPar}" >> ${EXP_FILE}
            echo "set DEST_FOLDER \"${inPar}\"" >> ${EXP_FILE}
        else
            DEVICE_LIST="${DEVICE_LIST}${inPar} "
            eval DEVICE_${index_1}=${DEV_ROOT}${inPar}
            #echo "export DEVICE_${index_1}=${DEV_ROOT}${inPar}" >> ${EXP_FILE}
            echo "set DEVICE(${index_1}) \"${DEV_ROOT}${inPar}\"" >> ${EXP_FILE}
        fi
        index_1=$(expr ${index_1} + 1)
    done
    #echo "export DEVICE_LIST=${DEVICE_LIST}" >> ${EXP_FILE}
    echo "set DEVICE_LIST \"${DEVICE_LIST}\"" >> ${EXP_FILE}
fi


index_2=1
checkDev=1
while [ ${checkDev} -eq 1 ]; do
    eval tmpDevice=\${DEVICE_${index_2}}
    #echo ${checkDev}
    if [ ! -z ${tmpDevice} ]; then
#set -x
        #col=\$${index_2}
        #eval tmpDev=$(echo ${DEVICE_LIST} | eval awk \'{ print ${col} }\')
#set +x
        device_check ${index_2}
        print_var ${index_2}
        index_2=$(expr ${index_2} + 1)
    else
        checkDev=0
    fi
done

echo "set DEV_OFFSET_MOD \"${DEV_OFFSET_MOD}\"" >> ${EXP_FILE}

mkdir -p ${DEST_FOLDER}/analyzer_folder
mv ${EXP_FILE} ${DEST_FOLDER}/analyzer_folder
cp analyzer_core.tcl ${DEST_FOLDER}/analyzer_folder
cp analyzer.sh ${DEST_FOLDER}/analyzer_folder

