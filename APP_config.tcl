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

# @name_file:   APP_config.tcl
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2013.07.10
# --
# @brief_description: Configuration file for the application module
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

set down(ip)      "" ;#127.0.0.1
set down(port)    "" ;#12702
set up(ip)        "" ;#127.0.0.1
set up(port)      "" ;#12703
set down(nscip)   "" ;#127.0.0.1
set down(nscport) "" ;#12704

# Global variables
set opt(connection_down)           ""
set opt(connection_up)             ""
set opt(up_connected)              ""
set opt(sendim_counter)            1
set opt(file_sendim_counter)       "APP_sendim_counter.tcl"
set opt(ack_mode)                  "noack"
set opt(net_forward_mode)          ""
set opt(mac_delay)                 ""
set opt(default_ttl)               5
set opt(pending_id_request)        -2
set opt(pending_power_request)     -2
set opt(sleep_before_answer)       1
set opt(max_sendim_size)           64
set opt(max_system_cmd_log_length) 240
set opt(map_ns_file_name)          "APP_map_ns.tcl"
set opt(ns_start_file_name)        "ns_start.sh"
set opt(getper_last_src)           ""
set opt(getper_last_ttl)           ""
set opt(verbose)                   "1"
set opt(module_name)               "APP"

set map_ns_pid()                   ""
set map_ns_id()                    ""
set modem(id)                      ""
set modem(powerlevel)              ""

