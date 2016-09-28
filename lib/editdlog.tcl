#editdlog:new parent wintitle class cmd
#
# cmd must support the following:
#   cmd names                  returns the names of all existing items
#   cmd exists ITEM            returns true if given ITEM exists
#   cmd delete ITEM            deletes the given ITEM
#   cmd register ID CMD        registers a CMD to invoke when items change
#   cmd deregister ID          deregisters that command
#   cmd get CATEGORY ITEM      returns the CATEGORY of ITEM
#
#   cmd widgets create         creates a set of widgets that represent an item
#   cmd widgets destroy        destroys the widgets created in 'widget create'
#   cmd widgets init           sets widget values to reflect a given item
#   cmd widgets mknode         create a new item based on values in widgets
#   cmd widgets getname        returns the item name value in the widgets
#   cmd widgets setname        sets the item name field in the widgets
#   cmd widgets compare        compares the widget values to a given item
#   cmd widgets validate       returns true if the user supplied data is good
#

proc editdlog:getactive {base} {
    set item [$base.slist.list get active]
    if {$item == ""} {
        $base.slist.list activate 0
        set item [$base.slist.list get 0]
    }
    return $item
}

proc editdlog:updatechanged {base cmd} {
    if {![winfo exists $base]} {
        return
    }
    set name [$cmd widgets getname $base.client]
    if {$name == ""} {
	set valid 0
    } else {
	set valid 1
	catch {
	    set valid [$cmd:widgets:validate $base.client]
	} err
    }

    set item [editdlog:getactive $base]
    if {$item == ""} {
        $base.buttons.update configure -state disabled -text Update
        $base.buttons.delete configure -state disabled
        if {!$valid} {
            $base.buttons.add configure -state disabled
        } else {
            $base.buttons.add configure -state normal
        }
        return
    }

    if {!$valid} {
        $base.buttons.update configure -state disabled -text Update
        $base.buttons.delete configure -state normal
	$base.buttons.add configure -state disabled
        return
    }

    set namechanged [expr {$name != "$item"}]
    set datachanged [expr {![$cmd widgets compare $base.client $item]}]

    $base.buttons.delete configure -state normal
    if {$namechanged} {
        $base.buttons.add configure -state normal
        if {$datachanged} {
            $base.buttons.update configure -state normal -text Replace
        } else {
            $base.buttons.update configure -state normal -text Rename
        }
    } else {
        $base.buttons.add configure -state disabled
        if {$datachanged} {
            $base.buttons.update configure -state normal -text Update
        } else {
            $base.buttons.update configure -state disabled -text Update
        }
    }
}

proc editdlog:updateview {base cmd} {
    after 10 "
        set item \[editdlog:getactive $base\]
        if {\$item != \"\"} {
            $cmd:widgets:init $base.client \$item
            $base.buttons.add configure -state disabled
            $base.buttons.update configure -state disabled -text Update
        }
    "
}

proc editdlog:verify {base title caption default} {
    return [/yesno_dlog $title $caption $default "warning"]
}

proc editdlog:selectitem {base cmd item} {
    set last [$base.slist.list size]
    for {set i 0} {$i < $last} {incr i} {
        set litem [$base.slist.list get $i]
        if {$litem == $item} {
            $base.slist.list selection clear 0 end
            $base.slist.list selection set $i
            $base.slist.list activate $i
            $base.slist.list see $i
            editdlog:updateview $base $cmd
            return
        }
    }
    $base.slist.list selection clear 0 end
    $base.slist.list selection set 0
    $base.slist.list activate 0
    $base.slist.list see 0
    editdlog:updateview $base $cmd
    return
}

proc editdlog:updatelist {base cmd changetype changedname} {
    set topitem [$base.slist.list index @1,1]
    set cursel [$base.slist.list curselection]
    set item ""
    if {$cursel >= 0} {
        set item [$base.slist.list get $cursel]
    }

    $base.slist.list delete 0 end
    foreach name [$cmd names] {
	if {$name == ""} {
	    catch {$cmd delete $item}
	} else {
	    $base.slist.list insert end $name
	}
    }

    if {$item != ""} {
        if {$topitem > 0} {
            $base.slist.list yview $topitem
        }
        editdlog:selectitem $base $cmd $item
    } else {
        $base.slist.list selection clear 0 end
        $base.slist.list activate 0
        $base.slist.list selection set 0
    }
    editdlog:updatechanged $base $cmd
}

proc editdlog:synclist {base cmd} {
    if {[string match "*.client" $base]} {
        set len [string length $base]
        set base [string range $base 0 [expr {$len - 8}]]
    }
    if {[string match ".editdlog*" $base]} {
        editdlog:updatelist $base $cmd "" ""
        editdlog:selectitem $base $cmd [$cmd widgets getname $base.client]
    }
}

proc editdlog:exec {base parent class cmd action} {
    set item [editdlog:getactive $base]
    set newname [$cmd widgets getname $base.client]
    set newnameexists [expr {[$cmd exists $newname] && "$newname" != "$item"}]
    set namechanged [expr {"$newname" != "$item"}]
    if {[catch { set datachanged [expr {![$cmd widgets compare $base.client "$item"]}] }]} {
    	set datachanged 0
    }

    switch -exact -- $action {
        new {
            set num 1
            while {[winfo exists .newdlog$num]} {incr num}
            editdlog:newdlog .newdlog$num $class $cmd
        }
        add {
            if {$newnameexists} {
                set results [editdlog:verify $base "Replace $class" \
                    "Are you sure you wish to replace the $class named '$newname'?" \
                    yes]
                if {$results == "yes"} {
                    $cmd widgets mknode $base.client
                    editdlog:updatelist $base $cmd "" ""
                    editdlog:selectitem $base $cmd [$cmd widgets getname $base.client]
                }
            } else {
                $cmd widgets mknode $base.client
                editdlog:updatelist $base $cmd "" ""
                editdlog:selectitem $base $cmd [$cmd widgets getname $base.client]
            }
        }
        update {
            if {$namechanged} {
                if {$datachanged} {
                    set results [editdlog:verify $base "Replace $class" \
                        "Are you sure you wish to replace the $class named '$item' with '$newname'?" \
                        yes]
                } else {
                    set results [editdlog:verify $base "Rename $class" \
                        "Are you sure you wish to rename the $class named '$item' to '$newname'?" \
                        yes]
                }
                if {$results == "yes"} {
                    catch {$cmd delete $item}
                    $cmd widgets mknode $base.client
                    editdlog:updatelist $base $cmd "" ""
                    editdlog:selectitem $base $cmd [$cmd widgets getname $base.client]
                }
            } else {
                $cmd widgets mknode $base.client
                editdlog:updatelist $base $cmd "" ""
                editdlog:selectitem $base $cmd [$cmd widgets getname $base.client]
            }
        }
        delete {
            set results [editdlog:verify $base "Delete $class" \
                "Are you sure you wish to delete the $class named '$item'?" \
                yes]
            if {$results == "yes"} {
                $cmd delete $item
                editdlog:updatelist $base $cmd "" ""
                editdlog:selectitem $base $cmd ""
            }
        }
        done {
	    if {$newname == ""} {
		set valid 0
	    } else {
		set valid 1
		catch {
		    set valid [$cmd:widgets:validate $base.client]
		} err
	    }
            if {$valid} {
                if {$datachanged} {
                    if {$newnameexists} {
                        set results [editdlog:verify $base "Replace $class" \
                            "Do you wish to replace the $class named '$newname' with the changes you have made?" \
                            yes]
                    } else {
                        if {$item == ""} {
                            set results [editdlog:verify $base "Add new $class" \
                                "Do you wish to add the $class named '$newname'?" \
                                yes]
                        } else {
                            set results [editdlog:verify $base "Update changed $class" \
                                "Do you wish to update the $class named '$item' with the changes you have made?" \
                                yes]
                        }
                    }
                    if {$results == "yes"} {
                        if {$namechanged && $item != ""} {
                            catch {$cmd delete $item}
                        }
                        $cmd widgets mknode $base.client
                    }
                } elseif {$namechanged} {
                    if {$newnameexists} {
                        set results [editdlog:verify $base "Replace $class" \
                            "Do you wish to replace the $class named '$newname' with the changes you have made?" \
                            yes]
                    } else {
                        set results [editdlog:verify $base "Rename $class" \
                            "Do you wish to rename the $class named '$item' to '$newname'?" \
                            yes]
                    }
                    if {$results == "yes"} {
                        $cmd delete $item
                        $cmd widgets mknode $base.client
                    }
                }
            }
            after 50 "
                $cmd widgets destroy $base.client
                $cmd deregister $base
                after 50 destroy $base
                after 100 focus $parent
            "
        }
        default {error "Internal error!"}
    }
    return
}


proc editdlog:newdlog_updatechanged {base cmd} {
    if {![winfo exists $base]} {
        return
    }
    set name [$cmd widgets getname $base.client]
    if {$name == ""} {
	set valid 0
    } else {
	set valid 1
	catch {
	    set valid [$cmd:widgets:validate $base.client]
	} err
    }

    if {!$valid} {
	set newstate "disabled"
    } else {
	set newstate "normal"
    }
    if {[$base.buttons.add cget -state] != $newstate} {
	$base.buttons.add configure -state $newstate
    }
}


proc editdlog:newdlog {wname class cmd {defname ""}} {
    set parent [focus]
    if {$parent == ""} {
        set parent .mw
    }
    set base $wname
    if {[winfo exists $base]} {
        wm deiconify $base
        focus $base
        return $base
    }
    ###################
    # CREATING WIDGETS
    ###################
    toplevel $base
    wm minsize $base 200 150
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base "New $class"
    wm protocol $base WM_DELETE_WINDOW "$base.buttons.cancel invoke"
    place_window_default $base $parent

    frame $base.client
    $cmd widgets create $base.client "after idle [list editdlog:newdlog_updatechanged $base $cmd]"
    catch {$cmd widgets clear $base.client}
    frame $base.divider -borderwidth 2 -relief sunken -height 2
    frame $base.buttons
    button $base.buttons.cancel -text Cancel -width 8 -command "
        [list $cmd] widgets destroy [list $base.client]
        destroy $base
        if \{\[winfo exists [list $parent]\]\} \{
            focus [list $parent]
        \}
    "

    bind $base <Key-Escape> "$base.buttons.cancel invoke"
    if {![$cmd exists $defname]} {
        set add_caption "Add"
        bind $base <Alt-Key-a> "$base.buttons.add invoke"
    } else {
        set add_caption "Set"
        bind $base <Alt-Key-s> "$base.buttons.add invoke"
    }
    button $base.buttons.add -text $add_caption -width 8 -underline 0 -command "
        if {\[[list $cmd] exists [list $defname]\]} {
            catch {[list $cmd] delete [list $defname]}
        }
        [list $cmd] widgets mknode [list $base.client]
        [list $cmd] widgets destroy [list $base.client]
        destroy [list $base]
        if \{\[winfo exists [list $parent]\]\} \{
            editdlog:synclist [list [winfo toplevel $parent]] [list $cmd]
            focus [list $parent]
        \}
    "

    ###################
    # SETTING GEOMETRY
    ###################
    grid columnconf $base 0 -weight 1
    grid rowconf    $base 0 -weight 1
    grid $base.client       -column 0 -row 0 -sticky nesw
    grid $base.divider      -column 0 -row 1 -sticky nesw -padx 5
    grid $base.buttons      -column 0 -row 2 -sticky nesw

    grid columnconf $base.buttons 0 -weight 1
    grid $base.buttons.cancel -row 0 -column 1 -padx 10  -pady 10
    grid $base.buttons.add    -row 0 -column 2 -padx 10  -pady 10

    if {$defname == ""} {
        set i 1
        while {[$cmd exists "$class$i"]} {
            incr i
        }
        $cmd widgets setname $base.client "$class$i"
    } else {
        if {[$cmd exists $defname]} {
            $cmd widgets init $base.client $defname
        } else {
            $cmd widgets setname $base.client "$defname"
        }
    }

    editdlog:newdlog_updatechanged $base $cmd
    focus [editdlog:findnamewidget $base.client]

    return $base
}

proc editdlog:findnamewidget {w} {
    if {[winfo class $w] == "Entry"} {
        return $w
    }
    foreach child [winfo children $w] {
        set res [editdlog:findnamewidget $child]
	if {$res != ""} {
	    return $res
	}
    }
    return ""
}

proc editdlog:new {wname wintitle class cmd} {
    set base $wname
    set parent [focus]
    if {$parent == ""} {
        set parent .mw
    }
    if {[winfo exists $base]} {
        wm deiconify $base
        focus $base
        return $base
    }
    ####################
    # CREATING WIDGETS #
    ####################
    toplevel $base -class EditWin
    bind $base <Key-Escape> "$base.buttons.done   invoke ; break"
    bind $base <Alt-Key-n>  "$base.buttons.new    invoke ; break"
    bind $base <Alt-Key-a>  "$base.buttons.add    invoke ; break"
    bind $base <Alt-Key-u>  "$base.buttons.update invoke ; break"

    wm minsize $base 400 300
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base "$wintitle"
    wm protocol $base WM_DELETE_WINDOW "$base.buttons.done invoke"
    place_window_default $base $parent

    frame $base.slist
    listbox $base.slist.list -yscrollcommand "$base.slist.scroll set" \
        -exportselection false -takefocus 1
    bindtags $base.slist.list [list $base $base.slist.list Listbox all]
    bind $base.slist.list <ButtonRelease-1> "+focus $base.slist.list;editdlog:updateview $base $cmd"
    bind $base.slist.list <Key> "+editdlog:updateview $base $cmd"
    bind $base.slist.list <Key-Delete> "$base.buttons.delete invoke"
    scrollbar $base.slist.scroll -command "$base.slist.list yview" -orient vert
    frame $base.client
    $cmd widgets create $base.client "after idle \{editdlog:updatechanged $base $cmd\}"
    catch {$cmd widgets clear $base.client}
    frame $base.buttons
    button $base.buttons.new    -text New    -width 8 -underline 0 -command \
        "editdlog:exec $base $parent [list $class] [list $cmd] new"
    button $base.buttons.add    -text Add    -width 8 -underline 0 -command \
        "editdlog:exec $base $parent [list $class] [list $cmd] add"
    button $base.buttons.update -text Update -width 8 -underline 0 -command \
        "editdlog:exec $base $parent [list $class] [list $cmd] update"
    button $base.buttons.delete -text Delete -width 8 -command \
        "editdlog:exec $base $parent [list $class] [list $cmd] delete"
    button $base.buttons.done   -text Done   -width 8 -command \
        "editdlog:exec $base $parent [list $class] [list $cmd] done"

    ###################
    # SETTING GEOMETRY
    ###################
    grid columnconf $base 1 -weight 1
    grid rowconf    $base 0 -weight 1
    grid $base.slist        -column 0 -row 0 -padx 5 -pady 5 -sticky nesw
    grid $base.client       -column 1 -row 0 -sticky nesw
    grid $base.buttons      -column 0 -row 1 -columnspan 2 -sticky nesw -padx 5 -pady 5

    grid columnconf $base.slist 0 -weight 1
    grid rowconf    $base.slist 0 -weight 1
    grid $base.slist.list   -column 0 -row 0 -sticky nesw
    grid $base.slist.scroll -column 1 -row 0 -sticky ns

    grid columnconfig $base.buttons 3 -weight 1
    grid columnconfig $base.buttons 5 -weight 1
    grid $base.buttons.new    -row 0 -column 0 -padx 5  -pady 5
    grid $base.buttons.add    -row 0 -column 1 -padx 5  -pady 5
    grid $base.buttons.update -row 0 -column 2 -padx 5  -pady 5
    grid $base.buttons.delete -row 0 -column 4 -padx 20 -pady 5
    grid $base.buttons.done   -row 0 -column 6 -padx 5  -pady 5

    editdlog:updatelist $base $cmd "" ""
    editdlog:updateview $base $cmd

    editdlog:updatechanged $base $cmd
    focus [editdlog:findnamewidget $base.client]

    $cmd register $base "editdlog:updatelist [list $base] [list $cmd]"
    return $base
}



