proc compass:new {base} {
    global compassInfo
    frame $base
    set dirs {
        {
            nw   nw
            n    north
            ne   ne
            up   up
        }
        {
            w    west
            in   in
            e    east
            out  out
        }
        {
            sw   sw
            s    south
            se   se
            down down
        }
    }
    set row 1
    foreach compassrow $dirs {
        set col 1
        foreach {dir dircmd} $compassrow {
            set compassInfo(cmd-$dir) $dircmd
            set btnimg [gdm:Bitmap get "compass_$dir"]
            fakebutton:new $base.b_$dir -image $btnimg \
                -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 \
                -command [list compass:invoke $base $dir]
            grid $base.b_$dir -row $row -column $col \
                -sticky nsew -padx 1 -pady 1 -ipadx 0 -ipady 0
            incr col
        }
        incr row
    }

    grid columnconfigure $base 0 -minsize 2
    grid columnconfigure $base $col -minsize 2
    grid rowconfigure $base 0 -minsize 2
    grid rowconfigure $base $row -minsize 2

    return $base
}


proc compass:invoke {base dir} {
    global compassInfo
    set world [/socket:foreground]
    /socket:sendln $world $compassInfo(cmd-$dir)
    set disp [/display]
    display:doautoscroll $disp
    display:markseen $disp
}


proc /compass:hide {} {
    global widget
    grid forget $widget(compass)
    /prefs:set show_compass 0
    if {![/prefs:get show_qbuttons]} {
        buttonbar:show $widget(bars) 0
    }
}


proc /compass:show {} {
    global widget
    buttonbar:show $widget(bars) 1
    grid $widget(compass) -in $widget(bars) -sticky nw -padx 1 -row 0 -column 0
    /prefs:set show_compass 1
}


proc /compass:hideshow {} {
    if {[/prefs:get show_compass]} {
        /compass:show
    } else {
        /compass:hide
    }
}


proc /compass:toggle {} {
    if {[/prefs:get show_compass]} {
        /compass:hidebar
    } else {
        /compass:showbar
    }
}


