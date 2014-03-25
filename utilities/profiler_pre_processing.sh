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

# @name_file:   profiler_pre_processing.sh
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.03.25
# --
# @brief_description: clean the log files made by the PROFILER to be processed in Matlab.
#                     Execute this script before running other tasks.

pre_process() {
    grep -E "[0-9]+[[:space:]]+[0-9]+[[:space:]]+([0-9]*\.[0-9]+|[0-9]+)" < ${1}_stat.log > ${1}_stat_clean.log
}

if [ $# -ne 1 ]; then
    echo "Use as input the target folder that contains the *_stat.log files. Exiting ..."
    exit 1
fi

DESTINATION_FOLDER=${1}

if [ ! -d ${DESTINATION_FOLDER} ]; then
    echo "The folder ${DESTINATION_FOLDER} does not exists. Exiting ..."
    exit 1
fi
START=$(date +%s)

echo "Pre-processing ..."
cd ${DESTINATION_FOLDER}

pre_process USR
pre_process APP
pre_process NET
pre_process MAC
pre_process NSC

cd - > /dev/null

STOP=$(date +%s)
DIFF=$(expr ${STOP} - ${START})

echo "Done in ${DIFF} seconds"
