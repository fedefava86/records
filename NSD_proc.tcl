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

# @name_file:   NSD_proc.tcl
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.02.27
# --
# @brief_description: Procedure file for the ns-dumb module
# @acknowledgement: stwo@users.sourceforge.net for the rand_str procedure
#
# The next line restarts using tclsh \
exec expect -f "$0" -- "$@"

proc sched_send {} {
    global opt

    set random_command "${opt(random_command_header)}[rand_str ${opt(payload_size)}]"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${random_command}\n"
    send -i ${opt(connection_down)} -- "${random_command}\n"
    after ${opt(send_period)} sched_send
}

proc rand_str {len} {
    return [subst [string repeat {[format %c [expr {int(rand() * 26) + (int(rand() * 10) > 5 ? 97 : 65)}]]} ${len}]]
}

proc log_nsd {msg} {
    global opt

    if {${opt(verbose)}} {
        puts -nonewline stdout "* ${msg}"
    }
}

proc debug_nsd {msg} {
    global opt

    log_string [s2c_clock] ${opt(module_name)} "|-----" "${msg}"
}
