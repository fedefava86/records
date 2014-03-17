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

# @name_file:   USR.tcl
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2013.07.10
# --
# @brief_description: User module
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

source USR_config.tcl
source USR_proc.tcl
source COMMON_proc.tcl

if {$argc != 8} {
    set tmpString "the input parameters are not correct: ./USR.tcl down(ip) down(port) opt(reset_modem) opt(request_id) opt(request_powerlevel) opt(default_set) opt(interactive_mode) opt(stress_test)"
    log_string [s2c_clock] ${opt(module_name)} "|-----" "${tmpString}\n"
} else {
    set down(ip)                  [lindex $argv 0]
    set down(port)                [lindex $argv 1]
    set opt(reset_modem)          [lindex $argv 2]
    set opt(request_id)           [lindex $argv 3]
    set opt(request_powerlevel)   [lindex $argv 4]
    set opt(default_set)          [lindex $argv 5]
    set opt(interactive_mode)     [lindex $argv 6]
    set opt(stress_test)          [lindex $argv 7]
}

set auto_path [linsert $auto_path 0 .]

set timeout -1
if {${opt(interactive_mode)} == 1} {
    log_user 0
}
#exp_internal 0
remove_nulls -d 0

spawn nc ${down(ip)} ${down(port)}
set opt(connection_down) ${spawn_id}

if {$opt(reset_modem) == 1} {
    set command "ATZ4"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${command}\n"
    send -i ${opt(connection_down)} -- "${command}\n"
    expect {
        -i ${opt(connection_down)} -re {(.*?)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        }
    }
    sleep ${opt(sleep)}
}
if {$opt(request_id) == 1} {
    set command "AT?AL"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${command}\n"
    send -i ${opt(connection_down)} -- "${command}\n"
    expect {
        -i ${opt(connection_down)} -re {(.*?)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        }
    }
    sleep ${opt(sleep)}
}
if {$opt(request_powerlevel) == 1} {
    set command "AT?L"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${command}\n"
    send -i ${opt(connection_down)} -- "${command}\n"
    expect {
        -i ${opt(connection_down)} -re {(.*?)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        }
    }
    sleep ${opt(sleep)}
}
if {$opt(default_set) == 1} {
    set command "MACDELAY 1"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${command}\n"
    send -i ${opt(connection_down)} -- "${command}\n"
    expect {
        -i ${opt(connection_down)} -re {(.*?)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        }
    }
    sleep ${opt(sleep)}
    set command "NETDED OFF"
    log_string [s2c_clock] ${opt(module_name)} "SENDDN" "${command}\n"
    send -i ${opt(connection_down)} -- "${command}\n"
    expect {
        -i ${opt(connection_down)} -re {(.*?)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
        }
    }
    sleep ${opt(sleep)}
}

if {$opt(stress_test) == 1} {
    log_user 0
    sched_send
    expect {
        -i ${opt(connection_down)} -re {(.*)\r\n} {
            log_string [s2c_clock] ${opt(module_name)} "READDN" "$expect_out(1,string)\n"
            exp_continue
        }
    }
}

if {${opt(interactive_mode)} == 1} {
    log_user 1
    interact
} else {
    expect {
        -i ${opt(connection_down)} -re {.+} {
            exp_continue
        }
    }
}

