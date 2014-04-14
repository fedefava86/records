#!/usr/bin/tclsh
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

# @name_file:   multipath_analisys.sh
# @author:      Giovanni Toso
# @last_update: 2014.02.28
# --
# @brief_description: extract features from a multipath file
#

set opt(verbose) "1"

proc log_stdout {msg} {
    global opt

    if {$opt(verbose)} {
        puts -nonewline stdout "* ${msg}"
    }
}

if {$argc != 1} {
    log_stdout "The number of input parameters is not correct: use as input the file name to process\n"
    exit
} else {
    set opt(input_file)    [lindex $argv 0]
}

if {[catch {open ${opt(input_file)} "r"} res] == 0} {
    set opt(num_multipath_lines) "8"
    set opt(first_line) "1"
    set fp ${res}
    set file_data [read $fp]
    foreach line [split ${file_data} "\n"] {
        if {[string length ${line}] != 0} {
            if {[regexp {^(([[:digit:]]+)[[:space:]]+RECVIM,([[:digit:]]+),([[:digit:]]+),([[:digit:]]+),(ack|noack),([[:digit:]]+),([-+]?[0-9]*\.?[0-9]+),([[:digit:]]+),([-+]?[0-9]*\.?[0-9]+),(.*))$} ${line} -> \
            -> \
            match(timestamp)   \
            match(length)      \
            match(source)      \
            match(destination) \
            match(ack_flag)    \
            match(bitrate)     \
            match(rssi)        \
            match(integrity)   \
            match(velocity)    \
            match(payload)
            ] == 1} {
                for {set i ${opt(num_multipath_lines)}} {${i} < 8} {incr i} {
                    puts -nonewline stdout "\t0\t0"
                }
                set opt(num_multipath_lines) "0"
                if { ${opt(first_line)} } {
                    puts -nonewline stdout "${match(timestamp)}\t${match(length)}\t${match(source)}\t${match(destination)}\t${match(ack_flag)}\t${match(bitrate)}\t${match(rssi)}\t${match(integrity)}\t${match(velocity)}"
                    set opt(first_line) "0"
                } else {
                    puts -nonewline stdout "\n${match(timestamp)}\t${match(length)}\t${match(source)}\t${match(destination)}\t${match(ack_flag)}\t${match(bitrate)}\t${match(rssi)}\t${match(integrity)}\t${match(velocity)}"
                }
                unset match
            } elseif {[regexp {^(([[:digit:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([[:digit:]]+).*$)} ${line} -> \
            -> \
            match(timestamp)   \
            match(timeline)    \
            match(integrity)
            ] == 1} {
                if { ${opt(num_multipath_lines)} < 8 } {
                    puts -nonewline stdout "\t${match(timeline)}\t${match(integrity)}"
                    set opt(num_multipath_lines) [expr ${opt(num_multipath_lines)} + 1]
                }
            }
        }
    }
}
