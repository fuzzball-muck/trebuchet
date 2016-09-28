
proc /bind {opt args} {
    dispatcher /bind $opt $args
}

proc /bind:edit {{item ""}} {
    if {$item == ""} {
        /editdlog "Keyboard Bindings" "Keyboard Binding" /bind
    } else {
        /newdlog "Keyboard Binding" /bind $item
    }
}

package require opt

tcl::OptProc /bind:add {
    {key    ""    "The keysym to bind to"}
    {script ""    "The script to evaluate"}
    {-tcl -bool 0 "Evaluate as TCL if set to true"}
} {
    global dirty_preferences
    if {$key == ""} {
        return
    }
    set dirty_preferences 1
    set preexistant [expr {[bind [/inbuf] $key] != {}}]
    if {$script != {}} {
        if {$tcl} {
            bind [/inbuf] $key "/socket:setforeground; $script ; break;#keybind"
        } else {
            bind [/inbuf] $key "/socket:setforeground; process_commands \{$script\}; break;#keybind"
        }
        if {$preexistant} {
            /bind:notifyregistered update $key
        } else {
            /bind:notifyregistered add $key
        }
        return "Binding added."
    } else {
        bind [/inbuf] $key {}
        /bind:notifyregistered delete $key
        return "Binding removed."
    }
}

proc /bind:delete {key} {
    if {[/bind:get script $key] != {}} {
        /bind:add $key {}
        return "Binding deleted."
    } else {
        error "/bind delete: There is no binding for '$key'."
    }
}

proc /bind:get {opt key} {
    if {![/bind:exists $key]} {
        error "/bind:get: That key is not bound!"
    }
    set bscript [bind [/inbuf] $key] 
    set showit [regexp "^/socket:setforeground; process_commands \{(.*)\}; break;#keybind\$" $bscript foo cscript]
    switch -exact -- $opt {
        script {
            if {$showit > 0} {
                return $cscript
            } else {
                set showit [regexp "^/socket:setforeground; (.*) ; break;#keybind\$" $bscript foo cscript]
                if {$showit > 0} {
                    return $cscript
                } else {
                    return $bscript
                }
            }
        }
        tcl {
            if {$showit > 0} {
            return 0
            } else {
            return 1
            }
        }
        default {error "/bind:get: $opt must be one of script or tcl."}
    }
}

proc /bind:names {{pattern *}} {
    set oot {}
    set bindslist [bind [/inbuf]]
    foreach binding $bindslist {
        if {[string match $pattern $binding]} {
            if {[/bind:exists $binding]} {
                lappend oot "$binding"
            }
        }
    }
    return $oot
}

proc /bind:list {{pattern *}} {
    set oot ""
    set bindslist [/bind:names $pattern]
    foreach binding $bindslist {
        set tcl [/bind:get tcl $binding]
        set bscript [/bind:get script $binding]
        if {$oot != ""} {
            append oot "\n"
        }
        append oot "/bind add $binding [list $bscript]"
        if {$tcl} { append oot " -tcl $tcl" }
    }
    return $oot
}

proc /bind:exists {name} {
    set bscript [bind [/inbuf] $name]
    if {$bscript == ""} {
        return 0
    }
    if {![string match "*;#keybind" $bscript]} {
        return 0
    }
    return 1
}

proc /bind:notifyregistered {type name} {
    global BindInfo
    foreach key [array names BindInfo "reg,*"] {
        eval "$BindInfo($key) [list $type] [list $name]"
    }
    return
}

proc /bind:register {id cmd} {
    global BindInfo
    if {[info exists BindInfo(reg,$id)]} {
        error "/bind register: That id is already registered!"
    }
    set BindInfo(reg,$id) "$cmd"
    return
}

proc /bind:deregister {id} {
    global BindInfo
    if {[info exists BindInfo(reg,$id)]} {
        unset BindInfo(reg,$id)
    }
    return
}


proc /bind:widgets {opt args} {
    dispatcher /bind:widgets $opt $args
}

proc bind:widgets:updatename {master} {
    global BindInfo
    global tcl_platform
    set esc $BindInfo($master,gui,modesc)
    set meta $BindInfo($master,gui,modmeta)
    set alt $BindInfo($master,gui,modalt)
    set ctrl $BindInfo($master,gui,modctrl)
    set shift $BindInfo($master,gui,modshift)
    set key $BindInfo($master,gui,modkey)
    if {[string length $key] == 1} {
        set key [string tolower $key]
    }

    set mods {}
    if {$ctrl} {append mods "Control-"}
    if {$shift} {
        append mods "Shift-"
        if {[string length $key] == 1} {
            set key [string toupper $key]
        }
    }
    if {$tcl_platform(os) == "Darwin" || $tcl_platform(platform) == "macintosh"} {
        if {$meta} {append mods "Command-"}
        if {$alt}  {append mods "Option-"}
    } else {
        if {$meta} {append mods "Meta-"}
        if {$alt}  {append mods "Alt-"}
    }
    
    set code {}
    if {$esc} {
        append code "<Key-Escape>"
    }
    append code "<$mods"
    append code "Key-$key>"
    set BindInfo($master,gui,name) $code
}

proc /bind:widgets:create {master updatescript} {
    global tcl_platform
    set base $master.fr

    frame $base -relief flat -borderwidth 2
    label $base.scriptlbl -text Script -anchor w

    set namecont [groupbox $base.name -text "Key Binding Name"]
    entry $namecont.name -textvariable BindInfo($master,gui,name) -width 32
    bind $namecont.name <Key> +$updatescript
    bind $namecont.name <<Cut>> +$updatescript
    bind $namecont.name <<Paste>> +$updatescript

    if {$tcl_platform(os) == "Darwin" || $tcl_platform(platform) == "macintosh"} {
	foreach {var keyname} {cmdimg command optnimg option ctrlimg control shftimg shift} {
	    set $var [gdm:Bitmap get $keyname]
	}
        fakebutton:new $namecont.esc   -type toggle -text "Esc"     -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modesc)
        fakebutton:new $namecont.meta  -type toggle -image $cmdimg  -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modmeta)
        fakebutton:new $namecont.alt   -type toggle -image $optnimg -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modalt)
        fakebutton:new $namecont.ctrl  -type toggle -image $ctrlimg -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modctrl)
        fakebutton:new $namecont.shift -type toggle -image $shftimg -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modshift)
    } else {
        checkbutton $namecont.esc -text "Esc" -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modesc)
        checkbutton $namecont.meta -text "Meta" -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modmeta)
        checkbutton $namecont.alt -text "Alt" -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modalt)
        checkbutton $namecont.ctrl -text "Ctrl" -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modctrl)
        checkbutton $namecont.shift -text "Shift" -command "bind:widgets:updatename $master ; $updatescript" -variable BindInfo($master,gui,modshift)
    }
    entry $namecont.key -textvariable BindInfo($master,gui,modkey) -width 16 -insertontime 0
    bind $namecont.key <Key-Meta_L> "continue"
    bind $namecont.key <Key-Meta_R> "continue"
    bind $namecont.key <Key-Alt_L> "continue"
    bind $namecont.key <Key-Alt_R> "continue"
    bind $namecont.key <Key-Control_L> "continue"
    bind $namecont.key <Key-Control_R> "continue"
    bind $namecont.key <Key-Shift_L> "continue"
    bind $namecont.key <Key-Shift_R> "continue"
    bind $namecont.key <Key-Caps_Lock> "continue"
    bind $namecont.key <Key> "set BindInfo($master,gui,modkey) %K ; bind:widgets:updatename $master ; $updatescript ; break"

    checkbutton $base.tcl -text "Evaluate as TCL script" -onvalue 1 -offvalue 0 \
        -variable BindInfo($master,gui,tcl) -command "$updatescript"
    frame $base.sfr -relief flat -borderwidth 0
    text $base.script -width 40 -height 10 -yscrollcommand "$base.sfr.scroll set"
    bind $base.script <Key> +$updatescript
    bind $base.script <<Cut>> +$updatescript
    bind $base.script <<Paste>> +$updatescript
    scrollbar $base.sfr.scroll -command "$base.script yview"

    pack $namecont.name -side top -expand 1 -fill x -padx 5 -pady 8
    pack $namecont.esc -side left -padx 5
    if {$tcl_platform(platform) != "windows"} {
        pack $namecont.meta -side left
    }
    pack $namecont.alt -side left -padx 5
    pack $namecont.ctrl -side left
    pack $namecont.shift -side left -padx 5
    pack $namecont.key -side left -expand 1 -fill x -padx 5 -pady 5

    pack $base.sfr.scroll -side right -expand 0 -fill y
    pack $base.script -in $base.sfr -side left -expand 1 -fill both
    grid columnconfig $base 0 -minsize 5
    grid columnconfig $base 1 -weight 1
    grid columnconfig $base 2 -minsize 5
    grid columnconfig $base 5 -minsize 5
    grid rowconfig $base 0 -minsize 5
    grid rowconfig $base 2 -minsize 5
    #grid rowconfig $base 4 -minsize 5
    grid rowconfig $base 5 -weight 1
    #grid rowconfig $base 6 -minsize 5

    # NNNNNNNNNNNNNNNNN-NNNNN
    # LLLLLL            TTTTT
    # SSSSSSSSSSSSSSSSS-SSSSS

    grid $base.name      -row 1 -column 1 -sticky nsw  -columnspan 3
    grid $base.scriptlbl -row 3 -column 1 -sticky nsw
    grid $base.tcl       -row 3 -column 3 -sticky nse
    grid $base.sfr       -row 5 -column 1 -sticky nsew -columnspan 3

    grid rowconf $master 0 -weight 1
    grid columnconf $master 0 -weight 1
    grid $base -pady 5 -row 0 -column 0 -sticky nsew

    return $base
}

proc /bind:widgets:destroy {master} {
    destroy $master.fr
    return
}

proc /bind:widgets:init {master name} {
    global BindInfo
    set BindInfo($master,gui,name) $name
    set key $name
    set BindInfo($master,gui,modesc) 0
    set BindInfo($master,gui,modalt) 0
    set BindInfo($master,gui,modctrl) 0
    set BindInfo($master,gui,modshift) 0
    set BindInfo($master,gui,modmeta) 0
    if {[regexp "^<Key-Escape>" $key]} {
        set BindInfo($master,gui,modesc) 1
        regsub "^<Key-Escape>" $key "" key
    }
    if {[regexp "^<Control-" $key]} {
        set BindInfo($master,gui,modctrl) 1
        regsub "^<Control-" $key "<" key
    }
    if {[regexp "^<Shift-" $key]} {
        set BindInfo($master,gui,modshift) 1
        regsub "^<Shift-" $key "<" key
    }
    if {[regexp "^<Command-" $key]} {
        set BindInfo($master,gui,modmeta) 1
        regsub "^<Command-" $key "<" key
    }
    if {[regexp "^<Option-" $key]} {
        set BindInfo($master,gui,modalt) 1
        regsub "^<Option-" $key "<" key
    }
    if {[regexp "^<Meta-" $key]} {
        set BindInfo($master,gui,modmeta) 1
        regsub "^<Meta-" $key "<" key
    }
    if {[regexp "^<Alt-" $key]} {
        set BindInfo($master,gui,modalt) 1
        regsub "^<Alt-" $key "<" key
    }
    if {[regexp "^<Key-" $key]} {
        regsub "^<Key-" $key "" key
        regexp "^\(.*\)>" $key foo key
    }
    set BindInfo($master,gui,modkey) $key
    set BindInfo($master,gui,tcl) [/bind:get tcl $name]
    $master.fr.script delete 0.0 end
    $master.fr.script insert end [/bind:get script $name]
    return
}

proc /bind:widgets:mknode {master} {
    global BindInfo
    /bind:add $BindInfo($master,gui,name) \
        [$master.fr.script get 0.0 "end - 1 chars"] \
        -tcl $BindInfo($master,gui,tcl)
    return
}

proc /bind:widgets:getname {master} {
    global BindInfo
    return $BindInfo($master,gui,name)
}

proc /bind:widgets:setname {master name} {
    global BindInfo
    set BindInfo($master,gui,name) $name
    return
}

proc /bind:widgets:compare {master name} {
    global BindInfo
    if {![/bind:exists $name]} { return 0 }
    if {[/bind:get tcl $name] != $BindInfo($master,gui,tcl)} { return 0 }
    if {[/bind:get script $name] != [$master.fr.script get 0.0 "end - 1 chars"]} {
        return 0
    }
    return 1
}

proc /bind:widgets:validate {master} {
    global BindInfo
    if {$BindInfo($master,gui,name) == ""} {return 0}
    if {[string trim [$master.fr.script get 0.0 "end - 1 chars"]] == ""} {return 0}
    return 1
}

