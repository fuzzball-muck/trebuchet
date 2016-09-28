# Routines for /menu handling.

global MenusInfo

proc menu:normalize_name {name} {
    regsub -all -nocase {[^A-Z_0-9|]} [string tolower $name] {} name
    return $name
}


proc menu:name2path {name} {
    set iname [menu:normalize_name $name]
    set wpath [concat .mw.menu [split $iname "|"]]
    regsub -all -nocase {\.([0-9])} [join $wpath "."] {.num_\1} wname
    return $wname
}


proc menu:join_name {ipath iname} {
    if {$ipath != {}} {
        return "$ipath|$iname"
    } else {
        return "$iname"
    }
}


proc menu:process_name {name newnamevar underlinevar} {
    upvar $underlinevar uvar
    upvar $newnamevar nvar
    set name [lindex [split $name "|"] end]
    regsub -all {\&\&} $name {~} tmp
    set uvar [string first "&" $tmp]
    regsub -all {\&} $tmp {} tmp
    regsub -all {~} $tmp {\&} nvar
    return
}


proc menu:position {iparent iname} {
    global MenusInfo
    set ipos 0
    foreach child [/menu:children $iparent] {
        if {$child == $iname} break
        if {$MenusInfo(prevstate-$child) != "" && $MenusInfo(prevstate-$child) != "hidden"} {
            incr ipos
        }
    }
    return $ipos
}


proc menu:invoke {base item} {
    set statecmd [/menu:get statecmd $item]
    set state "normal"
    if {$statecmd != {}} {
        if {[catch {eval $statecmd} state]} {
            global errorInfo
            set errInfo $errorInfo
            /error "" "[/menu:get name $item] statecommand failed: $state" $errInfo
            set state "disabled"
        }
    }
    if {[/menu:get type $item] == "cascade" && [/menu:children $item] == {}} {
        set state "disabled"
    }
    if {$state == "normal"} {
        set cmd [/menu:get command $item]
        set cmd "/socket:setcurrent \[/socket:foreground\];$cmd"
        uplevel #0 $cmd
    }
}


proc menu:bind_accelerator {base binding item} {
    if {$binding == ""} {
        return
    }
    set keybind "<"
    set pos [string last "+" $binding]
    if {$pos != -1} {
        set key [string range $binding [incr pos] end]
    } else {
        set key $binding
    }
    switch -exact $key {
        Del { set key Delete }
        ":" { set key colon }
        "=" { set key equals }
    }

    set binding [string tolower $binding]
    if {[string match "*option+*" $binding]} {
        append keybind "Option-"
    } elseif {[string match "*meta+*" $binding]} {
        append keybind "Meta-"
    }
    if {[string match "*command+*" $binding]} {
        append keybind "Command-"
    } elseif {[string match "*alt+*" $binding]} {
        append keybind "Alt-"
    }
    if {[string match "*control+*" $binding]} {
        append keybind "Control-"
    } elseif {[string match "*ctrl+*" $binding]} {
        append keybind "Control-"
    }
    if {[string match "*shift+*" $binding]} {
        append keybind "Shift-"
        if {[string length $key] == 1} {
            set key [string toupper $key]
        }
    } else {
        if {[string length $key] == 1} {
            set key [string tolower $key]
        }
    }
    append keybind "Key-$key>"
    set window $base
    while {[winfo class $window] == "Menu"} {
        set window [winfo parent $window]
    }
    set window [winfo toplevel $window]
    if {$window == ".mw"} {
        set window [/inbuf]
    }
    append cmd [list menu:invoke $base $item]
    bind $window $keybind "$cmd ; break"
    return
}


proc /menu {opt args} {
    dispatcher /menu $opt $args
}


proc /menu:exists {name} {
    global MenusInfo
    set iname [menu:normalize_name $name]
    if {$name == {}} {
        return 1
    }
    return [info exists MenusInfo(type-$iname)]
}


proc /menu:parent {name} {
    global MenusInfo
    set iname [menu:normalize_name $name]
    set ipath [split $iname "|"]
    set ilen [llength $ipath]
    if {$ilen > 1} {
        set ipath [lrange $ipath 0 [expr {$ilen - 2}]]
    } else {
        set ipath {}
    }
    set iparent [join $ipath "|"]
}


proc /menu:children {name} {
    global MenusInfo
    if {[/menu:exists $name]} {
        set iname [menu:normalize_name $name]
        if {[info exists MenusInfo(children-$iname)]} {
            return $MenusInfo(children-$iname)
        } else {
            return {}
        }
    } else {
        error "/menu children: No such menu!"
    }
}


proc menu:list_recurse {pattern parent} {
    set oot ""
    if {$pattern == ""} {
        set pattern "*"
    }
    foreach child [/menu:children $parent] {
        if {$oot != ""} {
            append oot "\n"
        }
        set name [/menu:get name $child]
        if {[string match $pattern $name]} {
            append oot "/menu add [list $name]"

            set type [/menu:get type $child]
            if {$type != "command"} {
                append oot " -type [list $type] "
            }

            set accel [/menu:get accel $child]
            if {$accel != ""} {
                append oot " -accelerator [list $accel] "
            }

            set command [/menu:get command $child]
            if {$command != ""} {
                append oot " -command [list $command] "
            }

            set statecmd [/menu:get statecmd $child]
            if {$statecmd != ""} {
                append oot " -statecommand [list $statecmd] "
            }

            if {$type == "cascade"} {
                if {$oot != ""} {
                    append oot "\n"
                }
                append oot [menu:list_recurse $pattern $child]
            }
        }
    }
    return $oot
}


proc /menu:list {{pattern *}} {
    menu:list_recurse $pattern {}
}


proc /menu:delete {name} {
    global MenusInfo

    # destroy all child menu items.
    foreach child [/menu:children $name] {
        /menu:delete $child
    }

    if {[/menu:exists $name]} {
        set iname [menu:normalize_name $name]
        set iparent [/menu:parent $iname]

        if {$MenusInfo(submenu-$iname) != ""} {
            # If a cascade item with a submenu, destroy the submenu widget.
            destroy $MenusInfo(submenu-$iname)
        }

        # If this item was previously visible, remove it.
        if {$MenusInfo(prevstate-$iname) != "" && $MenusInfo(prevstate-$iname) != "hidden"} {
            set ipos [menu:position $iparent $iname]
            $MenusInfo(submenu-$iparent) delete $ipos
        }

        # Clear all data on this menu item.
        foreach key [array names MenusInfo "*-$iname"] {
            unset MenusInfo($key)
        }

        # Remove this item from its parent's child list.
        set ipos [lsearch -exact $MenusInfo(children-$iparent) $iname]
        set MenusInfo(children-$iparent) [lreplace $MenusInfo(children-$iparent) $ipos $ipos]
    }
}


proc /menu:get {entry name} {
    global MenusInfo
    if {![/menu:exists $name]} {
        error "/menu get: No such menu!"
    }
    set iname [menu:normalize_name $name]
    switch -exact -- $entry {
        name     {return $MenusInfo(name-$iname)}
        type     {return $MenusInfo(type-$iname)}
        accel    {return $MenusInfo(accel-$iname)}
        command  {return $MenusInfo(command-$iname)}
        statecmd {return $MenusInfo(statecmd-$iname)}
        parent   {return $MenusInfo(parent-$iname)}
        "variable" {return $MenusInfo(variable-$iname)}
        "value"  {return $MenusInfo(value-$iname)}
        default  {error "/menu get: Entry '$entry' must be 'name', 'type', 'accel', 'command', 'statecmd', 'parent', 'variable', or 'value'."}
    }
}


tcl::OptProc /menu:add {
    {name          {} "The unique name associated with this menu item."}
    {-type -choice {command label separator checkbox radiobutton cascade} "Menu item type."}
    {-accelerator  {} "Keyboard accelerator to invoke this menu item."}
    {-command      {} "Command to execute when this menu item is selected."}
    {-statecommand {} "Command to get menu item's state. (normal, disabled, hidden)"}
    {-variable     {} "Variable to store value of checkbox menu items."}
    {-value        {} "Value of radiobutton menu items."}
} {
    global MenusInfo
    set iname [menu:normalize_name $name]
    set iparent [/menu:parent $iname]

    if {$name == ""} {
        return
    }

    if {$iparent != {} && ![/menu:exists $iparent]} {
        error "/menu add: Parent menu doesn't exist!"
    }

    if {[/menu:exists $iname]} {
        /menu:delete $iname
    }

    set base ".mw"
    if {![winfo exists $base.menu]} {
        menu $base.menu -tearoff false
        set MenusInfo(submenu-) $base.menu
    }

    lappend MenusInfo(children-$iparent) $iname
    set MenusInfo(name-$iname) $name
    set MenusInfo(type-$iname) $type
    set MenusInfo(accel-$iname) $accelerator
    set MenusInfo(command-$iname) $command
    set MenusInfo(statecmd-$iname) $statecommand
    set MenusInfo(prevstate-$iname) ""
    set MenusInfo(variable-$iname) $variable
    set MenusInfo(value-$iname) $value
    set MenusInfo(parent-$iname) $iparent
    set MenusInfo(submenu-$iname) ""
    menu:bind_accelerator $base $accelerator $name
}


proc /menu:update {{name {}}} {
    global MenusInfo
    set iname [menu:normalize_name $name]
    if {![/menu:exists $iname]} {
        error "/menu update: No such menu!"
    }
    if {$iname != {} && [/menu:get type $iname] != "cascade"} {
        return ""
    }
    set thismenu $MenusInfo(submenu-$iname)
    foreach child [/menu:children $iname] {
        set statecmd [/menu:get statecmd $child]
        set state "normal"
        if {$statecmd != {}} {
            if {[catch {eval $statecmd} state]} {
                global errorInfo
                set errInfo $errorInfo
                /error "" "[/menu:get name $child] statecommand failed: $state" $errInfo
                set state "disabled"
            }
        }
        if {[/menu:get type $child] == "cascade" && [/menu:children $child] == {}} {
            set state "disabled"
        }
        set prevstate $MenusInfo(prevstate-$child)
        if {$prevstate == ""} {
            set prevstate "hidden"
        }
        if {$state != $prevstate} {
            set ipos [menu:position $iname $child]
            if {$ipos > [$thismenu index end]} {
                set ipos "end"
            }
            if {$prevstate == "hidden"} {
                switch -exact -- [/menu:get type $child] {
                    command {
                        set name [/menu:get name $child]
                        set accel [/menu:get accel $child]
                        set cmd [/menu:get command $child]
                        set cmd "/socket:setcurrent \[/socket:foreground\];$cmd"
                        menu:process_name $name name pos
                        $thismenu insert $ipos command -label $name \
                            -underline $pos -command $cmd \
                            -accelerator $accel -state $state
                    }
                    label {
                        set name [/menu:get name $child]
                        menu:process_name $name name pos
                        $thismenu insert $ipos command -label $name -state $state
                    }
                    separator {
                        $thismenu insert $ipos separator
                    }
                    checkbox {
                        set name [/menu:get name $child]
                        set accel [/menu:get accel $child]
                        set var [/menu:get variable $child]
                        set cmd [/menu:get command $child]
                        set cmd "/socket:setcurrent \[/socket:foreground\];$cmd"
                        menu:process_name $name name pos
                        $thismenu insert $ipos checkbutton -label $name \
                            -underline $pos -command $cmd \
                            -accelerator $accel -state $state \
                            -variable $var 
                    }
                    radiobutton {
                        set name [/menu:get name $child]
                        set accel [/menu:get accel $child]
                        set var [/menu:get variable $child]
                        set val [/menu:get value $child]
                        set cmd [/menu:get command $child]
                        set cmd "/socket:setcurrent \[/socket:foreground\];$cmd"
                        menu:process_name $name name pos
                        $thismenu insert $ipos radiobutton -label $name \
                            -underline $pos -command $cmd \
                            -accelerator $accel -state $state \
                            -variable $var -value $val
                    }
                    cascade {
                        set name [/menu:get name $child]
                        set name [lindex [split $name "|"] end]
                        set ichild [menu:normalize_name $child]
                        if {$MenusInfo(submenu-$ichild) == ""} {
                            set wname [menu:name2path $ichild]
                            menu $wname -tearoff 0 -postcommand [list /menu:update $ichild]
                            set MenusInfo(submenu-$ichild) $wname
                        }
                        menu:process_name $name name pos
                        set submenu $MenusInfo(submenu-$ichild)
                        $thismenu insert $ipos cascade -label $name -menu $submenu -underline $pos -state $state
                    }
                }
            } elseif {$state == "hidden"} {
                $MenusInfo(submenu-$iname) delete $ipos
            } else {
                $MenusInfo(submenu-$iname) entryconfigure $ipos -state $state
            }
            set MenusInfo(prevstate-$child) $state
        }
    }
    foreach child [/menu:children $iname] {
        if {[/menu:get type $child] == "cascade"} {
            /menu:update $child
        }
    }

    set base ".mw"
    if {[$base cget -menu] == ""} {
	$base configure -menu $base.menu
    }

    return ""
}






##########################################################################
# Specific routines for making our default menus.
##########################################################################

proc menu:getfocus {} {
    set foc [focus]
    if {$foc == ""} {
        return ""
    }
    if {[winfo class $foc] == "Menu"} {
        while {[winfo class $foc] == "Menu"} {
            set foc [winfo parent $foc]
        }
        set foc [focus -lastfor $foc]
    }
    return $foc
}


proc menu:world_connected_state {} {
    set world [/socket:foreground]
    if {$world == ""} {
        return "disabled"
    }
    if {[/socket:get state $world] == "Disconnected"} {
        return "disabled"
    }
    return "normal"
}


proc menu:world_closable_state {} {
    set world [/socket:foreground]
    if {$world == ""} {
        return "disabled"
    }
    return "normal"
}


proc menu:world_loggable_state {} {
    set world [/socket:foreground]
    if {$world == ""} {
        return "disabled"
    }
    if {[/socket:get logfile $world] == ""} {
        return "normal"
    } else {
        return "hidden"
    }
}


proc menu:world_deloggable_state {} {
    set world [/socket:foreground]
    if {$world == ""} {
        return "hidden"
    }
    if {[/socket:get logfile $world] == ""} {
        return "hidden"
    } else {
        return "normal"
    }
}


proc menu:cuttable_state {} {
    set focus [menu:getfocus]
    if {$focus == [/inbuf] || $focus == [/display]} {
        if {[$focus tag ranges sel] != ""} {
            return "normal"
        } else {
            return "disabled"
        }
    }
    return "disabled"
}


proc menu:copyable_state {} {
    set focus [menu:getfocus]
    if {$focus == [/display] || $focus == [/inbuf]} {
        if {[$focus tag ranges sel] != ""} {
            return "normal"
        } else {
            return "disabled"
        }
    }
    return "disabled"
}


proc menu:pastable_state {} {
    set focus [menu:getfocus]
    if {$focus == [/display]} {
        return "disabled"
    }
    if {$focus == [/inbuf]} {
        if {![catch {set result [selection get -selection CLIPBOARD]}] && $result != ""} {
            return "normal"
        } else {
            return "disabled"
        }
    }
    return "disabled"
}


proc menu:deletable_state {} {
    set focus [menu:getfocus]
    if {$focus == [/display]} {
        return "disabled"
    }
    if {$focus == [/inbuf]} {
        if {[$focus tag ranges sel] != ""} {
            return "normal"
        } else {
            return "disabled"
        }
    }
    return "disabled"
}


proc menu:spelling_state {} {
    if {[/spell:enabled]} {
        return "normal"
    } else {
        return "disabled"
    }
}


set MenusInfo(sepnum) 0

proc menu:generate_from_description {in description} {
    global MenusInfo
    while {[llength $description] > 0} {
        set typ [lindex $description 0]
        switch -glob -- $typ {
            platform {
                set oslist [lindex $description 1]
                set cmds   [lindex $description 2]
                set description [lrange $description 3 end]
                global tcl_platform
                switch -exact -- $tcl_platform(winsys) {
                    win32 { set os windows }
                    aqua  { set os macintosh }
                    x11   { set os unix }
                    default { set os other }
                }
                if {[lsearch -exact $oslist $os] != -1} {
                    menu:generate_from_description $in $cmds
                }
            }
            menu {
                set name        [lindex $description 1]
                set cmds        [lindex $description 2]
                set description [lrange $description 3 end]
                set name [menu:join_name $in $name]
                /menu:add $name -type cascade
                menu:generate_from_description $name $cmds
            }
            ---* {
                set description [lrange $description 1 end]
                incr MenusInfo(sepnum)
                set name "sep$MenusInfo(sepnum)"
                /menu:add [menu:join_name $in $name] -type separator
            }
            cmd {
                set name     [lindex $description 1]
                set accel    [lindex $description 2]
                set cmd      [lindex $description 3]
                set statecmd [lindex $description 4]
                set description [lrange $description 5 end]
                set name [menu:join_name $in $name]
                /menu:add $name -accelerator $accel -command $cmd -statecommand $statecmd
            }
            ptoggle {
                set cmd "global dirty_preferences; set dirty_preferences 1; "
                set name  [lindex $description 1]
                set accel [lindex $description 2]
                set pref  [lindex $description 3]
                append cmd [lindex $description 4]
                set statecmd [lindex $description 5]
                set description [lrange $description 6 end]
                set name [menu:join_name $in $name]
                /menu:add $name -type checkbox -accelerator $accel -command $cmd -statecommand $statecmd -variable [/prefs:getvar $pref]
            }
            pradio {
                set cmd "global dirty_preferences; set dirty_preferences 1; "
                set name  [lindex $description 1]
                set accel [lindex $description 2]
                set pref  [lindex $description 3]
                append cmd [lindex $description 4]
                set statecmd [lindex $description 5]
                set value [lindex $description 6]
                set description [lrange $description 7 end]
                set name [menu:join_name $in $name]
                /menu:add $name -type radiobutton -accelerator $accel -command $cmd -statecommand $statecmd -variable [/prefs:getvar $pref] -value $value
            }
        }
    }
}


proc init_main_menus {base} {
    global tcl_platform env

    set mac_apple_menu {
        cmd "About Trebuchet"                ""  {/show_about}  ""
        cmd "&Check Network for Updates..."  ""  {/web_upgrade} ""
        -----------------------------------
    }
    if {![info exists env(TREB_MAC_PREFS_MENU)]} {
        append mac_apple_menu {
            cmd "Preferences..."                 "Command+comma"  {/prefs:edit}  ""
        }
    }

    set menus "platform {macintosh} {
            menu {Apple} {
                $mac_apple_menu
            }
        }
    "

    append menus {
        menu "&File" {
            platform {macintosh} {
                cmd "New World..."          "Command+N"  {/newdlog World /world} ""
                cmd "Edit Worlds..."        "Command+E"  {/world:edit} ""
                cmd "Connect World..."      "Command+O"  {/connect_dlog} ""
                cmd "Disconnect World..."   "Command+Shift+D" {/dc} {menu:world_connected_state}
                cmd "Close World..."        "Command+W"  {/close} {menu:world_closable_state}
                -----------------------------------
                cmd "Start Logging..."      "Command+L"  {/log_dlog} {menu:world_loggable_state}
                cmd "Stop Logging"          "Command+L"  {/log off} {menu:world_deloggable_state}
                cmd "Send File..."          "Command+Shift+S" {/sendfile_dlog} {menu:world_connected_state}
            }
            platform {windows unix other} {
                cmd "&New World..."          ""  {/newdlog World /world} ""
                cmd "&Edit Worlds..."        ""  {/world:edit} ""
                cmd "C&onnect World..."      ""  {/connect_dlog} ""
                cmd "&Disconnect World..."   ""  {/dc} {menu:world_connected_state}
                cmd "&Close World..."        ""  {/close} {menu:world_closable_state}
                -----------------------------------
                cmd "Start &Logging..."      ""  {/log_dlog} {menu:world_loggable_state}
                cmd "Stop &Logging"          ""  {/log off} {menu:world_deloggable_state}
                cmd "Send &File..."          ""  {/sendfile_dlog} {menu:world_connected_state}
                -----------------------------------
                cmd "E&xit"                  ""  {/quit} ""
            }
        }
        menu "&Edit" {
            platform {macintosh} {
                cmd "Cut"                 "Command+X"  {/edit:cut} {menu:cuttable_state}
                cmd "Copy"                "Command+C"  {/edit:copy} {menu:copyable_state}
                cmd "Paste"               "Command+V"  {/edit:paste} {menu:pastable_state}
                cmd "Delete"              ""           {/edit:delete} {menu:deletable_state}
                cmd "Select All"          "Command+A"  {/edit:selectall} ""
                -----------------------------------
                cmd "Find"                "Command+F"  {/edit:find} ""
                -----------------------------------
                cmd "Spell-check"         "Command+L"  {/spell:check} {menu:spelling_state}
                ptoggle "Spell As You Type" ""  spell_as_you_type {/spell:update_showbad} {menu:spelling_state}
            }
            platform {windows unix other} {
                cmd "Cu&t"                "Ctrl+X"  {/edit:cut} {menu:cuttable_state}
                cmd "&Copy"               "Ctrl+C"  {/edit:copy} {menu:copyable_state}
                cmd "P&aste"              "Ctrl+V"  {/edit:paste} {menu:pastable_state}
                cmd "&Delete"             ""        {/edit:delete} {menu:deletable_state}
                cmd "Select All"          "Shift+Control+A" {/edit:selectall} ""
                -----------------------------------
                cmd "&Find"               "Ctrl+F"  {/edit:find} ""
                -----------------------------------
                cmd "Spell-check"         "F7"  {/spell:check} {menu:spelling_state}
                ptoggle "Spell As You Type" ""  spell_as_you_type {/spell:update_showbad} {menu:spelling_state}
            }
            -----------------------------------
            cmd "&Edit TCL Proc..."        ""        {/editproc_dlog} ""
        }
        menu "&View" {
            platform {macintosh} {
                cmd "&Scratchpad"              "Command+Option+S"  {/scratchpad} ""
                cmd "&Process List..."         "Command+Shift+P" {/ps_dlog} ""
                -----------------------------------
                ptoggle "&Compass Rose" ""         show_compass {/compass:hideshow} ""
                ptoggle "&Quickbutton Toolbar" ""  show_qbuttons {/qbutton:hideshow} ""
                -----------------------------------
		pradio "No Syntax Hilites"       ""  last_edit_mode {mainwin:syntax:changemode none} "" "none"
		pradio "TCL Syntax Hilites"      ""  last_edit_mode {mainwin:syntax:changemode tcl}  "" "tcl"
		pradio "MUF Syntax Hilites"      ""  last_edit_mode {mainwin:syntax:changemode muf}  "" "muf"
		pradio "MPI Syntax Hilites"      ""  last_edit_mode {mainwin:syntax:changemode mpi}  "" "mpi"
		pradio "C Syntax Hilites"        ""  last_edit_mode {mainwin:syntax:changemode c}    "" "c"
                -----------------------------------
                cmd "C&lear Scrollback"        "Command+Shift+R" {[/display] delete 1.0 end-1c} ""
                -----------------------------------
                cmd "Make window 80 columns wide" "" {/setwidth 80} ""
            }
            platform {windows unix other} {
                cmd "&Scratchpad"              ""  {/scratchpad} ""
                cmd "&Process List..."         ""  {/ps_dlog} ""
                -----------------------------------
                ptoggle "&Compass Rose       " ""  show_compass {/compass:hideshow} ""
                ptoggle "&Quickbutton Toolbar" ""  show_qbuttons {/qbutton:hideshow} ""
                -----------------------------------
                cmd "C&lear Scrollback"        ""        {[/display] delete 1.0 end-1c} ""
                -----------------------------------
                cmd "Make window 80 columns wide" "" {/setwidth 80} ""
            }
        }
        menu "&Local" {
        }
        menu "&Option" {
            platform {macintosh} {
                cmd "&QuickButtons..."         "Command+B"  {/qbutton:edit} ""
                cmd "&Macros..."               "Command+Option+M"  {/macro:edit} ""
                cmd "&Hilites && Triggers..."  "Command+T"  {/hilite:edit} ""
                cmd "&Font Styles..."          "Command+Shift+T"  {/style:edit} ""
                cmd "&Keyboard Bindings..."    "Command+K"  {/bind:edit} ""
                -----------------------------------
                cmd "S&tartup Script..."       ""  {/editstartup_dlog} ""
                -----------------------------------
                cmd "&Save settings"           "Command+S"  {/saveprefs -all} ""
                -----------------------------------
                cmd "Import settings..."       ""           {/load -request} ""
                cmd "Export settings..."       ""           {/saveprefs -request} ""
            }
            platform {windows unix other} {
                cmd "&QuickButtons..."         ""  {/qbutton:edit} ""
                cmd "&Macros..."               ""  {/macro:edit} ""
                cmd "&Hilites && Triggers..."  ""  {/hilite:edit} ""
                cmd "&Font Styles..."          ""  {/style:edit} ""
                cmd "&Keyboard Bindings..."    ""  {/bind:edit} ""
                -----------------------------------
                cmd "&Preferences..."          ""  {/prefs:edit} ""
                cmd "S&tartup Script..."       ""  {/editstartup_dlog} ""
                -----------------------------------
                cmd "&Save settings"           ""  {/saveprefs -all} ""
                -----------------------------------
                cmd "Import settings..."       ""  {/load -request} ""
                cmd "Export settings..."       ""  {/saveprefs -request} ""
            }
        }
        menu "&Help" {
            platform {windows unix other} {
                cmd "&Check Network for Updates..." ""  {/web_upgrade} ""
            }
            cmd "&Help Topics..."          ""  {/richview -file [file join $treb_docs_dir helpfile.trh]} ""
            -----------------------------------
            cmd "&Trebuchet FAQ..."        ""  {/web_view {http://www.belfry.com/fuzzball/trebuchet/faq.html}} ""
            cmd "&Recent Changes..."       ""  {/textdlog -readonly -buttons -file [file join $treb_root_dir changes.txt]} ""
            cmd "&Copyright && Warranty Info..." ""  {/show_copyright} ""
            cmd "&Bug Reporting..."        ""  {/web_view {https://sourceforge.net/bugs/?group_id=1440}} ""
            platform {windows unix other} {
                -----------------------------------
                cmd "&About..."                ""  {/show_about} ""
            }
        }
    }

    menu:generate_from_description {} $menus
    /menu:update

    if {$tcl_platform(os) == "Darwin"} {
        bind .mw <Command-Key-q> /quit
    }

    return ""
}


