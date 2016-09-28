###########################
##  AWNS Ping Interface  ##
############################################################################
##
##
############################################################################

global PingInfo


proc awns_ping_init {world vers} {
    set pkg "dns-com-awns-ping"
    /menu:add "Local|Ping..." -command "/ping" -statecommand "ping:state"
}


proc awns_ping {world data} {
    set pkg "dns-com-awns-ping"

    array set arr $data
    setfrom id arr(id) {}

    /mcp_send $pkg "reply" -world $world id $id

    return
}


proc /ping {{world ""}} {
    global PingInfo

    set pkg "dns-com-awns-ping"
    if {$world == ""} {
        set world [/socket:foreground]
    }
    if {![/world:exists $world]} {
        return
    }
    if {[mcp_remote_pkg_supported $world $pkg] == ""} {
        return
    }

    while {1} {
        set    id [format "%04X" [expr {int(0x10000 * rand())}]]
        append id [format "%04X" [expr {int(0x10000 * rand())}]]
        if {![info exists PingInfo(starttime,$id)]} {
            break
        }
    }

    set PingInfo(starttime,$id) [/clock_clicks]

    /mcp_send $pkg "" -world $world id $id
}


proc awns_ping_reply {world data} {
    global PingInfo clicks_per_second

    set pkg "dns-com-awns-ping"

    array set arr $data
    setfrom id arr(id) {}

    if {[info exists PingInfo(starttime,$id)]} {
        set latency [expr {([/clock_clicks] - $PingInfo(starttime,$id)) * 1000 / $clicks_per_second}]
        unset PingInfo(starttime,$id)
        tk_messageBox -type ok -title "Ping $world" -message "Response time: $latency ms."
    }
    return
}

proc ping:state {} {
    set world [/socket:foreground]
    set pingpkg "dns-com-awns-ping"
    if {$world != ""} {
        if {[/socket:get state $world] != "Disconnected"} {
            if {[mcp_remote_pkg_supported $world $pingpkg] != ""} {
                return "normal"
            }
        }
    }
    return "disabled"
}


mcp_register_pkg "dns-com-awns-ping" 1.0 1.0 awns_ping_init
mcp_register_handler "dns-com-awns-ping" "" awns_ping
mcp_register_handler "dns-com-awns-ping" "reply" awns_ping_reply



proc awns_status {world data} {
    array set arr $data
    setfrom txt arr(text) {}

    /statbar 10 "$world - $txt"

    return
}


mcp_register_pkg "dns-com-awns-status" 1.0 1.0
mcp_register_handler "dns-com-awns-status" "" awns_status


global MSPurls
global MSPentries

proc msp_stop {world type} {
    global MSPentries
    catch {$type.$world destroy}
    catch {unset MSPentries($world,$type,name)}
    catch {unset MSPentries($world,$type,priority)}
    catch {unset MSPentries($world,$type,repeats)}
}

proc msp_forget {world} {
    global MSPurls
    catch {unset MSPurls($world)}
    msp_stop $world "sound"
    msp_stop $world "music"
}

proc msp_repeat {world type} {
    global MSPentries
    if {[catch {set repeats $MSPentries($world,$type,repeats)}]} {
        return
    }
    if {$repeats != 0} {
        if {$repeats > 0} {
            set repeats [expr $repeats - 1]
        }
        set MSPentries($world,$type,repeats) $repeats
        if {[catch {$type.$world play -blocking 0 -command "msp_repeat [list $world] $type"}]} {
            msp_stop $world $type
        }
    } else {
        msp_stop $world $type
    }
}

proc msp_play_it {world type url play_command status file} {
    global dirty_preferences tcl_platform MSPentries
    if {$status == "ok"} {
        if {[info commands snack::sound] == {}} {
            regsub -all {%f} $play_command "{$file}" full_command
            if {[catch {eval "exec $full_command &"} result]} {
                /socket:write $world "\nError playing sound: $result\n"
            } else {
                if {[/prefs:get msp_sound_cmd] == ""} {
                    if {$tcl_platform(platform) == "windows"} {
                        regsub -all {\\} $play_command {\\\\} play_command
                    }
                    /prefs:set msp_sound_cmd $play_command
                    set dirty_preferences 1
                }
            }
        } else {
            # Check that there is no race condition...
            if {$MSPentries($world,$type,name) == $url} {
                snack::sound $type.$world -file $file
                msp_repeat $world $type
            }
	}
    } else {
        /socket:write $world "\nError loading sound $url: $status\n"
    }
}

proc windows:soundcmd {} {
    package require registry 1.0
    set ext ".wav"

    set key "HKEY_CLASSES_ROOT\\$ext"
    set appkey [registry get $key ""]
    if {$appkey == ""} {
        return ""
    }

    set key "HKEY_CLASSES_ROOT\\$appkey\\shell\\open\\command"
    set appcmd [registry get $key ""]
    if {$appcmd == ""} {
        return ""
    }

    regsub -all { \"%1\"} $appcmd {} appcmd
    regsub -all {^\"} $appcmd "{" appcmd
    regsub -all {\"$} $appcmd "}" appcmd
    regsub -all {\\} $appcmd {\\\\} appcmd

    return $appcmd
}

proc msp_play {world type data} {
    global tcl_platform treb_lib_dir MSPurls MSPentries
    set pkg "dns-com-zuggsoft-msp"

    array set arr $data
    setfrom name arr(name) {}
    setfrom url  arr(u) {}
    if {$url != "" && $name != ""} {
        if {[string index $url end] != "/"} {
            append url "/"
        }
    }
    if {![info exists MSPurls($world)]} {
        set MSPurls($world) ""
    }
    if {$url == ""} {
        set file [file join $treb_lib_dir "sounds" $name]
        if {![file exists $file]} {
	    set file ""
	}
    } else {
        set file ""
        set MSPurls($world) $url
    }
    set url $MSPurls($world)
    append url $name
    setfrom volume   arr(v) "100"
    setfrom repeats  arr(l) "1"
    setfrom priority arr(p) "50"
    setfrom cont     arr(c) "0"

    if {[info commands snack::sound] == {}} {

        # Life without snack is a bit more difficult... The MSP implementation
        # is a bit looser... No repeats, no "Off" command... unless the user
        # can manage to find a player accepting this kind of parameters itself.
        set play_command [/prefs:get msp_sound_cmd]
        if {$play_command == ""} {
            switch -exact $tcl_platform(platform) {
                windows {
                    set play_command [windows:soundcmd]
                    if {$play_command != ""} {
                        append play_command " /minimized /close /play %f"
                    }
                }
                mac {
	            # I -think- this is correct, as Tcl is documented as missing an
                    # "exec" command on old Macintosh platforms...
                    return
                }
                default {
                    # The sox "play" command is available for UNICES and MacOS-X...
                    if {![catch {eval "exec play -h"}]} {
                        set play_command "play %f"
                    }
                }
            }
        }
 
        if {$play_command == ""} {
            /socket:write $world "\nError playing sound: Can't find a player.\n"
            return
        }
 
        regsub -all {%v} $play_command $volume   play_command
        regsub -all {%l} $play_command $repeats  play_command
        regsub -all {%p} $play_command $priority play_command
        regsub -all {%c} $play_command $cont     play_command

    } else {

        # Snack is installed, so let's use it...
        if {$name == "Off"} {
        	msp_stop $world $type
                return
        }
        if {$file == ""} {
            set name $url
        } else {
            set name $file
        }
        if {$type == "sound"} {
            if {[info exists MSPentries($world,sound,priority)]} {
                if {$priority <= $MSPentries($world,sound,priority)} {
	            return
                }
	    }
	} else {
            if {[info exists MSPentries($world,music,name)]} {
                if {$MSPentries($world,music,name) == $name} {
                    if {$cont == 1} {
                        set MSPentries($world,music,repeats) $repeats
                        return
                    }
                }
            }
        }
        msp_stop $world $type
        set MSPentries($world,$type,name) $name
        set MSPentries($world,$type,priority) $priority
        set MSPentries($world,$type,repeats) $repeats
        set play_command ""
    }

    if {$file == ""} {
        after 50 "
            /webcache:fetch [list $url] -quiet -byfile -command \"msp_play_it [list $world] $type [list $url] [list $play_command]\"
        "
    } else {
        msp_play_it $world $type $file $play_command "ok" $file
    }
}

proc msp_play_sound {world data} {
    if {[/prefs:get enable_msp_sounds]} {
        msp_play $world "sound" $data
    }
}

proc msp_play_music {world data} {
    if {[/prefs:get enable_msp_sounds]} {
        msp_play $world "music" $data
    }
}

mcp_register_pkg "dns-com-zuggsoft-msp" 1.0 1.0
mcp_register_handler "dns-com-zuggsoft-msp" "sound" msp_play_sound
mcp_register_handler "dns-com-zuggsoft-msp" "music" msp_play_music


tcl::OptProc /fbhelp {
    {-world    {}     "The world to get help from."}
    {-type     {man}  "The type of help to get. (help, man, mpi, news)"}
    {topic     {}     "The topic to get help on."}
} {
    set pkg "org-fuzzball-help"

    if {$world == {}} {
        set world [/socket:current]
    }
    /mcp_send $pkg "request" -world $world type $type topic $topic
}


proc fb_help_entry {world data} {
    set pkg "org-fuzzball-help"

    array set arr $data
    setfrom topic arr(topic) {}
    setfrom textval arr(text) {}

    if {[string first "-" $textval] == 0} {
        set textval "\n$textval"
    }
    /results -world $world -title "FuzzBall Help - $topic" -- $textval
    return
}

mcp_register_pkg "org-fuzzball-help" 1.0 1.0
mcp_register_handler "org-fuzzball-help" "entry" fb_help_entry
mcp_register_handler "org-fuzzball-help" "error" fb_help_entry



global LocalMenuInfo

proc fb_localmenu_enabled {name} {
    global LocalMenuInfo
    set world [/socket:foreground]
    regsub -all -nocase {[^A-Z_0-9|]} [string tolower $name] {} iname
    if {[info exists LocalMenuInfo(menuitem-$world-$iname)]} {
        return "normal"
    } else {
        return "disabled"
    }
}

proc fb_localmenu_report {world label id} {
    set pkg "org-fuzzball-localmenu"
    /mcp_send $pkg "selected" -world $world label $label id $id
}

proc fb_localmenu_add {world data} {
    global LocalMenuInfo
    set pkg "org-fuzzball-localmenu"

    array set arr $data
    setfrom itemtype  arr(type)  {}
    setfrom itemlabel arr(label) {}
    setfrom id        arr(id)    {}

    /menu:add "&Local|$itemlabel" -command "fb_localmenu_report [list $world] [list $itemlabel] [list $id]" -statecommand "fb_localmenu_enabled [list $itemlabel]"
    regsub -all -nocase {[^A-Z_0-9|]} [string tolower $itemlabel] {} iname
    unset LocalMenuInfo(menuitem-$world-$iname)
    return
}

proc fb_localmenu_del {world data} {
    global LocalMenuInfo
    set pkg "org-fuzzball-localmenu"

    array set arr $data
    setfrom itemlabel arr(label) {}
    setfrom id        arr(id)    {}

    /menu:del "&Local|$itemlabel"
    regsub -all -nocase {[^A-Z_0-9|]} [string tolower $itemlabel] {} iname
    set LocalMenuInfo(menuitem-$world-$iname) 1
    return
}

mcp_register_pkg "org-fuzzball-localmenu" 1.0 1.0
mcp_register_handler "org-fuzzball-localmenu" "add" fb_localmenu_add
mcp_register_handler "org-fuzzball-localmenu" "del" fb_localmenu_del


global McpLoadedImages

proc fb_image_loaded {world destimg url status file} {
    global McpLoadedImages
    if {[catch {image width $destimg}]} {
        return
    }
    if {$status == "ok"} {
        set disp [/display $world]
        set tmpimg [image create photo]
        if {[catch {$tmpimg configure -file $file} result]} {
            image delete $destimg $tmpimg
            /socket:write $world "\nError loading image $url: $result\n"
            return
        }
        set img_width [image width $tmpimg]
        set img_height [image height $tmpimg]
        set max_width [winfo width $disp]
        set max_height [winfo height $disp]
        set ratio 1
        while {[expr $img_width / $ratio] > $max_width} {
            set ratio [expr $ratio + 1]
        }
        while {[expr $img_height / $ratio] > $max_height} {
            set ratio [expr $ratio + 1]
        }
        $destimg copy $tmpimg -shrink -subsample $ratio
        image delete $tmpimg
        /socket:write $world "\n"
        if {[info exists McpLoadedImages($world)]} {
            lappend McpLoadedImages($world) $destimg
        } else {
            set McpLoadedImages($world) $destimg
        }
    } else {
        image delete $destimg
        /socket:write $world "Error loading $url: $status\n"
    }
}

proc fb_image_loading {destimg total current} {
    if {[catch {image width $destimg}] || $total == 0} {
        return
    }
    set width [image width image_loading]
    set height [image height image_loading]
    set pixels [expr $width * $current / $total]
    $destimg copy image_loading_back -to 0 0 $pixels $height
}

proc fb_image_load {world data} {
    global treb_lib_dir
    set pkg "org-fuzzball-loadimage"
    array set arr $data
    setfrom url arr(value) {}

    if {[info commands image_loading] == {}} {
        image create photo image_loading -file [file join $treb_lib_dir images/loading.gif]
        image create photo image_loading_back -file [file join $treb_lib_dir images/loadback.gif]
    }

    set disp [/display $world]
    set img [image create photo]
    /socket:write $world "\n"
    $disp image create end -image $img
    $img copy image_loading
    after 50 "
        /webcache:fetch [list $url] -quiet -byfile -command \"fb_image_loaded [list $world] [list $img] [list $url]\" -progress \"fb_image_loading [list $img]\"
    "
}

proc fb_images_forget {world} {
    global McpLoadedImages
    if {[info exists McpLoadedImages($world)]} {
        foreach img $McpLoadedImages($world) {
            image delete $img
        }
        unset McpLoadedImages($world)
    }
}

mcp_register_pkg "org-fuzzball-loadimage" 1.0 1.0
mcp_register_handler "org-fuzzball-loadimage" "" fb_image_load
