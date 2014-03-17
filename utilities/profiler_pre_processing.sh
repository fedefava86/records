#!/bin/sh

# @name_file:   pre_processing.sh
# @author:      Giovanni Toso
# @last_update: 2014.02.24
# --
# @brief_description: clean the log files made by the PROFILER to be processed in matlab.
#                     Execute this script before running other tasks.
#
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
