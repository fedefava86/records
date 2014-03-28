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

# @name_file:   analyzer.sh
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.03.28
# --
# @brief_description: this script starts the analyzer module

ANALYZER_ROOT=$(pwd)

echo " _______               __                         "
echo "|   _   |.-----.---.-.|  |.--.--.-----.-----.----."
echo "|       ||     |  _  ||  ||  |  |-- __|  -__|   _|"
echo "|___|___||__|__|___._||__||___  |_____|_____|__|  "
echo "                          |_____|                 "
echo "-------------------------------------------------------"
echo "TOOL for post-processing the RECORDS's log"
if [ ! $# -ge 0 ]; then
    echo "\nERROR: the number of the input parameters isn't correct."
    echo "Exiting ..."
    exit 1
else
    chmod +x analyzer_core.tcl
    ./analyzer_core.tcl 12709 &
    pid=$!
    echo "pid analyzer_core ${pid}"
    echo "wait..."
    sleep 2
    rlwrap nc localhost 12709
fi
