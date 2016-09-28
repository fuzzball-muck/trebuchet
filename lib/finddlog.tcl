package require opt

proc textdlog:refresh {wname} {
    global finddlogInfo
    if {$finddlogInfo($wname,pattern) == ""} {
        set newstate "disabled"
    } else {
        set newstate "normal"
    }
    set curstate [$wname.fr2.findnext cget -state]
    if {$curstate != $newstate} {
        $wname.fr2.findnext config -state $newstate
    }
}

proc finddlog:cancelblink {wname textwidget doselect} {
    global finddlogInfo
    if {[info exists finddlogInfo($wname,blinker)]} {
        after cancel $finddlogInfo($wname,blinker)
    }
    set ranges [$textwidget tag ranges finddloghi]
    if {$ranges != ""} {
        $textwidget tag remove sel 1.0 end
        $textwidget tag add sel finddloghi.first finddloghi.last
        $textwidget tag delete finddloghi
        event generate $textwidget <<Copy>>
    }
}

proc finddlog:blink {wname textwidget} {
    global finddlogInfo
    if {![info exists finddlogInfo($wname,blinkstate)]} {
        set finddlogInfo($wname,blinkstate) 0
    } elseif {$finddlogInfo($wname,blinkstate)} {
        set finddlogInfo($wname,blinkstate) 0
        $textwidget tag config finddloghi \
            -background #c080e0 -foreground black -underline 0
    } else {
        set finddlogInfo($wname,blinkstate) 1
        $textwidget tag config finddloghi \
            -background #b080d0 -foreground white -underline 0
    }

    set finddlogInfo($wname,blinker) \
        [after 500 finddlog:blink $wname $textwidget]
}

proc finddlog:search {wname textwidget} {
    global finddlogInfo
    set pattern   $finddlogInfo($wname,pattern)
    set nocase    $finddlogInfo($wname,nocase)
    set regexp    $finddlogInfo($wname,regexp)
    set direction $finddlogInfo($wname,direction)
    /prefs:set last_find_pattern $pattern
    /prefs:set last_find_nocase $nocase
    /prefs:set last_find_direct $direction
    /prefs:set last_find_regexp $regexp
    set cmd "$textwidget search -$direction "
    if {$nocase} {append cmd "-nocase "}
    if {$regexp} {append cmd "-regexp "}
    append cmd "-count charcount -- [list $pattern] insert"
    set next [eval $cmd]
    if {$next != ""} {
        $textwidget tag delete finddloghi
        $textwidget tag add finddloghi $next "$next + $charcount chars"
        if {$direction == "forwards"} {
            $textwidget mark set insert "$next + $charcount chars"
        } else {
            $textwidget mark set insert "$next"
        }
        $textwidget see "$next + $charcount chars"
        $textwidget see $next

        set startbox [$textwidget bbox $next]
        set endbox [$textwidget bbox "$next + $charcount chars"]
        set rooty [winfo rooty $textwidget]
        set top [expr {$rooty + [lindex $startbox 1]}]
        if {$endbox != ""} {
            set bot [expr {$rooty + [lindex $endbox 1] + [lindex $endbox 3]}]
        } else {
            set bot [expr {$rooty + [winfo reqheight $textwidget]}]
        }
        set dlogheight [winfo reqheight $wname]
        set dlogx [winfo rootx $wname]
        set dlogtop [winfo rooty $wname]
        set dlogbot [expr {$dlogtop + $dlogheight}]
        if {($top >= ($dlogtop - 25) && $top <= $dlogbot) || \
            ($bot >= ($dlogtop - 25) && $bot <= $dlogbot) \
        } {
            if {$top > (3 * $dlogheight)} {
                set dlogtop [expr {$top - (2 * $dlogheight) - 25}]
                wm geometry $wname +$dlogx+$dlogtop
            } else {
                set dlogtop [expr {$bot + $dlogheight + 25}]
                wm geometry $wname +$dlogx+$dlogtop
            }
        }
        finddlog:blink $wname $textwidget
    } else {
        bell
    }
}

tcl::OptProc finddlog:new {
    {wname {} "Name of the tk dialog to create."}
    {textwidget {} "Name of the tk text widget."}
    {-findcmd {} "Command to run after each 'find next'"}
    {-pattern {} "Default pattern to look for."}
    {-regexp "Enable regular expression searches."}
    {-nocase "Ignore letter case in searches."}
    {-direction -choice {forwards backwards} "Default direction to search."}
} {
    if {$textwidget == {}} {
        error "finddlog:new: invalid widget name."
    }
    if {[winfo class $textwidget] != "Text"} {
        error "finddlog:new: widget MUST be of the Text class."
    }

    set base $wname
    global finddlogInfo
    set finddlogInfo($base,pattern) $pattern
    set finddlogInfo($base,nocase) $nocase
    set finddlogInfo($base,regexp) $regexp
    set finddlogInfo($base,direction) $direction
    ###################
    if {[winfo exists $base]} {
        wm deiconify $base
        textdlog:refresh $base
        focus $base.fr1.pattern
        $base.fr1.pattern selection range 0 end
        $base.fr1.pattern icursor end
        return $base
    }
    ###################
    toplevel $base -class Toplevel
    wm resizable $base 0 0
    wm deiconify $base
    wm transient $base $textwidget
    wm positionfrom $base user
    wm sizefrom $base program
    wm title $base "Find text"
    set x [winfo rootx $textwidget]
    set y [winfo rooty $textwidget]
    incr x 20
    incr y 20
    wm geometry $base +$x+$y
    wm protocol $base WM_DELETE_WINDOW "$base.fr2.cancel invoke"

    frame $base.fr1
    label $base.fr1.patlbl -text Pattern -underline 0
    entry $base.fr1.pattern -width 40 \
        -textvariable finddlogInfo($base,pattern)
    bind $base <Alt-Key-p> "focus $base.fr1.pattern"
    checkbutton $base.fr1.nocase -text {Ignore Case} \
        -variable finddlogInfo($base,nocase) -underline 0
    bind $base <Alt-Key-i> "focus $base.fr1.nocase"
    checkbutton $base.fr1.regexp -text {Regular Expression} \
        -variable finddlogInfo($base,regexp) -underline 0
    bind $base <Alt-Key-r> "focus $base.fr1.regexp"
    radiobutton $base.fr1.dir1 -text {Search up} -value "backwards" \
        -variable finddlogInfo($base,direction) -underline 7
    bind $base <Alt-Key-u> "focus $base.fr1.dir1"
    radiobutton $base.fr1.dir2 -text {Search down} -value "forwards" \
        -variable finddlogInfo($base,direction) -underline 7
    bind $base <Alt-Key-d> "focus $base.fr1.dir2"
    frame $base.fr2
    button $base.fr2.findnext -text {Find Next} -default active -command "
        finddlog:cancelblink $base $textwidget 0
        finddlog:search $base $textwidget
        $findcmd
    "
    button $base.fr2.cancel -text Cancel -command "
        destroy $base
        focus $textwidget
    "
    ###################
    grid $base.fr1 -column 0 -row 0 -sticky nw 
    grid $base.fr1.patlbl -column 0 -row 0 -padx 5 -pady 5 -sticky w 
    grid $base.fr1.pattern -column 1 -row 0 -columnspan 2 -padx 5 -pady 5 -sticky w
    grid $base.fr1.nocase -column 0 -row 1 -columnspan 2 -padx 5 -sticky w
    grid $base.fr1.regexp -column 0 -row 2 -columnspan 2 -padx 5 -sticky w
    grid $base.fr1.dir1 -column 2 -row 1 -columnspan 1 -padx 5 -sticky w 
    grid $base.fr1.dir2 -column 2 -row 2 -columnspan 1 -padx 5 -sticky w 
    grid $base.fr2 -column 1 -row 0 -sticky nw 
    grid $base.fr2.findnext -column 0 -row 0 -padx 5 -pady 5 -sticky new 
    grid $base.fr2.cancel -column 0 -row 1 -padx 5 -pady 5 -sticky new 
    ###################
    bind $base.fr1.pattern <Key> "+after 10 textdlog:refresh $base"
    bind $base <Key-Return> "after 20 $base.fr2.findnext invoke ; break"
    bind $base <Key-Escape> "after 20 $base.fr2.cancel invoke ; break"
    bind $base <Destroy> "
        finddlog:cancelblink $base $textwidget 1
        focus $textwidget
    "
    ###################
    textdlog:refresh $base
    focus $base.fr1.pattern
    update idletasks
    $base.fr1.pattern selection range 0 end
    $base.fr1.pattern icursor end
    return $base
}


