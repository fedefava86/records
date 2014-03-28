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

# @name_file:   NSD.tcl
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.02.27
# --
# @brief_description: NS-Dumb module.
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

source NSD_config.tcl
source NSD_proc.tcl
source COMMON_proc.tcl

if {$argc != 5} {
    debug_nsd "the input parameters are not correct: ./NSD.tcl down(ip) down(port) opt(send_period) opt(payload_size)\n"
    exit
} else {
    set down(ip)                  [lindex $argv 0]
    set down(port)                [lindex $argv 1]
    set opt(send_period)          [lindex $argv 2]
    if {![string is integer -strict ${opt(send_period)}]} {
        debug_nsd "opt(send_period): ${opt(send_period)} is not an integer value\n"
        exit
    }
    set opt(send_period)          [expr [lindex $argv 2] * 1000] ;# from ms to s
    set opt(payload_size)         [lindex $argv 3]
    set opt(destination)          [lindex $argv 4]
    # Check if the opt(destination) is a valid input, if not set it to broadcast
    if {[expr [string is integer -strict ${opt(destination)}] != 1] || [expr ${opt(destination)} > 255] || [expr ${opt(destination)} < 1]} {
        debug_nsd "opt(destination): ${opt(destination)} is not a valid destination\n"
        exit
    }
}

set auto_path [linsert $auto_path 0 .]
set timeout -1
#exp_internal 0
remove_nulls -d 0

if {${opt(verbose)}} {
    debug_nsd "${opt(module_name)}: starting\n"
}

log_user 0
spawn -open [socket ${down(ip)} ${down(port)}]
set opt(connection_down) ${spawn_id}
fconfigure ${opt(connection_down)} -translation binary
log_user 1

if {${opt(verbose)}} {
    debug_nsd "Down connection ${down(ip)}:${down(port)}\n"
}

# Check the constrains about the size of the header
if {${opt(payload_size)} > ${opt(payload_max_size)}} {
    debug_nsd "Payload size set to the maximum allowed: ${opt(payload_max_size)}\n"
    set opt(payload_size) ${opt(payload_max_size)}
}

set opt(random_command_header) "AT*SENDIM,${opt(payload_size)},${opt(destination)},noack,"

log_user 0

# If the send period is 0 do not send data, just empty the buffer
if {${opt(send_period)} != 0} {
    sched_send
}

expect {
    -i ${opt(connection_down)} -re {(.*)\r\n} {
        log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        exp_continue
    }
}

