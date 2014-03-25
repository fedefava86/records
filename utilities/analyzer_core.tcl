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

# @name_file:   analyzer_core.tcl
# @author:      Ivano Calabrese, Giovanni Toso
# @last_update: 2014.03.25
# --
# @brief_description: analyzer core module
#
# the next line restarts using tclsh \
exec expect -f "$0" -- "$@"

set envFile "analyzer.env"
source ${envFile}

set ID_LIST ""

#set debug 0
set opt(verbose) 0

set id_sim ""
if {${argc} != 1} {
    puts stderr "Insert as input parameter the ID of the simulation. Exiting ..."
    exit
} else {
    set up(port_1) [lindex $argv 0]
}

# Expect variables
exp_internal     0
set timeout     -1
remove_nulls -d  0
log_user         0

proc Accept_userSock_cb {sock addr port} {
    global opt

    spawn -open ${sock}
    set opt(connection_up_user) ${spawn_id}
    fconfigure ${opt(connection_up_user)} -translation binary
    if {${opt(verbose)}} {
        debugLog "user Socket connected:: ${sock} - ${addr}:${port}\n"
    }
    main_loop
}

proc send_upsockUser {msg} {
    global opt

    send -i ${opt(connection_up_user)} -- ${msg}
}

socket -server Accept_userSock_cb -myaddr 127.0.0.1 ${up(port_1)}

proc sleep {time} {
    after $time set end 1
    vwait end
}

proc debugLog {msg} {
    global opt
    puts stdout -nonewline "\[[clock seconds]\] |----- ${msg}"
}

# #######
proc start_delay {idSim} {
    global opt MODEM DEVICE
    set idnode_timestamp ""
    #foreach path ${folder_list} id_node ${id_node_list} {}
    foreach modId [array names MODEM] {
        # Open the file
        eval set modIdPath  \"\$MODEM($modId)\"
        set fp        [open "${modIdPath}/S2C.log" r]
        set file_data [read ${fp}]
        # Scan all the lines
        set data      [split ${file_data} "\n"]
        foreach line ${data} {
            # Match the id of the sim and search for the timestamp
            regexp "^(\\d+)(\\s+)APP(\\s+)(\\|\\-\\-\\-\\--)(\\s+)ns with id ${idSim} and pid(.+)" ${line} -> \
                timestamp

            if {${opt(verbose)}} {
                if {[info exist ->]} {
                    puts "string: ${->}"
                    unset ->
                }
            }
            if {[info exist timestamp]} {
                eval set modIdPath \"\$MODEM($modId)\"
                lappend idnode_timestamp "MODEM_${modId}([lindex [split $modIdPath / ] end]) ${timestamp}"
                if {${opt(verbose)}} {
                    puts "${id_node} ${timestamp}"
                }
                unset timestamp
            }
        }
        close ${fp}
    }
    # Create the diff values
    set idnode_timestamp [lsort -integer -index 1 ${idnode_timestamp}]
    if {${opt(verbose)}} {
        puts ${idnode_timestamp}
    }
    foreach list_element ${idnode_timestamp} {
        send_upsockUser "[lindex ${list_element} 0] \t\t[expr [lindex ${list_element} 1] - [lindex [lindex ${idnode_timestamp} 0] 1]]\n"
    }
}

# #######
proc lsim {} {
    global opt MODEM DEVICE
    set log(file_name) "hist_lsim.dat"

    #---
    if {[file exists ${log(file_name)}] == 0} {
        if {[catch {exec touch ${log(file_name)}} res] != 0} {
            puts stderr "Error creating ${log(file_name)}. Details: ${res}"
            return
        }
    } else {
        exec rm ${log(file_name)}
        if {[catch {exec touch ${log(file_name)}} res] != 0} {
            puts stderr "Error creating ${log(file_name)}. Details: ${res}"
            return
        }
    }
    # Test if the log file are writable
    if {[catch {open ${log(file_name)} "a+"} res] != 0} {
        puts stderr "Error opening ${log(file_name)}. Details: ${res}"
        return
    }
    set fpdat ${res}
    #---

    foreach modIndex [array names MODEM] {
        # Open the file
        eval set modIdPath  \"\$MODEM($modIndex)\"
        send_upsockUser "[lindex [split $modIdPath / ] end]: \n"
        send_upsockUser "    TIME_STAMP \t\t\t S_ID \t N_ID \t N_PL \t R_ID \t NS_COMMAND\n"
        send_upsockUser "    -----------------------------------------------------------------------------------\n"

        set fp        [open "${modIdPath}/S2C.log" r]
        set file_data [read ${fp}]
        # Scan all the lines
        set data      [split ${file_data} "\n"]


        set tmp_modId     "--"
        set tmp_modPowLev "--"
        set lineP1        ""
        #--------------------------------------
        for {set iLine 0} {$iLine < [llength $data]} {incr iLine 1} {
            # ______________________
            # Match the last modem id before the simulation is started
            if {[regexp {^([[:digit:]]+)[[:space:]]+APP[[:space:]]+\|-\-\-\--[[:space:]]+Modem[[:space:]]id:[[:space:]]([[:digit:]]+)} [lindex $data $iLine] -> \
                timestamp_id \
                modId] ==1} {
            #if {[info exist modId]} {}
                if {[string compare ${modId} ${tmp_modId}] != 0} {
                    set tmp_modId "${modId}"
                }
                unset modId
            }
            # ______________________
            # Match the last modem Power Level before the simulation is started
            if {[regexp {^([[:digit:]]+)[[:space:]]+APP[[:space:]]+\|-\-\-\--[[:space:]]+Modem[[:space:]]power[[:space:]]level:[[:space:]]([[:digit:]]+)} [lindex $data $iLine] -> \
                timestamp_powLev \
                modPowLev] ==1} {
            #if {[info exist modPowLev]} {}
                if {[string compare ${modPowLev} ${tmp_modPowLev}] != 0} {
                    set tmp_modPowLev "${modPowLev}"
                }
                unset modPowLev
            }
            # ______________________
            # Match the simulation number and its timestamp (SUBJECT)
            if {[regexp {^([[:digit:]]+)[[:space:]]+APP[[:space:]]+\|-\-\-\--[[:space:]]+ns[[:space:]]with[[:space:]]id[[:space:]]([[:digit:]]+)[[:space:]]and[[:space:]]pid[[:space:]]} [lindex $data $iLine] -> \
                timestamp_sim \
                simNum] ==1} {
            #if {[info exist simNum]} {}
                set halfWin 60
                set tmp_remote "---"
                set tmp_nsCmd  "---"
                for {set iWin [expr $iLine - $halfWin]} {$iWin < [expr $iLine + $halfWin]} {incr iWin 1} {
                    if {$iWin > 0 && $iWin < [llength $data]} {
                        regexp "^.*APP.*CREATE.*noack,.+,.+,.+,(.+),.+,.+,.*R>STARTED.*$simNum" [lindex $data $iWin] -> \
                            remote
                        if {[info exist remote]} {
                            set tmp_remote "$remote"
                            #set tmp_remote "[lindex $data $iWin]"
                            unset remote
                        }
                    }
                }

                # ______________________
                # Match the commands that launches the simulation
                regexp {^[[:digit:]]+[[:space:]]+APP[[:space:]]+READUP[[:space:]]+(NS[[:space:]][[:digit:]]+[[:space:]][[:alpha:]]+[[:print:]]+)} [lindex $data [expr $iLine - 1]] -> \
                    nsCmd
                if {[info exist nsCmd]} {
                    set tmp_nsCmd ${nsCmd}
                    unset nsCmd
                }
                if {[regexp {^[[:digit:]]+[[:space:]]+APP[[:space:]]+SENDUP[[:space:]]+RECVIM,[[:graph:][:space:]]*,(NS[[:space:]][[:digit:]]+[[:space:]][[:alpha:]]+[[:print:]]+)} [lindex $data [expr $iLine - 1]] -> \
                    remoteNsCmd] ==1} {
                #if {[info exist remoteNsCmd]} {}
                    set tmp_nsCmd ${remoteNsCmd}
                    unset remoteNsCmd
                }

                #send_upsockUser "  [clock format [expr ${timestamp_sim}/1000000] -format {%Y-%m-%d %H:%M:%S}] \t${simNum} \t${tmp_modId} \t${nsCmd}\n"
                send_upsockUser "   \
                                    [clock format [expr ${timestamp_sim}/1000000] -format {%Y-%m-%d %H:%M:%S}] \t\
                                    ${simNum} \t\
                                    ${tmp_modId} \t\
                                    ${tmp_modPowLev} \t\
                                    ${tmp_remote} \t\
                                    ${tmp_nsCmd} \n"
                puts ${fpdat} ${simNum}
                unset simNum
            }
        }
        #--------------------------------------
        send_upsockUser "\n"
        close ${fp}
    }
    close ${fpdat}
}

# #######
proc multipath {} {
    global opt MODEM DEVICE

    foreach modIndex [array names MODEM] {
        eval set modIdPath  \"\$MODEM($modIndex)\"
        send_upsockUser "[lindex [split $modIdPath / ] end]: \n"
        #set log(file_name) "hist_multipath_[lindex [split $modIdPath / ] end].dat"
        set log(file_name) "hist_multipath_${modIndex}.dat"

        #---
        if {[file exists ${log(file_name)}] == 0} {
            if {[catch {exec touch ${log(file_name)}} res] != 0} {
                puts stderr "Error creating ${log(file_name)}. Details: ${res}"
                return
            }
        } else {
            exec rm ${log(file_name)}
            if {[catch {exec touch ${log(file_name)}} res] != 0} {
                puts stderr "Error creating ${log(file_name)}. Details: ${res}"
                return
            }
        }
        # Test if the log file are writable
        if {[catch {open ${log(file_name)} "a+"} res] != 0} {
            puts stderr "Error opening ${log(file_name)}. Details: ${res}"
            return
        }
        set fpdat ${res}
        #---
        # Open the file

        set fp        [open "${modIdPath}/multipath.log" r]
        set file_data [read ${fp}]
        # Scan all the lines
        set data      [split ${file_data} "\n"]


        set tmp_modId     "--"
        set tmp_modPowLev "--"
        set lineP1        ""
        #--------------------------------------

        set _mpfl "1";# multipath first line
        set _mplc "0";# multipath line counter
        set _line "";# processed line
        set _pkpc "0";# processed packet counter
        foreach line ${data} {
            #set _line ""
            if {[string length ${line}] != 0} {
                if {[regexp {^[[:digit:]]+[[:space:]]+RECVIM,[[:digit:]]+,[[:digit:]]+,[[:digit:]]+,(ack|noack),[[:digit:]]+,[-+]?[0-9]*\.?[0-9]+,[[:digit:]]+,[-+]?[0-9]*\.?[0-9]+,(.*)$} ${line} -> \
                -> \
                mp(payload)] == 1} {
                    set _mpfl "1"
                    set _mplc "0"
                    unset mp
                }
                if {[regexp {^([[:digit:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([[:digit:]]+.*$)} ${line} -> \
                mp(timestamp)   \
                mp(timeline)    \
                mp(integrity)] == 1} {
                    if {[string compare ${_mpfl} "1"] == 0} {
                        set _line "${mp(timestamp)}\t${mp(timeline)}\t${mp(integrity)}"
                        set _mpfl "0"
                        set _mplc [expr ${_mplc} + 1]
                    }
                    if {[string compare ${_mpfl} "0"] == 0 && ${_mplc} < 9} {
                        set _line "${_line}\t${mp(timeline)}\t${mp(integrity)}"
                        set _mplc [expr ${_mplc} + 1]
                    }
                }
            }
            if {[string compare ${_mplc} "8"] == 0} {
                puts ${fpdat} ${_line}
                set _pkpc [expr ${_pkpc} + 1]
                set line ""
            }
        }
        #--------------------------------------
        send_upsockUser "\n"
        close ${fp}
        close ${fpdat}
        send_upsockUser " ${_pkpc} packets has been processed. \n"
        send_upsockUser "    -----------------------------------------------------------------------------------\n"
    }
}

# -------
proc pkt {} {
    global opt MODEM DEVICE ID_LIST

    #send_upsockUser "ID_LIST: ${ID_LIST}"
    
    set formatStr {%13s}
    set item_lineString "--------------"
    set header_01 "[format $formatStr "MODEM NAME"]|"
    set header_02 "[format $formatStr "MODEM IDs"]|"
    set lineString "[format $formatStr "-------------"]+"
    set tmpCounters   ""
    set tmp_rxCounters   ""
    set tmp255Counter "0"
    foreach modIndex [array names MODEM] {
        eval set modIdPath  \"\$MODEM($modIndex)\"
        set currentMod_tx "[lindex [split $modIdPath / ] end]"
        set header_01 "${header_01} [format $formatStr "${currentMod_tx}"]|"
        set header_02 "${header_02} [format $formatStr "[lindex ${ID_LIST} [expr ${modIndex} - 1]]"]|"
        set lineString "${lineString}[format $formatStr "${item_lineString}"]+"
        set tmpCounters [lappend tmpCounters "0"]
        set tmp_rxCounters [lappend tmp_rxCounters "0"]
    }

    send_upsockUser "${header_01}\n"
    send_upsockUser "${header_02}\n"
    send_upsockUser "${lineString}\n"
    send_upsockUser "${lineString}\n"

    foreach modIndex [array names MODEM] {
        # Open the file
        eval set modIdPath  \"\$MODEM($modIndex)\"
        set currentMod_tx "[lindex [split $modIdPath / ] end]_TX"
        set currentMod_rx "[lindex [split $modIdPath / ] end]_RX"

        set fp        [open "${modIdPath}/S2C.log" r]
        set file_data [read ${fp}]
        # Scan all the lines
        set data      [split ${file_data} "\n"]


        set tmp_modId     "| "
        #--------------------------------------
        for {set iLine 0} {$iLine < [llength $data]} {incr iLine 1} {
            # ______________________
            # Match the last modem id before the simulation is started
            if {[regexp {^[[:digit:]]+[[:space:]]+APP[[:space:]]+SENDDN[[:space:]]+AT\*SENDIM,[[:alnum:]]+,[[:alnum:]]+,[[:alpha:]]+,[[:alpha:]],([[:alnum:]]+),[[:alnum:]]+,([[:alnum:][:space:]*]+),[[:graph:][:space:]]*} [lindex $data $iLine] -> \
                modId \
                dst ] == 1} {
                if {[string compare ${modId} [lindex ${tmp_modId} end]] != 0} {
                    set tmp_modId "${tmp_modId} ${modId} "
                }
                if {[string compare ${dst} "255"] == 0 } {
                    set tmp255Counter [expr ${tmp255Counter} + 1]
                }
                for {set idList_index 0} {$idList_index < [llength $ID_LIST]} {incr idList_index} {
                    foreach id4mod [lindex ${ID_LIST} ${idList_index}] {
                        if {[string compare ${dst} ${id4mod}] == 0 } {
                            set tmpCounters [lreplace ${tmpCounters} ${idList_index} ${idList_index} [expr [lindex ${tmpCounters} ${idList_index}] + 1]]
                            #send_upsockUser "$tmpCounters \n"
                            break
                        }
                    }
                }
                unset modId
            }
            # ______________________
            # Match the last modem id before the simulation is started
            if {[regexp {^[[:digit:]]+[[:space:]]+APP[[:space:]]+READDN[[:space:]]+RECVIM,[[:alnum:]]+,[[:alnum:]]+,[[:alnum:]]+,[[:alpha:]]+,[[:alnum:]]+,[[:graph:][:space:]]*,[F|S],([[:alnum:]]+),([[:alnum:]]+),} [lindex $data $iLine] -> \
                rx_modId \
                rx_sn] == 1} {
            #if {[info exist rx_modId]} {}
                #if {[string compare ${modId} [lindex ${tmp_modId} end]] != 0} {
                    #set tmp_modId "${tmp_modId} ${modId} "
                #}
                for {set idList_index 0} {$idList_index < [llength $ID_LIST]} {incr idList_index} {
                    foreach id4mod [lindex ${ID_LIST} ${idList_index}] {
                        if {[string compare ${rx_modId} "5"] == 0 && [string compare ${id4mod} "5"] == 0 } {
                            #send_upsockUser "id4mod(5?): ${id4mod}\n"
                            #send_upsockUser "idList_index: ${idList_index}\n"
                            #send_upsockUser "line: [lindex $data $iLine]\n"
                        }
                        if {[string compare ${rx_modId} ${id4mod}] == 0 } {
                            set tmp_rxCounters [lreplace ${tmp_rxCounters} ${idList_index} ${idList_index} [expr [lindex ${tmp_rxCounters} ${idList_index}] + 1]]
                            #if {[string compare ${rx_modId} "5"] == 0 && [string compare ${id4mod} "5"] == 0 } {
                                #send_upsockUser "id4mod(5?): ${id4mod}\n"
                                #send_upsockUser "idList_index: ${idList_index}\n"
                                #send_upsockUser "line: [lindex $data $iLine]\n"
                                #send_upsockUser "$tmp_rxCounters\n"
                            #}
                            #send_upsockUser "$tmpCounters \n"
                            #break
                        }
                    }
                }
                unset rx_modId
            }
        }
        set currentMod_tx "[format $formatStr $currentMod_tx]|"
        foreach i_tmpCounters ${tmpCounters} {
            set currentMod_tx "${currentMod_tx} [format $formatStr $i_tmpCounters]|"
        }
        set currentMod_tx "${currentMod_tx} [format $formatStr "+$tmp255Counter"]|"

        set currentMod_rx "[format $formatStr $currentMod_rx]|"
        foreach i_tmpCounters ${tmp_rxCounters} {
            set currentMod_rx "${currentMod_rx} [format $formatStr $i_tmpCounters]|"
        }

        send_upsockUser "${currentMod_tx}\n"
        send_upsockUser "${currentMod_rx}\n"
        send_upsockUser "${lineString}\n"

        for {set i_reset 0} {$i_reset < [llength $tmpCounters]} {incr i_reset} {
            set tmpCounters [lreplace ${tmpCounters} ${i_reset} ${i_reset} 0]
        }
        set tmp255Counter "0"

        for {set i_reset 0} {$i_reset < [llength $tmp_rxCounters]} {incr i_reset} {
            set tmp_rxCounters [lreplace ${tmp_rxCounters} ${i_reset} ${i_reset} 0]
        }
        #--------------------------------------
        close ${fp}
        #exit 1
    }
}
# -------

proc modIndex2modId {} {
    global opt MODEM DEVICE ID_LIST ID_LIST_TS

    set ID_LIST ""
    set ID_LIST_TS ""
    foreach modIndex [array names MODEM] {
        # Open the file
        eval set modIdPath  \"\$MODEM($modIndex)\"
        #send_upsockUser "[lindex [split $modIdPath / ] end]: \n"

        set fp        [open "${modIdPath}/S2C.log" r]
        set file_data [read ${fp}]
        # Scan all the lines
        set data      [split ${file_data} "\n"]


        set tmp_timestamp     ""
        set tmp_modId         ""
        #--------------------------------------
        for {set iLine 0} {$iLine < [llength $data]} {incr iLine 1} {
            # ______________________
            # Match the last modem id before the simulation is started
            if {[regexp {^([[:digit:]]+)[[:space:]]+APP[[:space:]]+\|-\-\-\--[[:space:]]+Modem[[:space:]]id:[[:space:]]([[:digit:]]+)} [lindex $data $iLine] -> \
                timestamp_id \
                modId] ==1} {
            #if {[info exist modId]} {}
                #if {[string compare ${modId} [lindex ${tmp_modId} end]] != 0 && [expr ${timestamp_id} > "1378030577"]}
                if {[string compare ${modId} [lindex ${tmp_modId} end]] != 0 } {
                    set tmp_modId "${tmp_modId} ${modId} "
                    set tmp_timestamp "${tmp_timestamp} ${timestamp_id} "
                } else {
                    set tmp_modId [lreplace ${tmp_modId} end end ${modId}]
                    set tmp_timestamp [lreplace ${tmp_timestamp} end end ${timestamp_id}]
                }
                unset modId
                #send_upsockUser "tmp_modId: $tmp_modId\n"
                #send_upsockUser "tmp_timestamp: $tmp_timestamp\n"
            }
        }
        lappend ID_LIST    "${tmp_modId}"
        lappend ID_LIST_TS "${tmp_timestamp}"
        #send_upsockUser "$ID_LIST_TS"
        #send_upsockUser "$ID_LIST"
        #send_upsockUser "------------------------------------\n"
        #--------------------------------------
        close ${fp}
    }
}

proc lmodem {} {
    global opt MODEM DEVICE ID_LIST ID_LIST_TS

    foreach modIndex [lsort -integer [array names MODEM]] {
        eval set modIdPath \"\$MODEM($modIndex)\"
        send_upsockUser "MODEM_$modIndex ([lindex [split $modIdPath / ] end]) \n"

        #for {set idList_index 0} {$idList_index < [llength $ID_LIST]} {incr idList_index} 
            #send_upsockUser "idList_index: $idList_index\n"
            #for {set id4mod 0} {$id4mod < [llength [lindex ${ID_LIST} ${idList_index}]]} {incr id4mod}
            for {set id4mod 0} {$id4mod < [llength [lindex ${ID_LIST} [expr ${modIndex} - 1]]]} {incr id4mod} {
                #send_upsockUser "id4mod: $id4mod\n"
                send_upsockUser "  \[[clock format [expr {[lindex [lindex ${ID_LIST_TS} [expr ${modIndex} - 1 ]] ${id4mod}] / 1000000}]] -format {%Y-%m-%d %H:%M:%S}]\]"
                send_upsockUser "\t[lindex [lindex ${ID_LIST} [expr ${modIndex} - 1]] ${id4mod}]\n"
            }
    send_upsockUser "\n"    
    }
    #puts [fmtable $ID_LIST]
}

proc print_help {} {
    send_upsockUser "+--------------------------------------------------------------------------+ \n"
    send_upsockUser "THE COMMANDS SUPPORTED ARE:\n"
    send_upsockUser " |  help\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  env\t\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  lmodem\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  start_delay\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  lsim\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  pkt\t\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  multipath\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  <empty>\t<cmd-DESCRIPTION>\n"
    send_upsockUser " |  exit\t<cmd-DESCRIPTION>\n"
    send_upsockUser "\n"
}

proc main_loop {} {
    global opt MODEM DEVICE
    send_upsockUser "\n@"

    modIndex2modId

    set opt(forever) 1
    expect {
        -i ${opt(connection_up_user)} -re {(.*)\n} {
            switch -regexp -- $expect_out(1,string) {
                {help} {
                    print_help
                }
                {env} {
                    send_upsockUser "+--------------------------------------------------------------------------+ \n"
                    set fp        [open "./${envFile}" r]
                    set file_data [read ${fp}]
                    set data      [split ${file_data} "\n"]
                    foreach line ${data} {
                        send_upsockUser " - ${line}\n"
                    }
                    send_upsockUser "+--------------------------------------------------------------------------+ \n"
                    close ${fp}
                }
                {lmodem} {
                    lmodem
                }
                {lsim} {
                    lsim
                    send_upsockUser "---\n"
                }
                {^start_delay} {
                    send_upsockUser " digit the simulation number: "
                    expect {
                        -i ${opt(connection_up_user)} -re {(.*)\n} {
                            switch -regexp -- $expect_out(1,string) {
                                {[[:digit:]]+} {
                                    send_upsockUser "modem_#  \t\tdelay(s) \n"
                                    send_upsockUser "--------------------------------------------------------------\n"
                                    start_delay $expect_out(1,string)
                                }
                                default {
                                    send_upsockUser "> $expect_out(1,string)\n"
                                }
                            }
                        }
                    }
                }
                {pkt} {
                    pkt
                    send_upsockUser "---\n"
                }
                {multipath} {
                    multipath
                    send_upsockUser "---\n"
                }
                {exit} {
                    exit 1
                }

                default {
                    send_upsockUser "$expect_out(1,string): command not found\n"
                    send_upsockUser "Use 'help' command for a usage summary\n"
                }
            }
            send_upsockUser "\n@"
            exp_continue
        }
        -i any_spawn_id eof {
            exit 1
        }
    }
}

vwait opt(forever)

exit 1

