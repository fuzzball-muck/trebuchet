proc /qbutton {opt args} {
    dispatcher /qbutton $opt $args
}

proc /qbutton:barvisible {} {
    global widget
    return [winfo ismapped $widget(qbuttons)]
}

proc /qbutton:hidebar {} {
    global widget
    buttonbar:show $widget(qbuttons) 0
    /prefs:set show_qbuttons 0
    if {![/prefs:get show_compass]} {
        buttonbar:show $widget(bars) 0
    }
}

proc /qbutton:showbar {} {
    global widget
    buttonbar:show $widget(bars) 1
    buttonbar:show $widget(qbuttons) 1
    /prefs:set show_qbuttons 1
}

proc /qbutton:hideshow {} {
    if {[/prefs:get show_qbuttons]} {
        /qbutton:showbar
    } else {
        /qbutton:hidebar
    }
}

proc /qbutton:togglebar {} {
    if {[/prefs:get show_qbuttons]} {
        /qbutton:hidebar
    } else {
        /qbutton:showbar
    }
}

proc /qbutton:edit {{item ""}} {
    if {$item == ""} {
        /editdlog QuickButtons QuickButton /qbutton
    } else {
        /newdlog QuickButton /qbutton $item
    }
}

tcl::OptProc /qbutton:add {
    {name    {}    "The name of the qbutton to create."}
    {script  {}    "The script to evaluate when this qbutton is run."}
    {-tcl          "Evaluate the script as TCL, not as user commands."}
} {
    global QButtons tcl_platform
    global widget
    if {$name == ""} {
        return
    }
    if {[/qbutton:exists $name]} {
        set preexistant 1
        buttonbar:delete $widget(qbuttons) [/qbutton:get _button $name]
    } else {
        set preexistant 0
    }
    if {$tcl_platform(winsys) == "aqua"} {
        set hlthick 2
	set bdwidth 3
    } else {
        set hlthick 0
	set bdwidth 1
    }
    if {$tcl_platform(platform) == "windows"} {
        set relief "raised"
    } else {
        set relief "flat"
    }
    if {$tcl} {
        set cmd $script
    } else {
        set cmd "process_commands [list $script] \[/socket:foreground\]"
    }
    set btn [buttonbar:add $widget(qbuttons) end \
        -data $name -text $name -relief $relief \
        -borderwidth $bdwidth -highlightthickness $hlthick \
        -command $cmd -padx 0 -pady 0]
    set QButtons($name) [list $script $tcl $btn]
    if {$preexistant} {
        /qbutton:notifyregistered update $name
    } else {
        /qbutton:notifyregistered add $name
    }
    global dirty_preferences; set dirty_preferences 1
    return "QuickButton added."
}


proc /qbutton:delete_confirm {name} {
    set results [/yesno_dlog "Delete QuickButton" \
        "Are you sure you wish to delete the QuickButton named '$name'?" \
        "yes" "warning"]
    if {$results == "yes"} {
        return [/qbutton:delete $name]
    }
    return ""
}


proc /qbutton:delete {name} {
    global QButtons
    global widget
    if {![/qbutton:exists $name]} {
        error "/qbutton delete: No such QuickButton!"
    }
    buttonbar:delete $widget(qbuttons) [/qbutton:get _button $name]
    unset QButtons($name)
    /qbutton:notifyregistered delete name
    global dirty_preferences; set dirty_preferences 1
    return "QuickButton deleted."
}

proc /qbutton:names {{pattern *}} {
    global QButtons
    return [lsort -dictionary [array names QButtons $pattern]]
}

proc /qbutton:exists {name} {
    global QButtons
    return [info exists QButtons($name)]
}

proc /qbutton:get {entry name} {
    global QButtons
    if {![/qbutton:exists $name]} {
        error "/qbutton get: No such QuickButton!"
    }
    switch -exact -- $entry {
        script   {return [lindex $QButtons($name) 0]}
        tcl      {return [lindex $QButtons($name) 1]}
        _button  {return [lindex $QButtons($name) 2]}
        default  {error "/qbutton get: Entry '$entry' must be 'script', 'tcl' or '_button'."}
    }
}

proc /qbutton:set {entry name value} {
    global QButtons
    if {![/qbutton:exists $name]} {
        error "/qbutton set: No such QuickButton!"
    }
    set qbutton $QButtons($name)
    switch -exact -- $entry {
        script  {set QButtons($name) [lreplace $qbutton 0 0 $value]}
        tcl     {set QButtons($name) [lreplace $qbutton 1 1 $value]}
        _button {set QButtons($name) [lreplace $qbutton 2 2 $value]}
        default {error "/qbutton set: Entry '$entry' must be 'script', 'tcl' or '_button'."}
    }
    return ""
}

proc /qbutton:list {{pattern *}} {
    set oot ""
    foreach qbutton [/qbutton:names $pattern] {
        if {$oot != ""} {
            append oot "\n"
        }
        append oot "/qbutton add [list $qbutton]"
        append oot " [list [/qbutton:get script $qbutton]]"
        if {[/qbutton:get tcl $qbutton]} {
            append oot " -tcl"
        }
    }
    return "$oot"
}

proc /qbutton:notifyregistered {type name} {
    global QButtonInfo
    foreach key [array names QButtonInfo "reg,*"] {
        eval "$QButtonInfo($key) [list $type] [list $name]"
    }
    return
}

proc /qbutton:register {id cmd} {
    global QButtonInfo
    if {[info exists QButtonInfo(reg,$id)]} {
        error "/qbutton register: That id is already registered!"
    }
    set QButtonInfo(reg,$id) "$cmd"
    return
}

proc /qbutton:deregister {id} {
    global QButtonInfo
    if {[info exists QButtonInfo(reg,$id)]} {
        unset QButtonInfo(reg,$id)
    }
    return
}

proc /qbutton:widgets {opt args} {
    dispatcher /qbutton:widgets $opt $args
}

proc /qbutton:widgets:create {master updatescript} {
    set base $master.fr

    frame $base -relief flat -borderwidth 2
    label $base.namelbl -text {Name} -anchor w
    entry $base.name -textvariable QButtonInfo($master,gui,name) -width 32
    label $base.scriptlbl -text {Script} -anchor w
    checkbutton $base.tclcb -text {Evaluate as TCL script} -onval 1 -offval 0 \
        -variable QButtonInfo($master,gui,tcl) -command $updatescript
    text $base.script -width 40 -height 10 -yscrollcommand "$base.scroll set"
    scrollbar $base.scroll -orient vert -command "$base.script yview"
    
    bind $base.name <Key> +$updatescript
    bind $base.script <Key> +$updatescript
    bind $base.name <<Cut>> +$updatescript
    bind $base.script <<Cut>> +$updatescript
    bind $base.name <<Paste>> +$updatescript
    bind $base.script <<Paste>> +$updatescript

    grid columnconfig $base 0 -weight 0
    grid columnconfig $base 1 -minsize 10
    grid columnconfig $base 2 -weight 1
    grid rowconfig $base 0 -minsize 10
    grid rowconfig $base 2 -minsize 10
    grid rowconfig $base 4 -minsize 5
    grid rowconfig $base 5 -weight 1
    grid $base.namelbl -row 1 -column 0 -sticky nsw
    grid $base.name -row 1 -column 2 -columnspan 2 -sticky nsew
    grid $base.scriptlbl -row 3 -column 0 -sticky nsw
    grid $base.tclcb -row 3 -column 2 -columnspan 2 -sticky nse
    grid $base.script -row 5 -column 0 -columnspan 3 -sticky nsew
    grid $base.scroll -row 5 -column 3 -sticky nsew

    grid rowconf $master 0 -weight 1
    grid columnconf $master 0 -weight 1
    grid $base -pady 5 -padx 10 -row 0 -column 0 -sticky nsew

    return $base
}

proc /qbutton:widgets:destroy {master} {
    destroy $master.fr
    return
}

proc /qbutton:widgets:init {master name} {
    global QButtonInfo
    set QButtonInfo($master,gui,name) $name
    set QButtonInfo($master,gui,tcl) [/qbutton get tcl $name]
    $master.fr.script delete 0.0 end
    $master.fr.script insert end [/qbutton get script $name]
    return
}

proc /qbutton:widgets:mknode {master} {
    global QButtonInfo
    if {$QButtonInfo($master,gui,tcl)} {
        /qbutton:add $QButtonInfo($master,gui,name) \
            [$master.fr.script get 0.0 "end - 1 chars"] -tcl
    } else {
        /qbutton:add $QButtonInfo($master,gui,name) \
            [$master.fr.script get 0.0 "end - 1 chars"]
    }
    return
}

proc /qbutton:widgets:getname {master} {
    global QButtonInfo
    return $QButtonInfo($master,gui,name)
}

proc /qbutton:widgets:setname {master name} {
    global QButtonInfo
    set QButtonInfo($master,gui,name) $name
    return
}

proc /qbutton:widgets:compare {master name} {
    global QButtonInfo
    if {![/qbutton:exists $name]} { return 0 }
    if {[/qbutton:get script $name] != [$master.fr.script get 0.0 "end - 1 chars"]} { return 0 }
    if {[/qbutton:get tcl $name] != $QButtonInfo($master,gui,tcl)} { return 0 }
    return 1
}

proc /qbutton:widgets:validate {master} {
    global QButtonInfo
    if {$QButtonInfo($master,gui,name) == ""} {return 0}
    if {[string trim [$master.fr.script get 0.0 "end - 1 chars"]] == ""} {return 0}
    return 1
}

