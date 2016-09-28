global currentworld; set currentworld ""
global socket_previous_keepalive_time;  set socket_previous_keepalive_time 0
global treb_icon_should_bounce; set treb_icon_should_bounce 0
global last_ping_cmd_index

proc /socket {opt args} {
    dispatcher /socket $opt $args
}


tcl::OptProc /socket:log {
    {-html   -boolean 0 "If true, log in HTML format."}
    {-dated  -boolean 0 "If true, process file name as by [clock format] or strftime()."}
    {-scrollback -int 0 "If given, log last N lines of scrollback first."}
    {world              "The world that the logging takes place in."}
    {file               "Specify the file to log to, or \"\" to stop logging."}
} {
    global widget
    set oldfd [/socket:get logfd $world]
    if {$oldfd != ""} {
        set oldhtml [/socket:get loghtml $world]
        if {$oldhtml} {
            puts -nonewline $oldfd "</p></body></html>"
        }
        close $oldfd
        /socket:set logfd $world ""
        /socket:set logfile $world ""
        /socket:set loghtml $world 0
    }
    if {$file == "" } {
        /socket:set logfd $world ""
        /socket:set logfile $world ""
        /socket:set loghtml $world 0
        $widget(loglight) config -text {}
    } else {
        set preexisting [file exists $file]
        if {$dated} {
            set dfile [clock format [clock seconds] -format $file]
        } else {
            set dfile $file
        }
        if {$html} {
            set f [log:html_open_append $dfile]
        } else {
            set dir [file dirname $dfile]
            if {![file isdirectory $dir]} {
                error "That directory doesn't exist."
            }
            if {![file writable $dir]} {
                error "Cannot create file, because you do not have write permissions for that directory."
            }
            set f [open $dfile "a+" 0600]
        }
        /socket:set logfd    $world $f
        /socket:set logfile  $world $dfile
        /socket:set loghtml  $world $html
        $widget(loglight) config -text {LOG}
        if {$html} {
            if {$preexisting} {
                puts -nonewline $f "\n<p>"
            } else {
                puts $f [log:html_header $world]
            }
            if {$scrollback} {
                puts $f [log:dump_scrollback_html $world "end-${scrollback}lines" end]
            }
        } else {
            if {$scrollback} {
                set disp [/display $world]
                puts $f [$disp get "end-${scrollback}lines" end]
            }
        }
    }
    return ""
}


proc /socket:open {world} {
    /socket:connect $world
}


proc /socket:connect {world {notls 0}} {
    global socketsreverse
    global sockets

    set host [/world:get host $world]
    set port [/world:get port $world]

    set disp ""
    if {[/socket:exists $world]} {
        set disp [/socket:get display $world]
        switch -exact -- [/socket:get state $world] {
            Connecting   {/socket:disconnect $world ; display:select $disp}
            Connected    {display:select $disp ; return}
            Disconnected {display:select $disp}
        }
    }
    /statbar 0 "Finding host for $world... ($host)"
    if {[/world:get socks $world] != 0 && [/prefs:get socks_host] != "" && [/prefs:get socks_port] != 0} {
        set use_proxy 1
        set realhost [/prefs:get socks_host]
        set realport [/prefs:get socks_port]
    } else {
        set use_proxy 0
        set realhost $host
        set realport $port
    }
    if {[catch {set sok [socket -async "$realhost" "$realport"]} errMsg]} {
        if {$use_proxy} {
            /statbar 10 "Connection to the SOCKS 5 proxy failed."
        } else {
            /statbar 10 "Connection to $world failed."
        }
        if {[string match "*invalid argument*" $errMsg]} {
            set errMsg "Host not found."
        }
        error "/world:connect: $errMsg"
    } else {
        /statbar 0 "Connecting to $world..."
        if {$disp == ""} {
            set disp [display:add "$world"]
        }
        set sockets($world) [list $disp $sok "Connecting" "" "" 0 1.0 0]
        set socketsreverse($disp) $world
        /style:initdisplay [/display $world]
        /socket:setlight $world yellow
        global treb_have_logged_in
        catch {unset treb_have_logged_in($sok)}
        if {$use_proxy} {
            fileevent $sok writable "proxyconnect $sok [list $world] $notls"
        } else {
            fileevent $sok writable "directconnect $sok [list $world] $notls"
        }
    }
    return $world
}


proc /socket:disconnect {{world ""}} {
    global sockets
    if {$world == ""} {
        set world [/socket:current]
        if {$world == ""} {
            return
        }
    }
    if {[/socket:exists $world]} {
        set logfd [/socket:get logfd $world]
        if {$logfd != ""} {
            /socket:log $world ""
        }
        if {[/socket:get state $world] == "Disconnected"} {
            return
        }
        /socket:writeln $world "Connection Closed" error
        catch { fileevent [/socket:get socket $world] readable "" }
        catch { fileevent [/socket:get socket $world] writable "" }
        catch { close [/socket:get socket $world] }
        /socket:set socket $world ""
        /socket:set state $world "Disconnected"
        /socket:setlight $world red
        mcp_reset_world $world
        /statbar 5 "Connection to $world was closed."
        return ""
    } else {
        error "/socket disconnect: No such socket!"
    }
}


proc /socket:close {{world ""}} {
    global sockets socketsreverse
    if {$world == ""} {
        set world [/socket:current]
    }
    if {[info exists sockets($world)]} {
        msp_forget $world
        fb_images_forget $world
        /socket:disconnect $world
        set disp [/socket:get display $world]
        unset socketsreverse($disp)
        catch {unset last_ping_cmd_index($world)}
        unset sockets($world)
        display:delete $disp
        return ""
    } else {
        error "/socket close: No such socket!"
    }
}


proc /socket:setlight {world color} {
    display:setlight [/socket:get display $world] $color
    return
}


proc /socket:get {opt world} {
    global sockets
    if {$world == ""} {
        return ""
    }
    switch -exact -- $opt {
        world   -
        name     {return $name}
        display  {return [lindex $sockets($world) 0]}
        socket   {return [lindex $sockets($world) 1]}
        state    {return [lindex $sockets($world) 2]}
        logfd    {return [lindex $sockets($world) 3]}
        logfile  {return [lindex $sockets($world) 4]}
        activity {return [lindex $sockets($world) 5]}
        pageridx {return [lindex $sockets($world) 6]}
        loghtml  {return [lindex $sockets($world) 7]}
        default  {
            error "/socket get: Unknown member \"$opt\" should be one of name, display, socket, state, logfd, logfile, loghtml, activity, or pageridx."
        }
    }
}


proc /socket:set {opt world value} {
    global sockets
    switch -exact -- $opt {
        world   -
        name     {error "/socket set: can't rename the socket."}
        display  {set sockets($world) [lreplace $sockets($world) 0 0 $value]}
        socket   {set sockets($world) [lreplace $sockets($world) 1 1 $value]}
        state    {set sockets($world) [lreplace $sockets($world) 2 2 $value]}
        logfd    {set sockets($world) [lreplace $sockets($world) 3 3 $value]}
        logfile  {set sockets($world) [lreplace $sockets($world) 4 4 $value]}
        activity {set sockets($world) [lreplace $sockets($world) 5 5 $value]}
        pageridx {set sockets($world) [lreplace $sockets($world) 6 6 $value]}
        loghtml  {set sockets($world) [lreplace $sockets($world) 7 7 $value]}
        default  {
            error "/socket set: Unknown member \"$opt\" should be one of name, display, socket, state, logfd, logfile, loghtml, activity, or pageridx."
        }
    }
}

proc /socket:names {{pattern *}} {
    global sockets
    return [array names sockets $pattern]
}


proc /socket:world {sok} {
    foreach world [/socket:names] {
        if {[/socket:get socket $world] == $sok} {
            return $world
        }
    }
    return ""
}


proc /socket:connectednames {{pattern *}} {
    set socks [/socket:names $pattern]
    set oot {}
    foreach world $socks {
        if {[/socket:get state $world] == "Connected"} {
            lappend oot $world
        }
    }
    return $oot
}


proc /socket:foreground {} {
    global socketsreverse
    set disp [display:current]
    if {[info exists socketsreverse($disp)]} {
        return $socketsreverse($disp)
    } else {
        return ""
    }
}


proc /socket:setforeground {} {
    global currentworld

    set currentworld [/socket:foreground]
}


proc /socket:current {} {
    global currentworld
    global sockets
    if {[info exists sockets($currentworld)]} {
        return $currentworld
    } else {
        return ""
    }
}


proc /socket:setcurrent {world} {
    global currentworld
    global sockets

    if {[info exists sockets($world)]} {
        set currentworld $world
    } else {
        set currentworld ""
    }
}


proc /socket:prev {} {
    display:prev
    if {[display:at_end [/display]]} {
        /socket:set activity [/socket:current] 0
    }
    return
}


proc /socket:next {} {
    display:next
    if {[display:at_end [/display]]} {
        /socket:set activity [/socket:current] 0
    }
    return
}


proc /socket:exists {name} {
    global sockets
    return [info exists sockets($name)]
}


proc /socket:sendln {world text} {
    mcp_output_inband $world $text
}


proc /socket:sendln_raw {world text} {
    if {[/socket:exists $world]} {
	set encoding [/world:get encoding $world]
	if {$encoding == "identity"} {
	    set encoding "utf-8"
	}
	set text [encoding convertto $encoding $text]

        # Make sure to escape all IACs for telnet support.
        regsub -all -- "\377" $text "\377\377" outtext
        catch { puts [/socket:get socket $world] "$outtext" } errMsg
    }
    return ""
}


proc socket:send_keepalives {} {
    global socket_previous_keepalive_time last_ping_cmd_index

    if {[clock seconds] > $socket_previous_keepalive_time + [/prefs:get keepalive_delay]} {
        foreach world [/socket:names] {
            if {[/socket:get state $world] == "Connected"} {
                set ping_command [/world:get pingcmd $world]
                set sok [/socket:get socket $world]
                catch {
                    flush $sok
                    set bufstate [fconfigure $sok -buffering]
                    fconfigure $sok -buffering none
                    if {$ping_command == ""} {
                        if {[/world:get keepalive $world]} {
                            # Send Telnet NOP.  Servers that don't grok Telnet NOP
                            # should strip high bit characters anyways.  I hope.
                            puts -nonewline $sok "\377\361"
                        }
                    } else {
                        # Send the ping command.
                        if {[string first "|" $ping_command]} {
                            set cmd_list [split $ping_command "|"]
                            if {![info exists last_ping_cmd_index($world)]} {
                                set last_ping_cmd_index($world) -1
                            }
                            set last_ping_cmd_index($world) [expr $last_ping_cmd_index($world) + 1]
                            if {$last_ping_cmd_index($world) >= [llength $cmd_list]} {
                                set last_ping_cmd_index($world) 0
                            }
                            set ping_command [lindex $cmd_list $last_ping_cmd_index($world)]
                        }
                        puts $sok $ping_command
                    }
                    flush $sok
                    fconfigure $sok -buffering $bufstate
                } errMsg
            }
        }
        set socket_previous_keepalive_time [clock seconds]
    }
}


proc socket:comptags {a b} {
    set major [expr {[lindex $a 0] - [lindex $b 0]}]
    if {$major != 0} {
        return $major
    }
    return [expr {[lindex $b 1] - [lindex $a 1]}]
}


proc /socket:write {world text {tagspans {}} {partial 0}} {
    global treb_icon_should_bounce
    if {![/socket:exists $world]} {
        set world ""
    } else {
        set havefocus 1
        if {[wm state .mw] == "iconic" || ![string match ".mw*" [focus -displayof .mw]]} {
            set havefocus 0
        }
        if {[/socket:foreground] == $world && $havefocus} {
            /socket:set activity $world 0
        } else {
            /socket:set activity $world 1
            set treb_icon_should_bounce 1
        }
    }
    set disp [/display $world]

    if {[llength [lindex $tagspans 0]] == 1} {
        foreach tag $tagspans {
            lappend tmptagspans [list 0 "end" $tag]
        }
        set tagspans $tmptagspans
    }
    if {![display:write $disp $text $tagspans]} {
        if {![display:at_end $disp]} {
            if {[/socket:exists $world]} {
                /socket:set activity $world 1
                set treb_icon_should_bounce 1
            }
        }
    }
    if {!$partial} {
        log:write_line $world $text $tagspans
    }
    return ""
}


proc /socket:writeln {world text {tagspans {}}} {
    /socket:write $world "\n" normal
    /socket:write $world "$text" $tagspans
    return ""
}


proc /socket:writeln_norefresh {world text {tagspans {}} {partial 0}} {
    /socket:write $world "\n" normal $partial
    /socket:write $world "$text" $tagspans $partial
    return ""
}


global socket_blinkenlight_flag
set socket_blinkenlight_flag 0

proc socket:blink_lights {} {
    global socket_blinkenlight_flag tcl_platform
    global treb_icon_should_bounce
    if {$socket_blinkenlight_flag} {
        set socket_blinkenlight_flag 0
    } else {
        set socket_blinkenlight_flag 1
    }

    set isbg 0
    if {[wm state .mw] == "iconic"} {
        set isbg 1
    }
    if {![string match ".mw*" [focus -displayof .mw]]} {
        set isbg 1
    }

    set needsnotify 0
    foreach sock [/socket:names] {
        if {!$isbg && $sock == [/socket:foreground]} {
            if {[display:at_end]} {
                /socket:set activity $sock 0
            }
        }
        switch -glob -- [/socket:get state $sock] {
            Connecting   {set color yellow}
            Connected    {set color green}
            Disconnected {set color red}
            default      {set color gray}
        }
        if {[/socket:get activity $sock]} {
            set needsnotify 1
            if {$socket_blinkenlight_flag} {
                set color gray
            }
        }
        /socket:setlight $sock $color
    }

    set titleflash 0
    if {$tcl_platform(winsys) != "aqua"} {
        if {[/prefs:get activity_flash_title]} {
            set titleflash $needsnotify
        }
    }

    set curr [/socket:foreground]
    if {$curr == ""} {
        if {[wm title .mw] != "Trebuchet Tk"} {
            wm title .mw "Trebuchet Tk"
        }
    } elseif {$titleflash && $socket_blinkenlight_flag && $isbg} {
        wm title .mw "$curr - Active"
    } elseif {[wm title .mw] != "$curr - TrebTk"} {
        wm title .mw "$curr - TrebTk"
    }

    if {!$isbg} {
        set treb_icon_should_bounce 0
    }
    if {$tcl_platform(winsys) == "aqua"} {
        if {![/prefs:get activity_notify]} {
            set treb_icon_should_bounce 0
        }
        catch {wm attributes .mw -notify $treb_icon_should_bounce}
    }
}


proc /socket:update_indicators {} {
    global widget
    set world [/socket:foreground]
    if {$world != ""} {
        set logfd [/socket:get logfile $world]
        if {$logfd == "" } {
            $widget(loglight) config -text {}
        } else {
            $widget(loglight) config -text {LOG}
        }
        update_secure_indicator
        /socket:set activity $world 0
    } else {
        $widget(loglight) config -text {}
    }
}


