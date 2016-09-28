global worldbuttonInfo; set worldbuttonInfo(worldbuttons) {}
global world_button_number; set world_button_number 0
global world_button_current; set world_button_current {}

proc worldbutton:names {} {
    global worldbuttonInfo
    return $worldbuttonInfo(worldbuttons)
}

proc worldbutton:current {} {
    global world_button_current
    return $world_button_current
}

proc worldbutton:prev {} {
    set worldbtns [worldbutton:names]
    if {[llength $worldbtns] == 0} {
        global world_button_current
        set world_button_current ""
        return
    }
    set pos [lsearch -exact $worldbtns [worldbutton:current]]
    set numbtns [llength $worldbtns]
    set pos [expr {($pos + $numbtns - 1) % $numbtns}]
    worldbutton:press [lindex $worldbtns $pos]
    return
}

proc worldbutton:next {} {
    set worldbtns [worldbutton:names]
    if {[llength $worldbtns] == 0} {
        global world_button_current
        set world_button_current ""
        return
    }
    set pos [lsearch -exact $worldbtns [worldbutton:current]]
    set pos [expr {($pos + 1) % [llength $worldbtns]}]
    worldbutton:press [lindex $worldbtns $pos]
    return
}

proc worldbutton:setpressed {world} {
    global world_button_current
    set world_button_current $world
    return
}

proc worldbutton:press {world} {
    global worldbuttonInfo
    worldbutton:setpressed $world
    eval "$worldbuttonInfo($world,script)"
    return
}

proc worldbutton:setlight {world color} {
    global worldbuttonInfo
    set btn $worldbuttonInfo($world,button)
    set lightimg [gdm:Bitmap get ${color}lt]
    fakebutton:setimage $btn $lightimg
    return
}


proc worldbutton:add {{world ""} {script ""}} {
    global widget treb_fonts
    global world_button_number
    global worldbuttonInfo
    global world_button_current
    set base $widget(worldsbar)
    incr world_button_number
    set inittitle $world
    if {$world == ""} {
        set world "World $world_button_number"
    }
    set lightimg [gdm:Bitmap get yellowlt]
    set name [buttonbar:add $base end -type radio \
                -text $world -image $lightimg -data $world \
                -command [list worldbutton:press $world] \
                -variable world_button_current -value $world \
                -anchor "w" -relief "groove" -borderwidth 2 \
                -padx 2 -pady 0 -font $treb_fonts(worldbar)]
    lappend worldbuttonInfo(worldbuttons) $world
    set worldbuttonInfo($world,script) $script
    set worldbuttonInfo($world,button) $name
    return $name
}

proc worldbutton:delete {world} {
    global widget
    global worldbuttonInfo
    set btn $worldbuttonInfo($world,button)
    buttonbar:delete $widget(worldsbar) $btn

    set worldbtns $worldbuttonInfo(worldbuttons)
    set pos [lsearch -exact $worldbtns $world]
    if {$pos >= 0} {
        set worldbtns [lreplace $worldbtns $pos $pos]
    }
    set worldbuttonInfo(worldbuttons) $worldbtns
}


