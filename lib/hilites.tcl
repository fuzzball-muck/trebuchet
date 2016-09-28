global hilite_match_string
global hilite_match_attrs
global hilite_proc_dirty
set hilite_match_string ""
set hilite_match_attrs {}
set hilite_proc_dirty 1


proc lremove {var data} {
    upvar $var myvar
    set out {}
    foreach item $myvar {
        if {$item != $data} {
            lappend out $item
        }
    }
    set myvar $out
    return $out
}

proc /substitute {string {attrs {}}} {
    global hilite_match_attrs
    global hilite_match_string

    if {![info exists hilite_match_string]} {
        error "/substitute: Can only be used within a /hilite script."
    }
    set hilite_match_attrs $attrs
    set hilite_match_string $string
    return ""
}

global HiliteInfo
global HiliteStyleBackMap
set HiliteInfo(matchvalues) {
    {starts      {Starting with}     {{*start*} {*begin*}}    }
    {ends        {Ending with}       {{*ends*} {*ending*}}    }
    {word        {Containing Word}   {{*word*}}               }
    {contains    {Containing Text}   {{*contain*}}            }
    {wildcard    {Wildcard Matching} {{*glob*} {*wild*}}      }
    {regexp      {RegExp Matching}   {{*match*} {*regexp*}}   }
}

proc hilite:matchtext {str} {
    global HiliteInfo

    set str [string tolower $str]
    foreach val $HiliteInfo(matchvalues) {
        foreach pat [lindex $val 2] {
            if {[string match $pat $str]} {
                return [lindex $val 1]
            }
        }
    }
    return ""
}

proc hilite:matchvalue {str} {
    global HiliteInfo

    set str [string tolower $str]
    foreach val $HiliteInfo(matchvalues) {
        foreach pat [lindex $val 2] {
            if {[string match $pat $str]} {
                return [lindex $val 0]
            }
        }
    }
    return ""
}

proc /hilite {opt args} {
    dispatcher /hilite $opt $args
}

proc /hilite:edit {{item ""}} {
    if {$item == ""} {
        /editdlog Hilites Hilite /hilite
    } else {
        /newdlog Hilite /hilite $item
    }
}

proc /hilite:get {opt name} {
    global hilites
    if {![/hilite:exists $name]} {
        error "/hilite:get: No such hilite"
    }
    switch -exact -- $opt {
        name     {return $name}
        pattern  {return [lindex $hilites($name) 1]}
        style    {return [lindex $hilites($name) 2]}
        script   {return [lindex $hilites($name) 3]}
        priority {return [lindex $hilites($name) 4]}
        fallthru {return [lindex $hilites($name) 5]}
        chance   {return [lindex $hilites($name) 6]}
        type     {return [lindex $hilites($name) 7]}
        match    {return [lindex $hilites($name) 8]}
        category {return [lindex $hilites($name) 9]}
        enabled  {return [lindex $hilites($name) 10]}
        template {return [expr {[lindex $hilites($name) 9] == "Templates"}]}
        beep     {return [lindex $hilites($name) 12]}
        tcl      {return [lindex $hilites($name) 13]}
        casesens {return [lindex $hilites($name) 14]}
        default {
            error "/hilite get: Unknown member \"$opt\" should be one of name, pattern, style, script, priority, fallthru, chance, type, match, category, enabled, template, beep, tcl, or casesens."
        }
    }
}

proc /hilite:set {name args} {
    global hilites
    if {![/hilite:exists $name]} {
        error "/hilite:set: No such hilite"
    }
    foreach {opt val} $args {
        set opt [string trimleft $opt -]
        switch -exact -- $opt {
            name     {error "/hilite:set: Can't rename a hilite via set."}
            pattern  -
            style    -
            script   -
            priority -
            fallthru -
            chance   -
            type     -
            match    -
            category -
            enabled  -
            template -
            beep     -
            tcl      -
            casesens {}
            default {
                error "/hilite get: Unknown member \"$opt\" should be one of name, pattern, style, script, priority, fallthru, chance, type, match, category, enabled, template, beep, tcl, or casesens."
            }
        }
    }
    foreach {opt val} $args {
        set opt [string trimleft $opt -]
        switch -exact -- $opt {
            pattern  {set hilites($name) [lreplace $hilites($name)  1  1 $val]}
            style    {set hilites($name) [lreplace $hilites($name)  2  2 $val]}
            script   {set hilites($name) [lreplace $hilites($name)  3  3 $val]}
            priority {set hilites($name) [lreplace $hilites($name)  4  4 $val]}
            fallthru {set hilites($name) [lreplace $hilites($name)  5  5 $val]}
            chance   {set hilites($name) [lreplace $hilites($name)  6  6 $val]}
            type     {set hilites($name) [lreplace $hilites($name)  7  7 $val]}
            match    {set hilites($name) [lreplace $hilites($name)  8  8 $val]}
            category {set hilites($name) [lreplace $hilites($name)  9  9 $val]}
            enabled  {set hilites($name) [lreplace $hilites($name) 10 10 $val]}
            template {
                if {$val == "1" || $val == "true"} {
                    set hilites($name) [lreplace $hilites($name)  9  9 Templates]
                }
            }
            beep     {set hilites($name) [lreplace $hilites($name) 12 12 $val]}
            tcl      {set hilites($name) [lreplace $hilites($name) 13 13 $val]}
            casesens {set hilites($name) [lreplace $hilites($name) 14 14 $val]}
        }
    }
    hilite:create_match_proc
    /hilite:notifyregistered update $name
}


proc /hilite:displayline {world attrs line {partial 0}} {
    set linetags normal
    /socket:writeln_norefresh $world $line $attrs $partial
    update idletasks
    return ""
}

# Finds ANSI codes in a text line.
# returns a list of {start stop attribute} lists.
proc hilite:process_ansi {text} {
    if {[string first "\033\[" $text] == -1} {
        return [list $text {}]
    }
    set pos 0
    set outstr {}
    set attrs {}
    set codeseq {}

    set old_bgcolor     {}
    set old_fgcolor     {}
    set old_bold        0
    set old_dim         0
    set old_italics     0
    set old_underline   0
    set old_flash       0
    set old_inverse     0
    set old_strike      0

    set start_bg        {}
    set start_fg        {}
    set start_bold      0
    set start_dim       0
    set start_italics   0
    set start_underline 0
    set start_flash     0
    set start_inverse   0
    set start_strike    0

    set new_bgcolor     {}
    set new_fgcolor     {}
    set new_bold        0
    set new_dim         0
    set new_italics     0
    set new_underline   0
    set new_flash       0
    set new_inverse     0
    set new_strike      0

    # ansi-sequence := '\033' "[" code-sequence "m"
    # code-sequence := code | code ";" code-sequence
    # code := simple-code | foreground-code | background-color
    # foreground-color := "3" color-code
    # background-color := "4" color-code
    # simple-code := "0" |  ; reset
    #                "1" |  ; bold
    #                "2" |  ; dim
    #                "3" |  ; italics
    #                "4" |  ; underline
    #                "5" |  ; flash slow
    #                "6" |  ; flash fast
    #                "7" |  ; inverse
    #                "8" |  ; elide
    #                "9" |  ; strikethru
    #                "22" | ; reset both bold and dim
    #                "23" | ; reset italics
    #                "24" | ; reset underline
    #                "25" | ; reset flash
    #                "27" | ; reset inverse
    #                "28" | ; reset elide
    #                "29" | ; reset strikethru
    # color-code := "0" |  ; black
    #               "1" |  ; red
    #               "2" |  ; green
    #               "3" |  ; yellow
    #               "4" |  ; blue
    #               "5" |  ; purple
    #               "6" |  ; cyan
    #               "7"    ; white

    while {$text != {}} {
        set codepos [string first "\033\[" $text]
        if {$codepos == -1} {
            incr pos [string length $text]
            append outstr $text
            set codeseq "0"
            set text ""
        } else {
            incr pos $codepos
            if {$codepos > 0} {
                append outstr [string range $text 0 [expr {$codepos - 1}]]
            }
            if {$codepos < [string length $text]} {
                set text [string range $text [expr {$codepos + 2}] end]
            } else {
                set text ""
            }
            set hascode [regexp -- "^(\[0-9;\]*)m(.*)\$" $text foo codeseq newtext]
            if {!$hascode} {
                set text "\[$text"
                continue
            } else {
                set text $newtext
            }
        }
        if {$codeseq == ""} {
            set codeseq "0"
        }
        foreach code [split $codeseq ";"] {
            switch -exact -- $code {
                00  -
                0   {
                    set new_bgcolor {}
                    set new_fgcolor {}
                    set new_bold 0
                    set new_dim 0
                    set new_italics 0
                    set new_underline 0
                    set new_flash 0
                    set new_inverse 0
                    set new_strike 0
                }
                01  -
                1   { set new_bold 1 }
                02  -
                2   { set new_dim 1 }

                22  {
                    set new_bold 0
                    set new_dim 0
                }

                03  -
                3   { set new_italics 1 }

                23  { set new_italics 0 }

                04  -
                4   { set new_underline 1 }

                24  { set new_underline 0 }

                05  -
                5   { set new_flash 1 }

                25  { set new_flash 0 }

                07  -
                7   { set new_inverse 1 }

                27  { set new_inverse 0 }

                09  -
                9   { set new_strike 1 }

                29  { set new_strike 0 }

                30  { set new_fgcolor 0 }
                31  { set new_fgcolor 1 }
                32  { set new_fgcolor 2 }
                33  { set new_fgcolor 3 }
                34  { set new_fgcolor 4 }
                35  { set new_fgcolor 5 }
                36  { set new_fgcolor 6 }
                37  { set new_fgcolor 7 }

                39  { set new_fgcolor {} }

                40  { set new_bgcolor 0 }
                41  { set new_bgcolor 1 }
                42  { set new_bgcolor 2 }
                43  { set new_bgcolor 3 }
                44  { set new_bgcolor 4 }
                45  { set new_bgcolor 5 }
                46  { set new_bgcolor 6 }
                47  { set new_bgcolor 7 }

                49  { set new_fgcolor {} }

                -1       continue
                default  continue
            }
        }
        set new_bg "$new_bgcolor-$new_bold-$new_dim-$new_inverse"
        set old_bg "$old_bgcolor-$old_bold-$old_dim-$old_inverse"
        if {$new_bg != $old_bg} {
            if {$old_bg != "-0-0-0"} {
                set len [expr {$pos - $start_bg}]
                if {$old_inverse} {
                    set tag "fg_color"
                } else {
                    set tag "bg_color"
                }
                if {$old_bgcolor == ""} {
                    if {$old_inverse} {
                        append tag "i"
                    }
                } else {
                    append tag "$old_bgcolor"
                }
                if {$old_inverse && $old_bold} {
                    append tag "_bold"
                } elseif {$old_dim} {
                    append tag "_dim"
                }
                lappend attrs [list $start_bg $len $tag]
            }
            set old_bgcolor $new_bgcolor
            set start_bg $pos
        }
        set new_fg "$new_fgcolor-$new_bold-$new_dim-$new_inverse"
        set old_fg "$old_fgcolor-$old_bold-$old_dim-$old_inverse"
        if {$new_fg != $old_fg} {
            if {$old_fg != "-0-0-0"} {
                set len [expr {$pos - $start_fg}]
                if {$old_inverse} {
                    set tag "bg_color"
                } else {
                    set tag "fg_color"
                }
                if {$old_fgcolor == ""} {
                    if {$old_inverse} {
                        append tag "i"
                    }
                } else {
                    append tag "$old_fgcolor"
                }
                if {!$old_inverse && $old_bold} {
                    append tag "_bold"
                } elseif {$old_dim} {
                    append tag "_dim"
                }
                lappend attrs [list $start_fg $len $tag]
            }
            set old_fgcolor $new_fgcolor
            set old_dim $new_dim
            set old_inverse $new_inverse
            set start_fg $pos
        }
        if {$new_bold != $old_bold} {
            if {$old_bold != 0} {
                set len [expr {$pos - $start_bold}]
                lappend attrs [list $start_bold $len "font_bold"]
            }
            set old_bold $new_bold
            set start_bold $pos
        }
        if {$new_italics != $old_italics} {
            if {$old_italics != 0} {
                set len [expr {$pos - $start_italics}]
                lappend attrs [list $start_italics $len "font_italic"]
            }
            set old_italics $new_italics
            set start_italics $pos
        }
        if {$new_underline != $old_underline} {
            if {$old_underline != 0} {
                set len [expr {$pos - $start_underline}]
                lappend attrs [list $start_underline $len "font_underline"]
            }
            set old_underline $new_underline
            set start_underline $pos
        }
        if {$new_flash != $old_flash} {
            if {$old_flash != 0} {
                set len [expr {$pos - $start_flash}]
                lappend attrs [list $start_flash $len "font_flash"]
            }
            set old_flash $new_flash
            set start_flash $pos
        }
        if {$new_strike != $old_strike} {
            if {$old_strike != 0} {
                set len [expr {$pos - $start_strike}]
                lappend attrs [list $start_strike $len "font_strike"]
            }
            set old_strike $new_strike
            set start_strike $pos
        }
    }
    return [list $outstr $attrs]
}

proc /hilite:processline {world line {partial 0}} {
    global hilite_match_string
    global hilites
    global gag_flag
    set oldsocket [/socket:current]
    /socket:setcurrent $world
    set pline [hilite:process_ansi $line]
    set attrs [lindex $pline 1]
    if {$partial} {
        set gag_flag 0
        set hilite_match_string [lindex $pline 0]
        lappend attrs [list 0 end "__partialline__"] [list 0 end "normal"]
    } else {
        set attrs [concat $attrs [matchhilite [lindex $pline 0] $world]]
    }
    if {!$gag_flag} {
        /hilite:displayline $world $attrs $hilite_match_string $partial
    }
    /socket:setcurrent $oldsocket
    return ""
}

proc /hilite:names {{pattern *}} {
    global hilites
    set items [array names hilites]
    if {[llength $items] == 0} {
        return {}
    }
    foreach item $items {
        if {[string match "$pattern" "$item"]} {
            lappend ulist $hilites($item)
        }
    }
    set ulist [lsort -dictionary -increasing -index 0 $ulist]
    set slist [lsort -integer -decreasing -index 4 $ulist]
    foreach item $slist {
        lappend oot [lindex $item 0]
    }
    return "$oot"
}

proc hilite:calc_attr_indexes {attrvar matchtype pattern string style casesens} {
    upvar $attrvar attr
    switch -glob -- $matchtype {
        *start* {
            set plen [string length $pattern]
            lappend attr [list 0 $plen $style]
        }
        *end* {
            set slen [string length $string]
            set plen [string length $pattern]
            lappend attr [list [expr {$slen - $plen}] $plen $style]
        }
        *word* {
            set first 0
            if {!$casesens} {
                set pattern [string tolower $pattern]
                set string [string tolower $string]
            }
            regsub -all -- {[][\|\(\)\$\^\\\+\.\*\?\{\}]} $pattern {\&} pattern
            set pat "(^|\[^A-Za-z0-9\])($pattern)(\[^A-Za-z0-9\]|\$)"
            while {1} {
                set rstring [string range $string $first end]
                if {![regexp -indices -- $pat $rstring junk junk matchidx junk]} {
                    break
                }
                set rfirst [lindex $matchidx 0]
                set rlast [lindex $matchidx 1]
                incr first $rfirst
                set plen [expr {$rlast + 1 - $rfirst}]
                lappend attr [list $first $plen $style]
                incr first $plen
            }
        }
        *contain* {
            set first 0
            if {!$casesens} {
                set pattern [string tolower $pattern]
                set string [string tolower $string]
            }
            while {1} {
                set first [stringnext $pattern $string $first]
                if {$first == -1} {
                    break
                }
                set plen [string length $pattern]
                lappend attr [list $first $plen $style]
                incr first $plen
            }
        }
        *regexp* {
            set first 0
            if {!$casesens} {
                set pattern [string tolower $pattern]
                set string [string tolower $string]
            }
            while {1} {
                set rstring [string range $string $first end]
                if {![regexp -indices -- $pattern $rstring matchidx]} {
                    break
                }
                set rfirst [lindex $matchidx 0]
                set rlast [lindex $matchidx 1]
                incr first $rfirst
                set plen [expr {$rlast + 1 - $rfirst}]
                lappend attr [list $first $plen $style]
                incr first $plen
            }
        }
        *wild* {
            set first 0
            if {!$casesens} {
                set pattern [string tolower $pattern]
                set string [string tolower $string]
            }
            # Escape all regexp chars except ? * [ and ]
            # those chars are glob related.
            regsub -all -- {[\|\(\)\$\^\\\+\.]} $pattern {\&} pattern
            regsub -all -- {\*} $pattern {.*} pattern
            regsub -all -- {\?} $pattern {.} pattern
            if {![regsub -all -- {^\.\*} $pattern {^.*(} pattern]} {
                set pattern "^($pattern"
            }
            if {![regsub -all -- {\.\*$} $pattern {).*$} pattern]} {
                set pattern "$pattern)\$"
            }
            while {1} {
                set rstring [string range $string $first end]
                if {![regexp -indices -- $pattern $rstring junk matchidx]} {
                    break
                }
                set rfirst [lindex $matchidx 0]
                set rlast [lindex $matchidx 1]
                incr first $rfirst
                set plen [expr {$rlast + 1 - $rfirst}]
                lappend attr [list $first $plen $style]
                incr first $plen
            }
        }
    }
    return ""
}

proc hilite:create_match_proc {} {
    global hilite_proc_dirty
    set hilite_proc_dirty 1
}

proc hilite:update_match_proc {} {
    global hilites hilite_proc_dirty
    if {!$hilite_proc_dirty} {
        return
    }
    set hilite_proc_dirty 0

    set newproc "proc matchhilite \{textline world\} \{\n"
    append newproc "    upvar #0 hilite_match_attrs attr\n"
    append newproc "    upvar #0 hilite_match_string text\n"
    append newproc "    set text \$textline\n"
    append newproc "    global hilites\n"
    append newproc "    global url_regexp\n"
    append newproc "    global gag_flag\n"
    append newproc "    global trigger_halt\n"
    append newproc "    set gag_flag 0\n"
    append newproc "    set trigger_halt 0\n"
    append newproc "    set attr \{\}\n  \n"
    append newproc "    if \{\[regexp -nocase -- \$url_regexp \$text\]\} \{\n"
    append newproc "        hilite:calc_attr_indexes attr regexp \$url_regexp \$text url 0\n"
    append newproc "    \}\n"

    foreach item [/hilite:names] {
        if {![lindex $hilites($item) 10] || [lindex $hilites($item) 9] == "Templates"} {
            # if not enabled, or if a template, ignore this hilite
            continue
        }
        append newproc "    if \{"

        set casesens [lindex $hilites($item) 14]
        switch -glob -- [string tolower [lindex $hilites($item) 8]] {
            *glob* -
            *wildcard* {
                if {$casesens} {
                    append newproc "\[string match "
                    append newproc "[list [lindex $hilites($item) 1]] "
                    append newproc "\$text\]"
                } else {
                    append newproc "\[string match "
                    append newproc "[list [string tolower [lindex $hilites($item) 1]]] "
                    append newproc "\[string tolower \$text\]\]"
                }
            }
            *word* {
                set pattern [lindex $hilites($item) 1]
                regsub -all -- {[][\|\(\)\$\^\\\+\.\*\?\{\}]} $pattern {\&} pattern
                set pat "(^|\[^A-Za-z0-9\])($pattern)(\[^A-Za-z0-9\]|\$)"
                # set pat "^$pattern\[^A-Za-z0-9\]|\[^A-Za-z0-9\]$pattern\[^A-Za-z0-9\]|\[^A-Za-z0-9\]$pattern\$"
                if {$casesens} {
                    append newproc "\[regexp -- [list $pat] \$text\]"
                } else {
                    append newproc "\[regexp -nocase -- [list $pat] \$text\]"
                }
            }
            *regexp* -
            *match* {
                if {$casesens} {
                    append newproc "\[regexp -- "
                } else {
                    append newproc "\[regexp -nocase -- "
                }
                append newproc "[list [lindex $hilites($item) 1]] \$text\]"
            }
            contain* {
                if {$casesens} {
                    append newproc "\[string first "
                    append newproc "[list [lindex $hilites($item) 1]] "
                    append newproc "\$text\] != -1"
                } else {
                    append newproc "\[string first "
                    append newproc "[list [string tolower [lindex $hilites($item) 1]]] "
                    append newproc "\[string tolower \$text\]\] != -1"
                }
            }
            begin* -
            start* {
                if {$casesens} {
                    append newproc "\[string first "
                    append newproc "[list [lindex $hilites($item) 1]] "
                    append newproc "\$text\] == 0"
                } else {
                    append newproc "\[string first "
                    append newproc "[list [string tolower [lindex $hilites($item) 1]]] "
                    append newproc "\[string tolower \$text\]\] == 0"
                }
            }
            ending* -
            ends* {
                if {$casesens} {
                    append newproc "\[set tmp \[string last "
                    append newproc "[list [lindex $hilites($item) 1]] "
                    append newproc "\$text\]\] != -1 && \$tmp == "
                    append newproc "(\[string length \$text\] - "
                    append newproc "[string length [lindex $hilites($item) 1]])"
                } else {
                    append newproc "\[set tmp \[string last "
                    append newproc "[list [string tolower [lindex $hilites($item) 1]]] "
                    append newproc "\[string tolower \$text\]\]\] != -1 && \$tmp == "
                    append newproc "(\[string length \$text\] - "
                    append newproc "[string length [lindex $hilites($item) 1]])"
                }
            }
        }

        if {[lindex $hilites($item) 6] != 100} {
            append newproc " && (rand() * 100) <= [lindex $hilites($item) 6]"
        }

        append newproc "\} \{\n"
        set style [lindex $hilites($item) 2]
        set type [string tolower [lindex $hilites($item) 7]]
        set script [lindex $hilites($item) 3]
        set beep [lindex $hilites($item) 12]
        set tcl [lindex $hilites($item) 13]
        if {$style == "gag" && $type == "line"} {
            append newproc "    set gag_flag 1\n"
        }
        if {![lindex $hilites($item) 5]} {
            append newproc "    set trigger_halt 1\n"
        }
        if {$beep} {
            append newproc "    /bell\n"
        }
        if {$script != ""} {
            if {$tcl} {
                append newproc "    if \{\[catch \{uplevel #0 \[/line_subst \[lindex \$hilites($item) 3\] \$text\]\} errMsg\] && \$errMsg != \{\}\} \{\n"
            } else {
                append newproc "    if \{\[catch \{process_commands \[/line_subst \[lindex \$hilites($item) 3\] \$text\] \$world\} errMsg\] && \$errMsg != \{\}\} \{\n"
            }
            append newproc "        global errorInfo\n"
            append newproc "        /nonmodalerror \$world \$errorInfo\n"
            append newproc "    \}\n"
        }

        if {($style != "gag" || $type == "words") && $style != "none"} {
            switch -glob -- $type {
                "" -
                line* {
                    append newproc "    lappend attr \[list 0 \[string length \$text\] [list $style]\]\n"
                }
                word* {
                    append newproc "    hilite:calc_attr_indexes attr [list [lindex $hilites($item) 8]] [list [lindex $hilites($item) 1]] \$text [list $style] [lindex $hilites($item) 14]\n"
                }
            }
        }
        if {![lindex $hilites($item) 5] || $script != {}} {
            append newproc "    if \{\$trigger_halt\} \{\n"
            append newproc "        return \$attr\n"
            append newproc "    \}\n"
        }
        append newproc "    \}\n"
    }
    append newproc "    return \$attr\n"
    append newproc "\}"
    eval $newproc
    return ""
}

proc /hilite:add {name pattern args} {
    global hilites defpri
    global HiliteStyleBackMap

    if {$name == "" || $pattern == ""} {
        return
    }

    set preexistant [info exists hilites($name)]
    set style hilite
    set script {}
    set pri $defpri
    set fallthru 0
    set chance 100
    set type "Lines"
    set match "Matching"
    set category ""
    set enabled 1
    set template 0
    set beep 0
    set casesens 0
    set tcl 0

    while {[llength $args] > 0} {
        set arg [lindex $args 0]
        if {[string range $arg 0 0] == "-"} {
            set args [lreplace $args 0 0]
            switch -exact -- $arg {
                -s -
                -style {
                    set style [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -sc -
                -script {
                    set script [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -p -
                -pri -
                -priority {
                    set pri [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -f -
                -fallthru -
                -fallthrough {
                    set fallthru [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -c -
                -chance {
                    set chance [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -t -
                -type {
                    set type [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -b -
                -beep {
                    set beep [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -t -
                -tcl {
                    set tcl [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -temp -
                -template {
                    set template [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -en -
                -enabled {
                    set enabled [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -case -
                -casesens {
                    set casesens [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -cat -
                -category {
                    set category [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
                -m -
                -match {
                    set match [lindex $args 0]
                    set args [lreplace $args 0 0]
                }
            }
        } else {
            error "/hilite: unknown option \"$arg\""
        }
    }

    if {$template} {
        set category "Templates"
    }
    switch -glob -- [string tolower $type] {
        *word*  {set type "Words"}
        *line*  {set type "Line"}
        default {error "/hilite:add: -type should be one of 'Words' or 'Line'."}
    }
    set match [hilite:matchvalue $match]
    if {$match == ""} {
        error "/hilite:add: -match should be wildcard, regexp, word, contains, starting, or ending."
    }
    if {$match == "regexp"} {
        if {[catch {regexp -- $pattern foo} result]} {
            error "/hilite:add: Bad regular expression pattern."
        }
    }

    if {$preexistant} {
        set oldstyle [/hilite:get style $name]
        lremove HiliteStyleBackMap($oldstyle) $name
    }
    set hilites($name) [list "$name" "$pattern" "$style" "$script" "$pri" "$fallthru" "$chance" "$type" "$match" "$category" "$enabled" "$template" "$beep" "$tcl" "$casesens"]
    lappend HiliteStyleBackMap($style) $name

    hilite:create_match_proc
    if {$preexistant} {
        /hilite:notifyregistered update $name
    } else {
        /hilite:notifyregistered add $name
    }
    global dirty_preferences; set dirty_preferences 1
    return "Hilite set."
}

proc /hilite:delete {name} {
    global hilites
    global HiliteStyleBackMap

    if {[/hilite:exists $name]} {
        set oldstyle [/hilite:get style $name]
        lremove HiliteStyleBackMap($oldstyle) $name
        unset hilites($name)
        hilite:create_match_proc
        /hilite:notifyregistered delete $name
        global dirty_preferences; set dirty_preferences 1
        return "Hilite removed."
    } else {
        error "/hilite delete: No such hilite!"
    }
}


proc hilite:configstyle {hilite style} {
    foreach socket [/socket:names] {
        set disp [/display $socket]
        foreach {opt val} [styleconf $style] {
            $disp tag config $hilite $opt $val
        }
        set prev ""
        foreach h [/hilite:names] {
            if {$prev == ""} {
                $disp tag raise $h
            } else {
                $disp tag lower $h $prev
            }
        }
        $disp tag raise sel
    }
}

# WORK: /style:register this callback.
# WORK: Change /style to store styles in an array, instead of as tags in a text widget.
proc hilite:stylechange {type name} {
    global hilites defpri
    global HiliteStyleBackMap

    if {[info exists HiliteStyleBackMap($name)]} {
        foreach hilite $HiliteStyleBackMap($name) {
            hilite:configstyle $hilite $name
        }
    }
}


proc /hilite:list {{pattern *}} {
    global hilites defpri

    set oot ""
    foreach h [/hilite:names] {
        if {[string match $pattern $h]} {
            if {$oot != ""} {
                append oot "\n"
            }
            set hi "$hilites($h)"
            append oot "/hilite add [list [lindex $hi 0]] [list [lindex $hi 1]]"
            if {[lindex $hi 2] != "hilite"} {append oot " -style [list [lindex $hi 2]]"}
            if {[lindex $hi 3] != {}}       {append oot " -script [list [lindex $hi 3]]"}
            if {[lindex $hi 4] != $defpri}  {append oot " -pri [lindex $hi 4]"}
            if {[lindex $hi 5] != 0}        {append oot " -fallthru [lindex $hi 5]"}
            if {[lindex $hi 6] != 100}      {append oot " -chance [list [lindex $hi 6]]"}
            if {[lindex $hi 7] != "Lines"}  {append oot " -type [list [lindex $hi 7]]"}
            if {[lindex $hi 8] != ""}       {append oot " -match [list [lindex $hi 8]]"}
            if {[lindex $hi 9] != ""}       {append oot " -category [list [lindex $hi 9]]"}
            if {[lindex $hi 10] != 1}       {append oot " -enabled [list [lindex $hi 10]]"}
            #if {[lindex $hi 11] != 0}       {append oot " -template [list [lindex $hi 11]]"}
            if {[lindex $hi 12] != 0}       {append oot " -beep [list [lindex $hi 12]]"}
            if {[lindex $hi 13] != 0}       {append oot " -tcl [list [lindex $hi 13]]"}
            if {[lindex $hi 14] != 0}       {append oot " -casesens [list [lindex $hi 14]]"}
        }
    }
    return $oot
}

proc /hilite:exists {name} {
    global hilites
    return [info exists hilites($name)]
}

proc /hilite:notifyregistered {type name} {
    global HiliteInfo
    foreach key [array names HiliteInfo "reg,*"] {
        eval "$HiliteInfo($key) [list $type] [list $name]"
    }
    return
}

proc /hilite:register {id cmd} {
    global HiliteInfo
    if {[info exists HiliteInfo(reg,$id)]} {
        error "/hilite register: That id is already registered!"
    }
    set HiliteInfo(reg,$id) "$cmd"
    return
}

proc /hilite:deregister {id} {
    global HiliteInfo
    if {[info exists HiliteInfo(reg,$id)]} {
        unset HiliteInfo(reg,$id)
    }
    return
}

hilite:create_match_proc 

proc /hilite:widgets {opt args} {
    dispatcher /hilite:widgets $opt $args
}

proc /hilite:widgets:compare {master name} {
    global HiliteInfo
    if {![/hilite:exists $name]} { return 0 }
    if {$HiliteInfo($master,gui,pattern) != [/hilite:get pattern $name]} {return 0}
    if {$HiliteInfo($master,gui,style) != [/hilite:get style $name]} {return 0}
    if {$HiliteInfo($master,gui,script) != [/hilite:get script $name]} {return 0}
    if {$HiliteInfo($master,gui,priority) != [/hilite:get priority $name]} {return 0}
    if {$HiliteInfo($master,gui,fallthru) != [/hilite:get fallthru $name]} {return 0}
    if {$HiliteInfo($master,gui,chance) != [/hilite:get chance $name]} {return 0}
    if {$HiliteInfo($master,gui,type) != [/hilite:get type $name]} {return 0}
    if {[hilite:matchvalue $HiliteInfo($master,gui,match)] != [/hilite:get match $name]} {return 0}
    if {$HiliteInfo($master,gui,category) != [/hilite:get category $name]} {return 0}
    if {$HiliteInfo($master,gui,enabled) != [/hilite:get enabled $name]} {return 0}
    # if {$HiliteInfo($master,gui,template) != [/hilite:get template $name]} {return 0}
    if {$HiliteInfo($master,gui,beep) != [/hilite:get beep $name]} {return 0}
    if {$HiliteInfo($master,gui,tcl) != [/hilite:get tcl $name]} {return 0}
    if {$HiliteInfo($master,gui,casesens) != [/hilite:get casesens $name]} {return 0}
    return 1
}

proc /hilite:widgets:getname {master} {
    global HiliteInfo
    return $HiliteInfo($master,gui,name)
}

proc /hilite:widgets:setname {master str} {
    global HiliteInfo
    set HiliteInfo($master,gui,name) $str
    return
}

proc /hilite:widgets:validate {master} {
    global HiliteInfo
    if {$HiliteInfo($master,gui,name) == ""} {return 0}
    if {$HiliteInfo($master,gui,pattern) == ""} {return 0}
    if {$HiliteInfo($master,gui,chance) == ""} {return 0}
    if {![stringis integer $HiliteInfo($master,gui,chance)]} {return 0}
    return 1
}

proc /hilite:widgets:init {master name} {
    global HiliteInfo
    set base $master.fr
    set HiliteInfo($master,gui,name) $name
    set HiliteInfo($master,gui,pattern)  [/hilite:get pattern $name]
    set HiliteInfo($master,gui,style)    [/hilite:get style $name]
    set HiliteInfo($master,gui,script)   [/hilite:get script $name]
    set HiliteInfo($master,gui,priority) [/hilite:get priority $name]
    set HiliteInfo($master,gui,fallthru) [/hilite:get fallthru $name]
    set HiliteInfo($master,gui,chance)   [/hilite:get chance $name]
    set HiliteInfo($master,gui,type)     [/hilite:get type $name]
    set HiliteInfo($master,gui,match)    [hilite:matchtext [/hilite:get match $name]]
    set HiliteInfo($master,gui,category) [/hilite:get category $name]
    set HiliteInfo($master,gui,enabled)  [/hilite:get enabled $name]
    # set HiliteInfo($master,gui,template) [/hilite:get template $name]
    set HiliteInfo($master,gui,beep)     [/hilite:get beep $name]
    set HiliteInfo($master,gui,tcl)      [/hilite:get tcl $name]
    set HiliteInfo($master,gui,casesens) [/hilite:get casesens $name]
    /hilite:widgets:update $master
    return
}

proc /hilite:widgets:mknode {master} {
    global HiliteInfo
    set name     $HiliteInfo($master,gui,name)
    set pattern  $HiliteInfo($master,gui,pattern)
    set style    $HiliteInfo($master,gui,style)
    set script   $HiliteInfo($master,gui,script)
    set priority $HiliteInfo($master,gui,priority)
    set fallthru $HiliteInfo($master,gui,fallthru)
    set chance   $HiliteInfo($master,gui,chance)
    set type     $HiliteInfo($master,gui,type)
    set match    $HiliteInfo($master,gui,match)
    set category $HiliteInfo($master,gui,category)
    set enabled  $HiliteInfo($master,gui,enabled)
    #set template $HiliteInfo($master,gui,template)
    set beep     $HiliteInfo($master,gui,beep)
    set tcl      $HiliteInfo($master,gui,tcl)
    set casesens $HiliteInfo($master,gui,casesens)

    set    cmd "/hilite add [list $name] [list $pattern]"
    append cmd " -style [list $style]"
    append cmd " -script [list $script]"
    append cmd " -pri [list $priority]"
    append cmd " -fallthru [list $fallthru]"
    append cmd " -chance [list $chance]"
    append cmd " -type [list $type]"
    append cmd " -match [list $match]"
    append cmd " -category [list $category]"
    append cmd " -enabled [list $enabled]"
    #append cmd " -template [list $template]"
    append cmd " -beep [list $beep]"
    append cmd " -tcl [list $tcl]"
    append cmd " -casesens [list $casesens]"
    eval "$cmd"
    return
}

proc /hilite:widgets:destroy {master} {
    set hicont [$master.fr.hilite container]
    /style:deregister $hicont.style
    destroy $master.fr
}

proc /hilite:widgets:update {master} {
    global HiliteInfo treb_colors
    set base $master.fr
    # NEEDS WORK.  INCOMPLETE
    # should be used for updating when styles get changed.
    set hicont [$base.hilite container]
    set actcont [$base.script container]
    $hicont.sample config -font [/style:get font normal]
    if {[/style:get foreground normal] != ""} {
        $hicont.sample config -foreground [/style:get foreground normal]
    }
    if {[/style:get background normal] != ""} {
        $hicont.sample config -background [/style:get background normal]
    }

    set style $HiliteInfo($master,gui,style)
    set type $HiliteInfo($master,gui,type)
    if {$style == "" || $style == "none"} {
        $hicont.sample tag configure word -font [/style:get font normal]
        $hicont.sample tag configure word -foreground [/style:get foreground normal]
        $hicont.sample tag configure word -background [/style:get background normal]
        $hicont.sample tag configure word -elide 0
        $hicont.sample tag configure line -font [/style:get font normal]
        $hicont.sample tag configure line -foreground [/style:get foreground normal]
        $hicont.sample tag configure line -background [/style:get background normal]
        $hicont.sample tag configure line -elide 0
    } elseif {$style == "gag"} {
        $hicont.sample tag configure word -elide 1
        if {[string match "*word*" [string tolower $type]]} {
            $hicont.sample tag configure line -font [/style:get font normal]
            $hicont.sample tag configure line -foreground [/style:get foreground normal]
            $hicont.sample tag configure line -background [/style:get background normal]
            $hicont.sample tag configure line -elide 0
        } else {
            $hicont.sample tag configure line -elide 1
        }
    } else {
        $hicont.sample tag configure word -font [/style:get font $style]
        $hicont.sample tag configure word -foreground [/style:get foreground $style]
        $hicont.sample tag configure word -background [/style:get background $style]
        $hicont.sample tag configure word -elide 0
        $hicont.sample tag configure line -elide 0
        if {[string match "*word*" [string tolower $type]]} {
            $hicont.sample tag configure line -font [/style:get font normal]
            $hicont.sample tag configure line -foreground [/style:get foreground normal]
            $hicont.sample tag configure line -background [/style:get background normal]
        } else {
            $hicont.sample tag configure line -font [/style:get font $style]
            $hicont.sample tag configure line -foreground [/style:get foreground $style]
            $hicont.sample tag configure line -background [/style:get background $style]
        }
        $hicont.sample tag raise word
    }
    if {$HiliteInfo($master,gui,script) == ""} {
        $actcont.editbtn config -text "Set script..."
    } else {
        $actcont.editbtn config -text "Edit script..."
    }
    return
}


proc hilite:widget:stylechange {master changetype changedstyle} {
    set hicont [$master.fr.hilite container]
    $hicont.style entrydelete 0 end
    foreach style [/style:names] {
        $hicont.style entryinsert end $style
    }
    /hilite:widgets:update $master
}


proc /hilite:widgets:create {master script} {
    global HiliteInfo
    set base $master.fr
    set updatescript "/hilite:widgets:update $master; $script"
    
    set HiliteInfo($master,gui,name)     ""
    set HiliteInfo($master,gui,pattern)  ""
    set HiliteInfo($master,gui,style)    "hilite"
    set HiliteInfo($master,gui,script)   ""
    set HiliteInfo($master,gui,priority) 0
    set HiliteInfo($master,gui,fallthru) 0
    set HiliteInfo($master,gui,chance)   100
    set HiliteInfo($master,gui,type)     "Lines"
    set HiliteInfo($master,gui,match)    "Wildcard"
    set HiliteInfo($master,gui,category) ""
    set HiliteInfo($master,gui,enabled)  1
    set HiliteInfo($master,gui,template) 0
    set HiliteInfo($master,gui,beep)     0
    set HiliteInfo($master,gui,tcl)      0
    set HiliteInfo($master,gui,casesens) 0

    frame $base -relief flat -borderwidth 0

    set namecont [groupbox $base.name -text "Name"]
        entry $namecont.name -textvariable HiliteInfo($master,gui,name) -width 20
        bind $namecont.name <Key> "+$updatescript"
        label $namecont.catlbl -text "Category" -anchor w
        combobox $namecont.category -changecommand "$updatescript" \
            -width 20 -textvariable HiliteInfo($master,gui,category)
        set cats {Templates}
        foreach hname [/hilite:names] {
            set thiscat [/hilite:get category $hname]
            if {$thiscat != "" && [lsearch -exact $cats $thiscat] == -1} {
                lappend cats $thiscat
            }
        }
        foreach thiscat $cats {
            $namecont.category entryinsert end $thiscat
        }
        unset thiscat
        unset cats
		set HiliteInfo($master,gui,category) ""

    set matchcont [groupbox $base.match -text "Matching"]
        label $matchcont.matchlbl -text "Type" -anchor w
        combobox $matchcont.match -editable 0 -width 17 \
                -textvariable HiliteInfo($master,gui,match) \
                -changecommand "$updatescript"
            foreach val $HiliteInfo(matchvalues) {
                $matchcont.match entryinsert end [lindex $val 1]
            }
        label $matchcont.chancelbl -text "%Chance" -anchor e
        spinner $matchcont.chance -width 3 -min 0 -max 100 -val 100 \
            -command "$updatescript" \
            -variable HiliteInfo($master,gui,chance)
        label $matchcont.patlbl -text "Pattern" -anchor w
        entry $matchcont.pattern -textvariable HiliteInfo($master,gui,pattern)
        bind $matchcont.pattern <Key> "+$updatescript"
        checkbutton $matchcont.casesens -text "Case sensitive" \
            -onvalue 1 -offvalue 0 -variable HiliteInfo($master,gui,casesens) \
            -command "$updatescript"
        checkbutton $matchcont.enabled -text "Enabled" \
            -onvalue 1 -offvalue 0 -variable HiliteInfo($master,gui,enabled) \
            -command "$updatescript"
        label $matchcont.prilbl -text "Priority"
        spinner $matchcont.priority -width 4 -min 0 -max 9999 -val 100 \
            -command "$updatescript" \
            -variable HiliteInfo($master,gui,priority)
        checkbutton $matchcont.fallthru -text "Check remaining hilites" \
            -onvalue 1 -offvalue 0 -variable HiliteInfo($master,gui,fallthru) \
            -command "$updatescript"

    set hicont [groupbox $base.hilite -text "Highlight"]
        label $hicont.stylelbl -text "Apply style" -anchor w
        combobox $hicont.style -editable 0 -width 16 \
                -textvariable HiliteInfo($master,gui,style) \
                -changecommand "$updatescript"
            set styles [/style:names]
            set spos [lsearch -exact $styles "none"]
            if {$spos != -1} {
                set styles [lreplace $styles $spos $spos]
            }
            set spos [lsearch -exact $styles "gag"]
            if {$spos != -1} {
                set styles [lreplace $styles $spos $spos]
            }
            foreach style [concat "none" "gag" [/style:names]] {
                $hicont.style entryinsert end "$style"
            }
        /style:register $hicont.style "hilite:widget:stylechange $master"
        checkbutton $hicont.type -text "Only to matched words" \
            -variable HiliteInfo($master,gui,type) -onval Words -offval Line \
            -command "$updatescript"
        text $hicont.sample -width 15 -height 2 -takefocus 0 -wrap none
            $hicont.sample insert end "The quick brown fox jumps over the lazy dog."
            $hicont.sample tag add line "1.0" "end"
            $hicont.sample tag add word "1.5 wordstart" "1.17 wordend"
        button $hicont.editbtn -text "Edit styles..." -command {
            /editdlog Styles Style /style
        } -width 10
    
    set actcont [groupbox $base.script -text "Actions"]
        checkbutton $actcont.beep -text "Beep" -command "$updatescript" \
            -variable HiliteInfo($master,gui,beep)
        checkbutton $actcont.tcl -text "Script is TCL" \
            -command "$updatescript" -variable HiliteInfo($master,gui,tcl)
        button $actcont.editbtn -text "Edit script..." -width 10 \
            -command "
                /textdlog -modal -buttons -title \"Edit script\" \
                    -width 60 -height 12 -nowrap -autoindent -mode tcl \
                    -text \$HiliteInfo($master,gui,script) \
                    -variable HiliteInfo($master,gui,script)
                $updatescript
            "

    /hilite:widgets:update $master

    ###################
    # SETTING GEOMETRY
    ###################
    grid $base.name -column 0 -row 0 -padx 10 -pady 10  -sticky nesw 
        grid rowconfig $namecont 0 -minsize 10
        grid columnconfig $namecont 0 -minsize 10
        grid $namecont.name -column 1 -row 1 -sticky w
        grid columnconfig $namecont 2 -minsize 20
        grid $namecont.catlbl -column 3 -row 1 -sticky w
        grid columnconfig $namecont 4 -minsize 10
        grid $namecont.category -column 5 -row 1 -sticky w
        grid columnconfig $namecont 6 -minsize 10 -weight 1
        grid rowconfig $namecont 2 -minsize 10

    grid $base.match -column 0 -row 1 -padx 10 -pady 2 -sticky nesw 

        set bm $matchcont
        grid rowconfig $bm 0 -minsize 10
        grid rowconfig $bm 2 -minsize 8
        grid rowconfig $bm 4 -minsize 6
        grid rowconfig $bm 6 -minsize 6

        grid columnconfig $bm 0 -minsize 8
        grid columnconfig $bm 2 -minsize 10
        grid columnconfig $bm 4 -minsize 20
        grid columnconfig $bm 6 -minsize 5
        grid columnconfig $bm 8 -weight 1 -minsize 20
        grid columnconfig $bm 10 -minsize 10
        grid columnconfig $bm 12 -minsize 5
        grid columnconfig $bm 14 -minsize 10

        grid x $bm.matchlbl x $bm.match   - -          - -            x x            x $bm.chancelbl x $bm.chance -sticky e -row 1
        grid x $bm.patlbl   x $bm.pattern - -          - -            - -            - $bm.casesens  - -          -sticky e -row 3
        grid x $bm.enabled  - -           x $bm.prilbl x $bm.priority x $bm.fallthru - -             - -          -sticky e -row 5
        grid $bm.pattern $bm.match $bm.chance -sticky ew
        grid $bm.enabled $bm.fallthru -sticky w


    grid $base.hilite -column 0 -row 2 -padx 10 -pady 10 -sticky nesw 

        set bh $hicont
        for {set i 0} {$i <= 2} {incr i} {
            grid rowconfig $bh [expr {$i * 2}] -minsize 10
        }
        grid columnconfig $bh 0 -minsize 10
        grid columnconfig $bh 2 -minsize 10
        grid columnconfig $bh 4 -minsize 20
        grid columnconfig $bh 5 -weight 1
        grid columnconfig $bh 6 -minsize 10
        grid columnconfig $bh 8 -minsize 10

        grid x $bh.stylelbl x $bh.style x $bh.type - -           -row 1 -sticky e
        grid x $bh.sample   - -         - -        x $bh.editbtn -row 3 -sticky ew
        grid $bh.style  -sticky ew
        grid $bh.type   -sticky w
        grid $bh.sample -sticky nsew


    grid $base.script -column 0 -row 3 -padx 10 -pady 2 -sticky nesw 
        grid columnconfig $actcont 0 -minsize 10
        grid columnconfig $actcont 2 -minsize 20
        grid columnconfig $actcont 3 -weight 1
        grid columnconfig $actcont 4 -minsize 20
        grid columnconfig $actcont 6 -minsize 10
        grid rowconfig $actcont 0 -minsize 10
        grid rowconfig $actcont 1 -weight 0
        grid rowconfig $actcont 2 -minsize 10
        grid $actcont.beep    -row 1 -column 1 -sticky w
        grid $actcont.tcl     -row 1 -column 3 -sticky w
        grid $actcont.editbtn -row 1 -column 5 -sticky w

    grid rowconf $base 4 -minsize 10 -weight 1

    pack $base -fill both -expand 1
    return
}

