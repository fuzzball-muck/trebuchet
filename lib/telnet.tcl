# Module to process TELNET protocol codes.
# You can add support for more TELNET options in here.

proc telnet_init {} {
    set telcmds {
        {"IAC"   "\377" telnet_cmd_iac  0 "Telnet escape char"}
        {"DONT"  "\376" telnet_cmd_dont 1 "Dont enable option"}
        {"DO"    "\375" telnet_cmd_do   1 "Do enable option"}
        {"WONT"  "\374" telnet_cmd_wont 1 "Won't do option"}
        {"WILL"  "\373" telnet_cmd_will 1 "Will do option"}
        {"SB"    "\372" telnet_cmd_sb   1 "Subnegotiate Begin"}
        {"SE"    "\360" telnet_cmd_se   0 "Subnegotiate End"}
        {"GA"    "\371" telnet_cmd_ga   0 "Go Ahead"}
        {"AYT"   "\366" telnet_cmd_ayt  0 "Are You There"}
        {"NOP"   "\361" ""              0 "No-OPeration"}
        {"EOR"   "\357" telnet_cmd_eor  0 "End Of Record"}
    }
    foreach telcmd $telcmds {
        foreach {name char command argc comment} $telcmd {
            telnet_register_command $name $char $command $argc
        }
    }

    set telopts {
        {"TERMTYPE" "\030" telnet_opt_termtype telnet_subneg_termtype "Terminal Type reporting"}
        {"EOR"      "\031" telnet_opt_eor      ""                     "End Of Record capability"}
        {"NAWS"     "\037" telnet_opt_naws     ""                     "Negotiate About Window Size"}
        {"LINEMODE" "\042" telnet_opt_linemode ""                     "Enable Linemode"}
        {"STARTTLS" "\056" telnet_opt_starttls telnet_subneg_starttls "STARTTLS encryption capability"}
    }
    # We may want to add support for the following later:
    #   {"MCCP2"    "\126" telnet_opt_mccp2    telnet_subneg_mccp2    "Mud Client Compression Protocol 2"}
    #   {"MSP"      "\132" telnet_opt_msp      telnet_subneg_msp      "Mud Sound Protocol"}
    #   {"MXP"      "\133" telnet_opt_mxp      telnet_subneg_mxp      "Mud eXtension hypertext Protocol"}

    foreach telopt $telopts {
        foreach {name char command sbcmd comment} $telopt {
            telnet_register_option $name $char $command $sbcmd
        }
    }
}


proc telnet_command_char_exists {char} {
    global telnetInfo
    if {![info exists telnetInfo(cmd-name-$char)]} {
        return 0
    }
    return 1
}


proc telnet_command_name_exists {name} {
    global telnetInfo
    if {![info exists telnetInfo(cmd-char-$name)]} {
        return 0
    }
    return 1
}


proc telnet_command_name {char} {
    global telnetInfo
    if {![telnet_command_char_exists $char]} {
        return ""
    }
    return $telnetInfo(cmd-name-$char)
}


proc telnet_command_argcount {name} {
    global telnetInfo
    if {![telnet_command_name_exists $name]} {
        return 0
    }
    return $telnetInfo(cmd-argc-$name)
}


proc telnet_command_call {name sok argv} {
    global telnetInfo
    if {[telnet_command_name_exists $name]} {
        if {[info commands $telnetInfo(cmd-cmd-$name)] != ""} {
            $telnetInfo(cmd-cmd-$name) $sok $argv
        }
    }
}


proc telnet_register_command {name char command argc} {
    global telnetInfo
    set telnetInfo(cmd-name-$char) $name
    set telnetInfo(cmd-char-$name) $char
    set telnetInfo(cmd-cmd-$name)  $command
    set telnetInfo(cmd-argc-$name) $argc
}





proc telnet_option_char_exists {char} {
    global telnetInfo
    if {![info exists telnetInfo(opt-name-$char)]} {
        return 0
    }
    return 1
}


proc telnet_option_name_exists {name} {
    global telnetInfo
    if {![info exists telnetInfo(opt-char-$name)]} {
        return 0
    }
    return 1
}


proc telnet_option_name {char} {
    global telnetInfo
    if {![telnet_option_char_exists $char]} {
        return ""
    }
    return $telnetInfo(opt-name-$char)
}


proc telnet_option_call {name sok request} {
    global telnetInfo
    if {[telnet_option_name_exists $name]} {
        if {[info commands $telnetInfo(opt-cmd-$name)] != ""} {
            $telnetInfo(opt-cmd-$name) $sok $request
        }
    }
}


proc telnet_option_subnegotiate {name sok data} {
    global telnetInfo
    if {[telnet_option_name_exists $name]} {
        if {[info commands $telnetInfo(opt-sbcmd-$name)] != ""} {
            $telnetInfo(opt-sbcmd-$name) $sok $data
        }
    }
}


proc telnet_register_option {name char command subnegcmd} {
    global telnetInfo
    set telnetInfo(opt-name-$char)   $name
    set telnetInfo(opt-char-$name)   $char
    set telnetInfo(opt-cmd-$name)    $command
    set telnetInfo(opt-sbcmd-$name)  $subnegcmd
}


proc telnet_options_list {} {
    global telnetInfo
    set out {}
    foreach opt [array names telnetInfo opt-char-*] {
        lappend out [string range $opt 9 end]
    }
    return $out
}




# direction is one of "in" or "out"
proc telnet_option_enable {name sok direction enabled} {
    global telnetInfo
    if {[telnet_option_name_exists $name]} {
        set telnetInfo(sok-$sok-opten-$name-$direction) $enabled
    }
}


# direction is one of "in" or "out"
proc telnet_option_is_enabled {name sok direction} {
    global telnetInfo
    if {[telnet_option_name_exists $name]} {
        if {[info exists telnetInfo(sok-$sok-opten-$name-$direction)]} {
            return $telnetInfo(sok-$sok-opten-$name-$direction)
        }
    }
    return 0
}


proc telnet_send {sok symbols} {
    global telnetInfo
    set world [/socket:world $sok]
#/echo -world $world -style error "$symbols"
    set out {}
    foreach sym $symbols {
        if {[telnet_command_name_exists $sym]} {
            append out $telnetInfo(cmd-char-$sym)
        } elseif {[telnet_option_name_exists $sym]} {
            append out $telnetInfo(opt-char-$sym)
        } else {
            error "internal error: Unknown telnet symbol."
        }
    }
    puts -nonewline $sok $out
}


proc telnet_debug_echo {sok data} {
    return
    global telnetInfo
    set world [/socket:world $sok]
    foreach ch [split $data ""] {
        if {[telnet_command_char_exists $ch]} {
            /echo -style results -world $world [telnet_command_name $ch]
        } elseif {[telnet_option_char_exists $ch]} {
            /echo -style results -world $world [telnet_option_name $ch]
        } else {
            binary scan $ch c charval
            /echo -style results -world $world $charval
        }
    }
}


proc telnet_socket_init {sok notls} {
    global telnetInfo treb_partial_line
    foreach opt [telnet_options_list] {
        telnet_option_enable $opt $sok "in" 0
        telnet_option_enable $opt $sok "out" 0
    }

    set treb_partial_line($sok) ""
    set telnetInfo(sok-$sok-state)  ""
    set telnetInfo(sok-$sok-SBopt)  ""
    set telnetInfo(sok-$sok-SBdata) ""
    set telnetInfo(sok-$sok-argc)   0
    set telnetInfo(sok-$sok-argv)   ""
    set telnetInfo(sok-$sok-slow)   0
    set telnetInfo(sok-$sok-notls)  $notls
}


proc telnet_socket_cleanup {sok} {
    global telnetInfo
    foreach name [array names telnetInfo sok-$sok-*] {
        unset telnetInfo($name)
    }
}




proc telnet_cmd_iac {sok argv} {
    upvar #0 telnetInfo(sok-$sok-SBopt) SBopt
    if {$SBopt == ""} {
        upvar #0 treb_partial_line($sok) partline
        append partline "\377"
    } else {
        upvar #0 telnetInfo(sok-$sok-SBdata) SBdata
        append SBdata "\377"
    }
}


proc telnet_cmd_dont {sok argv} {
    telnet_send $sok "IAC WONT"
    puts -nonewline $sok $argv
    set opt [telnet_option_name $argv]
    if {$opt != ""} {
        telnet_option_enable $opt $sok "out" 0
        telnet_option_call $opt $sok "DONT"
    } else {
        binary scan $argv c opt
    }
    flush $sok
}


proc telnet_cmd_do {sok argv} {
    set opt [telnet_option_name $argv]
    if {$opt == ""} {
        telnet_send $sok "IAC WONT"
        puts -nonewline $sok $argv
        binary scan $argv c opt
    } else {
        telnet_option_call $opt $sok "DO"
    }
    flush $sok
}


proc telnet_cmd_wont {sok argv} {
    set opt [telnet_option_name $argv]
    if {$opt != ""} {
        telnet_option_enable $opt $sok "in" 0
        telnet_option_call $opt $sok "WONT"
    } else {
        binary scan $argv c opt
    }
}


proc telnet_cmd_will {sok argv} {
    set opt [telnet_option_name $argv]
    if {$opt == ""} {
        telnet_send $sok "IAC DONT"
        puts -nonewline $sok $argv
        binary scan $argv c opt
    } else {
        telnet_option_call $opt $sok "WILL"
    }
    flush $sok
}


proc telnet_cmd_sb {sok argv} {
    global telnetInfo
    set opt [telnet_option_name $argv]
    if {$opt != ""} {
        if {[telnet_option_is_enabled $opt $sok "in"] ||
            [telnet_option_is_enabled $opt $sok "out"]
        } {
            set telnetInfo(sok-$sok-SBopt) $opt
            set telnetInfo(sok-$sok-SBdata) ""
        }
    } else {
        binary scan $argv c opt
    }
}


proc telnet_cmd_se {sok argv} {
    global telnetInfo
    set opt $telnetInfo(sok-$sok-SBopt)
    if {[telnet_option_name_exists $opt]} {
        set data $telnetInfo(sok-$sok-SBdata)
        telnet_debug_echo $sok $data
        set telnetInfo(sok-$sok-SBdata) ""
        set telnetInfo(sok-$sok-SBopt) ""
        telnet_option_subnegotiate $opt $sok $data
    }
}


proc telnet_cmd_ga {sok argv} {
    global treb_partial_line
    append treb_partial_line($sok) "\n"
}


proc telnet_cmd_ayt {sok argv} {
    puts -nonewline $sok {[Yes]}
    flush $sok
}


proc telnet_cmd_nop {args} {
    # Does nothing.
}


proc telnet_cmd_eor {sok argv} {
    global treb_partial_line
    append treb_partial_line($sok) "\n"
}


proc telnet_opt_starttls {sok request} {
    if {$request == "DO"} {
        
        set world [/socket:world $sok]
        if {[info commands tls::init] != {}
            && !$telnetInfo(sok-$sok-notls)
            && ![/world:get secure $world]
        } {
            telnet_send $sok "IAC WILL STARTTLS"
            telnet_option_enable "STARTTLS" $sok "in" 1
            telnet_option_enable "STARTTLS" $sok "out" 1
            telnet_proceed_slowly $sok 1
            tls_status_set $sok "wait"
        } else {
            telnet_send $sok "IAC WONT STARTTLS"
            telnet_option_enable "STARTTLS" $sok "in" 0
            telnet_option_enable "STARTTLS" $sok "out" 0
            tls_status_set $sok ""
        }
    }
}

proc telnet_subneg_starttls {sok data} {
    set FOLLOWS "\001" ;# TLS encrypted data Follows

    set world [/socket:world $sok]
    if {$data == $FOLLOWS &&
        [info commands tls::init] != "" &&
        ![/world:get secure $world]
    } {
        /statbar 30 "Negotiating SSL for $world..."
        update idletasks

        telnet_send $sok "IAC SB STARTTLS"
        puts -nonewline $sok $FOLLOWS
        telnet_send $sok "IAC SE"
        flush $sok

        tls_startup $sok $world
        telnet_proceed_slowly $sok -1

        # TODO: If SSL negotiation fails, resume raw telnet.
        #       (Works already?)
    }
}


proc telnet_opt_termtype {sok request} {
    switch -exact -- $request {
        "DO" {
            telnet_send $sok "IAC WILL TERMTYPE"
            telnet_option_enable "TERMTYPE" $sok "out" 1
        }
        "DONT" {
            telnet_send $sok "IAC WONT TERMTYPE"
            telnet_option_enable "TERMTYPE" $sok "out" 0
        }
    }
}


proc telnet_subneg_termtype {sok data} {
    global treb_name

    set IS "\000"
    set SEND "\001"

    if {$data == $SEND} {
        /statbar 5 "Telnet: Sent terminal type..."

        telnet_send $sok "IAC SB TERMTYPE"
        puts -nonewline $sok $IS
        puts -nonewline $sok "$treb_name"
        telnet_send $sok "IAC SE"
        flush $sok
    }
}


proc telnet_opt_linemode {sok request} {
    switch -exact -- $request {
        "DO" {
            # Some MUSHes send IAC DO LINEMODE, but they can't deal with
            # The required IAC WILL LINEMODE reply!  So we won't send it.
            #telnet_send $sok "IAC WILL LINEMODE"
            telnet_option_enable "LINEMODE" $sok "out" 1
        }
        "DONT" {
            telnet_send $sok "IAC WONT LINEMODE"
            telnet_option_enable "LINEMODE" $sok "out" 0
        }
        "WILL" {
            # Not highly useful, but eh, why not?
            telnet_send $sok "IAC DO LINEMODE"
            telnet_option_enable "LINEMODE" $sok "in" 1
        }
        "WONT" {
            telnet_option_enable "LINEMODE" $sok "in" 0
        }
    }
}


proc telnet_opt_eor {sok request} {
    switch -exact -- $request {
        "DO" {
            telnet_send $sok "IAC WONT EOR"
        }
        "DONT" {
            telnet_send $sok "IAC WONT EOR"
        }
        "WILL" {
            telnet_send $sok "IAC DO EOR"
            telnet_option_enable "EOR" $sok "in" 1
        }
        "WONT" {
            telnet_option_enable "EOR" $sok "in" 0
        }
    }
}


proc telnet_opt_naws {sok request} {
    if {$request == "DO"} {
        telnet_send $sok "IAC WILL NAWS"
        telnet_option_enable "NAWS" $sok "out" 1
        telnet_send_naws $sok
    } elseif {$request == "DONT"} {
        telnet_send $sok "IAC WONT NAWS"
        telnet_option_enable "NAWS" $sok "out" 0
    }
}


proc telnet_send_naws {{tosock ""}} {
    foreach {cols rows} [get_display_size] break;

    if {($cols%256) == 255} {
        set ecols [binary format c [expr {$cols>>8}]]
        append ecols "\377\377"
    } else {
        set ecols [binary format S $cols]
    }

    if {($rows%256) == 255} {
        set erows [binary format c [expr {$rows>>8}]]
        append erows "\377\377"
    } else {
        set erows [binary format S $rows]
    }

    foreach sok [/socket:connectednames] {
        if {$tosock == "" || $sok == $tosock} {
            if {[telnet_option_is_enabled "NAWS" $sok "out"]} {
                telnet_send $sok "IAC SB NAWS"
                puts -nonewline $sok "$ecols$erows"
                telnet_send $sok "IAC SE"
            }
        }
    }
}


proc telnet_partial_line_get {sok} {
    upvar #0 treb_partial_line($sok) partline
    return $partline
}


proc telnet_partial_line_set {sok data} {
    global treb_partial_line
    regsub -all -- "\r" $data "" data
    set treb_partial_line($sok) $data
}


proc telnet_partial_line_append {sok data} {
    upvar #0 treb_partial_line($sok) partline
    regsub -all -- "\r" $data "" data
    append partline $data
}


proc telnet_wants_single_chars {sok} {
    global telnetInfo
    return [expr {$telnetInfo(sok-$sok-slow) > 0}]
}


proc telnet_proceed_slowly {sok incdec} {
    global telnetInfo
    incr telnetInfo(sok-$sok-slow) $incdec
}


# States:
#  state == "" with SBopt == ""        raw data.
#  state == "" with SBopt != ""        SB subnegotiation data.  SBopt = option.
#  state == "IAC"                      IAC was received.
#  state == other                      Command received.  argc = args left.
proc telnet_process {sok newdata} {
    global telnetInfo

    set IAC "\377" ;# Telnet escape character

    upvar #0 telnetInfo(sok-$sok-state) state
    upvar #0 telnetInfo(sok-$sok-SBopt) SBopt
    upvar #0 telnetInfo(sok-$sok-SBdata) SBdata
    upvar #0 telnetInfo(sok-$sok-argc) argc
    upvar #0 telnetInfo(sok-$sok-argv) argv

    while {$newdata != ""} {
        if {$state == ""} {
            if {$SBopt != ""} {
                set pos [string first $IAC $newdata]
                if {$pos == -1} {
                    append SBdata $newdata
                    set newdata ""
                    break
                }
                append SBdata [string range $newdata 0 [incr pos -1]]
                set newdata [string range $newdata [incr pos 2] end]
                set state "IAC"
                telnet_debug_echo $sok $IAC
            } else {
                set pos [string first $IAC $newdata]
                if {$pos == -1} {
                    telnet_partial_line_append $sok $newdata
                    set newdata ""
                    break
                }
                telnet_partial_line_append $sok [string range $newdata 0 [incr pos -1]]
                set newdata [string range $newdata [incr pos 2] end]
                set state "IAC"
                telnet_debug_echo $sok $IAC
            }
            continue
        } else {
            set arg [string index $newdata 0]
            set newdata [string range $newdata 1 end]
            telnet_debug_echo $sok $arg
            if {$state == "IAC"} {
                # Received IAC-Cmd
                set opt [telnet_command_name $arg]
                set argc [telnet_command_argcount $opt]
                set argv ""
                set state $opt
            } else {
                # Received IAC-Cmd arg
                append argv $arg
                incr argc -1
            }
            if {$argc == 0} {
                set opt $state
                set data $argv
                set state ""
                set argv ""
                telnet_command_call $opt $sok $data
            }
        }
    }

    return
}

telnet_init


