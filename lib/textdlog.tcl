
tcl::OptProc textsenddlog:new {
    {wname    {}                "Toplevel window widget name"}
    {-parent  {}                "Widget to focus on after exiting"}
    {-title   "Send text to..." "Toplevel window title"}
} {
    if {$wname == ""} {
        error "No textdlog widget specified!"
    }
    if {$parent == ""} {
        set parent [focus]
        if {$parent == ""} {
            set parent .mw
        }
    }
    if {![winfo exists $parent]} {
        set parent .mw
    }
    set base $wname.textsenddlog
    if {[winfo exists $base]} {
        wm deiconify $base
        focus $base.world.entry
    } else {
        ###################
        # CREATING WIDGETS
        ###################
        toplevel $base
        place_window_default $base $parent
        wm resizable $base 0 0
        wm title $base $title
        label $base.worldlbl \
            -anchor w -borderwidth 1 -text {Destination world} -underline 0 
        combobox $base.world -editable 0 \
            -textvariable TextDlogInfo(world,$wname)
        label $base.pfixlbl \
            -anchor w -borderwidth 1 -text {Prefix text} -underline 0 
        text $base.pfixtxt \
            -height 3 -width 10 -yscrollcommand "$base.pfixscroll set" 
        scrollbar $base.pfixscroll \
            -command "$base.pfixtxt yview" -orient vert 
        label $base.lpfixlbl \
            -anchor w -borderwidth 1 -text {Prepend each line} -underline 1 
        entry $base.lpfixentry -width 32
        label $base.lpostfixlbl \
            -borderwidth 1 -text {Append each line} -underline 0 
        entry $base.lpostfixentry -width 32
        label $base.postfixlbl \
            -anchor w -borderwidth 1 -text {Postfix text} -underline 1 
        text $base.postfixtxt \
            -height 3 -width 10 -yscrollcommand "$base.postfixscroll set" 
        scrollbar $base.postfixscroll \
            -command "$base.postfixtxt yview" -orient vert 
        frame $base.buttons \
            -borderwidth 2 -height 30 -width 125 
        button $base.buttons.send \
            -text Send -width 6  -command "
                global TextDlogInfo
                set TextDlogInfo(world,$wname) \[$base.world get\]
                set TextDlogInfo(prefix,$wname) \[$base.pfixtxt get 0.0 end-1c\]
                set TextDlogInfo(prepend,$wname) \[$base.lpfixentry get\]
                set TextDlogInfo(append,$wname) \[$base.lpostfixentry get\]
                set TextDlogInfo(postfix,$wname) \[$base.postfixtxt get 0.0 end-1c\]
                destroy $base
                textdlog:refocus $parent
                textdlog:send $wname
            "
        button $base.buttons.cancel \
            -text Cancel -width 6 -command "destroy $base ; textdlog:refocus $parent"
        ###################
        # SETTING GEOMETRY
        ###################
        grid columnconf $base 0 -minsize 10
        grid columnconf $base 2 -minsize 10
        grid columnconf $base 3 -weight 1
        grid columnconf $base 5 -minsize 10
        grid rowconf $base 0 -minsize 10
        grid rowconf $base 2 -minsize 10
        grid rowconf $base 5 -minsize 10
        grid rowconf $base 7 -minsize 10
        grid rowconf $base 9 -minsize 10
        grid rowconf $base 12 -minsize 10
        grid rowconf $base 14 -minsize 10
        grid $base.worldlbl      -column 1 -row 1 -sticky w 
        grid $base.world         -column 3 -row 1 -columnspan 2 -sticky nesw 
        grid $base.pfixlbl       -column 1 -row 3 -sticky w 
        grid $base.pfixtxt       -column 1 -row 4 -columnspan 3 -sticky nesw 
        grid $base.pfixscroll    -column 4 -row 4 -sticky nesw 
        grid $base.lpfixlbl      -column 1 -row 6 -sticky w 
        grid $base.lpfixentry    -column 3 -row 6 -columnspan 2 -sticky nesw 
        grid $base.lpostfixlbl   -column 1 -row 8 -sticky w 
        grid $base.lpostfixentry -column 3 -row 8 -columnspan 2 -sticky nesw 
        grid $base.postfixlbl    -column 1 -row 10 -sticky w 
        grid $base.postfixtxt    -column 1 -row 11 -columnspan 3 -sticky nesw 
        grid $base.postfixscroll -column 4 -row 11 -sticky nesw 
        grid $base.buttons       -column 1 -row 13 -columnspan 4 -sticky nesw 

        grid columnconf $base.buttons 0 -weight 1
        grid columnconf $base.buttons 2 -minsize 10
        grid columnconf $base.buttons 4 -minsize 10
        grid $base.buttons.cancel -column 1 -row 1 -sticky nsew
        grid $base.buttons.send   -column 3 -row 1 -sticky nesw 
    }

    wm title $base $title

    global TextDlogInfo

    $base.world entrydelete 0 end
    foreach world [/socket:connectednames] {
        $base.world entryinsert end $world
    }
    if {$TextDlogInfo(world,$wname) == ""} {
        set TextDlogInfo(world,$wname) [/socket:current]
    } elseif {[lsearch -exact [/socket:connectednames] $TextDlogInfo(world,$wname)] == -1} {
        set TextDlogInfo(world,$wname) [/socket:current]
    }
    $base.world delete 0 end
    $base.world insert end $TextDlogInfo(world,$wname)

    $base.pfixtxt delete 0.0 end
    $base.pfixtxt insert end $TextDlogInfo(prefix,$wname)

    $base.lpfixentry delete 0 end
    $base.lpfixentry insert end $TextDlogInfo(prepend,$wname)

    $base.lpostfixentry delete 0 end
    $base.lpostfixentry insert end $TextDlogInfo(append,$wname)

    $base.postfixtxt delete 0.0 end
    $base.postfixtxt insert end $TextDlogInfo(postfix,$wname)

    focus $base.world.entry
    return
}


proc textdlog:new {wname} {
    $wname.text delete 1.0 end
}

proc textdlog:save {wname} {
    global TextDlogInfo
    if {$TextDlogInfo(filename,$wname) == ""} {
        textdlog:saveas $wname
    } else {
        set f [open $TextDlogInfo(filename,$wname) w]
        puts -nonewline $f [$wname.text get 1.0 end-1c]
        close $f
    }
}

proc textdlog:saveas {wname {fyle ""}} {
    set filetypes {
        {{Text Files}               {.txt}    TEXT}
        {{Trebuchet Resource Files} {.trc}    TRRC}
        {{Log Files}                {.log}    TEXT}
        {{MUF Files}                {.muf}    TEXT}
        {{All Files}                *             }
    }
    if {$fyle == ""} {
        set fyle [tk_getSaveFile -defaultextension ".txt" -filetypes $filetypes \
                -initialfile Untitled.txt -title {Save File}]
        if {$fyle == ""} {
            return
        }
    }
    set f [open $fyle w]
    puts -nonewline $f [$wname.text get 1.0 end-1c]
    close $f
    global TextDlogInfo
    set TextDlogInfo(filename,$wname) $fyle
    wm title $wname "$TextDlogInfo(title,$wname) - $fyle"
    return
}

proc textdlog:open {wname {fyle ""}} {
    set filetypes {
        {{All Files}                  *        }
        {{Text Files}                 {.txt}   TEXT}
        {{Log Files}                  {.log}   TEXT}
        {{MUF Files}                  {.muf}   TEXT}
        {{Trebuchet Resource Files}   {.trc}   TRRC}
    }
    if {$fyle == ""} {
        set fyle [tk_getOpenFile -filetypes $filetypes -title {Open File}]
    }
    if {[file exists $fyle]} {
	if {[file size $fyle] > 1048576} {
	    /error "Load failed: The text editor can only load files 1 MB or smaller in size."
	} else {
	    textdlog:new $wname
	    set f [open $fyle "r"]
	    $wname.text insert end [read -nonewline $f]
	    close $f
	    global TextDlogInfo
	    set TextDlogInfo(filename,$wname) $fyle
	    wm title $wname "$TextDlogInfo(title,$wname) - $fyle"
	}
    }
}

proc textdlog:send {wname} {
    global TextDlogInfo
    set world   $TextDlogInfo(world,$wname)
    if {$world == ""} {
        textdlog:sendto $wname
    } else {
        set prefix  $TextDlogInfo(prefix,$wname)
        set prepend $TextDlogInfo(prepend,$wname)
        set append  $TextDlogInfo(append,$wname)
        set postfix $TextDlogInfo(postfix,$wname)
        set text    [$wname.text get 1.0 "end - 1 chars"]

        if {[lsearch -exact [/socket:connectednames] $world] == -1} {
            /nonmodalerror "" "World \"$world\" is not connected or does not exist."
            return
        }
        if {$prefix  != ""} {/socket:sendln $world $prefix}
        foreach line [split $text "\n"] {
            /socket:sendln $world "$prepend$line$append"
        }
        if {$postfix != ""} {/socket:sendln $world $postfix}
        /statbar 5 "Text sent to world \"$world\"."
    }
}

proc textdlog:sendto {wname} {
    if {[catch {
        textsenddlog:new $wname -parent $wname
    } errMsg]} {
        global errorInfo
        error $errMsg $errorInfo
    }
}

proc textdlog:filemenupost {wname} {
    if {[llength [/socket:connectednames]] > 0} {
        $wname.mbar.file entryconfig "Send" -state normal
        $wname.mbar.file entryconfig "Send to..." -state normal
    } else {
        $wname.mbar.file entryconfig "Send" -state disabled
        $wname.mbar.file entryconfig "Send to..." -state disabled
    }
}

proc textdlog:refocus {wname} {
    if {[winfo exists $wname]} {
        focus $wname
    } else {
        focus .mw
    }
}

proc textdlog:updatestatbar {w} {
    after 10 "
    if {\[winfo exists $w\]} {
        set line \[lindex \[split \[$w.text index insert\] {.}\] 0\]
        $w.statbar.line config -text \"Line \$line\"
    }
    "
}

proc textdlog:syntax:init {wname} {
    global TextDlogHiliteInfo

    set textwidget $wname.text
    set matches {
        tcl {
            keywords {-foreground "#090"} {
                set for foreach break continue while
                lindex lrange llength lappend
                append incr list update after expr
                switch regexp regsub return default
                proc global if else then elseif info
                split join bind lsort string
                upvar uplevel
            }
            variables {-foreground "#C0C"} {
                {\$[A-Za-z_]*} {\${.*}}
            }
            strings {-foreground brown -background "#FFC"} {
                "\"" "\""
            }
            comments {-foreground "#00F"  -background "#CCF"} {
                "#" "$"
            }
            errors {-background red -foreground white} {
            }
        }
        muf {
            preprocessor {-background "#CFC"} {
                {\$def .*$}
                {\$define *[^ ]*}
                {\$libdef .*$}
                {\$author .*$}
                {\$note .*$}
                {\$version .*$}
                {\$lib-version .*$}
                \\$enddef
                {\$include *[^ ]*}
                {\$ifdef *[^ ]*}
                {\$ifndef *[^ ]*}
                \\$else
                \\$endif
                \\$echo
            }
            worddef {-background "#AFA" -foreground black} {
                {^ *: *[^ ]*\[.* \]}
                {^ *: *[^[ ]*}
                ;
            }
            structure {-foreground "#0A0"} {
                var! lvar var ! @
                if else then begin
                foreach for repeat until
                break continue while
                try catch endcatch catch_detailed abort
                exit execute call public
            }
            stackmanip {-foreground "#C0C"} {
                ldup dupn dup popn pop swap rotate rot
                over pick put lreverse reverse
            }
            arrays {-foreground "#0AA"} {
                \{ \} \}list \}dict \}join \}tell
                array_insertitem array_insertrange
                array_appenditem {->\[\]} {\[\]}
                array_getitem array_getrange array_extract
                array_setitem array_setrange
                array_delitem array_delrange
                array_nunion array_union
                array_nintersect array_intersect
                array_ndiff array_diff
                array_sort array_make array_make_dict
                array_first array_last array_next array_prev
                array_explode array_keys array_vals
                array_count array_count array_join
                array_findval array_matchkey array_matchval
                array_get_reflist array_put_reflist
                array_get_proplist array_put_proplist
                array_get_propvals array_put_propvals
                array_get_propdirs array_filter_prop
                array_fmtstrings
            }
            iowords {-foreground "#0AA"} {
                read tread notify notify_except
                notify_exclude array_notify
                event_waitfor event_wait
            }
            propstuff {-foreground "#0AA"} {
                getpropfval getpropval getpropstr
                setprop addprop getprop
                remove_prop nextprop propdir\?
                reflist_add reflist_del reflist_find
                envpropstr envprop parseprop
                blessprop unblessprop blessed?
            }
            logic {-foreground green3} {
                not and or
            }
            numbers {-foreground brown} {
                [+-]?[0-9][0-9]*
                [+-]?[0-9][0-9]*\.[0-9]*
                [+-]?[0-9]\.[0-9][0-9]*
                [+-]?[0-9][0-9]*[eE][+-]?[0-9][0-9]*
                [+-]?[0-9][0-9]*\.[0-9]*[eE][+-]?[0-9][0-9]*
                [+-]?[0-9]\.[0-9][0-9]*[eE][+-]?[0-9][0-9]*
            }
            strings {-foreground brown -background "#FFC"} {
                \\\" \\\"  {lhajelkjhwjksfljkhaenfe} "$"
            }
            comments {-foreground "#00F"  -background "#CCF"} {
                \\( \\)
            }
            errors {-background red -foreground white} {
            }
        }
        mpi {
            escaped {-foreground brown -background "#FFC"} {
                \\\\[[r\{,\}\\\\`]
            }
            logics {-foreground green3} {
                \{parse: \{for: \{foreach: \{while:
                \{filter: \{fold: \{commas:
                \{if: \{or: \{xor: \{and: \{not:
                \{eq: \{ne: \{lt: \{le: \{gt: \{ge:
                \{func:
            }
            keywords {-foreground blue} {
                \{prop: \{prop!: \{exec: \{exec!:
                \{lexec: \{lexec!: \{rand: \{lrand:
                \{add: \{subt: \{div: \{mult: \{mod:
                \{mklist[:\}] \{index: \{index!: \{null:
                \{default: \{tell: \{fullname: \{name:
                \{otell: \{abs: \{awake: \{nearby:
                \{lunique: \{type: \{istype: \{delprop:
                \{concat: \{dbeq: \{center: \{left:
                \{contains: \{contents: \{controls:
                \{convsecs: \{convtime: \{count:
                \{created: \{date[:\}] \{dec: \{delay:
                \{dist: \{exits: \{flags: \{ftime:
                \{smatch: \{dice[:\}] \{holds: \{idle:
                \{inc: \{instr: \{isdbref: \{isnum:
                \{kill: \{lastused: \{lcommon: \{nl\}
                \{links: \{list: \{listprops: \{lit:
                \{lmember: \{locked: \{lremove: \{ref:
                \{ltimestr: \{lunion: \{max: \{midstr:
                \{min: \{modified: \{money: \{muckname\}
                \{online\} \{ontime: \{owner: \{pronouns:
                \{propdir: \{secs\} \{select: \{set:
                \{with: \{sign: \{stimestr: \{strip:
                \{strlen: \{sublist: \{subst: \{time[:\}]
                \{testlock: \{timestr: \{timesub:
                \{tolower: \{touppper: \{tzoffset\}
                \{usecount: \{version\} \{right:
            }
            warns {-foreground blue -background "#CCF"} {
                \{eval: \{eval!: \{debug: \{debugif:
                \{force: \{muf: \{store:
            }
            variables {-foreground "#C0C"} {
                \{:[0-9]\}
                \{\&[^:\}]*[:\}]
                \{v:[^,\}]*\}
                \{v:[^,\}]*
            }
            strings {-foreground brown -background "#FFC"} {
                "`" "`"
            }
            comments {-foreground "#00F"  -background "#CCF"} {
                {$asdfgeteywioaskjf^} {$akjlsheafhskje^}
            }
            errors {-background red -foreground white} {
            }
        }
    }
    set TextDlogHiliteInfo(modes) {}
    foreach {mode data} $matches {
        lappend TextDlogHiliteInfo(modes) $mode
        set TextDlogHiliteInfo(hilites,$mode) {}
        foreach {name style patterns} $data {
            eval "$textwidget tag configure [list hi-$mode-$name] $style"
            $textwidget tag raise "hi-$mode-$name"
            lappend TextDlogHiliteInfo(hilites,$mode) $name
            set TextDlogHiliteInfo(patterns,$mode,$name) $patterns
        }
    }
    $textwidget tag raise "sel"
    textdlog:syntax:hiliterange $wname 1.0 end-1c
    bind $textwidget <Key> "+textdlog:syntax:hilitecurr $wname %K"
}


proc textdlog:syntax:changemode {wname} {
    global TextDlogInfo
    set mode $TextDlogInfo(mode,$wname)
    set textwidget $wname.text
    textmods:set_match_mode $textwidget $mode
    update idletasks
    after idle textdlog:syntax:hiliterange $wname 1.0 end-1c
}

proc textdlog:syntax:hilitecurr {wname keysym} {
    global TextDlogHiliteInfo
    
    set textwidget $wname.text

    switch -exact $keysym {
        Shift_L -
        Shift_R -
        Prior -
        Next -
        Home -
        End -
        Up -
        Down -
        Left -
        Right { return "" }

        BackSpace -
        grave -
        braceleft -
        braceright -
        quotedbl -
        apostrophe -
        bracketleft -
        bracketright -
        parenleft -
        parenright {
            set endpos [$textwidget index {insert+30line lineend}]
        }

        default {
            set endpos [$textwidget index {insert+1line lineend}]
        }
    }

    if {[info exists TextDlogHiliteInfo(idletask,$wname)]} {
        after cancel $TextDlogHiliteInfo(idletask,$wname)
    }
    set TextDlogHiliteInfo(idletask,$wname) [after idle "
        textdlog:syntax:hiliterange $wname [$textwidget index {insert-1line linestart}] [list $endpos];
        global TextDlogHiliteInfo;
        unset TextDlogHiliteInfo(idletask,$wname)
        "
    ]
}


proc textdlog:syntax:hiliterange {wname startpos endpos} {
    global TextDlogHiliteInfo
    global TextDlogInfo

    if {![winfo exists $wname]} {
        return
    }
    set textwidget $wname.text
    set mode $TextDlogInfo(mode,$wname)

    set tags [$textwidget tag names "$startpos-1c"]
    set commentmode [expr {[lsearch -exact $tags "hi-$mode-comments"] != -1}]
    set stringmode [expr {[lsearch -exact $tags "hi-$mode-strings"] != -1}]

    foreach tmpmode $TextDlogHiliteInfo(modes) {
        foreach name $TextDlogHiliteInfo(hilites,$tmpmode) {
            $textwidget tag remove "hi-$tmpmode-$name" $startpos $endpos
        }
    }
    if {[info exists TextDlogHiliteInfo(patterns,$mode,strings)]} {
        set strstarts {}
        set strends {}
        if {[info exists TextDlogHiliteInfo(patterns,$mode,strings)]} {
            foreach {start end} $TextDlogHiliteInfo(patterns,$mode,strings) {
                lappend strstarts $start
                lappend strends $end
            }
        }
        set cstarts {}
        set cends {}
        if {[info exists TextDlogHiliteInfo(patterns,$mode,comments)]} {
            foreach {start end} $TextDlogHiliteInfo(patterns,$mode,comments) {
                lappend cstarts $start
                lappend cends $end
            }
        }
        set allpatterns [join [concat $strstarts $strends $cstarts $cends {\\\\}] "|"]
        set strstartpats [join $strstarts "|"]
        set strendpats [join $strends "|"]
        set cstartpatterns [join $cstarts "|"]
        set cendpatterns $cends
        lremove cendpatterns "$"
        set cendpatterns   [join $cendpatterns "|"]
        set cend_has_eolpat [expr {[lsearch -exact $cends "$"] != -1}]
        set start $startpos
        set prev $startpos
        while {1} {
            set start [$textwidget search -regexp -nocase -forwards -count numchars -- $allpatterns $start $endpos]
            if {$start != ""} {
                set chr [$textwidget get $start "$start+${numchars}c"]
                if {$commentmode} {
                    if {$cendpatterns != {} && [regexp $cendpatterns $chr]} {
                        set commentmode 0
                        $textwidget tag add "hi-$mode-comments" $prev "$start+${numchars}c"
                    }
                } elseif {$stringmode} {
                    if {$chr == "\\"} {
                        set start "$start+${numchars}c"
                    } elseif {[regexp $strendpats $chr]} {
                        set stringmode 0
                        $textwidget tag add "hi-$mode-strings" $prev "$start+${numchars}c"
                    }
                } else {
                    if {[regexp $strstartpats $chr]} {
                        set stringmode 1
                        set prev $start
                    } elseif {[regexp $cstartpatterns $chr]} {
                        set commentmode 1
                        set prev $start
                    } elseif {$cendpatterns != {} && [regexp $cendpatterns $chr]} {
                        $textwidget tag add "hi-$mode-errors" $start "$start+${numchars}c"
                    }
                }
                if {[$textwidget compare "$start+${numchars}c" >= "$start lineend"]} {
                    if {$commentmode && $cend_has_eolpat} {
                        set commentmode 0
                        $textwidget tag add "hi-$mode-comments" $prev "$start+${numchars}c"
                    }
                    set start "$start+1line linestart"
                } else {
                    if {$numchars == 0} {
                        set numchars 1
                    }
                    set start "$start+${numchars}c"
                }
            } else {
                set start $endpos
            }
            if {[$textwidget compare $start >= $endpos]} {
                if {$commentmode || $stringmode} {
                    if {[$textwidget compare $start >= "$startpos+60lines lineend"]} {
                        break
                    }
                    set endpos [$textwidget index "$endpos+2lines lineend"]
                    if {[$textwidget compare $endpos >= "end-1c"]} {
                        set endpos [$textwidget index "end-1c"]
                        if {[$textwidget compare $start >= "end-1c"]} {
                            break
                        }
                    }
                    foreach tmpmode $TextDlogHiliteInfo(modes) {
                        foreach name $TextDlogHiliteInfo(hilites,$tmpmode) {
                            $textwidget tag remove "hi-$tmpmode-$name" $start $endpos
                        }
                    }
                } else {
                    break
                }
            }
        }
        if {$commentmode} {
            $textwidget tag add "hi-$mode-comments" $prev $endpos
        } elseif {$stringmode} {
            $textwidget tag add "hi-$mode-strings" $prev $endpos
        }
    }
    if {[info exists TextDlogHiliteInfo(hilites,$mode)]} {
        foreach name $TextDlogHiliteInfo(hilites,$mode) {
            if {$name == "strings" || $name == "comments"} {
                continue
            }
            foreach pattern $TextDlogHiliteInfo(patterns,$mode,$name) {
                set start $startpos
                while {[set start [$textwidget search -regexp -nocase -forwards -count numchars -- $pattern $start $endpos]] != ""} {
                    if {$mode != "muf" ||
                        (([$textwidget compare $start == 1.0] ||
                        [regexp -- {[\n 	]} [$textwidget get "$start-1c"]]) &&
                        [regexp -- {[\n 	]} [$textwidget get "$start+${numchars}c"]])
                    } {
                        if {[lsearch -glob [$textwidget tag names "$start"] "hi-$mode-*"] == -1} {
                            $textwidget tag add "hi-$mode-$name" $start "$start+${numchars}c"
                        }
                    }
                    set start "$start+${numchars}c"
                    if {[$textwidget compare $start >= $endpos]} break
                }
            }
        }
    }
}

proc textdlog:doreturn {w} {
    global TextDlogInfo
    set wname [winfo parent $w]
    set indent ""
    if {$TextDlogInfo(autoindent,$wname)} {
        set start [$w index "insert linestart"]
        set end $start
        while {1} {
            set ch [$w get $end]
            if {$ch != " " && $ch != "    "} {
                break
            }
            if {[$w compare $end >= insert]} {
                break
            }
            set end [$w index "$end + 1 chars"]
        }
        if {[$w compare $start < $end]} {
            set indent [$w get $start $end]
        }
    }
    $w insert insert "\n$indent"
    textdlog:updatestatbar $wname
}

proc textdlog:doexectcl {w} {
    if {[$w tag ranges sel] != {}} {
        set cmd [$w get sel.first sel.last]
        $w mark set insert sel.last
        $w tag remove sel 0.0 end
    } else {
        set cmd [$w get "insert linestart" "insert lineend"]
        $w mark set insert "insert lineend"
    }
    if {[catch {set result [eval $cmd]} errMsg]} {
        global errorInfo
        $w insert "insert" "\n$errorInfo" sel
        $w mark set insert sel.last
    } else {
        if {$result != {}} {
            $w insert "insert" "\n$result" sel
            $w mark set insert sel.last
        } else {
            $w insert "insert" "\n"
        }
    }
    textdlog:updatestatbar [winfo parent $w]
}


proc textdlog:gomark {wname mark} {
    global TextDlogInfo
    set pos [lindex $TextDlogInfo(marks,$wname) $mark]
    if {$pos == "0"} {
        /bell
    } else {
        $wname.text mark set insert $pos
        $wname.text see $pos
    }
}


proc textdlog:setmark {wname mark} {
    global TextDlogInfo
    set marks $TextDlogInfo(marks,$wname)
    set marks [lreplace $marks $mark $mark [$wname.text index insert]]
    set TextDlogInfo(marks,$wname) $marks
}


proc textdlog:gethelp {wname world} {
    global TextDlogInfo

    set mode $TextDlogInfo(mode,$wname)
    if {[catch {set topic [$wname.text get sel.first sel.last]}] || $topic == ""} {
        set topic [$wname.text get "insert wordstart" "insert wordend"]
    }
    switch -exact -- $mode {
        "muf" { set type "man" }
        "mpi" { set type "mpi" }
        default { return }
    }
    /fbhelp -world $world -type $type $topic
    return
}


tcl::OptProc textdlog:create {
    {wname    {}            "Toplevel window widget name"}
    {-parent  {}            "Widget to focus on after exiting"}
    {-title   "Text Editor" "Toplevel window title"}
    {-file    ""            "File to open.  Defaults to none."}
    {-text    {}            "Text to put in editor"}
    {-prefix  {}            "Text to prefix with in a Send"}
    {-postfix {}            "Text to postfix with in a Send"}
    {-prepend {}            "Text to prepend each line with in a Send"}
    {-append  {}            "Text to append each line with in a Send"}
    {-world   {}            "World to send to in a Send"}
    {-font    {}            "Font to use in editor"}
    {-width   80            "Number of columns in editor"}
    {-height  24            "Number of rows in editor"}
    {-variable ""           "Global variable to store results in."}
    {-nowrap                "Turns off word-wrapping of long lines."}
    {-autoindent            "Indents new lines to match previous line."}
    {-buttons               "Adds Done and Cancel buttons to dialog."}
    {-donecommand ""        "Script run when Done or File->Exit are selected."}
    {-thirdbutton ""        "Name of third button to add if any, for -buttons."}
    {-thirdcmd    ""        "Script run when third button is pressed."}
    {-modal                 "Make this dialog modal and blocking."}
    {-persistent            "Dialog isn't destroyed when closed, just hidden."}
    {-readonly              "Text is non-editable."}
    {-notabs                "User entry of tabs is prohibited."}
    {-mode -choice {none c tcl muf mpi} "Programmers assistance mode."}
} {
    global TextDlogInfo treb_colors treb_fonts tcl_platform
    set TextDlogInfo(title,$wname) $title
    set TextDlogInfo(world,$wname) $world
    set TextDlogInfo(prefix,$wname) $prefix
    set TextDlogInfo(postfix,$wname) $postfix
    set TextDlogInfo(prepend,$wname) $prepend
    set TextDlogInfo(append,$wname) $append
    set TextDlogInfo(donecmd,$wname) $donecommand
    set TextDlogInfo(thirdcmd,$wname) $thirdcmd
    set TextDlogInfo(mode,$wname) $mode
    set TextDlogInfo(marks,$wname) [list 0 0 0 0 0 0 0 0 0 0]

    if {$font == ""} {
        set font $treb_fonts(fixed)
    }
    if {$parent == ""} {
        set parent [focus]
        if {$parent == ""} {
            set parent .mw
        }
    }
    if {![winfo exists $parent]} {
        set parent .mw
    }

    set third_cmd ""
    set done_cmd ""
    set cancel_cmd ""

    if {$readonly} {
        set buttons 1
    }
    if {$modal} {
        append done_cmd   "set TextDlogInfo(result,$wname) done ; "
        append third_cmd   "set TextDlogInfo(result,$wname) third ; "
        append cancel_cmd "set TextDlogInfo(result,$wname) cancel ; "
    }
    if {$variable != ""} {
        append done_cmd "set [list $variable] "
        append done_cmd "\[$wname.text get 1.0 \"end - 1 chars\"\] ;"
        append third_cmd "set [list $variable] "
        append third_cmd "\[$wname.text get 1.0 \"end - 1 chars\"\] ;"
    }
    if {$persistent} {
        append cancel_cmd "wm withdraw $wname ; textdlog:refocus $parent"
        append done_cmd "$donecommand ; wm withdraw $wname ; textdlog:refocus $parent"
        append third_cmd "$thirdcmd"
    } else {
        append cancel_cmd "destroy $wname ; textdlog:refocus $parent"
        append done_cmd "$donecommand ; destroy $wname ; textdlog:refocus $parent"
        append third_cmd "$thirdcmd"
    }

    set TextDlogInfo(autoindent,$wname) $autoindent
    if {!$nowrap} {
        set TextDlogInfo(wordwrap,$wname) word
    } else {
        set TextDlogInfo(wordwrap,$wname) none
    }

    if {[winfo exists $wname]} {
        wm deiconify $wname
        focus $wname
    } else {
        if {$readonly} {
            toplevel $wname
        } else {
            toplevel $wname -menu $wname.mbar
        }
        place_window_default $wname $parent

        menu $wname.mbar -tearoff false
            $wname.mbar add cascade -label "File" -under 0 \
                -menu $wname.mbar.file
            $wname.mbar add cascade -label "Edit" -under 0 \
                -menu $wname.mbar.edit
            $wname.mbar add cascade -label "Mode" -under 0 \
                -menu $wname.mbar.mode

        menu $wname.mbar.file -tearoff false \
                -postcommand "textdlog:filemenupost $wname"
            $wname.mbar.file add command -label "New"        -under 0 \
                -command "textdlog:new $wname"
            $wname.mbar.file add command -label "Open"       -under 0 \
                -command "textdlog:open $wname"
            $wname.mbar.file add command -label "Save"       -under 0 \
                -command "textdlog:save $wname"
            $wname.mbar.file add command -label "Save as..." -under 1 \
                -command "textdlog:saveas $wname"
            $wname.mbar.file add separator
            $wname.mbar.file add command -label "Send"       -under 3 \
                -command "textdlog:send $wname"
            $wname.mbar.file add command -label "Send to..." -under 5 \
                -command "textdlog:sendto $wname"
            $wname.mbar.file add separator
            $wname.mbar.file add command -label "Exit"       -under 1

        menu $wname.mbar.edit -tearoff false
            $wname.mbar.edit add command -label "Cut"        -under 2 \
                -command {event generate [focus] <<Cut>>}
            $wname.mbar.edit add command -label "Copy"       -under 0 \
                -command {event generate [focus] <<Copy>>}
            $wname.mbar.edit add command -label "Paste"      -under 0 \
                -command {event generate [focus] <<Paste>>}
            $wname.mbar.edit add command -label "Delete"     -under 2 \
                -command {event generate [focus] <Key-Delete>}
            $wname.mbar.edit add separator
            $wname.mbar.edit add command -label "Select all" -under 7 \
                -command "$wname.text tag add sel 1.0 end"
            $wname.mbar.edit add command -label "Find..."    -under 0 \
                -command "
                        set cmd {finddlog:new $wname.find $wname.text}
                        append cmd \" -pattern \[list \[/prefs:get last_find_pattern\]\]\"
                        append cmd \" -direction \[/prefs:get last_find_direct\]\"
                        if {\[/prefs:get last_find_nocase\]} {
                            append cmd { -nocase}
                        }
                        if {\[/prefs:get last_find_regexp\]} {
                            append cmd { -regexp}
                        }
                        eval \$cmd
                    "
            set spellstate "disabled"
            if {[/spell:enabled]} {
                set spellstate "normal"
            }
            $wname.mbar.edit add command -label "Spell-check..." -under 0 \
                -command "/spell:check $wname.text" -state $spellstate
            $wname.mbar.edit add separator
            $wname.mbar.edit add checkbutton -label " Word wrap"  -under 1 \
                -onvalue word -offvalue none -indicatoron 1 \
                -variable TextDlogInfo(wordwrap,$wname) -command "
                    global TextDlogInfo
                    $wname.text config -wrap \$TextDlogInfo(wordwrap,$wname)
                "
            $wname.mbar.edit add checkbutton -label " Auto-indent"  -under 6 \
                -onvalue 1 -offvalue 0 -indicatoron 1 \
                -variable TextDlogInfo(autoindent,$wname)

        menu $wname.mbar.mode -tearoff false
            $wname.mbar.mode add radiobutton -label " No mode"  -under 1 \
                -indicatoron 1 -value "none" \
                -variable TextDlogInfo(mode,$wname) \
                -command "textdlog:syntax:changemode $wname"
            $wname.mbar.mode add radiobutton -label " TCL mode"  -under 1 \
                -indicatoron 1 -value "tcl" \
                -variable TextDlogInfo(mode,$wname) \
                -command "textdlog:syntax:changemode $wname"
            $wname.mbar.mode add radiobutton -label " MUF mode"  -under 1 \
                -indicatoron 1 -value "muf" \
                -variable TextDlogInfo(mode,$wname) \
                -command "textdlog:syntax:changemode $wname"
            $wname.mbar.mode add radiobutton -label " MPI mode"  -under 2 \
                -indicatoron 1 -value "mpi" \
                -variable TextDlogInfo(mode,$wname) \
                -command "textdlog:syntax:changemode $wname"
            $wname.mbar.mode add radiobutton -label " C mode"  -under 1 \
                -indicatoron 1 -value "c" \
                -variable TextDlogInfo(mode,$wname) \
                -command "textdlog:syntax:changemode $wname"

        text $wname.text -wrap word \
            -xscrollcommand "$wname.scrollx set" \
            -yscrollcommand "$wname.scrolly set" \
            -width 1 -height 1 -font $treb_fonts(fixed)
        if {[info commands textPopup:addentry] != ""} {
            textPopup:addentry $wname.text sel "Get help on..." "textdlog:gethelp [list $wname] [list $world]"
        }
        for {set i 0} {$i < 10} {incr i} {
            bind $wname.text "<Key-F[expr {$i + 1}]>" "textdlog:gomark $wname $i"
            bind $wname.text "<Shift-Key-F[expr {$i + 1}]>" "textdlog:setmark $wname $i"
        }
        if {$readonly} {
            if {$tcl_platform(winsys) == "aqua"} {
                set bgcolor "white"
            } else {
                set bgcolor $treb_colors(buttonface)
            }
            $wname.text config -background $bgcolor
            $wname.text config -insertwidth 0
            bind $wname.text <Key> {
                switch -exact -- %K {
                    Home     {%W see 1.0}
                    End      {%W see end}
                    Left     {%W xview scroll -1 units}
                    Right    {%W xview scroll 1 units}
                    Up       {%W yview scroll -1 units}
                    Down     {%W yview scroll 1 units}
                    Prior    {%W yview scroll -1 pages}
                    Next     {%W yview scroll 1 pages}
                    Escape   {continue}
                    Return   {continue}
                    default  {bell ; break}
                }
                break
            }
        } else {
            bind $wname.text <Key-Return> {
                textdlog:doreturn %W
                break
            }
            if {$notabs} {
                bind $wname.text <Key-Tab> {
                    focus [tk_focusNext %W]
                    break
                }
            }
            bind $wname.text <Control-Key-Return> {
                textdlog:doexectcl %W
                break
            }
            bind $wname.text <Key-F12> "textdlog:gethelp [list $wname] [list $world];break"
        }
        scrollbar $wname.scrolly -command "$wname.text yview"
        scrollbar $wname.scrollx -orient horizontal -command "$wname.text xview"

        grid columnconf $wname 0 -weight 1
        grid columnconf $wname 1 -weight 0
        grid rowconf $wname 0 -weight 1
        grid rowconf $wname 1 -weight 0
        grid rowconf $wname 2 -weight 0
        grid $wname.text   -column 0 -row 0 -sticky nsew
        grid $wname.scrolly -column 1 -row 0 -sticky ns
        grid $wname.scrollx -column 0 -row 1 -sticky ew

        if {$buttons} {
            frame $wname.buttons -relief flat
            set bwid 7
            if {$thirdbutton != {}} {
                set slen [string length $thirdbutton]
                if {$slen > $bwid} {
                    set bwid $slen
                }
                button $wname.buttons.third -width $bwid -text $thirdbutton
            }
            button $wname.buttons.cancel -width $bwid -text "Cancel"
            button $wname.buttons.done -width $bwid -text "Done" -underline 0
            grid columnconfig $wname.buttons 0 -minsize 15
            grid columnconfig $wname.buttons 2 -minsize 15 -weight 1
            grid columnconfig $wname.buttons 4 -minsize 15
            grid columnconfig $wname.buttons 6 -minsize 15
            grid columnconfig $wname.buttons 8 -minsize 15
            grid rowconfig $wname.buttons 0 -minsize 10
            grid rowconfig $wname.buttons 2 -minsize 10
            if {$thirdbutton != {}} {
                grid $wname.buttons.third   -row 1 -column 3
            }
            grid $wname.buttons.cancel -row 1 -column 5
            grid $wname.buttons.done   -row 1 -column 7
            # I lost four hours work due to the following line; I'm a vi user:
            # bind $wname <Key-Escape> "$wname.buttons.cancel invoke"
            bind $wname <Alt-Key-d> "$wname.buttons.done invoke"

            grid $wname.buttons -row 2 -column 0 -columnspan 2 -sticky nsew
        }
        if {!$readonly} {
            frame $wname.statbar -borderwidth 0 -relief flat
            label $wname.statbar.line -text "Line 1" -width 10 \
                    -borderwidth 1 -relief sunken -anchor w
            pack $wname.statbar.line -side right -fill y -padx 1 -pady 2
            bind $wname.text <ButtonPress-1> "textdlog:updatestatbar $wname"
            bind $wname.text <KeyPress> "textdlog:updatestatbar $wname"

            if {$buttons} {
                grid $wname.statbar -in $wname.buttons -row 2 -column 1 -sticky w
                $wname.statbar.line config -relief flat
            } else {
                grid rowconfig $wname 3 -weight 0 -minsize 15
                grid $wname.statbar -row 3 -column 0 -columnspan 2 -sticky nsew
            }
        }
    }

    wm title $wname $title
    wm protocol $wname WM_DELETE_WINDOW "$cancel_cmd"
    if {$modal && $tcl_platform(winsys) != "aqua"} {
        wm transient $wname $parent
    }
    place_window_default $wname $parent

    $wname.text config -wrap $TextDlogInfo(wordwrap,$wname)
    $wname.text config -font $font -width $width -height $height
    if {$text != ""} {
        $wname.text delete 1.0 end
        $wname.text insert end $text
    }
    set TextDlogInfo(filename,$wname) ""

    if {$file != ""} {
        textdlog:open $wname $file
    }
    $wname.mbar.file entryconfig "Exit" -command "$done_cmd"
    if {$buttons} {
        if {$thirdbutton != {}} {
            $wname.buttons.third config -command "$third_cmd"
        }
        $wname.buttons.done config -command "$done_cmd"
        $wname.buttons.cancel config -command "$cancel_cmd"
    }

    textdlog:syntax:init $wname
    $wname.text mark set insert 1.0
    $wname.text see insert
    focus $wname.text

    if {$modal} {
        grab $wname
        vwait TextDlogInfo(result,$wname)
        if {[winfo exists $wname]} {
            wm transient $wname {}
        }
        return $TextDlogInfo(result,$wname)
    } else {
        return $wname
    }
}


global textdlog_widgetnumber
set textdlog_widgetnumber 0

proc /textdlog {args} {
    global textdlog_widgetnumber
    incr textdlog_widgetnumber
    set wname .textdlog$textdlog_widgetnumber

    eval "textdlog:create $wname $args"
}

