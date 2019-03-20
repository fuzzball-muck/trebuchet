#################################
# MACRO COMMANDS
#

proc / {args} {
    return ""
}

proc /set {variables values} {
    uplevel #0 "setvars [list $variables] [list $values]"
}

proc /editproc {name} {
    if {[catch {set body [info body $name]}]} {
        error "No such proc $name"
    }
    set args {}
    foreach arg [info args $name] {
        if {[info default $name $arg def]} {
            lappend args [list $arg $def]
        } else {
            lappend args $arg
        }
    }
    set body "proc $name [list $args] [list $body]"
    /textdlog -text $body -title "Editing proc $name" -mode tcl -nowrap -autoindent -buttons -variable newproc -donecommand "if {\[catch {uplevel #0 \$newproc} errMsg\]} {catch {$body};/results \$errMsg}"
    return
}

proc /editproc_dlog {} {
    /selector -list [lsort [info proc]] -selectpersist -title "Editproc" \
        -caption "Select a procedure to edit" -selectbutton "Edit" \
        -selectscript {/editproc %!}
}

proc /scratchpad {} {
    textdlog:create .scratchpad -title "Scratchpad" -persistent -font default_system_font
}

proc /setwidth {{cols 80}} {
    set disp [/display]
    update idletasks
    set font [$disp cget -font]
    set charw [font measure $font "0"]
    set idealw [expr {$charw*$cols}]
    set currw [winfo width $disp]
    if {[wm state .mw] == "withdrawn" && $currw <= 1} {
	set currw 0
    }
    set currw [expr {$currw - 2*[$disp cget -borderwidth]}]
    set currw [expr {$currw - 2*[$disp cget -highlightthickness]}]
    set currw [expr {$currw - 2*[$disp cget -padx]}]
    if {[wm state .mw] == "withdrawn" && $currw <= 0} {
        set tmpw $currw
        set currw 0
    }
    if {$currw != $idealw} {
        set delta [expr {$idealw-$currw}]
        set winw [winfo width .mw]
        set winh [winfo height .mw]
        if {[wm state .mw] == "withdrawn" && $winw <= 1} {
            set winw [expr {25-$tmpw}]
            set winh 480
        }
        incr winw $delta
        wm geometry .mw "${winw}x${winh}"
    }
}

proc /dokey {key} {
    switch -exact -- $key {
        insert_enter    {/inbuf insert insert "\n"}
        scroll_line_dn {
            set disp [/display]
            $disp yview scroll 1 units
            display:markseen $disp
            set sock [/socket:foreground]
            if {[display:at_end $disp] && [/socket:exists $sock]} {
                /socket:set activity $sock 0
            }
        }
        scroll_line_up    {
            set disp [/display]
            $disp yview scroll -1 units
            display:markseen $disp
        }
        page        -
        scroll_page_dn {
            set disp [/display]
            $disp yview scroll 1 pages
            display:markseen $disp
            set sock [/socket:foreground]
            if {[display:at_end $disp] && [/socket:exists $sock]} {
                /socket:set activity $sock 0
            }
        }
        scroll_page_up    {
            set disp [/display]
            $disp yview scroll -1 pages
            display:markseen $disp
        }
        backspace -
        delete_char   {/inbuf delete "insert-1chars" "insert"}
        complete_word {/complete_word}
        del_to_start  {/inbuf delete 1.0 insert}
        socket_next   {/socket next}
        socket_prev   {/socket prev}
        delete_word {
            set inbuf [/inbuf]
            while {1} {
                if {[$inbuf compare insert <= 1.0]} {
                    break
                }
                set chr [$inbuf get "insert - 1 chars" "insert"]
                if {$chr != " "} {
                    break
                }
                $inbuf delete "insert - 1 chars" "insert"
            }
            while {1} {
                if {[$inbuf compare insert <= 1.0]} {
                    break
                }
                set chr [$inbuf get "insert - 1 chars" "insert"]
                if {$chr == " " || $chr == "\n"} {
                    break
                }
                $inbuf delete "insert - 1 chars" "insert"
            }
        }
        clear_screen {
            set disp [/display]
            /echo "\n"
            $disp see end
            set count [expr {[winfo height $disp] / [lindex [$disp bbox "end - 1 chars"] 3]}]
            while {[incr count -1]} {
                $disp insert end "\n"
            }
            $disp see end
            display:markseen $disp
        }
        history_next {
            global cmdhist cmdhistnum cmdhisttmp
            if {$cmdhistnum < 0 || $cmdhistnum >= [llength $cmdhist]} {
                /statbar 5 "You are at the end of the command history."
                /bell
            } else {
                incr cmdhistnum
                [/inbuf] delete 1.0 end
                if {$cmdhistnum < [llength $cmdhist]} {
                    [/inbuf] insert 1.0 [lindex $cmdhist $cmdhistnum]
                } else {
                    [/inbuf] insert 1.0 $cmdhisttmp
                }
            }
        }
        history_prev {
            global cmdhist cmdhistnum cmdhisttmp
            if {$cmdhistnum < 1} {
                /statbar 5 "You are at the beginning of the command history."
                /bell
            } else {
                if {$cmdhistnum >= [llength $cmdhist]} {
                    set cmdhisttmp [/inbuf get 1.0 "end - 1 chars"]
                }
                incr cmdhistnum -1
                [/inbuf] delete 1.0 end
                [/inbuf] insert 1.0 [lindex $cmdhist $cmdhistnum]
            }
        }
        history_stack {
            global cmdhist cmdhistnum cmdhisttmp
            set disp [/display]
            display:doautoscroll $disp
            display:markseen $disp
            set cmd [/inbuf get 1.0 "end - 1 chars"]
            /inbuf delete 1.0 end
            set cmdhisttmp ""
            lappend cmdhist "$cmd"
            if {[llength $cmdhist] > [/prefs:get command_lines]} {
                set delta [expr {[llength $cmdhist] - [/prefs:get command_lines]}]
                set cmdhist [lrange $cmdhist $delta end]
            }
            set cmdhistnum [llength $cmdhist]
            /statbar 5 "Text stacked into the command history."
        }
        enter {
            global cmdhist cmdhistnum errorInfo errorCode cmdhisttmp
            set disp [/display]
            display:doautoscroll $disp
            display:markseen $disp
            set cmd [/inbuf get 1.0 "end - 1 chars"]
            /inbuf delete 1.0 end
            set cmdhisttmp ""
            if {$cmd != ""} {
                if {[/prefs:get echo_flag]} {
                    /echo -style results $cmd
                }
                if {$cmd != [lindex $cmdhist end]} {
                    lappend cmdhist "$cmd"
                }
            } else {
                if {[/prefs:get echoblanks_flag]} {
                    /echo
                }
            }
            if {$cmd == "" && [/prefs:get eatblanks_flag]} {
                return ""
            }
            if {$cmd != "" && $cmd != [lindex $cmdhist end]} {
                lappend cmdhist "$cmd"
            }
            if {[llength $cmdhist] > [/prefs:get command_lines]} {
                set delta [expr {[llength $cmdhist] - [/prefs:get command_lines]}]
                set cmdhist [lrange $cmdhist $delta end]
            }
            set cmdhistnum [llength $cmdhist]
            set ret [catch {process_commands "$cmd"} result]
            if {$ret != 0} {
                set lines [split $errorInfo "\n"]
                set cnt [llength $lines]
                incr cnt -3
                set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                return -code $ret -errorcode $errorCode -errorinfo $savedInfo $result
            } elseif {$result != ""} {
                /results $result
            }
        }
        default {error "/dokey: Unknown key command!"}
    }
    /inbuf see insert
    return ""
}

global treb_readlines

tcl::OptProc /readlines {
    {-world  {} "The world to watch for the lines in."}
    {-nolast    "Don't include matched end line in args to command."}
    {pattern {} "The string match pattern of the line to stop reading at."}
    {command {} "The command to execute when done reading."}
} {
    global treb_readlines

    if {$world == {}} {
        set world [/socket:current]
        if {$world == {}} {
            error "/readlines: no world to read lines from."
        }
    }
    if {[llength [/socket:connectednames $world]] == 0} {
        error "/readlines: That world is not connected or does not exist."
    }

    if {[info exists treb_readlines(pattern,$world)]} {
        if {$treb_readlines(pattern,$world) != {}} {
            error "/readlines: Can only be active once at a time per world."
        }
    }
    set treb_readlines(pattern,$world) [string tolower $pattern]
    set treb_readlines(command,$world) $command
    set treb_readlines(text,$world) {}
    set treb_readlines(nolast,$world) $nolast
    return
}


proc /echo {args} {
    set style normal
    set socket [/socket:current]
    set newline 1
    while {[llength $args] > 1} {
        set opt [lindex $args 0]
        set val [lindex $args 1]
        switch -exact -- $opt {
	    -w - -world {set socket $val}
            -s - -style {set style [concat $style $val]}
            -n - -newline {set newline $val}
            -- {set args [lreplace $args 0 0]; break}
            default {break}
        }
        set args [lreplace $args 0 1]
    }
    if {$newline} {
        /socket:writeln $socket [join $args] $style
    } else {
        /socket:write $socket [join $args] $style
    }
    return ""
}

proc /benchmark {args} {
    global clicks_per_second
    set starttime [/clock_clicks]
    if {[llength $args] == 1} {
        uplevel 1 [lindex $args 0]
    } else {
        uplevel 1 $args
    }
    set endtime [/clock_clicks]
    return [expr {(($endtime - $starttime) * 1000) / $clicks_per_second}]
}

proc /newdlog {class cmdbase {name ""}} {
    set num 1
    while {[winfo exists ".newdlog$num"]} {incr num}
    editdlog:newdlog ".mw.newdlog$num" $class $cmdbase $name
}

proc /editdlog {plural singular cmdbase} {
    editdlog:new ".mw.editdlog$cmdbase" "Edit $plural" $singular $cmdbase
}

proc /yesnocancel_dlog {title text {default "yes"} {icon "question"}} {
    if {![/prefs:get ask_confirmation]} {
        return $default
    } else {
        set focus [focus]
        if {$focus != ""} {
            set parent [winfo toplevel $focus]
        } else {
            set parent .mw
        }
        return [tk_messageBox -message $text -title $title \
                -type yesnocancel -icon $icon -parent $parent]
    }
}

proc /yesno_dlog {title text {default "yes"} {icon "question"}} {
    if {![/prefs:get ask_confirmation]} {
        return $default
    } else {
    set focus [focus]
    if {$focus != ""} {
        set parent [winfo toplevel $focus]
    } else {
        set parent .mw
    }
    return [tk_messageBox -message $text -title $title \
            -type yesno -icon $icon -parent $parent]
    }
}

proc /verify_and_do {title text script} {
    set focus [focus]
    set socket [/socket:current]
    if {$focus != ""} {
        set parent [winfo toplevel $focus]
    } else {
        set parent .mw
    }
    if {![/prefs:get ask_confirmation]} {
        set result "yes"
    } else {
    set result [tk_messageBox -message $text -title $title \
            -type yesno -default yes -icon question -parent $parent]
    }
    if {$result == "yes"} {
        process_commands "$script" $socket
    }
    return $result
}

proc /textentry_dlog {title caption {default ""} {command ""}} {
    global TextEntryDlogText TextEntryDlogResult
    set focus [focus]
    set socket [/socket:current]
    if {$focus != ""} {
        set parent [winfo toplevel $focus]
    }
    set parent {}
    if {$parent == {}} {
        set parent .mw
    }

    set base .textentrydlog
    toplevel $base
    wm title $base $title
    wm resizable $base 0 0
    place_window_default $base $parent

    label $base.label -text $caption -anchor w -justify left
    set TextEntryDlogText $default
    entry $base.entry -textvariable TextEntryDlogText
    bind $base.entry <Key-Return> "$base.ok invoke"
    bind $base.entry <Key-Escape> "$base.cancel invoke"
    if {$command == ""} {
        button $base.ok -text Ok -width 6 -default active -command "
            set TextEntryDlogResult {ok}
            destroy $base
        "
        button $base.cancel -text Cancel -width 6 -command "
            set TextEntryDlogResult {cancel}
            set TextEntryDlogText {}
            destroy $base
        "
    } else {
        button $base.ok -text Ok -width 6 -default active -command "
            set cmd \[/line_subst [list $command] \$TextEntryDlogText\]
            process_commands \$cmd $socket
            destroy $base
        "
        button $base.cancel -text Cancel -width 6 -command "
            destroy $base
        "
    }

    pack $base.label -anchor nw -side top -pady 5 -padx 10
    pack $base.entry -anchor nw -side top -pady 5 -padx 10 -expand 1 -fill x
    pack $base.cancel -anchor e -side right -padx 10 -pady 10
    pack $base.ok -anchor e -side right -pady 10 -padx 10

    focus $base.entry
    $base.entry icursor end
    $base.entry selection range 0 end

    if {$command == ""} {
        grab set $base
        tkwait window $base
        focus $parent
        return [list $TextEntryDlogResult $TextEntryDlogText]
    }
    return ""
}

proc /tcl {args} {
    global errorCode errorInfo
    set ret [catch {uplevel #0 $args} result]
    if {$ret == 0} {
        return $result
    } else {
        set lines [split $errorInfo "\n"]
        set cnt [llength $lines]
        incr cnt -4
        set savedInfo [join [lrange $lines 0 $cnt] "\n"]
        error $result $savedInfo $errorCode
    }
}

proc /sendln {text} {
    /socket:sendln [/socket:current] "$text"
}

proc /escape {text} {
    regsub -all {[]\"{\\}\$; []} $text {\\&} esccmd
    return $esccmd
}

proc /line_subst {string cmdline {byspaces 1}} {
    set oot ""
    if {$byspaces} {
        regsub {  *} $cmdline { } words
        set words [split $words " "]
    } else {
        set words $cmdline
    }
    while {$string != ""} {
        set pos [string first "%" $string]
        if {$pos == -1} {
            append oot $string
            break
        }
        append oot [string range $string 0 [expr {$pos - 1}]]
        incr pos
        set code [string range $string $pos $pos]
        incr pos
        set string [string range $string $pos end]
        switch -exact -- $code {
            % {append oot "%"}
            1 {append oot [lindex $words 0]}
            2 {append oot [lindex $words 1]}
            3 {append oot [lindex $words 2]}
            4 {append oot [lindex $words 3]}
            5 {append oot [lindex $words 4]}
            6 {append oot [lindex $words 5]}
            7 {append oot [lindex $words 6]}
            8 {append oot [lindex $words 7]}
            9 {append oot [lindex $words 8]}
            * {append oot $cmdline}
            ! {append oot [/escape $cmdline]}
        }
    }
    return $oot
}

global statbar_timeout_process
set statbar_timeout_process {}
global statbar_history
set statbar_history {}

# -nolog     Don't remember message in statbar history.
# timeout    Timeout in seconds before message should vanish.  0 for none.
# message    The text to display.
proc /statbar {args} {
    global statbar_timeout_process
    global statbar_history

    set nolog 0
    if {[lindex $args 0] == "-nolog"} {
        set nolog 1
        set args [lrange $args 1 end]
    }
    if {[llength $args] < 2} {
        error {Usage: /statbar [-nolog] timeout message}
    }
    set timeout [lindex $args 0]
    set message [lindex $args 1]

    set timeout [expr {int(1000 * $timeout)}]
    if {$statbar_timeout_process != {}} {
        after cancel $statbar_timeout_process
        set statbar_timeout_process {}
    }
    if {$timeout > 0} {
        set statbar_timeout_process [after $timeout {
                .mw.statusbar.note configure -text {}
                set statbar_timeout_process {}
            }]
    }

    if {!$nolog} {
        lappend statbar_history $message
        set curlen [llength $statbar_history]
        set maxhist [/prefs:get statbar_histlen]
        if {$curlen > $maxhist} {
            set statbar_history [lrange $statbar_history [expr {$curlen-$maxhist}] end]
        }
    }
    .mw.statusbar.note configure -text $message
    update idletasks
    return ""
}


proc /statbar:list {} {
    global statbar_history
    return [join $statbar_history "\n"]
}


proc /connect {world} {
    /world:connect $world
}

proc /connect_dlog {} {
    /selector -contentscript {/world names} -register {/world} \
        -title "Connect to world" -caption {Select a world to connect to} \
        -selectbutton "Connect" -selectscript {/connect %!} \
        -editbutton "Edit" -editscript {/world:edit %!} -editpersist
}

proc /if {cond tru {fals ""}} {
    set result [uplevel "expr [list $cond]"]
    if {$result} {
        process_commands $tru
    } else {
        if {$fals != ""} {
            process_commands $fals
        }
    }
}

tcl::OptProc /reconnect {
    {-force          "Don't ask for confirmation."}
    {?world?     {}  "The world to reconnect to."}
} {
    if {$world == ""} {
        set socket [/socket:current]
    } else {
        set socket $world
    }
    if {$socket == ""} return
    if {[/socket:exists $socket]} {
        if {[/socket:get state $socket] == "Disconnected"} {
            /socket:connect $socket
        } elseif {$force} {
            /socket:disconnect $socket
            /socket:connect $socket
        } else {
            /verify_and_do "Reconnect" \
                    "Are you sure you want disconnect and reconnect to world $socket?" \
                    "/socket:disconnect [list $socket] ; /socket:connect [list $socket]"
        }
    } else {
        /socket:connect $socket
    }
}

tcl::OptProc /dc {
    {-force          "Don't ask for confirmation."}
    {?world?     {}  "The world to disconnect from."}
} {
    if {$world == ""} {
        set socket [/socket:current]
    } else {
        set socket $world
    }
    if {$socket == ""} return
    if {[/socket:exists $socket] && [/socket:get state $socket] == "Disconnected"} {
        return
    }

    if {$force} {
        /socket:disconnect $socket
    } else {
        /verify_and_do "Disconnect" \
                "Are you sure you want disconnect from world $socket?" \
                "/socket:disconnect [list $socket]"
    }
    return ""
}


tcl::OptProc /close {
    {-force          "Don't ask for confirmation."}
    {?world?     {}  "The world to close."}
} {
    if {$world == ""} {
        set socket [/socket:current]
    } else {
        set socket $world
    }
    if {$socket == ""} return
    if {[/socket:exists $socket] && [/socket:get state $socket] == "Disconnected"} {
        set force 1
    }
    if {$force} {
        /socket:close $socket
    } else {
        /verify_and_do "Close" \
                "Are you sure you want close the world $socket?" \
                "/socket:close [list $socket]"
    }
    return
}


proc repeat:internal {delay count socket cmds} {
    process_commands $cmds $socket
    if {$count != -1} {
        incr count -1
    }
    if {$count > 0 || $count == -1} {
        /process:requeue $delay "repeat:internal $delay $count [list $socket] [list $cmds]"
    }
}


proc /repeat {args} {
    set delay 0
    set socket [/socket:current]
    while {[llength $args] > 1} {
        set opt [lindex $args 0]
        set val [lindex $args 1]
        switch -exact -- $opt {
	    -w - -world {set socket $val}
            -d - -delay {set delay $val}
            -- {set args [lreplace $args 0 0]; break}
            default {break}
        }
        set args [lreplace $args 0 1]
    }
    if {[llength $args] < 2} {
        error "/repeat: Syntax is /repeat ?-world name? ?-delay secs? count commands..."
    }

    set count [lindex $args 0]
    set cmd [join [lrange $args 1 end]]
    /process:new "/repeat $args" $delay "repeat:internal $delay $count [list $socket] [list $cmd]"
}


proc quote:internal {delay prefix suffix command text file fd world after} {
    if {$text == {}} {
        if {$fd == {}} {
            /statbar 0 ""
            return
        }
        if {[eof $fd]} {
            close $fd
            /statbar 10 "Finished sending [file tail $file] to $world..."
            if {$after != {}} {
                process_commands $after $world
            }
            return
        }
        set cnt [gets $fd line]
        if {[eof $fd]} {
            close $fd
            /statbar 10 "Finished sending [file tail $file] to $world..."
            if {$after != {}} {
                process_commands $after $world
            }
            return
        }
    } else {
        set list [split $text "\n"]
        set line [lindex $list 0]
        set text [lrange $list 1 end]
    }
    if {$command != ""} {
        process_commands "$command [list $prefix$line$suffix]" $world
    } else {
        /socket:sendln $world "$prefix$line$suffix"
    }
    /process:requeue $delay "quote:internal $delay [list $prefix] [list $suffix] [list $command] [list $text] [list $file] [list $fd] [list $world] [list $after]"
    return
}


tcl::OptProc /quote {
    {-world     {}  "The world to send the data to."}
    {-delay    0.0  "The time between lines sent, in seconds."}
    {-prefix    {}  "The prefix to prepend to each line."}
    {-suffix    {}  "The suffix to append to each line."}
    {-command   {}  "A command to perform on each line."}
    {-text      {}  "The text to send to the given world first."}
    {-file      {}  "The file to quote to the given world."}
    {-after     {}  "A command performed after the quote is finished."}
    {-getpid        "If you want it to return the ID of the /quote process."}
} {
    if {$world == {}} {
        set world [/socket:current]
    }
    if {$file != {}} {
        set fd [open $file r]
        fconfigure $fd -buffering line
        /statbar 5 "Sending [file tail $file] to $world..."
    } else {
        set fd {}
    }

    set pidnum [/process:new "/quote $args" $delay "quote:internal $delay [list $prefix] [list $suffix] [list $command] [list $text] [list $file] [list $fd] [list $world] [list $after]"]
    if {$getpid} {
        return $pidnum
    }
    return
}


proc /recall {args} {
    set pattern "*"
    set socket [/socket:current]
    while {[llength $args] > 1} {
        set opt [lindex $args 0]
        set val [lindex $args 1]
        switch -exact -- $opt {
            -w - -world {set socket $val}
            -p - -pattern {set pattern $val}
            -- {set args [lreplace $args 0 0]; break}
            default {break}
        }
        set args [lreplace $args 0 1]
    }
    if {[llength $args] != 1} {
        error "/recall: Syntax is /recall ?-world name? ?-pattern str? ?--? count"
    }
    set count [lindex $args 0]
    set disp [/display]
    set oot ""
    set i [$disp index "end - 1 chars"]
    set i [$disp index "$i - $count lines"]
    while {[$disp compare $i < end]} {
        set line [$disp get "$i linestart" "$i lineend"]
        set cipat [string tolower $pattern]
        set ciline [string tolower $line]
        if {[string match $cipat $ciline]} {
            if {$oot != ""} {
                append oot "\n"
            }
            append oot $line
        }
        set i [expr {$i + 1.0}]
    }
    return $oot
}

global socketsreverse; set socketsreverse() {}


rename exit treb_exit

proc exit {} {
    /quit
}


proc /exit {} {
    foreach world [/socket:names] {
        /socket:close $world
    }
    treb_exit
}


proc /quit {} {
    global dirty_preferences
    set opencount [llength [/socket:connectednames]]
    if {$dirty_preferences == 1} {
        set msg "Your preferences or world settings were changed but not saved.  Would you like to save them?"
        set result [/yesnocancel_dlog "Save Preferences & Worlds" $msg "yes"]
        if {$result == "yes"} {
            if {[catch {/saveprefs -all} errMsg] && $errMsg != ""} {
                global errorInfo
                error $errMsg $errorInfo
            }
        } elseif {$result == "cancel"} {
            return ""
        }
    } else {
        if {$opencount > 0} {
            set msg "One or more worlds are still connected.  Do you really want to quit Trebuchet Tk?"
            if {[/yesno_dlog "Quit Trebuchet Tk" $msg] == "no"} {
                return ""
            }
        }
    }

    catch {
        if { [/prefs:get empty_web_cache] == 1 } {
            global treb_web_cache_dir
            file delete -force $treb_web_cache_dir
        } else {
            global treb_web_cache_index
            global treb_web_cache_map
            set f [open $treb_web_cache_index "w+"]
            puts $f "1"
            puts $f [array get treb_web_cache_map]
            close $f
        }
    }

    foreach world [/socket:names] {
        /socket:disconnect $world
    }

    /exit
    return ""
}


proc /complete_word {args} {
    complete_word_proc
}


proc /display {args} {
    global widget
    switch -exact -- [llength $args] {
        0 {
            set disp [display:current]
            if {$disp == ""} {
                return $widget(backdrop).disp
            } else {
                return $disp.disp
            }
        }
        1 {
            if {[lindex $args 0] == ""} {
                return $widget(backdrop).disp
            } else {
                set disp [/socket:get display [lindex $args 0]]
                if {$disp == ""} {
                    return $widget(backdrop).disp
                }
                return $disp.disp
            }
        }
        default {
            set disp [/socket:get display [lindex $args 0]].disp
            return [eval "$disp [lrange $args 1 end]"]
        }
    }
}


proc /inbuf {args} {
    global widget
    if {$args == {}} {
        return $widget(inbuf)
    }
    return [eval "$widget(inbuf) $args"]
}


proc /grab {text} {
    /inbuf delete 1.0 end
    /inbuf insert end $text
    return ""
}


proc process_command_file {filename {socket {}}} {
    global errors_nonfatal errorInfo

    if {![file exists $filename] || ![file isfile $filename]} {
        error "$filename: No such file or directory"
    }
    if {[catch {set commandfile [open $filename "RDONLY"]}]} {
        error "$filename: Could not open"
    }

    if {$socket == {}} {
        set socket [/socket:current]
        set oldsocket {}
    } else {
        set oldsocket [/socket:current]
        if {$oldsocket == $socket} {
            set oldsocket {}
        } else {
            /socket:setcurrent $socket
        }
    }

    set text {}
    set line {}
    while {[gets $commandfile line] >= 0} {
        if {$text != ""} {
            append text "\n"
        }
        append text $line
        if {[info complete $text]} {
            if {[catch {set result [process_command $text $socket]} errMsg] && $errMsg != ""} {
                set savedInfo $errorInfo
                if {!$errors_nonfatal} {
                    if {$oldsocket != {}} {
                        /socket:setcurrent $oldsocket
                    }
                    close $commandfile
                    error $errMsg $savedInfo
                }
                /nonmodalerror $socket $errMsg
            }
            set text ""
        }
    }
    if {$text != ""} {
        if {[catch {process_command $text $socket} result] && $result != ""} {
            set savedInfo $errorInfo
            if {!$errors_nonfatal} {
                if {$oldsocket != {}} {
                    /socket:setcurrent $oldsocket
                }
                close $commandfile
                error $result $savedInfo
            }
            /nonmodalerror $socket $result
        }
        set text ""
    }
    if {$oldsocket != {}} {
        /socket:setcurrent $oldsocket
    }
    close $commandfile
    return $result
}


proc /source {filename} {
    if {![file isfile $filename]} {
        error "$filename: No such file or directory"
    }
    set oldworld [/socket:current]
    /socket:setcurrent ""
    if {[catch {process_command_file $filename} returnval] && $returnval != ""} {
        global errorInfo
        set savedInfo $errorInfo
        /socket:setcurrent $oldworld
        error $returnval $savedInfo
    }
    /socket:setcurrent $oldworld
    return $returnval
}


tcl::OptProc /load {
    {-request       "If given, pops up a GUI dialog to ask what file to load."}
    {?file?      {} "The file to run the commands of."}
} {
    if {$request} {
        set filetypes {
            {{Trebuchet Config Files} {.trc}    TEXT}
            {{Text Files}             {.txt}    TEXT}
            {{All Files}              *             }
        }
        set defaultext "trc"
        set file [tk_getOpenFile -defaultextension .$defaultext \
                    -title {Import configuration from file...} \
                    -filetypes $filetypes]
        if {$file == ""} {
            return ""
        }
    }
    if {![file exists $file] || ![file readable $file]} {
        return 0
    }
    if {[catch {/source $file} mesg]} {
        global errorInfo
        set savedInfo $errorInfo
        /error [/socket:current] $mesg $savedInfo
        return 0
    }
    return 1
}


proc /geometry:get {} {
    return [wm geometry .mw]
}


proc /geometry:set {geom} {
    wm geometry .mw $geom
}


proc /inbuf:getsize {} {
    return [/inbuf cget -height]
}


proc /inbuf:setsize {height} {
    /inbuf configure -height $height
}


proc /isize {height} {
    /inbuf:setsize $height
}


proc /clipboard:copy {text} {
    clipboard clear -displayof .mw
    clipboard append -displayof .mw -type STRING -format STRING -- $text
}

proc /edit:cut {} {
    event generate [focus] <<Cut>>
}

proc /edit:copy {} {
    event generate [focus] <<Copy>>
}

proc /edit:paste {} {
    event generate [focus] <<Paste>>
}

proc /edit:selectall {} {
    event generate [focus] <<SelectAll>>
}

proc /edit:delete {} {
    event generate [focus] <Key-Delete>
}

proc /edit:find {} {
    set disp [/display [/socket:foreground]]
    $disp mark set insert end
    set cmd {finddlog:new .finddlog $disp}
    append cmd " -direction backwards"
    append cmd " -pattern [list [/prefs:get last_find_pattern]]"
    if {[/prefs:get last_find_nocase]} {
        append cmd " -nocase"
    }
    if {[/prefs:get last_find_regexp]} {
        append cmd " -regexp"
    }
    append cmd " -findcmd {display:markseen $disp}"
    eval $cmd
}

proc /editstartup_dlog {} {
    /textdlog -buttons -title "Edit startup script" \
        -width 60 -height 12 -nowrap -autoindent \
        -text [/prefs:get startup_script] -mode tcl \
        -variable [/prefs:getvar startup_script] \
        -donecommand {global dirty_preferences; set dirty_preferences 1}
}

proc /switchworld number {
    if {[llength [worldbutton:names]] >= $number} {
        worldbutton:press [lindex [worldbutton:names] $number-1]
    }
}

#############################
# LOAD OTHER COMMANDS FILES #
#############################
global treb_lib_dir
source [file join $treb_lib_dir sockets.tcl]
source [file join $treb_lib_dir worlds.tcl]
source [file join $treb_lib_dir styles.tcl]
source [file join $treb_lib_dir hilites.tcl]
source [file join $treb_lib_dir binds.tcl]
source [file join $treb_lib_dir macros.tcl]
source [file join $treb_lib_dir qbuttons.tcl]
source [file join $treb_lib_dir tools.tcl]
source [file join $treb_lib_dir webcmds.tcl]
source [file join $treb_lib_dir richview.tcl]
source [file join $treb_lib_dir senddlog.tcl]
source [file join $treb_lib_dir process.tcl]
source [file join $treb_lib_dir logs.tcl]
source [file join $treb_lib_dir prefs.tcl]

