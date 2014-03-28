#!/bin/sh
#
# Copyright (c) 2013 Regents of the SIGNET lab, University of Padova.
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

# @name_file:   ns_start.sh
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.02.27
# --
# @brief_description: this script manage the execution of ns and ns-dumb

# Variables
STDOUTLOG="ns.out"
STDERRLOG="ns.err"
TCLEXPERIMENTS="tcl_experiments"

# Exports
if [ -f "env_ns" ]; then
    . ./env_ns
else
    echo "The env_ns file does not exist. Exiting ..." >>${STDERRLOG}
    exit 1
fi

# Check for params:
# - $1 is the sim ID
# - $2 is the name of the tcl file
# - $3 is the modem ID
if [ "$#" -lt 3 ]; then
    echo "Too few input parameters: $@. Exiting ..." >>${STDERRLOG}
    exit 1
fi

SIMID=$1
TCLFILENAME=$2
case ${TCLFILENAME} in
    "F")
        TCLFILENAME="ufetch.tcl"
        ;;
    "M")
        TCLFILENAME="msun.tcl"
        ;;
    "P")
        TCLFILENAME="uwpolling.tcl"
        ;;
    "NSD")
        TCLFILENAME="NSD.tcl"
        ;;
    *)
        echo "Unsupported protocol $2. Exiting.tcl ..." >>${STDERRLOG}
        exit 1
esac

NODEID=$3
shift
shift
shift
NSPARAMS=$@

if [ -d "${SIMID}" ]; then
    echo "The folder of the experiment ${SIMID} already exists. Exiting ..." >>${STDERRLOG}
    exit 1
fi

# create the folder
mkdir ${SIMID}

if [ "${TCLFILENAME}" == "NSD.tcl" ]; then
    cd ${SIMID}
    echo "------------------------------------------------" >> ${STDOUTLOG}
    echo "$(date +"%s")    Starting: NSD ${TCLFILENAME} ${SIMID} ${NODEID} ${NSPARAMS}" >> ${STDOUTLOG}
    cd - > /dev/null

    if [ "$#" -lt 8 ]; then
        exec ./NSD.tcl localhost 12705 ${NSPARAMS} 2>>${STDERRLOG} >>${STDOUTLOG}
    else
        exec ./NSD.tcl ${NSPARAMS} 2>>${STDERRLOG} >>${STDOUTLOG}
    fi
else
    cp -fr ${TCLEXPERIMENTS}/* ${SIMID}
    cd ${SIMID}
    find . -name "*.tcl" -exec chmod +x {} \;
    find . -name "*.sh" -exec chmod +x {} \;
    cd - > /dev/null

    # Start the simulation
    cd ${SIMID}
    echo "------------------------------------------------" >> ${STDOUTLOG}
    echo "$(date +"%s")    Starting: ns ${TCLFILENAME} ${SIMID} ${NODEID} ${NSPARAMS}" >> ${STDOUTLOG}
    exec ns ${TCLFILENAME} ${SIMID} ${NODEID} ${NSPARAMS} 2>>${STDERRLOG} >>${STDOUTLOG}
    cd - > /dev/null
fi

