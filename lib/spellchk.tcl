proc /spell:enabled {{issuggest 0}} {
    global spell_is_ispell_compat
    set spell_is_ispell_compat 0
    set spell_cmd [spell:command $issuggest]
    if {$spell_cmd == ""} {
        return "0"
    }
    if {![file executable [lindex $spell_cmd 0]]} {
        return "0"
    }
    set cmd [lindex [spell:command 1] 0]
    if {[lsearch -regexp [file split $cmd] "(?i)\[ai\]spell(\.exe)?"] >= 0} {
        set spell_is_ispell_compat 1
    }
    return "1"
}


proc /spell:check {{wname ""}} {
    global spell_suggestions
    global spell_badwords
    global spell_curr_offset
    global spell_is_ispell_compat
    global tcl_platform

    if {$wname == ""} {
        set wname [/inbuf]
    }
    set parent [winfo toplevel $wname]
    spell:process check $wname

    set win "$parent.spell_win"
    catch {destroy $win}
    if {[llength [array names spell_badwords]] == 0} {
        tk_messageBox -type ok -icon info -parent $parent \
            -title "Spell-check completed" \
            -message "No misspelled words."
        return
    }

    toplevel $win -class Toplevel
    if {$tcl_platform(winsys) == "aqua"} {
        if {[info commands ::tk::unsupported::MacWindowStyle] != ""} {
            # If the command exists, make this window a tool window.
            wm transient $win $parent
            ::tk::unsupported::MacWindowStyle style $win floating standardFloating
        }
    } else {
        wm transient $win $parent
    }

    wm title  $win "Spelling - TrebTk"

    label   $win.listlbl -text "Spelling suggestions"
    frame   $win.listfr
    if { [info tclversion] >= 8.4 } {
        listbox $win.listfr.list -relief sunken -height 8 -width 20 \
            -activestyle underline -highlightthickness 0 \
            -yscrollcommand "$win.listfr.sb set"
    } else {
        listbox $win.listfr.list -relief sunken -height 8 -width 20 \
            -highlightthickness 0 -yscrollcommand "$win.listfr.sb set"
    }
    bind $win.listfr.list <<ListboxSelect>> [list spell:select_suggestion $win]
    bind $win.listfr.list <Double-Button-1> [list spell:doubleclick_suggestion $win %x %y]
    scrollbar $win.listfr.sb -command "$win.listfr.list yview"
    entry $win.word -width 20
    bind $win.word <Key-Return> [list $win.corrall invoke]
    bind $win.word <Key-Up>   [list spell:updown_suggestion $win -1]
    bind $win.word <Key-Down> [list spell:updown_suggestion $win 1]
    bind $win.listfr.list <Key-Escape> ""
    bind $win.word <Key-Escape> ""
    bind $win <Key-Escape> [list $win.done invoke]

    button  $win.corrall -text "Replace all" -command "spell:replace_all $win $wname" -default active
    button  $win.correct -text "Replace"     -command "spell:replace_word $win $wname"
    button  $win.ignore  -text "Ignore all"  -command "spell:ignore_word $win $wname"
    button  $win.learn   -text "Learn"       -command "spell:learn_word $win $wname"
    button  $win.next    -text "Next word"   -command "spell:next_word $win $wname"
    button  $win.done    -text "Done"        -command "destroy $win"

    pack $win.listfr.list -side left -fill both -expand true
    pack $win.listfr.sb -side left -fill y

    if {$spell_is_ispell_compat} {
        $win.learn configure -state normal
    } else {
        $win.learn configure -state disabled
    }

    grid columnconfigure $win 0 -minsize 10
    grid columnconfigure $win 1 -weight 1
    grid columnconfigure $win 3 -minsize 10
    grid rowconfigure    $win 0 -minsize 10
    grid rowconfigure    $win 2 -weight 1
    grid rowconfigure    $win 4 -weight 1
    grid rowconfigure    $win 7 -minsize 10

    grid x $win.listlbl $win.corrall x -row 1
    grid x $win.listfr  $win.correct x
    grid x x            $win.ignore  x
    grid x x            $win.learn   x
    grid x x            $win.next    x
    grid x $win.word    $win.done    x

    grid $win.done $win.next $win.ignore $win.learn $win.corrall $win.correct -sticky new -padx 10 -pady 2
    grid $win.listlbl -sticky w -padx 10 -pady 2
    grid $win.word -sticky ew -padx 10 -pady 3
    grid $win.listfr -sticky nsew -padx 10 -pady 5 -rowspan 4

    focus $win.word

    spell:next_word $win $wname 1.0

    grab set $win
    tkwait window $win
    grab release $win
}


proc /spell:suggest {word {wname ""}} {
    global spell_suggestions

    if {$wname == ""} {
        set wname [/inbuf]
    }
    spell:process suggest $wname $word
    if {[info exists spell_suggestions($word)]} {
        return $spell_suggestions($word)
    } else {
        return {}
    }
}


proc /spell:showbad {{wname ""}} {
    global spell_suggestions
    global spell_badwords
    global spell_curr_offset

    if {$wname == ""} {
        set wname [/inbuf]
    }
    if {![/spell:enabled]} {
        return
    }
    spell:process check $wname

    $wname tag remove badwords 1.0 end
    $wname tag configure badwords -underline 1 -foreground red -background black
    set insert [$wname index insert]
    foreach offset [array names spell_badwords] {
        set badword $spell_badwords($offset)
        set charcount [string length $badword]
        if {[$wname compare $insert < $offset] ||
            [$wname compare $insert > "$offset + $charcount chars"]
        } {
            $wname tag add badwords $offset "$offset + $charcount chars"
        }
    }
}


proc /spell:showbad_clear {{wname ""}} {
    if {$wname == ""} {
        set wname [/inbuf]
    }
    $wname tag remove badwords 1.0 end
}


proc /spell:showbad_if_needed {{wname ""}} {
    global spell_live_needscheck
    if {$wname == ""} {
        set wname [/inbuf]
    }
    if {![info exists spell_live_needscheck($wname)]} {
        return
    }
    if {!$spell_live_needscheck($wname)} {
        return
    }
    /spell:showbad $wname
    unset spell_live_needscheck($wname)
}


proc /spell:needs_checking {{wname ""}} {
    global spell_live_needscheck
    if {$wname == ""} {
        set wname [/inbuf]
    }
    set spell_live_needscheck($wname) 1
    return
}


proc /spell:update_showbad {{wname ""}} {
    if {$wname == ""} {
        set wname [/inbuf]
    }
    if {[/prefs:get spell_as_you_type]} {
        /spell:showbad $wname
    } else {
        /spell:showbad_clear $wname
    }
    return
}


proc /spell:toggle_showbad {{wname ""}} {
    if {[/prefs:get spell_as_you_type]} {
        /prefs:set spell_as_you_type 0
    } else {
        /prefs:set spell_as_you_type 1
    }
    /spell:update_showbad $wname
    return
}


proc /spell:learn {word {wname ""}} {
    global spell_learned_words

    if {$wname == ""} {
        set wname [/inbuf]
    }
    lappend spell_learned_words $word
    spell:process learn $wname
    spell:process check $wname
    return
}


proc /spell:ignore {word {wname ""}} {
    global spell_ignored_words

    if {$wname == ""} {
        set wname [/inbuf]
    }
    lappend spell_ignored_words $word
    spell:process check $wname
    return
}




proc /spell:fixword {pos newword {wname ""}} {
    global spell_badwords

    if {$wname == ""} {
        set wname [/inbuf]
    }
    if {![info exists spell_badwords($pos)]} {
        return ""
    }
    set badword $spell_badwords($pos)
    set badlen [string length $badword]

    $wname delete $pos $pos+${badlen}c
    $wname insert $pos $newword

    spell:process check $wname
}


proc spell:updown_suggestion {win delta} {
    set idx [$win.listfr.list curselection]
    if {$idx == ""} {
        set idx 0
    } else {
        incr idx $delta
    }
    set max [$win.listfr.list index end]
    if {$idx >= 0 && $idx < $max} {
        $win.listfr.list selection clear 0 end
        $win.listfr.list selection set $idx
        $win.listfr.list see $idx
        spell:select_suggestion $win
    }
}


proc spell:doubleclick_suggestion {win x y} {
    $win.listfr.list selection clear 0 end
    $win.listfr.list selection set @$x,$y
    $win.listfr.list activate @$x,$y
    spell:select_suggestion $win
    $win.correct invoke
}


proc spell:select_suggestion {win} {
    set idx [$win.listfr.list curselection]
    if {$idx == ""} {
        return
    }
    $win.listfr.list activate $idx
    set word [$win.listfr.list get $idx]
    $win.word delete 0 end
    $win.word insert end $word
}


proc spell:populate_suggestions {win badword} {
    global spell_suggestions
    $win.listfr.list delete 0 end
    if {[info exists spell_suggestions($badword)]} {
        foreach sugg $spell_suggestions($badword) {
            $win.listfr.list insert end $sugg
        }
    }
    $win.listfr.list selection clear 0 end
    $win.listfr.list selection set 0
    $win.listfr.list activate 0
    $win.listfr.list see 0
    return
}


proc spell:next_word {win wname {pos ""}} {
    global spell_suggestions
    global spell_badwords
    global spell_curr_offset
    set startpos $pos
    set parent [winfo toplevel $wname]
    if {$pos == ""} {
        if {![info exists spell_curr_offset]} {
            set spell_curr_offset 1.0
            set pos 1.0
        } else {
            set pos [$wname index $spell_curr_offset+1c]
        }
    }
    set badword ""
    set foundoff "end"
    foreach offset [array names spell_badwords] {
        if {[$wname compare $offset >= $pos]} {
            if {[$wname compare $offset < $foundoff]} {
                set badword $spell_badwords($offset)
                set foundoff $offset
            }
        }
    }
    if {$badword != ""} {
        set charcount [string length $badword]
        $wname tag configure badwords -background red2 -foreground black
        $wname tag remove badwords 1.0 end
        $wname tag add badwords $foundoff "$foundoff + $charcount chars"
        $wname tag remove sel 1.0 end
        $wname tag add sel $foundoff "$foundoff + $charcount chars"
        $wname mark set insert "$foundoff + $charcount chars"
        $wname see "$foundoff + $charcount chars"
        $wname see $foundoff
        set spell_curr_offset $foundoff
        $win.word delete 0 end
        $win.word insert end $badword
        spell:process suggest $wname $badword
        spell:populate_suggestions $win $badword
    } else {
        set spell_curr_offset 1.0
        if {$startpos != "1.0"} {
            spell:next_word $win $wname 1.0
        } else {
            $wname tag remove sel 1.0 end
            $wname tag remove badwords 1.0 end
            destroy $win
            update
            tk_messageBox -type ok -icon info -parent $parent \
                -title "Spell-checker" \
                -message "No more misspelled words."
        }
    }
    return
}


proc spell:ignore_word {win wname} {
    global spell_badwords
    global spell_curr_offset
    global spell_ignored_words
    if {![info exists spell_curr_offset]} {
        set spell_curr_offset 1.0
        spell:next_word $win $wname
        return ""
    }
    if {![info exists spell_badwords($spell_curr_offset)]} {
        return ""
    }
    set badword $spell_badwords($spell_curr_offset)
    lappend spell_ignored_words $badword

    foreach offset [array names spell_badwords] {
        set word $spell_badwords($offset)
        if {$word == $badword} {
            unset spell_badwords($offset)
        }
    }

    spell:next_word $win $wname
}


proc spell:learn_word {win wname} {
    global spell_badwords
    global spell_curr_offset
    global spell_learned_words
    if {![info exists spell_curr_offset]} {
        set spell_curr_offset 1.0
        spell:next_word $win $wname
        return ""
    }
    if {![info exists spell_badwords($spell_curr_offset)]} {
        return ""
    }
    set word $spell_badwords($spell_curr_offset)

    foreach offset [array names spell_badwords] {
        set badword $spell_badwords($offset)
        if {$word == $badword} {
            unset spell_badwords($offset)
        }
    }

    lappend spell_learned_words $word

    spell:process learn $wname
    spell:next_word $win $wname
}


proc spell:replace_all {win wname} {
    global spell_badwords
    global spell_curr_offset
    if {![info exists spell_curr_offset]} {
        set spell_curr_offset 1.0
        spell:next_word $win $wname
        return ""
    }
    if {![info exists spell_badwords($spell_curr_offset)]} {
        return ""
    }
    set badword $spell_badwords($spell_curr_offset)

    foreach offset [array names spell_badwords] {
        set word $spell_badwords($offset)
        if {$word == $badword} {
            unset spell_badwords($offset)
        }
    }

    set word [$win.word get]
    if {$word == $badword} {
        spell:select_suggestion $win
        set word [$win.word get]
    }
    set newlen [string length $word]
    set badlen [string length $badword]
    set pos 1.0
    while {1} {
        set next [$wname search -forwards -regexp -- "\\m$badword\\M" $pos "end-1c"]
        if {$next == ""} {
            break
        }
        $wname delete $next $next+${badlen}c
        $wname insert $next $word
        if {[$wname compare $next < $spell_curr_offset]} {
            set spell_curr_offset [$wname index "$spell_curr_offset-$badlen chars +$newlen chars"]
        }
        set pos [$wname index $next+${newlen}c]
    }

    spell:process check $wname
    spell:next_word $win $wname
}


proc spell:replace_word {win wname {word ""}} {
    global spell_badwords
    global spell_curr_offset
    if {![info exists spell_curr_offset]} {
        set spell_curr_offset 1.0
        spell:next_word $win $wname
        return ""
    }
    if {![info exists spell_badwords($spell_curr_offset)]} {
        return ""
    }
    set pos $spell_curr_offset
    set badword $spell_badwords($pos)
    unset spell_badwords($pos)

    if {$word == ""} {
        set word [$win.word get]
    }
    if {$word == $badword} {
        spell:select_suggestion $win
        set word [$win.word get]
    }
    set newlen [string length $word]
    set badlen [string length $badword]

    $wname delete $pos $pos+${badlen}c
    $wname insert $pos $word

    spell:process check $wname
    spell:next_word $win $wname
}


proc spell:command {issuggest} {
    global tcl_platform env
    global spell_expanded_command
    if {$issuggest} {
        set spell_cmd [/prefs:get spell_suggest_cmd]
    } else {
        set spell_cmd [/prefs:get spell_check_cmd]
    }
    if {$spell_cmd == ""} {
        return ""
    }
    set spell_args [lrange $spell_cmd 1 end]
    set spell_cmd [lindex $spell_cmd 0]

    if {[info exists spell_expanded_command($spell_cmd)]} {
        set spell_cmd $spell_expanded_command($spell_cmd)
        return [concat [list $spell_cmd] $spell_args]
    }
    set spell_cmd_short $spell_cmd

    set pathlist {}
    if {[info exists env(PATH)]} {
        if {$tcl_platform(platform) == "windows"} {
            set pathlist [concat $pathlist [split $env(PATH) ";"]]
        } else {
            set pathlist [concat $pathlist [split $env(PATH) ":"]]
        }
    }
    if {$tcl_platform(platform) == "windows"} {
        set key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Aspell"
        if {![catch {registry get $key "Path"} aspell_path]} {
            if {$aspell_path != ""} {
                set pathlist [concat [list $aspell_path] $pathlist]
            }
        }
    } elseif {$tcl_platform(os) == "Darwin"} {
        lappend pathlist /sw/bin /usr/local/bin
    }

    if {[file pathtype $spell_cmd] != "absolute"} {
        foreach path $pathlist {
            set cmd [file join $path $spell_cmd]
            if {[file isfile $cmd] && [file executable $cmd]} {
                set spell_cmd $cmd
                break
            }
            if {$tcl_platform(platform) == "windows"} {
                append cmd ".exe"
                if {[file isfile $cmd] && [file executable $cmd]} {
                    set spell_cmd $cmd
                    break
                }
            }
        }
    }
    if {![file isfile $cmd] || ![file executable $cmd]} {
        return ""
    }
    set spell_expanded_command($spell_cmd_short) $spell_cmd
    return [concat [list $spell_cmd] $spell_args]
}


# mode is one of "check", "suggest", or "learn"
proc spell:process {mode wname {word ""}} {
    global spell_suggestions
    global spell_badwords
    global spell_learned_words
    global spell_ignored_words
    global spell_is_ispell_compat
    global env tcl_platform

    if {$mode == "suggest" && $word != ""} {
        if {[info exists spell_suggestions($word)]} {
            return
        }
        set spell_suggestions($word) {}
    }
    set parent [winfo toplevel $wname]

    if {![/spell:enabled]} {
        tk_messageBox -type ok -icon error -parent $parent \
            -title "Spell-checker error" \
            -message "You need to install ispell or aspell, and set your spelling command preference before you can use the spell-checking command."
        return
    }

    if {[info exists env(TMP)]} {
        set spell_temp [file join $env(TMP) treb-spell.[pid]]
    } elseif {[info exists env(TEMP)]} {
        set spell_temp [file join $env(TEMP) treb-spell.[pid]]
    } else {
        set spell_temp [file join "/" "tmp" treb-spell.[pid]]
    }
    if {[file exists $spell_temp]} {
        file delete $spell_temp
    }

    if {$mode == "check"} {
        set spell_cmd [spell:command 0]
    } else {
        set spell_cmd [spell:command 1]
    }
    if {$spell_cmd == ""} {
        return
    }
    if {[catch {set spell_stdin [open "|$spell_cmd >$spell_temp" w]} err]} {
        tk_messageBox -type ok -icon error -parent $parent \
            -title "Spell-checker error" \
            -message "An error occured during the execution of the spell-checking command: $err"
        if {[file exists $spell_temp]} {
            file delete $spell_temp
        }
        return
    }

    if {$mode == "check" || ($mode == "suggest" && $word == "")} {
        if {[info exists spell_badwords]} {
            unset spell_badwords
        }
    }
    if {![info exists spell_ignored_words]} {
        set spell_ignored_words {}
    }

    if {$mode != "check"} {
        puts $spell_stdin "!"
        if {[info exists spell_learned_words]} {
            if {[llength $spell_learned_words] > 0} {
                foreach lword $spell_learned_words {
                    puts $spell_stdin "*$lword"
                }
                puts $spell_stdin "#"
                set spell_learned_words {}
            }
        }
        if {[info exists spell_ignored_words]} {
            if {[llength $spell_ignored_words] > 0} {
                foreach iword $spell_ignored_words {
                    puts $spell_stdin "@$iword"
                }
            }
        }
    }

    if {$mode == "check"} {
        foreach line [split [$wname get 1.0 end-1c] "\n"] {
            puts $spell_stdin "$line"
        }
    } elseif {$mode == "suggest"} {
        if {$word != ""} {
            puts $spell_stdin "^$word"
        } else {
            foreach line [split [$wname get 1.0 end-1c] "\n"] {
                puts $spell_stdin "^$line"
            }
        }
    }

    flush $spell_stdin
    if {[catch {close $spell_stdin} err]} {
	if {[string first "Sorry, I can't read the file " $err] != -1 ||
	    [string first "Error: No word lists can be found for " $err] != -1
	} {
	    set mesg "The --lang argument for your spell-checker command referred to a language that aspell didn't recognize.\n\nOn most systems, when using aspell for spell-checking English, this argument should be:\n\n    --lang=en\n\nthough on some you may need to use:\n\n    --lang=english\n\nYou can edit the spelling command in the Spelling tab of the Preferences dialog."
	} else {
	    set mesg "An error occured during the execution of the spell-checking command: $err"
	}
	tk_messageBox -type ok -icon error -parent $parent \
	    -title "Spell-checker error" -message $mesg
        if {[file exists $spell_temp]} {
            file delete $spell_temp
        }
        return
    }

    if {[catch {set spell_stdout [open $spell_temp r]}]} {
        tk_messageBox -type ok -icon error -parent $parent \
            -title "Spell-checker error" \
            -message "An error occured while opening the result file."
        if {[file exists $spell_temp]} {
            file delete $spell_temp
        }
        return
    }

    set linenum 1
    set pos 1.0
    while {![eof $spell_stdout]} {
        set wordinfo [gets $spell_stdout]
        if {$mode == "check"} {
            if {[lsearch -exact $spell_ignored_words $wordinfo] == -1} {
                set pos [$wname search -forwards -regexp -- \
                                "\\m$wordinfo\\M" $pos "end-1c"]
                if {$pos == ""} {
                    break
                }
                set spell_badwords($pos) $wordinfo
                set wordlen [string length $wordinfo]
                set pos [$wname index "$pos+${wordlen}c"]
            }
        } else {
            if {$wordinfo == ""} {
                incr linenum
                continue
            }
            if {$spell_is_ispell_compat} {
                switch -exact [string index $wordinfo 0] {
                    "@" {
                        # This is a comment, more or less.  Ignore it.
                    }
                    "*" -
                    "-" -
                    "+" {
                        # Word is good.  Do nothing.
                    }
                    "?" -
                    "&" {
                        # Bad word!  But I have some suggestions.
                        regsub -all {[,:] } $wordinfo ":" wordinfo
                        set info [lindex [split $wordinfo ":"] 0]
                        set suggs [lrange [split $wordinfo ":"] 1 end]
                        foreach {dummy badword numsuggs offset} $info break
                        incr offset -1
                        if {$numsuggs <= 0} {
                            set suggs {}
                        } else {
                            incr numsuggs -1
                            set suggs [lrange $suggs 0 $numsuggs]
                        }
                        set spell_suggestions($badword) $suggs
                        if {$word == ""} {
                            set spell_badwords($linenum.$offset) $badword
                        }
                    }
                    "#" {
                        # Bad word!  But I have no suggestions.
                        foreach {dummy badword offset} $wordinfo break
                        set spell_suggestions($badword) {}
                        if {$word == ""} {
                            set spell_badwords($linenum.$offset) $badword
                        }
                    }
                }
            } else {
                if {[string first [string index $wordinfo 0] "@*-+#?&"] == -1} {
                    set suggs $wordinfo
                } else {
                    set suggs [string trim [string range $wordinfo 1 end]]
                }
                if {[lindex $suggs 0] == $word} {
                    set suggs [string trim [lrange $suggs 1 end]]
                }
                regsub -all "\[0-9,:\]" $suggs "" suggs
                set spell_suggestions($word) [split [string trim $suggs]]
            }
        }
    }

    close $spell_stdout
    file delete $spell_temp
}


