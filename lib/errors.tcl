proc estimate_text_size {text} {
    set textlist [split $text "\n"]
    set height [expr {[llength $textlist] + 2}]
    set width 1
    foreach line $textlist {
        if {[string length $line] > $width} {
            set width [string length $line]
        }
    }
    incr width 2
    if {$height > 24} {
        set height 24
    }
    if {$height < 5} {
        set height 5
    }
    if {$width > 80} {
        set width 80
    }
    if {$width < 40} {
        set width 40
    }
    return [list $width $height]
}

proc /error {world msg {trace ""}} {
    global tcl_platform
    if {$world == ""} {
        set title "Trebuchet Error"
        set prefix "You received the following error:"
        set longmsg "$prefix\n$trace"
    } else {
        set title "Error - $world"
        set prefix "You received the following error in world '$world':"
        set longmsg "$prefix\n$trace"
    }
    set size [estimate_text_size $longmsg]
    set w [lindex $size 0]
    set h [lindex $size 1]

    if {$tcl_platform(winsys) == "aqua"} {
	set parent [focus]
	if {$parent != ""} {
	    set parent [winfo toplevel $parent]
	}
        set shortmsg "$prefix\n$msg"
        if {$trace != ""} {
            set shortmsg "$shortmsg\n\nWould you like to see the full stack trace?"
            if {[catch {tk_messageBox -parent $parent -title $title -icon error -type yesno -default no -message $shortmsg} result]} {
                puts stderr $longmsg
                set result "yes"
            }
            if {$result == "yes"} {
                /textdlog -modal -readonly -title $title -text $longmsg -width $w -height $h
            }
        } else {
            tk_messageBox -parent $parent -title $title -icon error -type ok -message $shortmsg
        }
        return ""
    }

    set shortmsg $msg
    set i 0
    set base ".mw.errdlog"
    while {[winfo exists $base$i]} {incr i}
    set base $base$i

    toplevel $base
    wm title $base $title
    wm resizable $base 0 0
    wm transient $base .mw
    place_window_default $base

    label $base.icon -bitmap error
    label $base.label -text $shortmsg -wraplength 500 -justify left
    if {$trace != ""} {
        button $base.trace -text "Call Trace..." -width 13 -command "
            /textdlog -modal -readonly -title [list $title] -text [list $longmsg] -width $w -height $h
            grab set $base
            #destroy $base
        "
    }
    button $base.close -text "Close" -width 13 -default active -command "grab release $base ; destroy $base"
    bind $base <Key-Escape> "$base.close invoke"
    bind $base <Key-Return> "$base.close invoke"

    grid rowconfig $base 0 -minsize 10
    grid rowconfig $base 2 -minsize 10
    grid rowconfig $base 4 -minsize 10
    grid columnconfig $base 0 -minsize 10
    grid columnconfig $base 2 -minsize 10
    grid columnconfig $base 3 -weight 1
    grid columnconfig $base 4 -minsize 10
    grid columnconfig $base 6 -minsize 10

    grid $base.icon  -column 1 -row 1 -sticky nsew
    grid $base.label -column 3 -row 1 -sticky nsw  -columnspan 3
    if {$trace != "" && [llength [split $trace "\n"]] > 1} {
        grid $base.trace -column 3 -row 3 -sticky nse
    }
    grid $base.close -column 5 -row 3 -sticky nse

    /bell

    return ""
}

proc /nonmodalerror {world msg} {
    global tcl_platform
    if {$tcl_platform(winsys) == "aqua"} {
        /error $world $msg
        return ""
    }
    if {$world == ""} {
        set title "Trebuchet Error"
        set msg "You received the following error:\n$msg"
    } else {
        set title "Error - $world"
        set msg "You received the following error in world '$world':\n$msg"
    }
    set size [estimate_text_size $msg]
    set w [lindex $size 0]
    set h [lindex $size 1]
    /textdlog -readonly -title "$title" -text "$msg" -width $w -height $h
    return ""
}

tcl::OptProc /results {
    {-world     {}  "The world to send the data to."}
    {-title     {}  "The title to display for the window."}
    {-showend       "If given, scroll to end of text."}
    {msg        {}  "The text to display in the window."}
} {
    if {$title == {}} {
        if {$world == ""} {
            set title "Trebuchet command results"
        } else {
            set title "Command Results - $world"
        }
    }
    set size [estimate_text_size $msg]
    set w [lindex $size 0]
    set h [lindex $size 1]
    set wname [/textdlog -readonly -title "$title" -text "$msg" -width $w -height $h]
    if {$showend} {
        $wname.text see "end-1c"
    }
    return ""
}

rename unknown unknown:orig
proc unknown {args} {
    global errorCode errorInfo
    set savedErrorCode $errorCode
    set savedErrorInfo $errorInfo
    set name [lindex $args 0]

    if {[string index $name 0] == "/" && [/macro:exists [string range $name 1 end]]} {
        set ret [catch {/macro:execute [string range $name 1 end] [lrange $args 1 end]} result]
        if {$ret == 0} {
            return $result
        } else {
            return -code $ret -errorcode $errorCode $result
        }
    }

    set errorCode $savedErrorCode
    set errorInfo $savedErrorInfo
    set ret [catch {uplevel unknown:orig $args} result]
    if {$ret == 0} {
        return $result
    } else {
        return -code $ret -errorcode $errorCode $result
    }
}
