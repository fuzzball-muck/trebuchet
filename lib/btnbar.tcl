tcl::OptProc fakebutton:new {
    {wname            {}    {Widget name to create.}}
    {-text            {}    {Text to put on button.}}
    {-image           {}    {Image to put on button.}}
    {-width           0     {Width of button.}}
    {-height          0     {Height of button.}}
    {-font            {}    {Font for button text.}}
    {-command         {}    {Command to execute when button is pressed.}}
    {-borderwidth     2     {Width of 3D bezel around button.}}
    {-padx            2     {Width of internal padding around image and text.}}
    {-pady            2     {Height of internal padding around image and text.}}
    {-highlightthickness 2  {Width of focus highlight ring around button.}}
    {-variable        {}    {Variable name to use for toggle or radiobutton.}}
    {-value    -string 0    {Value to use for radiobutton when it is selected.}}
    {-offvalue -string 0    {Value to use for toggle when it is 'off'}}
    {-onvalue  -string 1    {Value to use for toggle when it is 'on'}}
    {-relief -choice {sunken raised flat groove} {Relief of unpressed 3D bezel.}}
    {-anchor -choice {center n ne e se s sw w nw} {Anchor side for text and image in the button.}}
    {-type -choice {button toggle radio} {Type of button.}}
} {
    global FakebuttonInfo
    global tcl_platform env
    global treb_fonts
    if {$font == {}} {
        set font $treb_fonts(bbar)
    }
    if {$tcl_platform(winsys) == "aqua" && [info exists env(TREB_MAC_COMPOUND_FIX)]} {
        set compound left
        if {$image == {}} {
            set image [gdm:Bitmap:get invisible]
            set compound center
        }
        if {$type == "toggle"} {
            set cmd [list checkbutton $wname]
        } elseif {$type == "radio"} {
            set cmd [list radiobutton $wname]
        } else {
            set cmd [list button $wname]
        }
        lappend cmd -compound $compound
        lappend cmd -image $image
        lappend cmd -text $text
        lappend cmd -font $font
        lappend cmd -padx $padx -pady $pady
        lappend cmd -borderwidth $borderwidth
        lappend cmd -highlightthickness $highlightthickness
        lappend cmd -anchor $anchor
        lappend cmd -command $command
        if {$type == "toggle"} {
            lappend cmd -onvalue $onvalue
            lappend cmd -offvalue $offvalue
        } elseif {$type == "radio"} {
            lappend cmd -value $value
        } else {
            lappend cmd -default disabled
        }
        if {$type == "toggle" || $type == "radio"} {
            lappend cmd -indicatoron 0
            if {$variable != {}} {
                lappend cmd -variable $variable
            }
        }
        return [eval $cmd]
    }

    global treb_clickedin treb_fonts
    set treb_clickedin {}
    set FakebuttonInfo($wname,type) $type
    set FakebuttonInfo($wname,command) $command
    set FakebuttonInfo($wname,variable) $variable
    upvar #0 $variable thevar
    if {$type == "toggle"} {
        set FakebuttonInfo($wname,onvalue) $onvalue
        set FakebuttonInfo($wname,offvalue) $offvalue
        set thevar $offvalue
    } elseif {$type == "radio"} {
        set FakebuttonInfo($wname,onvalue) $value
        set thevar $value
    }
    if {[catch {
        frame $wname -class FakeBtn -relief $relief -borderwidth $borderwidth -highlightthickness $highlightthickness -padx 3
    }]} {
        frame $wname -class FakeBtn -relief $relief -borderwidth $borderwidth -highlightthickness $highlightthickness
    }
    frame $wname.ff -highlightthickness 1 -takefocus 1
    bindtags $wname.ff [list $wname $wname.ff [winfo toplevel $wname] all]
    pack $wname.ff -expand 1 -fill both
    if {$width > 0} { $wname config -width $width }
    if {$height > 0} { $wname config -height $height }
    if {$image != {}} {
        label $wname.ff.img -image $image -borderwidth 0 -padx 0 -pady $pady -highlightthickness 0
        bindtags $wname.ff.img [list $wname $wname.ff.img [winfo toplevel $wname] all]
        pack $wname.ff.img -expand 0 -fill none -side left
    }
    if {$text != {}} {
        label $wname.ff.lbl -text $text -borderwidth 0 -padx $padx -pady $pady -highlightthickness 0 -font $font
        if {$image != {}} {
            $wname.ff.lbl config -anchor w
        }
        bindtags $wname.ff.lbl [list $wname $wname.ff.lbl Label [winfo toplevel $wname] all]
        pack $wname.ff.lbl -expand 1 -fill both -side left
    }

    if {$type == "toggle" || $type == "radio"} {
        if {$variable != ""} {
            if {[catch {trace add variable thevar "write" "fakebutton:tracevar $wname"}]} {
                trace variable thevar w "fakebutton:tracevar $wname"
            }
        }
        bind $wname <Destroy> "fakebutton:destroy $wname"
    }

    set FakebuttonInfo($wname,relief) $relief
    set FakebuttonInfo($wname,background) [$wname cget -background]

    bind $wname <Enter> "fakebutton:enter $wname"
    bind $wname <Leave> "fakebutton:leave $wname"
    bind $wname <ButtonPress-1> "fakebutton:buttonpress $wname"
    bind $wname <ButtonRelease-1> "fakebutton:buttonrelease $wname"
    bind $wname <Key-space> "fakebutton:spacepressed $wname"
}

proc fakebutton:setimage {wname image} {
    global tcl_platform env
    if {$tcl_platform(winsys) == "aqua" && [info exists env(TREB_MAC_COMPOUND_FIX)]} {
        set w $wname
        if {$image == {}} {
            set image [gdm:Bitmap:get invisible]
        }
    } else {
        set w $wname.ff.img
    }
    if {$image != [$w cget -image]} {
        $w configure -image $image
    }
    return
}

proc fakebutton:tracevar {wname varname subscript op} {
    fakebutton:shownormal $wname
}

proc fakebutton:invoke {wname} {
    global tcl_platform env
    if {$tcl_platform(winsys) == "aqua" && [info exists env(TREB_MAC_COMPOUND_FIX)]} {
        $wname invoke
    } else {
        global FakebuttonInfo
        uplevel #0 $FakebuttonInfo($wname,command)
        upvar #0 $FakebuttonInfo($wname,variable) value
        set type $FakebuttonInfo($wname,type)
        if {$type == "radio"} {
            set value $FakebuttonInfo($wname,onvalue)
        } elseif {$type == "toggle"} {
            if {$value == $FakebuttonInfo($wname,onvalue)} {
                set value $FakebuttonInfo($wname,offvalue)
            } else {
                set value $FakebuttonInfo($wname,onvalue)
            }
        }
    }
    return
}

proc fakebutton:showpressed {wname} {
    $wname config -relief "sunken"
    update idletasks
}

proc fakebutton:showactive {wname} {
    global FakebuttonInfo
    if {$FakebuttonInfo($wname,type) == "button"} {
        $wname config -relief "raised"
    }
    update idletasks
}

proc fakebutton:shownormal {wname} {
    global FakebuttonInfo
    set relief $FakebuttonInfo($wname,relief)
    if {$FakebuttonInfo($wname,type) == "button"} {
        $wname config -relief $relief
    } else {
        set varname $FakebuttonInfo($wname,variable)
        global $varname
        if {$varname == "" || ![info exists $varname]} {
            $wname config -relief $relief
        } else {
            upvar #0 $varname value
            set onval $FakebuttonInfo($wname,onvalue)
            if {$value != $onval} {
                $wname config -relief $relief
            } else {
                $wname config -relief solid
            }
        }
    }
    update idletasks
}

proc fakebutton:enter {wname} {
    global treb_clickedin
    if {$treb_clickedin == $wname} {
        fakebutton:showpressed $wname
    } else {
        fakebutton:showactive $wname
    }
}

proc fakebutton:leave {wname} {
    fakebutton:shownormal $wname
}

proc fakebutton:buttonpress {wname} {
    global treb_clickedin
    fakebutton:showpressed $wname
    set treb_clickedin $wname
}

proc fakebutton:buttonrelease {wname} {
    global treb_clickedin
    if {$treb_clickedin == $wname} {
        set mousex [winfo pointerx $wname]
        set mousey [winfo pointery $wname]
        set btnx1 [winfo rootx $wname]
        set btny1 [winfo rooty $wname]
        set btnx2 $btnx1
        set btny2 $btny1
        incr btnx2 [winfo width $wname]
        incr btny2 [winfo height $wname]
        if {$mousex >= $btnx1 && $mousex <= $btnx2} {
            if {$mousey >= $btny1 && $mousey <= $btny2} {
                fakebutton:invoke $wname
            }
        }
    }
    fakebutton:shownormal $wname
    set treb_clickedin {}
}

proc fakebutton:spacepressed {wname} {
    global treb_clickedin
    fakebutton:showpressed $wname
    fakebutton:invoke $wname
    set treb_clickedin {}
    after 200 "fakebutton:shownormal $wname"
}

proc fakebutton:destroy {wname} {
    global FakebuttonInfo
    if {[info exists FakebuttonInfo($wname,variable)]} {
        if {$FakebuttonInfo($wname,variable) != ""} {
            upvar #0 $FakebuttonInfo($wname,variable) thevar
            if {[catch {trace remove variable thevar write "fakebutton:tracevar $wname"}]} {
                trace vdelete thevar w "fakebutton:tracevar $wname"
            }
        }
    }
    foreach item [array names FakebuttonInfo "$wname,*"] {
        unset FakebuttonInfo($item)
    }
}

proc fakebutton:width {wname} {
    global tcl_platform env
    if {$tcl_platform(winsys) == "aqua" && [info exists env(TREB_MAC_COMPOUND_FIX)]} {
        return [winfo reqwidth $wname]
    }
    set width 0
    if {[winfo exists $wname.ff.lbl]} {
        set font [$wname.ff.lbl cget -font]
        set text [$wname.ff.lbl cget -text]
        incr width [font measure $font $text]
        incr width [expr {2 * [$wname.ff.lbl cget -padx]}]
        incr width [expr {2 * [$wname.ff.lbl cget -borderwidth]}]
        incr width [expr {2 * [$wname.ff.lbl cget -highlightthickness]}]
    }
    if {[winfo exists $wname.ff.img]} {
        set img [$wname.ff.img cget -image]
        incr width [image width $img]
        incr width [expr {2 * [$wname.ff.img cget -padx]}]
        incr width [expr {2 * [$wname.ff.img cget -borderwidth]}]
        incr width [expr {2 * [$wname.ff.img cget -highlightthickness]}]
    }
    incr width [expr {2 * [$wname.ff cget -borderwidth]}]
    incr width [expr {2 * [$wname.ff cget -highlightthickness]}]
    incr width [expr {2 * [$wname cget -borderwidth]}]
    incr width [expr {2 * [$wname cget -highlightthickness]}]
    catch {
        incr width [expr {2 * [$wname cget -padx]}]
    }
    return $width
}


tcl::OptProc buttonbar:new {
    {base       {}      {The widget name of the buttonbar to create.}}
    {title      {}      {The title of the buttonbar to create, for menus.}}
    {-menuitems {}      {List of menu item and commands}}
    {-relief -choice {sunken raised flat groove} {Relief of buttonbar bezel.}}
    {-borderwidth 2     {Width of bezel around buttonbar.}}
    {-minwidth  20      {Minimum width of a button in the buttonbar.}}
} {
    global treb_buttonbar tcl_platform
    if {$tcl_platform(winsys) == "aqua"} {
        set relief "flat"
    }
    frame $base -borderwidth $borderwidth -relief $relief -height 25
    if {![info exists treb_buttonbar(bars)]} {
        set treb_buttonbar(bars) {}
    }
    lappend treb_buttonbar(bars) $base
    set treb_buttonbar(title,$base) $title
    set treb_buttonbar(order,$base) {}
    set treb_buttonbar(minwidth,$base) $minwidth
    set treb_buttonbar(visible,$base) 1
    set cnt 0
    foreach {txt cmd} $menuitems {
        set treb_buttonbar(menutext,$base,$cnt) $txt
        set treb_buttonbar(menucmd,$base,$cnt) $cmd
        incr cnt
    }
    set treb_buttonbar(menucount,$base) $cnt
    bind $base <Configure> "buttonbar:refresh $base"
    bind $base <<ContextMenu>> "buttonbar:contextmenu $base {}"
}

proc buttonbar:delete {base id} {
    global treb_buttonbar
    if {![info exists treb_buttonbar(order,$base)]} {
        return
    }
    if {[string first $base $id] == 0} {
        set id [string range $id [string length "$base."] end]
    }
    set pos [lsearch -exact $treb_buttonbar(order,$base) $base.$id]
    set treb_buttonbar(order,$base) [lreplace $treb_buttonbar(order,$base) $pos $pos]
    set treb_buttonbar(cols,$base) 0
    destroy $base.$id
    buttonbar:refresh $base
    return
}

proc buttonbar:show {base {state 1}} {
    global treb_buttonbar
    if {$state != 0} {
        if {[winfo ismapped $base]} {
            set mgr [winfo manager $base]
            if {$mgr != {}} {
                set treb_buttonbar(mgrinfo,$base) "$mgr $base [$mgr info $base]"
            }
        } else {
            if {[info exists treb_buttonbar(mgrinfo,$base)]} {
                eval $treb_buttonbar(mgrinfo,$base)
            }
        }
    } else {
        set mgr [winfo manager $base]
        if {$mgr != {}} {
            set treb_buttonbar(mgrinfo,$base) "$mgr $base [$mgr info $base]"
            eval "$mgr forget $base"
        }
    }
}

proc buttonbar:contextmenu {base {data {}}} {
    global treb_buttonbar
    set treb_buttonbar(visible,$base) [winfo ismapped $base]
    set toplev [winfo toplevel $base]
    set menu $toplev.bbarcontextmenu
    if {[winfo exists $menu]} {
        destroy $menu
    }

    menu $menu -tearoff false

    set cnt $treb_buttonbar(menucount,$base)
    for {set i 0} {$i < $cnt} {incr i} {
        set txt $treb_buttonbar(menutext,$base,$i)
        set cmd $treb_buttonbar(menucmd,$base,$i)
        set state "normal"
        if {[string first "%!" $cmd] >= 0 && $data == {}} {
            set state "disabled"
        }
        if {[string range $txt 0 1] == "--"} {
            $menu add separator
        } else {
            $menu add command -label $txt -state $state -command "eval \[/line_subst [list $cmd] [list $data]\]"
        }
    }

    if {$i > 0} {
        tk_popup $menu [winfo pointerx $base] [winfo pointery $base]
    }
}

tcl::OptProc buttonbar:add {
    {base       {}      {The buttonbar widget to add a button to.}}
    {?pos?      {end}   {The position to insert the button before.}}
    {-type -choice {button toggle radio} {Type of button.}}
    {-image     {}      {The Icon to display in the button.}}
    {-text      {}      {The text to display in the button.}}
    {-font      {}      {Font for button text.}}
    {-command   {}      {The command to execute when the button is pressed.}}
    {-data      {}      {Instance specific data.}}
    {-variable        {}    {Variable name to use for toggle or radiobutton.}}
    {-value    -string 0    {Value to use for radiobutton when it is selected.}}
    {-offvalue -string 0    {Value to use for toggle when it is 'off'}}
    {-onvalue  -string 1    {Value to use for toggle when it is 'on'}}
    {-anchor -choice {center n ne e se s sw w nw} {Anchor side for text and image in the button.}}
    {-relief -choice {raised flat groove} {Relief of unpressed 3D bezel.}}
    {-borderwidth        1  {Width of bezel around button.}}
    {-highlightthickness 2  {Width of focus highlight ring around button.}}
    {-padx               2  {Width of internal padding around image and text.}}
    {-pady               2  {Height of internal padding around image and text.}}
} {
    global env treb_buttonbar tcl_platform
    set i 0
    while {[winfo exists $base.$i]} {
        incr i
    }
    if {$tcl_platform(winsys) == "aqua"} {
        if {![info exists env(TREB_MAC_THEME_FIX)]} {
            set borderwidth 0
            set relief "flat"
        } elseif {$env(TREB_MAC_THEME_FIX) < 2} {
            set borderwidth 0
            set relief "flat"
        } elseif {$env(TREB_MAC_THEME_FIX) < 3} {
            set borderwidth 2
            set relief "flat"
        }
    }
    fakebutton:new $base.$i -type $type \
        -text $text -image $image -command $command \
        -borderwidth $borderwidth -relief $relief \
        -variable $variable -value $value \
        -onvalue $onvalue -offvalue $offvalue \
        -highlightthickness $highlightthickness \
        -anchor $anchor -font $font -padx $padx -pady $pady
    if {![info exists treb_buttonbar(order,$base)]} {
        set treb_buttonbar(order,$base) {}
    }
    if {$pos == "end"} {
        set pos [llength $treb_buttonbar(order,$base)]
    }
    set treb_buttonbar(order,$base) [linsert $treb_buttonbar(order,$base) $pos $base.$i]
    set treb_buttonbar(widths,$base.$i) [fakebutton:width $base.$i]
    set treb_buttonbar(data,$base.$i) $data
    set treb_buttonbar(cols,$base) 0
    buttonbar:refresh $base
    bind $base.$i <<ContextMenu>> "buttonbar:contextmenu $base [list $data]"
    return $base.$i
}

proc buttonbar:calccols {base minwidth cols} {
    if {$cols <= 1} { return 1 }
    global treb_buttonbar
    for {set col 0} {$col < $cols} {incr col} {
        set treb_buttonbar(colwidths,$base,$col) 0
    }
    set col 0
    set totalwidth 0
    set winwidth [winfo width $base]
    foreach child $treb_buttonbar(order,$base) {
        set childwidth $treb_buttonbar(widths,$child)
        if {$childwidth < $minwidth} {
            set childwidth $minwidth
        }
        if {$childwidth > $treb_buttonbar(colwidths,$base,$col)} {
            set treb_buttonbar(colwidths,$base,$col) $childwidth
        }
        incr totalwidth $treb_buttonbar(colwidths,$base,$col)
        if {$totalwidth >= $winwidth} {
            return [buttonbar:calccols $base $minwidth $col]
        }
        incr col
        if {$col >= $cols} {
            set col 0
            set totalwidth 0
        }
    }
    set totalwidth 0
    for {set col 0} {$col < $cols} {incr col} {
        incr totalwidth $treb_buttonbar(colwidths,$base,$col)
        if {$totalwidth >= $winwidth} {
            return [buttonbar:calccols $base $minwidth $col]
        }
    }
    return $cols
}


proc buttonbar:get_minwidth {base} {
    global treb_buttonbar
    if {![info exists treb_buttonbar(minwidth,$base)]} {
        return 0
    }
    return $treb_buttonbar(minwidth,$base)
}


proc buttonbar:set_minwidth {base minwidth} {
    global treb_buttonbar
    set treb_buttonbar(minwidth,$base) $minwidth
    buttonbar:refresh $base
}


proc buttonbar:refresh {base} {
    global treb_buttonbar
    if {[info exists treb_buttonbar(refreshing)]} return
    set treb_buttonbar(refreshing) 1
    set minwidth $treb_buttonbar(minwidth,$base)
    set cnt [llength $treb_buttonbar(order,$base)]
    set cols [buttonbar:calccols $base $minwidth $cnt]
    if {![info exists treb_buttonbar(order,$base)]} {
        set treb_buttonbar(order,$base) {}
    }
    if {[info exists treb_buttonbar(cols,$base)]} {
        if {$cols == $treb_buttonbar(cols,$base)} {
            unset treb_buttonbar(refreshing)
            return
        }
    }
    set treb_buttonbar(cols,$base) $cols
    set row 0
    set col 0
    foreach child $treb_buttonbar(order,$base) {
        if {$col >= $cols} {
            set col 0
            incr row
        }
        grid columnconf $base $col -weight 0 -minsize $minwidth
        grid rowconf $base $row -weight 0
        grid $child -row $row -column $col \
            -sticky nsew -padx 0 -pady 0 -ipadx 0 -ipady 0
        incr col
    }
    incr row
    grid columnconf $base $cols -weight 1
    grid rowconf $base $row -weight 1
    update idletasks
    unset treb_buttonbar(refreshing)
}

proc buttonbar:clear {base} {
    foreach btn [winfo children $base] {
        destroy $btn
    }
}


