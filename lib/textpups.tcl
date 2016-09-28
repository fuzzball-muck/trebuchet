# textpups.tcl
# Popup Menus for text displays

proc textPopup:popup {widget x y} {
    global TextPopupInfo tcl_platform
    set base $widget.textpopupmenu
    if {[winfo exists $base]} {
        destroy $base
    }
    menu $base -tearoff 0
    if {[winfo class $widget] == "Entry"} {
        set selp [$widget selection present]
    } elseif {[winfo class $widget] == "Text"} {
        set selp [expr {[$widget tag ranges sel] != ""}]
    }
    if {[winfo class $widget] == "Text"} {
        if {[/spell:enabled] && $widget != [/display]} {
            if {[lsearch -exact [$widget tag names @$x,$y] badwords] != -1} {
                set wpos [$widget index "@$x,$y wordstart"]
                set word [$widget get $wpos "@$x,$y wordend"]
                set suggs [lrange [/spell:suggest $word $widget] 0 4]
                if {[llength $suggs] > 0} {
                    foreach sugg $suggs {
                        $base add command -label "$sugg" \
                            -command [list /spell:fixword $wpos $sugg $widget]
                    }
                    $base add separator
                }
                $base add command -label "Ignore spelling" \
                    -command [list /spell:ignore $word $widget]
                $base add command -label "Learn spelling" \
                    -command [list /spell:learn $word $widget]
            }
            $base add command -label "Spell-check" -underline 0 \
                -command [list /spell:check $widget]
            $base add separator
        }
    }

    if {[$widget cget -insertwidth] > 0 || $widget == [/display]} {
        if {$selp} {
            $base add command -label Cut  -underline 2 \
                -command "event generate $widget <<Cut>>"
            $base add command -label Copy -underline 0 \
                -command "event generate $widget <<Copy>>"
        } else {
            $base add command -label Cut  -underline 2 -state disabled
            $base add command -label Copy -underline 0 -state disabled
        }
        if {[catch {set csel [selection get -disp $widget -sel CLIPBOARD]}]} {
            set csel ""
        }
        if {$csel != "" && $widget != [/display]} {
            $base add command -label Paste -underline 0 \
                -command "event generate $widget <<Paste>>"
        } else {
            $base add command -label Paste -underline 0 -state disabled
        }
    } else {
        $base add command -label Cut  -underline 2 -state disabled
        if {$selp} {
            $base add command -label Copy -underline 0 \
                -command "event generate $widget <<Copy>>"
        } else {
            $base add command -label Copy -underline 0 -state disabled
        }
        $base add command -label Paste -underline 0 -state disabled
    }
    if {[winfo class $widget] == "Text"} {
        set sepflag 0
        set templateflag 0

        if {[lsearch -exact [$widget tag names @$x,$y] sel] != -1} {
            set hmenu $base.hilitemenu
            if {[winfo exists $hmenu]} {
                destroy $hmenu
            }
            menu $hmenu -tearoff 0
            set rng [$widget tag prevrange sel @$x,$y]
            if {$rng == {}} {
                set rng [$widget tag prevrange sel "@$x,$y +1c"]
            }
            if {$rng != {}} {
                $base add separator
                incr sepflag
                set txt [$widget get [lindex $rng 0] [lindex $rng 1]]
                set hname $txt
                set count 0
                while {[/hilite:exists $hname]} {
                    set hname "$txt[incr count]"
                }
                $base add command -label "Create hilite..." -command "
                    global dirty_preferences; set tmp_dirty \$dirty_preferences
                    /hilite:add [list $hname] [list $txt] -style hilite -type word -match contains -fallthru 1
                    /hilite:edit [list $hname]
                    /hilite:delete [list $hname]
                    set dirty_preferences \$tmp_dirty
                "
                foreach hilite [/hilite:names] {
                    if {[/hilite:get template $hilite]} {
                        set templateflag 1
                        set cmd [lrange [/hilite:list $hilite] 4 end]
                        $hmenu add command -label "$hilite..." -command "
                            global dirty_preferences; set tmp_dirty \$dirty_preferences
                            /hilite:add [list $hname] [list $txt] $cmd -category [list $hilite]
                            /hilite:edit [list $hname]
                            /hilite:delete [list $hname]
                            set dirty_preferences \$tmp_dirty
                        "
                    }
                }
                $base add cascade -label "Create hilite from template" -underline 0 -menu $hmenu
                set sepflag 0
                set hname "Gag: $txt"
                set count 0
                while {[/hilite:exists $hname]} {
                    set hname "Gag: $txt[incr count]"
                }
                $base add command -label "Create gag to suppress line..." -command "
                    global dirty_preferences; set tmp_dirty \$dirty_preferences
                    /hilite:add [list $hname] [list $txt] -style gag -category Gagged -match contains -type line -priority 100
                    /hilite:edit [list $hname]
                    /hilite:delete [list $hname]
                    set dirty_preferences \$tmp_dirty
                "
                if {$widget == [/inbuf] || $widget == [/display]} {
                    $base add separator
                    $base add command -label "Find..." -underline 0 \
                        -command "/prefs:set last_find_pattern [list $txt]; /edit:find"
                    $base add command -label "Send to the MU*" -underline 0 \
                        -command "/socket:sendln_raw [list [worldbutton:current]] [list $txt]"
                }
                $base add separator
                $base add command -label "Open as URL..." -underline 0 \
                    -command "/web_view [list $txt]"
            }
        }
        set spos [$widget search -backwards -regexp -nocase -- "\[ \n\]" @$x,$y 1.0]
        if {$spos == ""} {
            set spos 1.0
        }
        set epos [$widget search -forwards -regexp -nocase -- "\[ \n\]" @$x,$y end]
        if {$epos == "" || [$widget compare $spos > $epos]} {
            set epos [$widget index "end-1c"]
        }
        set urltxt [$widget get $spos $epos+1c]
        if {[regexp -nocase -indices -- "(https?:\[^ \n\"\]*\[^ \n\".\])" $urltxt dummy urlpos]} {
            set urlspos [$widget index "$spos + [lindex $urlpos 0] chars"]
            set urlepos [$widget index "$spos + [lindex $urlpos 1] chars + 1 char"]
            set url [$widget get $urlspos $urlepos]
            $base add command -label "Convert to TinyURL.com link..." \
                -underline 0 -command [list web:tinyurlize $widget $url $urlspos $urlepos]
        }

        foreach tag [$widget tag names @$x,$y] {
            if {[info exists TextPopupInfo(labels,$widget,$tag)]} {
                foreach label $TextPopupInfo(labels,$widget,$tag) {
                    if {[regexp -- "<<.*>>" $label]} {
                        continue
                    }
                    set rng [$widget tag prevrange $tag @$x,$y]
                    if {$rng == {}} {
                        set rng [$widget tag prevrange $tag "@$x,$y +1c"]
                        if {$rng == {}} {
                            continue
                        }
                    }
                    set txt [$widget get [lindex $rng 0] [lindex $rng 1]]
                    set scr $TextPopupInfo(script,$widget,$tag,$label)
                    set scr [/line_subst $scr $txt]
                    set statescr $TextPopupInfo(state,$widget,$tag,$label)
                    if {!$sepflag} {
                        $base add separator
                        incr sepflag
                    }
                    if {$statescr != ""} {
                        set statescr [/line_subst $statescr $txt]
                        if $statescr {
                            set state normal
                        } else {
                            set state disabled
                        }
                        $base add command -label $label -command $scr \
                            -state $state
                    } else {
                        $base add command -label $label -command $scr
                    }
                }
            }
        }
    }
    incr x [winfo rootx $widget]
    incr y [winfo rooty $widget]
    tk_popup $base $x $y
    return
}

proc textPopup:getscript {widget tag label} {
    global TextPopupInfo
    if {[textPopup:exists $widget $tag $label]} {
        return $TextPopupInfo(script,$widget,$tag,$label)
    }
    error "textPopup:getscript: No such menu item '$label' in style '$tag'."
}

proc textPopup:getstatescript {widget tag label} {
    global TextPopupInfo
    if {[textPopup:exists $widget $tag $label]} {
        return $TextPopupInfo(state,$widget,$tag,$label)
    }
    error "textPopup:getstatescript: No such menu item '$label' in style '$tag'."
}

proc textPopup:addentry {widget tag label script {statescript ""}} {
    global TextPopupInfo
    global tcl_platform

    set pos -1
    if {[info exists TextPopupInfo(labels,$widget,$tag)]} {
        set pos [lsearch -exact $TextPopupInfo(labels,$widget,$tag) $label]
    } else {
        lappend TextPopupInfo(tags,$widget) $tag
    }
    if {$pos == -1} {
        lappend TextPopupInfo(labels,$widget,$tag) $label
    }
    set TextPopupInfo(script,$widget,$tag,$label) $script
    set TextPopupInfo(state,$widget,$tag,$label) $statescript
    if {$label == "<<Click>>"} {
        set os $tcl_platform(winsys)
        switch -exact $os {
            aqua {
                if {$tcl_platform(vermajor) == 8 &&
                    "$tcl_platform(verminor).$tcl_platform(patchlevel)" < 4.2
                } {
                    set cursor "arrow"
                } else {
                    set cursor "pointinghand"
                }
                set ncursor "ibeam"
            }
            win32 {
                set cursor "arrow"
                set ncursor "ibeam"
            }
            x11 {
                set cursor "hand2"
                set ncursor "xterm"
            }
            default {
                set cursor "arrow"
                set ncursor "arrow"
            }
        }
        $widget tag bind $tag "<Enter>" [list $widget config -cursor $cursor]
        $widget tag bind $tag "<Leave>" [list $widget config -cursor $ncursor]
    }
    return
}

proc textPopup:exists {widget tag label} {
    global TextPopupInfo
    if {[info exists TextPopupInfo(script,$widget,$tag,$label)]} {
        return 1
    }
    return 0
}

proc textPopup:names {widget tag} {
    global TextPopupInfo
    if {[info exists TextPopupInfo(labels,$widget,$tag)]} {
        return $TextPopupInfo(labels,$widget,$tag)
    }
    return ""
}

proc textPopup:delentry {widget tag label} {
    global TextPopupInfo
    if {[info exists TextPopupInfo(labels,$widget,$tag)]} {
        set pos [lsearch -exact $TextPopupInfo(labels,$widget,$tag) $label]
        if {$pos != -1} {
            set tmp [lreplace TextPopupInfo(labels,$widget,$tag) $pos $pos]
            set TextPopupInfo(labels,$widget,$tag)  $tmp
            unset TextPopupInfo(script,$widget,$tag,$label)
            unset TextPopupInfo(state,$widget,$tag,$label)
        }
    }
    return
}

proc textPopup:invoke {widget tag label x y} {
    global TextPopupInfo
    if {[info exists TextPopupInfo(labels,$widget,$tag)]} {
        set pos [lsearch -exact $TextPopupInfo(labels,$widget,$tag) $label]
        if {$pos != -1} {
            set rng [$widget tag prevrange $tag @$x,$y]
            if {$rng == {}} {
                set rng [$widget tag prevrange $tag "@$x,$y +1c"]
                if {$rng == {}} {
                    continue
                }
            }
            set txt [$widget get [lindex $rng 0] [lindex $rng 1]]
            set scr $TextPopupInfo(script,$widget,$tag,$label)
            set scr [/line_subst $scr $txt]
            eval $scr
        }
    }
}


proc textPopup:buttonpress {widget x y} {
    global TextPopupInfo
    set TextPopupInfo(clickedat) [list $widget $x $y]
}


proc textPopup:buttonrelease {widget x y} {
    global TextPopupInfo
    global tcl_platform

    set os $tcl_platform(winsys)
    switch -exact $os {
        aqua {
            if {$tcl_platform(vermajor) == 8 &&
                "$tcl_platform(verminor).$tcl_platform(patchlevel)" < 4.2
            } {
                set cursor "arrow"
            } else {
                set cursor "pointinghand"
            }
            set ncursor "ibeam"
        }
        win32 {
            set cursor "arrow"
            set ncursor "ibeam"
        }
        x11 {
            set cursor "hand2"
            set ncursor "xterm"
        }
        default {
            set cursor "arrow"
            set ncursor "arrow"
        }
    }
    if {![info exists TextPopupInfo(clickedat)]} {
        return ""
    }
    foreach {oldwidget oldx oldy} $TextPopupInfo(clickedat) break;
    if {$oldwidget == $widget} {
        set dist [expr {sqrt(($oldx-$x)*($oldx-$x) + ($oldy-$y)*($oldy-$y))}]
        if {$dist < 3.0} {
            foreach tag [$widget tag names @$x,$y] {
                textPopup:invoke $widget $tag "<<Click>>" $x $y
                $widget config -cursor $ncursor
            }
        }
    }
}

proc textPopup:new {widget} {
    global TextPopupInfo
    set TextPopupInfo(tags,$widget) {}
    # bind $widget <<ContextMenu>> "textPopup:popup %W %x %y ; break"
    # bind $widget <ButtonPress-1> "+textPopup:buttonpress %W %x %y"
    # bind $widget <ButtonRelease-1> "+textPopup:buttonrelease %W %x %y"
    return
}

bind Text <<ContextMenu>> "textPopup:popup %W %x %y ; break"
bind Entry <<ContextMenu>> "textPopup:popup %W %x %y ; break"
bind Text <ButtonPress-1> "+textPopup:buttonpress %W %x %y"
bind Text <ButtonRelease-1> "+textPopup:buttonrelease %W %x %y"
 
