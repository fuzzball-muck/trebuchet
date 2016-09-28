proc /macro {opt args} {
    dispatcher /macro $opt $args
}

proc /macro:edit {{item ""}} {
    if {$item == ""} {
        /editdlog Macros Macro /macro
    } else {
        /newdlog Macro /macro $item
    }
}

tcl::OptProc /macro:add {
    {name    {}    "The name of the macro to create."}
    {script  {}    "The script to evaluate when this macro is run."}
    {-tcl          "Flag that the script is TCL, not user commands."}
} {
    global Macros
    if {$name == ""} {
        return
    }
    set preexistant [info exists Macros($name)]
    set Macros($name) [list "$script" "$tcl"]
    if {$preexistant} {
        /macro:notifyregistered update $name
    } else {
        /macro:notifyregistered add $name
    }
    global dirty_preferences; set dirty_preferences 1
    return "Macro added."
}

proc /macro:delete {name} {
    global Macros
    if {![/macro:exists $name]} {
        error "/macro delete: No such Macro!"
    }
    unset Macros($name)
    /macro:notifyregistered delete $name
    global dirty_preferences; set dirty_preferences 1
    return "Macro deleted."
}

proc /macro:names {{pattern *}} {
    global Macros
    return [lsort -dictionary [array names Macros $pattern]]
}

proc /macro:exists {name} {
    global Macros
    return [info exists Macros($name)]
}

proc /macro:get {entry name} {
    global Macros
    if {![/macro:exists $name]} {
        error "/macro get: No such Macro!"
    }
    switch -exact -- $entry {
        script   {return [lindex $Macros($name) 0]}
        tcl      {return [lindex $Macros($name) 1]}
        default  {error "/macro get: Entry '$entry' must be 'script' or 'tcl'."}
    }
}

proc /macro:set {entry name value} {
    global Macros
    if {![/macro:exists $name]} {
        error "/macro set: No such Macro!"
    }
    set macro $Macros($name)
    switch -exact -- $entry {
        script {set Macros($name) [lreplace $macro 0 0 $value]}
        tcl    {set Macros($name) [lreplace $macro 1 1 $value]}
        default {error "/macro set: Entry '$entry' must be 'script' or 'tcl'."}
    }
    return ""
}

proc /macro:list {{pattern *}} {
    set oot ""
    foreach macro [/macro:names $pattern] {
        if {$oot != ""} {
            append oot "\n"
        }
        append oot "/macro add [list $macro]"
        append oot " [list [/macro:get script $macro]]"
        if {[/macro:get tcl $macro]} {
            append oot " -tcl"
        }
    }
    return "$oot"
}

proc /macro:execute {args} {
    set socket [/socket:current]
    while {[llength $args] > 1} {
        set opt [lindex $args 0]
        set val [lindex $args 1]
        switch -exact -- $opt {
            -w - -world {set socket $val}
            -- {set args [lreplace $args 0 0]; break}
            default {break}
        }
        set args [lreplace $args 0 1]
    }
    set macro [lindex $args 0]
    set tclflag [/macro:get tcl $macro]
    set cmdline [join [lrange $args 1 end]]
    unset args
    set script [list
        global args 0 1 2 3 4 5 6 7 8 9 ;
        set args $cmdline ;
        foreach {0 1 2 3 4 5 6 7 8 9} [concat [list $macro] $cmdline] break ;
    ]
    append script [/line_subst [/macro:get script $macro] $cmdline 1]
    if {$tclflag} {
        set result [uplevel #0 $script]
    } else {
        set result [process_commands $script $socket]
    }
    return $result
}

proc /macro:notifyregistered {type name} {
    global MacroInfo
    foreach key [array names MacroInfo "reg,*"] {
        eval "$MacroInfo($key) [list $type] [list $name]"
    }
    return
}

proc /macro:register {id cmd} {
    global MacroInfo
    if {[info exists MacroInfo(reg,$id)]} {
        error "/macro register: That id is already registered!"
    }
    set MacroInfo(reg,$id) "$cmd"
    return
}

proc /macro:deregister {id} {
    global MacroInfo
    if {[info exists MacroInfo(reg,$id)]} {
        unset MacroInfo(reg,$id)
    }
    return
}

proc /macro:widgets {opt args} {
    dispatcher /macro:widgets $opt $args
}

proc /macro:widgets:create {master updatescript} {
    set base $master.fr

    frame $base -relief flat -borderwidth 2
    label $base.namelbl -text {Name} -anchor w
    entry $base.name -textvariable MacroInfo($master,gui,name) -width 32
    label $base.scriptlbl -text {Script} -anchor w
    checkbutton $base.tclcb -text {Evaluate as TCL script} -onval 1 -offval 0 \
        -variable MacroInfo($master,gui,tcl) -command $updatescript
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

proc /macro:widgets:destroy {master} {
    destroy $master.fr
    return
}

proc /macro:widgets:init {master name} {
    global MacroInfo
    set MacroInfo($master,gui,name) $name
    set MacroInfo($master,gui,tcl) [/macro get tcl $name]
    $master.fr.script delete 0.0 end
    $master.fr.script insert end [/macro get script $name]
    return
}

proc /macro:widgets:mknode {master} {
    global MacroInfo
    if {$MacroInfo($master,gui,tcl)} {
        /macro:add $MacroInfo($master,gui,name) \
            [$master.fr.script get 0.0 "end - 1 chars"] -tcl
    } else {
        /macro:add $MacroInfo($master,gui,name) \
            [$master.fr.script get 0.0 "end - 1 chars"]
    }
    return
}

proc /macro:widgets:getname {master} {
    global MacroInfo
    return $MacroInfo($master,gui,name)
}

proc /macro:widgets:setname {master name} {
    global MacroInfo
    set MacroInfo($master,gui,name) $name
    return
}

proc /macro:widgets:compare {master name} {
    global MacroInfo
    if {![/macro:exists $name]} { return 0 }
    if {[/macro:get script $name] != [$master.fr.script get 0.0 "end - 1 chars"]} { return 0 }
    if {[/macro:get tcl $name] != $MacroInfo($master,gui,tcl)} { return 0 }
    return 1
}

proc /macro:widgets:validate {master} {
    global MacroInfo
    if {$MacroInfo($master,gui,name) == ""} {return 0}
    if {[string trim [$master.fr.script get 0.0 "end - 1 chars"]] == ""} {return 0}
    return 1
}

