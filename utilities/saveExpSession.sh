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

# @name_file:   saveExpSession.sh
# @author:      
# @last_update: 
# --
# @brief_description: 
#                     
#                     

if ! test $# = 2; then
    echo "$0 <device_name> <Experiment_Session_label>"
    exit
fi
#echo ${1}
RECORDS_DIR="$(pwd)/../"
DIR_EXPSES="${RECORDS_DIR}/../${1}/records/"
mkdir -p ${DIR_EXPSES}

MODEMS_NAME=$(grep "boot.sh" ${RECORDS_DIR}/boot_init.log | awk '{print $8}') >> /dev/null

for modem in ${MODEMS_NAME}; do
    if ! test -d ${DIR_EXPSES}/${modem} ; then
        mv ${RECORDS_DIR}/${modem} ${DIR_EXPSES}
    fi
done
mv ${RECORDS_DIR}/boot_init.log ${DIR_EXPSES}
mkdir -p ${DIR_EXPSES}/utilities
cp -r ${RECORDS_DIR}/utilities/analyzer_core.tcl ${DIR_EXPSES}/utilities
cp -r ${RECORDS_DIR}/utilities/analyzer_init.sh ${DIR_EXPSES}/utilities
cp -r ${RECORDS_DIR}/utilities/analyzer.sh ${DIR_EXPSES}/utilities
cp -r ${RECORDS_DIR}/utilities/profiler_plot.m ${DIR_EXPSES}/utilities
cp -r ${RECORDS_DIR}/utilities/profiler_pre_processing.sh ${DIR_EXPSES}/utilities

cd ${RECORDS_DIR}/../
echo -n "compressing..."
tar czf ExperimentSession_${2}.tar.gz ${1}
if ! test $? = 0 ; then
    echo "error during the compretion"
    exit 1
fi
echo " OK"

rm -rf ${RECORDS_DIR}/../${1}

