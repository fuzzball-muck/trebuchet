########################################################################
# MPI reformatting and compaction
########################################################################

proc textmods:get_range {w} {
    if {[$w tag ranges sel] != {}} {
        set spos [$w index sel.first]
        set epos [$w index sel.last]
    } else {
        set spos [$w index "insert linestart"]
        set epos [$w index "insert lineend"]
    }
    return [list $spos $epos]
}


proc textmods:mpi_compact_text {txt} {
    set out {}
    foreach line [split $txt "\n"] {
        append out [string trimleft $line]
    }
    return $out
}


proc textmods:getColorChromaDiff {color1 color2} {
    set rgb1 [winfo rgb . $color1]
    set rval1 [expr {[lindex $rgb1 0]/65535.0}]
    set gval1 [expr {[lindex $rgb1 1]/65535.0}]
    set bval1 [expr {[lindex $rgb1 2]/65535.0}]

    set rgb2 [winfo rgb . $color2]
    set rval2 [expr {[lindex $rgb2 0]/65535.0}]
    set gval2 [expr {[lindex $rgb2 1]/65535.0}]
    set bval2 [expr {[lindex $rgb2 2]/65535.0}]

    return [expr {(abs($rval1-$rval2)*0.3)+(abs($gval1-$gval2)*0.59)+(abs($bval1-$bval2)*0.11)}]
}


proc textmods:get_contrasted_color {w colors} {
    set fgcolor [$w cget -foreground]
    set bgcolor [$w cget -background]
    set bestcolor ""
    set bestdiff 0.0
    foreach color $colors {
        set fgdiff [textmods:getColorChromaDiff $color $fgcolor]
        set bgdiff [textmods:getColorChromaDiff $color $bgcolor]
        if {$bgdiff > $bestdiff && $fgdiff > 0.2} {
            set bestcolor $color
            set bestdiff $bgdiff
        }
    }
    return $bestcolor
}


proc textmods:mpi_reformat_text {txt} {
    set lev 0
    set breaksinceopen 0
    set inquote 0
    set out {}
    while {[regexp -nocase -- {^([^{}`\\]*)([{}`\\])(.*)} $txt dummy pre ch post]} {
        append out $pre
        switch -exact $ch {
            "\\" {
                append out $ch
                append out [string index $post 0]
                set post [string range $post 1 end]
            }
            "`" {
                if {$inquote} {
                    set inquote 0
                } else {
                    set inquote 1
                }
                append out "`"
            }
            "{" {
                if {$inquote} {
                    append out "\{"
                } elseif {![regexp -nocase -- {^(&?[^{:}]*)([{:}])(.*)} $post dummy cmd div post2]} {
                    append out "\{"
                } elseif {[string index $cmd 0] == "&" && $div == "\}"} {
                    append out "\{$cmd$div"
                    set post $post2
                } else {
                    if {$out != ""} {
                        append out "\n"
                    }
                    for {set i 0} {$i < $lev} {incr i} {
                        append out "    "
                    }
                    append out "\{$cmd$div"
                    incr lev
                    switch -exact $div {
                        "{" {
                            set post $post2
                            set breaksinceopen 0
                        }
                        ":" {
                            set post $post2
                            set breaksinceopen 0
                        }
                        "}" {
                            set post $post2
                            incr lev -1
                        }
                    }
                }
            }
            "}" {
                if {$inquote} {
                    append out "\}"
                } else {
                    incr lev -1
                    if {$breaksinceopen} {
                        if {$out != ""} {
                            append out "\n"
                        }
                        for {set i 0} {$i < $lev} {incr i} {
                            append out "    "
                        }
                    }
                    set breaksinceopen 1
                    append out "\}"
                }
            }
        }
        if {$lev < 0} {
            set lev 0
        }
        set txt $post
    }
    return $out
}


proc textmods:mpi_compact {w} {
    foreach {spos epos} [textmods:get_range $w] break
    set txt [$w get $spos $epos]
    set txt [textmods:mpi_compact_text $txt]
    $w delete $spos $epos
    $w insert $spos $txt sel
    return
}


proc textmods:mpi_reformat {w} {
    foreach {spos epos} [textmods:get_range $w] break
    set txt [$w get $spos $epos]
    set txt [textmods:mpi_compact_text $txt]
    set txt [textmods:mpi_reformat_text $txt]
    $w delete $spos $epos
    $w insert $spos $txt sel
    return
}


########################################################################
# Fix for going up a visual line in Text widgets
########################################################################

proc gdm:TextUpDownSingleLine {w n} {
    if {[info exists tk::Priv]} {
        upvar #0 tk::Priv priv
    } else {
        upvar #0 tkPriv priv
    }

    $w see insert
    set i [$w index insert]
    set ibox [$w bbox insert]
    set curx [lindex $ibox 0]
    set cury [lindex $ibox 1]
    set oldy $cury
    set curh [lindex $ibox 3]
    set yslop [expr {[$w cget -borderwidth] + [$w cget -highlightthickness] + [$w cget -pady]}]
    if {$n > 0} {
        set xslop [expr {[$w cget -borderwidth] + [$w cget -padx]}]
        set winw [expr {[winfo width $w] - $xslop}]
        set winh [expr {[winfo height $w] - $yslop}]
        if {$cury + $curh >= $winh && [$w compare @$winw,$winh != end-1c]} {
            $w yview scroll 1 units
        } else {
            incr cury $curh
        }
    } elseif {$n < 0} {
        if {$cury - 1 <= $yslop && [$w compare @0,0 != 1.0]} {
            $w yview scroll -1 units
        } else {
            incr cury -1
        }
    }
    scan $i "%d.%d" line char
    if {[string compare $priv(prevPos) $i] != 0} {
        set priv(char) $char
    }
    set new [$w index @$curx,$cury]
    set priv(prevPos) $new
    return $new
}

proc tkTextUpDownLine {w n} {
    set step [expr {abs($n)}]
    if {$n > 0} {
        for {set i $n} {$i > 0} {incr i -1} {
            set new [gdm:TextUpDownSingleLine $w 1]
        }
    } else {
        for {set i $n} {$i < 0} {incr i 1} {
            set new [gdm:TextUpDownSingleLine $w -1]
        }
    }
    return $new
}

if {[string first "::tk" [namespace children]] >= 0} {
    namespace eval ::tk {
        proc TextUpDownLine {w n} {
            tkTextUpDownLine $w $n
        }
    }
}


########################################################################
# Brace matching
########################################################################

proc textmods:match_clear {w} {
    if {![winfo exists $w]} {
        return
    }
    if {[catch {$w tag delete __MBR_Match __MBR_Error __MBR_Quoted}]} {
        $w tag remove __MBR_Match 1.0 end
        $w tag remove __MBR_Error 1.0 end
        $w tag remove __MBR_Quoted 1.0 end
    }
    return
}


proc textmods:schedule_match_clear {w} {
    after cancel textmods:match_clear $w
    after 4000 textmods:match_clear $w
}


proc textmods:set_match_mode {w mode} {
    global TextModsInfo
    set TextModsInfo(mode,$w) $mode
}


proc textmods:match_braces {w {matchpos insert}} {
    global TextModsInfo

    if {![winfo exists $w]} {
        return
    }

    if {[info exists TextModsInfo(mode,$w)]} {
        set mode $TextModsInfo(mode,$w)
    } else {
        set mode "none"
    }
    switch -exact -- $mode {
        "generic" -
        "c"   -
        "tcl" -
        "mpi" -
        "muf" { }
        "none" -
        default {
            textmods:schedule_match_clear $w
            return
        }
    }

    set matchchars {}
    set quotechars {}
    set escapechars {
        \\ backslash
    }

    if {$mode == "muf"} {
        set matchchars {
            \[ \] brace
            \{ \} brace
            (  ) brace
        }
        set quotechars {
            \" dquotes
        }
    } elseif {$mode == "mpi"} {
        set matchchars {
            \{ \} brace
        }
        set quotechars {
            ` ticks
        }
    } elseif {$mode == "c"} {
        set matchchars {
            \{ \} brace
            (  ) brace
        }
        set quotechars {
            \" dquotes
            ' squotes
        }
    } elseif {$mode == "tcl"} {
        set matchchars {
            \[ \] brace
            \{ \} brace
            (  ) brace
        }
        set quotechars {
            \" ticks
        }
    } elseif {$mode == "generic"} {
        set matchchars {
            \[ \] brace
            \{ \} brace
            (  ) brace
        }
        set quotechars {
            \" dquotes
            ` ticks
        }
    }

    foreach {startchar endchar name} $matchchars {
        set grouptype($name) pair
        set chargroup($startchar) $name
        set chargroup($endchar) $name
        set charval($startchar) 1
        set charval($endchar) -1
        switch -exact -- $startchar {
            "(" { append pairpattern "\\$endchar\\$startchar" }
            default { append pairpattern "$endchar$startchar" }
        }
    }
    foreach {char name} $quotechars {
        set grouptype($name) quote
        set chargroup($char) $name
        append quotepattern "$char"
    }
    foreach {char name} $escapechars {
        set grouptype($name) escape
        set chargroup($char) $name
        append escapepattern "\\$char"
    }

    set errors {}
    set stack {}
    set matches {}
    set allpattern "\[$pairpattern$quotepattern$escapepattern\]"
    set inquote 0

    set curr 1.0

    while {1} {
        set next [$w search -forwards -regexp -- "$allpattern" $curr end]
        if {$next == {} || [$w compare $next >= end] || [$w compare $next < $curr]} {
            set curr end
            break
        }
        set char [$w get $next]
        set group $chargroup($char)
        set type $grouptype($group)
        if {$type == "escape"} {
            set curr [$w index $next+2c]
            continue
        } elseif {$type == "quote"} {
            if {!$inquote} {
                set inquote 1
                lappend stack [list $group $next]
            } else {
                set top [lindex $stack end]
                if {$group == [lindex $top 0]} {
                    set inquote 0
                    set slen [llength $stack]
                    set stack [lrange $stack 0 [expr {$slen - 2}]]
                    lappend top [$w index $next+1c]
                    lappend matches $top
                } else {
                    set curr [$w index $next+1c]
                    continue
                }
            }
        } elseif {!$inquote} {
            set val $charval($char)
            if {$val > 0} {
                lappend stack [list $group $next]
            } else {
                if {[llength $stack] == 0} {
                    lappend errors $next
                } else {
                    set top [lindex $stack end]
                    if {[lindex $top 0] != $group} {
                        lappend errors $next
                    } else {
                        set slen [llength $stack]
                        set stack [lrange $stack 0 [expr {$slen - 2}]]
                        lappend top [$w index $next+1c]
                        lappend matches $top
                    }
                }
            }
        }
        set curr [$w index $next+1c]
    }

    set found 0
    set start 1.0
    set end end
    foreach match $matches {
        set first [lindex $match 1]
        set last [lindex $match 2]
        if {[$w compare $matchpos > $first] && [$w compare $first >= $start]} {
            if {[$w compare $matchpos < $last] && [$w compare $last < $end]} {
                set start $first
                set end $last
                set found 1
            }
        }
    }

    if {!$found} {
        set start end
        set end end
    }
    foreach level $stack {
        set first [lindex $level 1]
        lappend errors $first
        if {[$w compare $matchpos > $first] && [$w compare $first >= $start]} {
            set found 1
            set start $first
        }
    }

    textmods:match_clear $w
    foreach err $errors {
        $w tag add __MBR_Error $err
    }
    if {[$w compare $start < $end]} {
        foreach match $matches {
            set group [lindex $match 0]
            set first [lindex $match 1]
            set last [lindex $match 2]
            if {$grouptype($group) == "quote"} {
                if {[$w compare $first >= $start] && [$w compare $last <= $end]} {
                    $w tag add __MBR_Quoted $first $last
                }
            }
        }
        $w tag add __MBR_Match $start $end
    }


    set matchcolor [textmods:get_contrasted_color $w {green #003f00 #007f00 #00bf00 #00ff00}]
    set quotecolor [textmods:get_contrasted_color $w {brown #3f3f00 #7f7f00 #bfbf00 #ffff00}]

    $w tag configure __MBR_Error -foreground black -background #ff0000
    $w tag configure __MBR_Match -foreground $matchcolor -relief solid -borderwidth 1
    $w tag configure __MBR_Quoted -foreground $quotecolor

    $w tag raise __MBR_Match
    $w tag raise __MBR_Quoted
    $w tag raise __MBR_Error
    $w tag raise sel

    textmods:schedule_match_clear $w
}


proc textmods:match_braces_if_short {w {offset 0}} {
    if {[$w index "end-1c"] < 400.0} {
        if {$offset >= 0} {
            set pos "insert+${offset}c"
        } else {
            set pos "insert${offset}c"
        }
        textmods:match_braces $w $pos
    }
}


proc textmods:cleanup {w} {
    global TextModsInfo
    catch {unset TextModsInfo(mode,$w)}
    catch {unset TextModsInfo(clearmatchpid,$w)}
}


proc textmods:shift_indent {chars w} {
    if {[catch {
        set first [$w index "sel.first linestart"]
        set last [$w index "sel.last lineend"]
    }]} {
        set first [$w index "insert linestart"]
        set last [$w index "insert lineend"]
    }
    set curr $first
    while {[$w compare $curr < $last]} {
        set line [$w get $curr "$curr lineend"]
        regexp {^[ 	]*} $line whitespace
        set count [string length $whitespace]
        regsub -all -- {	} $whitespace {        } whitespace
        if {$chars < 0} {
            set whitespace [string range $whitespace [expr {abs($chars)}] end]
        } else {
            for {set i 0} {$i < $chars} {incr i} {
                append whitespace " "
            }
        }
        $w delete $curr "$curr+${count}c"
        $w insert $curr $whitespace
        set oldcurr $curr
        set curr [$w index "$curr+1lines"]
        if {[$w compare $oldcurr == $curr]} {
            break
        }
    }
    $w tag add sel $first $last
    return
}


proc textmods:init {} {
    bind Text <Control-Key-m> "+after idle textmods:match_braces %W"

    set cmd "after idle textmods:match_braces_if_short %W -1;"
    append cmd [bind Text <Key>]
    bind Text <Key> $cmd

    bind Text <Key-BackSpace> "+after idle textmods:match_braces_if_short %W -1"

    bind Text <<Cut>> "+after idle textmods:match_braces_if_short %W"
    bind Text <<Paste>> "+after idle textmods:match_braces_if_short %W -1"
    bind Text <<PasteAt>> "+after idle textmods:match_braces_if_short %W -1"

    bind Text <Destroy> "+textmods:cleanup %W"

    bind Text <Key-Escape><Key-m> "textmods:mpi_reformat %W"
    bind Text <Key-Escape><Key-k> "textmods:mpi_compact %W"

    bind Text <Control-Key-less>  "textmods:shift_indent -4 %W"
    bind Text <Control-Key-greater> "textmods:shift_indent 4 %W"
}


if {0} {
    text .t1 -width 80 -height 10 -background black -foreground #bfbfbf -insertbackground white
    text .t2 -width 80 -height 10
    pack .t1
    pack .t2
    textmods:set_match_mode .t1 mpi
    textmods:set_match_mode .t2 mpi
}


