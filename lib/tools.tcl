proc /tool {opt args} {
    dispatcher /tool $opt $args
}

proc /tool:edit {{item ""}} {
    if {$item == ""} {
        /editdlog Tools Tool /tool
    } else {
        /newdlog Tool /tool $item
    }
}

tcl::OptProc /tool:add {
    {name "" "Required name of tool"}
    {?path? "" "Required path to tool"}
    {-disabled "Disables tool."}
} {
    global tools
    if {$name == ""} {
        return
    }
    #global dirty_preferences; set dirty_preferences 1
    set preexistant [/tool:exists $name]
    set tools($name) [list $path $disabled]
    if {$preexistant} {
        /tool:notifyregistered update $name
    } else {
        /tool:notifyregistered add $name
    }
    return "Tool added."
}

proc /tool:delete {name} {
    global tools
    if {![/tool:exists $name]} {
        error "/tool delete: No such Tool!"
    }
    unset tools($name)
    /tool:notifyregistered delete $name
    return "Tool deleted."
}

proc /tool:names {{pattern *}} {
    global tools
    return [lsort -dictionary [array names tools $pattern]]
}

proc /tool:exists {name} {
    global tools
    return [info exists tools($name)]
}

proc /tool:get {entry name} {
    global tools
    if {![/tool:exists $name]} {
        error "/tool get: No such Tool!"
    }
    switch -exact -- $entry {
        path     {return [lindex $tools($name) 0]}
        disabled {return [lindex $tools($name) 1]}
        default  {error "/tool get: Entry '$entry' must be one of path, or enabled."}
    }
}

proc /tool:set {entry name value} {
    global tools
    if {![/tool:exists $name]} {
        error "/tool set: No such Tool!"
    }
    set tool $tools($name)
    switch -exact -- $entry {
        path     {set tools($name) [lreplace $tool 0 0 $value]}
        disabled {set tools($name) [lreplace $tool 1 1 $value]}
        default  {error "/tool set: Entry '$entry' must be one of path, or enabled."}
    }
    return ""
}

proc /tool:list {{pattern *}} {
    set oot ""
    foreach tool [/tool:names $pattern] {
        if {$oot != ""} {
            append oot "\n"
        }
        append oot "/tool add [list $tool]"
        append oot " [list [/tool:get path $tool]]"
        if {[/tool:get disabled $tool]} {
            append oot " -disabled"
        }
    }
    return "$oot"
}

proc /tool:start {name} {
    global tools
    if {![/tool:exists $name]} {
        error "/tool start: No such Tool!"
    }
    if {[info exists ${name}::Start]} {
        uplevel #0 ${name}::Start
    }

    return ""
}

proc /tool:load {{pkg ""}} {
    global treb_root_dir

    set oldwd [pwd]
    if {$pkg == ""} {
        set pkg "*"
    }
    set paths [glob -nocomplain -- [file join $treb_root_dir pkgs $pkg]]
    if {[llength $paths] == 0 && $pkg != "*"} {
        error "Could not locate the package $pkg."
    }
    foreach path $paths {
        if {[file isdirectory $path]} {
            if {![catch {
                cd $path
                uplevel #0 "source toolinit.tcl"
            }]} {
                /tool:add [lindex [file split $path] end] $path
            }
        } elseif {[file isfile $path]} {
            if {![catch {
                uplevel #0 "source $path"
            }]} {
                set name [lindex [file split $path] end]
                if {[string match "*.tcl" $name]} {
                    set len [string length $name]
                    incr len -5
                    set name [string range $name 0 $len]
                }
                /tool:add $name $path
            }
        }
    }
    cd $oldwd
    return
}

proc /tool:notifyregistered {type name} {
    global ToolInfo
    foreach key [array names ToolInfo "reg,*"] {
        eval "$ToolInfo($key) [list $type] [list $name]"
    }
    return
}

proc /tool:register {id cmd} {
    global ToolInfo
    if {[info exists ToolInfo(reg,$id)]} {
        error "/tool register: That id is already registered!"
    }
    set ToolInfo(reg,$id) "$cmd"
    return
}

proc /tool:deregister {id} {
    global ToolInfo
    if {[info exists ToolInfo(reg,$id)]} {
        unset ToolInfo(reg,$id)
    }
    return
}

proc /tool:widgets {opt args} {
    dispatcher /tool:widgets $opt $args
}

proc /tool:widgets:create {master updatescript} {
    global treb_tool_dir
    set base $master.fr

    frame $base -relief flat -borderwidth 2
    label $base.namelbl -text Name -anchor w
    label $base.pathlbl -text Path -anchor w

    entry $base.name -textvariable ToolInfo($master,gui,name)
    entry $base.path -textvariable ToolInfo($master,gui,path)
    button $base.pathbtn -text "Choose..." -command "
            global ToolInfo
            set initialdir \$ToolInfo([list $master],gui,path)
            if {\$initialdir == {}} {
                set initialdir [list $treb_tool_dir]
            }
            set result \[tk_chooseDirectory -title {Tool path} \
                            -initialdir \$initialdir \
                            -mustexist 1 -parent [list $master]\]
            if {\$result != {}} {
                set ToolInfo([list $master],gui,path) \$result
                $updatescript
            }
        "
    bind $base.name <Key> +$updatescript
    bind $base.path <Key> +$updatescript

    checkbutton $base.enabled -variable ToolInfo($master,gui,disabled) \
        -onval 0 -offval 1 -text "Enabled" -command $updatescript

    grid columnconfig $base 1 -weight 1
    grid rowconfig $base 3 -weight 1

    grid $base.namelbl -row 0 -column 0 -sticky nsew -padx 5 -pady 5
    grid $base.pathlbl -row 1 -column 0 -sticky nsew -padx 5 -pady 5

    grid $base.name    -row 0 -column 1 -sticky nsew -padx 10 -pady 5 -columnspan 2
    grid $base.path    -row 1 -column 1 -sticky nsew -padx 10 -pady 5
    grid $base.pathbtn -row 1 -column 2 -sticky e
    grid $base.enabled -row 2 -column 0 -columnspan 2 -sticky nsw \
        -padx 10 -pady 5

    grid rowconf $master 0 -weight 1
    grid columnconf $master 0 -weight 1
    grid $base -pady 5 -row 0 -column 0 -sticky new

    return $base
}

proc /tool:widgets:destroy {master} {
    destroy $master.fr
    return
}

proc /tool:widgets:clear {master} {
    global ToolInfo
    set ToolInfo($master,gui,name) ""
    set ToolInfo($master,gui,path) ""
    set ToolInfo($master,gui,disabled) 0
    return
}

proc /tool:widgets:init {master name} {
    global ToolInfo
    set ToolInfo($master,gui,name) $name
    set ToolInfo($master,gui,path) [/tool get path $name]
    set ToolInfo($master,gui,disabled) [/tool get disabled $name]
    return
}

proc /tool:widgets:mknode {master} {
    global ToolInfo
    set cmd "/tool:add $ToolInfo($master,gui,name)"
    append cmd " [list $ToolInfo($master,gui,path)]"
    if {$ToolInfo($master,gui,disabled)} {
        append cmd " -disabled"
    }
    eval $cmd
    return
}

proc /tool:widgets:getname {master} {
    global ToolInfo
    return $ToolInfo($master,gui,name)
}

proc /tool:widgets:setname {master name} {
    global ToolInfo
    set ToolInfo($master,gui,name) $name
    return
}

proc /tool:widgets:compare {master name} {
    global ToolInfo
    if {![/tool:exists $name]} { return 0 }
    if {[/tool:get path $name] != $ToolInfo($master,gui,path)} { return 0 }
    if {[/tool:get disabled $name] != $ToolInfo($master,gui,disabled)} { return 0 }
    return 1
}


