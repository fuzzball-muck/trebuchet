proc remote:getdata {sock} {
    global tmp_world
    if {[eof $sock]} {
        fileevent $sock readable {}
        close $sock
    } else {
        set data ""
        catch { append data [read -nonewline $sock] }
        set host [fconfigure $sock -sockname]
        set peer [fconfigure $sock -peername]
        if {$data != ""} {
            set cmd [lindex [string trim $data] 0]
            switch -exact -- $cmd {
                "connect" {
                    if {[lindex $peer 0] != [lindex $host 0]} {
                        puts $sock "ERR:000 Permission Denied."
                        flush $sock
                        close $sock
                        return
                    }
                    regsub -all ":" $data " " data
                    set parameters [split [string trim $data]]
                    if {[llength $parameters] == 3} {
                        /world:add World.[incr tmp_world] [lindex $parameters 1] [lindex $parameters 2] -temp 1
                        /world:connect World.$tmp_world
                        catch { raise .mw }
                    } else {
                        puts $sock "ERR:002 Bad command argument format."
                        flush $sock
                        close $sock
                        tk_messageBox -type ok -icon error -title "Remote command error" \
                            -message "Bad parameter for --connect command."
                        return
                    }
                }
                default {
                    puts $sock "ERR:001 Bad command."
                    flush $sock
                    close $sock
                    return
                }
            }
        }
    }
}

proc remote:connect {sock host port} {
    fconfigure $sock -blocking 0
    fileevent $sock readable [list remote:getdata $sock]
}

proc remote:init {argc argv} {
    global env tmp_world tcl_platform
    set tmp_world 0
    set remote_port 0
    if {[info exists env(TREB_REMOTE_PORT)]} {
        set remote_port $env(TREB_REMOTE_PORT)
    }
    if {$remote_port <= 1024 || $remote_port > 65535} {
        set remote_port 38888
    }
    if {[catch {socket -server remote:connect $remote_port }]} {
        set remote_server 0
    } else {
        set remote_server 1
    }
    if {$tcl_platform(platform) == "windows"} {
        # Windows Tk usually has broken argv splitting.
        set argv [split [string trim [join $argv]]]
        set argc [llength $argv]
    }
    set index [lsearch -exact $argv "--connect"]
    if {$index >= 0 && $index < $argc - 1} {
        set address [lindex $argv [incr index]]
        set port [lindex $argv [incr index]]
        set sock [socket -async localhost $remote_port]
        fconfigure $sock -blocking 0
        if {[catch { puts $sock "connect $address $port" } err]} {
            # Expect it to wrongly report a failure under Windoze.
            # This isn't strictly clean, as sometimes windows may
            # actually HAVE a failure.
            if {$tcl_platform(platform) != "windows"} {
                tk_messageBox -type ok -icon error -title "Connect command error" \
                    -message "Error while sending a connect command to Trebuchet: $err"
            }
        }
        close $sock
        if {!$remote_server} {
            exit
        }
    } elseif {$index != -1} {
        tk_messageBox -type ok -icon error -title "Connect command error" \
            -message "Bad parameter for --connect command."
        exit
    }
}
