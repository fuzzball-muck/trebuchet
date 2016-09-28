
tcl::OptProc /selector {
    {-list			-list {}	{The list to populate the listbox with.}}
    {-contentscript	{}			{Script that returns a list to fill the listbox.}}
    {-default		0			{List item position selected by default.}}
    {-world			{}			{World to use as context.}}
    {-title			{Selector}	{Window title}}
    {-caption		{Select one}	{Dialog caption}}
    {-register		{}			{Class to register with for contents changes.}}
    {-selectpersist				{Don't dismiss dialog if select is pressed.}}
    {-selectbutton	{Select}	{Text of selection button.}}
    {-selectscript	{}			{Script to run when select button is pressed.}}
    {-editpersist				{Don't dismiss dialog if edit is pressed.}}
    {-editbutton	{}			{Text of edit button.}}
    {-editscript	{}			{Script to run when edit button is pressed.}}
    {-cancelbutton	{Cancel}	{Text of cancel button.}}
    {-cancelscript	{}			{Script to run when cancel button is pressed.}}
} {
    global SelectorDlogText SelectorDlogResult
    if {$selectpersist && $editpersist && $cancelbutton == {}} {
        error "/selector: No way to dismiss dialog."
    }
    if {$selectpersist && $selectscript == {}} {
        error "/selector: Cannot use -selectpersist without select script."
    }
    if {$editpersist && $editscript == {}} {
        error "/selector: Cannot use -editpersist without edit script."
    }

    if {$world == {}} {
        set world [/socket:current]
    }

    set focus [focus]
    set socket [/socket:current]
    set parent {}
    if {$focus != ""} {
        set parent [winfo toplevel $focus]
    }
    if {$parent == {}} {
        set parent .mw
    }

    global SelectorDlogNumber
    if {![info exists SelectorDlogNumber]} {
        set SelectorDlogNumber 0
    }
    incr SelectorDlogNumber
    set base .mw.selector$SelectorDlogNumber

    toplevel $base
    wm title $base $title
    wm resizable $base 0 0
    place_window_default $base $parent
    label $base.label -text $caption -anchor w -justify left
    set SelectorDlogText {}
    set SelectorDlogItem -1
    listbox $base.listbox -height 10 -width 30 \
        -yscrollcommand "$base.scroll set"
    scrollbar $base.scroll -orient vert -command "$base.listbox yview"
    bind $base.listbox <Double-Button-1> "$base.ok invoke"
    bind $base.listbox <Key-Return> "$base.ok invoke"
    bind $base.listbox <Key-Escape> "$base.cancel invoke"
    if {$selectscript == ""} {
        button $base.ok -text $selectbutton -default active -command "
            set SelectorDlogItem \[$base.listbox curselection\]
            set SelectorDlogText \[$base.listbox get \$SelectorDlogItem\]
            set SelectorDlogResult {ok}
            if {!$selectpersist} {
                if {\"$register\" != {}} {
                    $register deregister $base
                }
                after 10 destroy $base
            }
        "
        if {$editbutton != {}} {
            button $base.edit -text $editbutton -command "
                set SelectorDlogItem \[$base.listbox curselection\]
                set SelectorDlogText \[$base.listbox get \$SelectorDlogItem\]
                set SelectorDlogResult {edit}
                if {!$editpersist} {
                    if {\"$register\" != {}} {
                        $register deregister $base
                    }
                    after 10 destroy $base
                }
            "
        }
        if {$cancelbutton != {}} {
            button $base.cancel -text $cancelbutton -command "
                set SelectorDlogResult {cancel}
                set SelectorDlogItem -1
                set SelectorDlogText {}
                if {\"$register\" != {}} {
                    $register deregister $base
                }
                after 10 destroy $base
            "
        }
    } else {
        button $base.ok -text $selectbutton -default active -command "
            set SelectorDlogItem \[$base.listbox curselection\]
            set SelectorDlogText \[$base.listbox get \$SelectorDlogItem\]
            set cmd \[/line_subst [list $selectscript] \$SelectorDlogText\]
            process_commands \$cmd [list $socket]
            if {!$selectpersist} {
                if {\"$register\" != {}} {
                    $register deregister $base
                }
                after 10 destroy $base
            }
        "
        if {$editbutton != {}} {
            button $base.edit -text $editbutton -command "
                set SelectorDlogItem \[$base.listbox curselection\]
                set SelectorDlogText \[$base.listbox get \$SelectorDlogItem\]
                set cmd \[/line_subst [list $editscript] \$SelectorDlogText\]
                process_commands \$cmd [list $socket]
                if {!$editpersist} {
                    if {\"$register\" != {}} {
                        $register deregister $base
                    }
                    after 10 destroy $base
                }
            "
        }
        if {$cancelbutton != {}} {
            button $base.cancel -text $cancelbutton -command "
                set SelectorDlogItem -1
                set SelectorDlogText {}
                if {\"$register\" != {}} {
                    $register deregister $base
                }
                after 10 destroy $base
            "
        }
    }

    grid columnconf $base 0 -minsize 10
    grid columnconf $base 1 -weight 1
    grid columnconf $base 3 -minsize 10
    grid columnconf $base 5 -minsize 10
    grid rowconf $base 0 -minsize 5
    grid rowconf $base 2 -minsize 5
    grid rowconf $base 4 -minsize 5
    grid rowconf $base 6 -minsize 5 -weight 1
    grid rowconf $base 8 -minsize 10

    grid $base.label   -row 1 -column 1 -sticky w -columnspan 4
    grid $base.listbox -row 3 -column 1 -sticky nsew -rowspan 5
    grid $base.scroll  -row 3 -column 2 -sticky nsw  -rowspan 5
    grid $base.ok      -row 3 -column 4 -sticky nsew
    if {$editscript != {}} {
        grid $base.edit -row 5 -column 4 -sticky nsew
    }
    if {$cancelbutton != {}} {
        grid $base.cancel -row 7 -column 4 -sticky nsew
    }

    after idle raise $base
    after idle focus $base.listbox
    if {$contentscript != {}} {
        if {$register != {}} {
            eval "$register register $base [list [list selector:update $base $contentscript]]"
        }
        selector:update $base $contentscript
    } else {
        foreach item $list {
            $base.listbox insert end $item
        }
    }
    if {[$base.listbox size] > 0} {
        $base.ok config -state normal
        if {[winfo exists $base.edit]} {
            $base.edit config -state normal
        }
    } else {
        $base.ok config -state disabled
        if {[winfo exists $base.edit]} {
            $base.edit config -state disabled
        }
    }
    $base.listbox selection clear 0 end
    $base.listbox selection set $default

    if {$selectscript == ""} {
        grab set $base
        tkwait window $base
        focus $parent
        return [list $SelectorDlogResult $SelectorDlogItem $SelectorDlogText]
    }
    return ""
}


proc selector:update {base script {type "dummy"} {name "dummy"}} {
    set first [$base.listbox nearest 0]
    set sel [$base.listbox curselection]
    if {$sel != {}} {
        set val [$base.listbox get $sel]
    }
    $base.listbox delete 0 end
    $base.listbox selection clear 0 end
    set selected 0
    foreach item [eval "$script"] {
        $base.listbox insert end $item
        if {$sel != {} && $item == $val} {
            $base.listbox selection set end
            set selected 1
        }
    }
    if {$first != {}} {
        $base.listbox yview $first
    }
    if {$selected == 0} {
        $base.listbox selection set 0
    }
}

