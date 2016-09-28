global display_number; set display_number 0

proc display:names {} {
    global widget
    return [winfo children $widget(disp)]
}

proc display:current {} {
    global widget
    return [pack slaves $widget(disp)]
}

proc display:at_end {{disp ""}} {
    if {$disp == ""} {
        set disp "[display:current].disp"
    }

    set info [$disp dlineinfo end-1c]
    if {$info == {}} {
        return 0
    }
    # dlineinfo returns clipped size.  there's no easy way to check if the
    # entire line is visible, so instead we see if the baseline is visible.
    if {[lindex $info 3] <= [lindex $info 4]} {
        return 0
    }
    return 1
}

proc display:prev {} {
    global widget
    if {[llength [worldbutton:names]] == 0} {
        display:select $widget(backdrop)
    } else {
        worldbutton:prev
    }
}

proc display:next {} {
    global widget
    if {[llength [worldbutton:names]] == 0} {
        display:select $widget(backdrop)
    } else {
        worldbutton:next
    }
}


proc display:clearpartial {disp} {
    if {$disp == ""} {
        set disp [display:current]
    }
    catch {
        $disp delete "__partialline__.first-1c" "__partialline__.last"
        $disp tag delete "__partialline__"
    }
}


proc display:write {disp text {tagspans {}}} {
    if {$disp == ""} {
        set disp [display:current]
    }

    set at_end [display:at_end $disp]


    $disp mark set "treb_buffer_end" "end-2c"
    $disp insert end "$text" "normal"
    set hfirst [$disp index "treb_buffer_end+1c"]
    foreach attr $tagspans {
        if {$attr != {}} {
            set style [lindex $attr 2]
            set start "$hfirst + [lindex $attr 0] chars"
            set end [lindex $attr 1]
            if {$end == "end"} {
                set end [string length $text]
            }
            set end "$start + $end chars"
            if {[$disp compare $end == "end"]} {
                set end "end-1c"
            }
            $disp tag add $style $start $end
        }
    }

    set lines [expr {int([$disp index end-1c])}]
    set max [/prefs:get scrollback_lines]
    if {$max < $lines} {
        set diff [expr {$lines - $max + 1}]
        $disp delete 1.0 "$diff.0"
    }
    display:autoscroll $disp
    return $at_end
}

proc display:autoscroll {disp} {
    global displayInfo

    if {! [/prefs:get jumpscroll_flag]} {
        display:doautoscroll $disp
    } elseif {$displayInfo($disp,autoscroll_task) == {}} {
        set displayInfo($disp,autoscroll_task) \
            [after 200 display:doautoscroll $disp]
    }
}

proc display:doautoscroll {{disp ""}} {
    global displayInfo

    if {$disp == ""} {
        set disp "[display:current].disp"
    }
    if {![winfo exists $disp]} {
        return 0
    }

    if {$displayInfo($disp,autoscrolling) && ! [display:at_end $disp]} {
        if {[/prefs:get pager_flag]} {
            $disp yview pagestop_mark
        } else {
            $disp see end
        }
    }

    set displayInfo($disp,autoscroll_task) {}
    set displayInfo($disp,autoscrolling) [display:at_end $disp]
}

proc display:markseen {{disp ""}} {
    global displayInfo

    if {$disp == ""} {
        set disp "[display:current].disp"
    }

    set y [expr {[winfo height $disp] - 1}]
    set pos [$disp index "@0,$y linestart"]
    if {[$disp compare pagestop_mark < $pos]} {
        $disp mark set pagestop_mark $pos
    }

    set displayInfo($disp,autoscrolling) [display:at_end $disp]
}

proc display:select {display} {
    global displayInfo widget
    set disp [display:current]
    if {$disp != {}} {
        pack forget $disp
    }
    pack $display -anchor center -expand 1 -fill both -side top
    if {$display != $widget(backdrop)} {
        worldbutton:setpressed $displayInfo($display,worldbutton)
    }
    /socket:update_indicators
}

proc display:setlight {display color} {
    global displayInfo
    set btn $displayInfo($display,worldbutton)
    worldbutton:setlight $btn $color
    return
}

proc display:delete {display} {
    global displayInfo
    worldbutton:delete $displayInfo($display,worldbutton)
    display:next
    destroy $display
}

proc display:mkdisplay {base} {
    global displayInfo treb_fonts tcl_platform
    if {$tcl_platform(winsys) == "aqua"} {
        frame $base -relief flat -borderwidth 0
    } else {
        frame $base -relief sunken -borderwidth 2
    }
    set sbarbw 0
    if {$tcl_platform(winsys) == "x11"} {
        set sbarbw 1
    }
    scrollbar $base.scroll \
        -command "display:markseen $base.disp ; $base.disp yview" -orient vert -borderwidth $sbarbw -relief raised
    text $base.disp \
        -takefocus 0 -width 80 -height 1 \
        -font $treb_fonts(fixed) -wrap word -insertwidth 0 \
        -highlightthickness 0 -relief flat -borderwidth 0 \
        -yscrollcommand "$base.scroll set"
    bind $base.disp <<Copy>> {editCopy %W ; break}
    bind $base.disp <<Paste>> {
        focus [/inbuf]
        event generate [/inbuf] <<Paste>>
        break
    }
    bind $base.disp <<PasteAt>> {
        bell
        break
    }
    if {$tcl_platform(winsys) == "x11"} {
        bind $base.disp <Button-4> {
            /dokey scroll_line_up
            /dokey scroll_line_up
            /dokey scroll_line_up
            /dokey scroll_line_up
            break;
        }
        bind $base.disp <Button-5> {
            /dokey scroll_line_dn
            /dokey scroll_line_dn
            /dokey scroll_line_dn
            /dokey scroll_line_dn
            break;
        }
    }
    set tlev [winfo toplevel $base.disp]
    bindtags $base.disp [list $base.disp WorldDisplay $tlev all]
    $base.disp tag add normal 0.0 end

    style:ansi_update $base.disp

    grid columnconfigure $base 1 -weight 0
    grid columnconfigure $base 0 -weight 1
    grid rowconfigure $base 0 -weight 1
    grid $base.scroll -row 0 -column 1 -sticky nsew
    grid $base.disp -row 0 -column 0 -sticky nsew
    textPopup:new $base.disp
    $base.disp mark set pagestop_mark 1.0
    $base.disp mark gravity pagestop_mark left
    set displayInfo($base.disp,autoscrolling) 1
    set displayInfo($base.disp,autoscroll_task) {}
    return
}

proc display:add {label} {
    global display_number displayInfo widget
    incr display_number

    set base $widget(disp).$display_number
    display:mkdisplay $base
    worldbutton:add $label "display:select $base"
    set displayInfo($base,worldbutton) $label
    worldbutton:press $label
    return $base
}


proc display:init {} {
    foreach binding [bind Text] {
        switch -glob $binding {
            <<Redo>> -
            <<Undo>> -
            <<Clear>> -
            <<PasteSelection>> {
                continue
                bind WorldDisplay $binding {/bell}
            }
            <Mod1-Key> -
            <Key-KP_Enter> -
            <Key-Escape> -
            <Control-Key> -
            <Meta-Key> -
            <Alt-Key> {
                bind WorldDisplay $binding {# nothing}
            }
            "\{" -
            "\}" -
            {\[} -
            {\]} -
            "(" -
            ")" -
            "`" -
            "'" -
            "\"" -
            <<Paste>> -
            <*Key*> {
                set keycmd [bind Text $binding]
                regsub -all "%W" $keycmd {[/inbuf]} keycmd
                bind WorldDisplay $binding "focus \[/inbuf\]; $keycmd"
            }
            <Control-Shift-Key-Tab> -
            <Control-Key-Tab> -
            <Shift-Key-Tab> -
            default {
                bind WorldDisplay $binding [bind Text $binding]
            }
        }
    }
    catch {bind WorldDisplay <Key-Control_L> "# nothing"}
    catch {bind WorldDisplay <Key-Control_R> "# nothing"}
    catch {bind WorldDisplay <Key-Shift_L> "# nothing"}
    catch {bind WorldDisplay <Key-Shift_R> "# nothing"}
    catch {bind WorldDisplay <Key-Alt_L> "# nothing"}
    catch {bind WorldDisplay <Key-Alt_R> "# nothing"}
    catch {bind WorldDisplay <Key-Mod1> "# nothing"}
    catch {bind WorldDisplay <Key-Meta> "# nothing"}
}


