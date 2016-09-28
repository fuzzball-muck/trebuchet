proc /style {opt args} {
    dispatcher /style $opt $args
}

proc /style:edit {{item ""}} {
    if {$item == ""} {
        /editdlog Styles Style /style
    } else {
        /newdlog Style /style $item
    }
}

proc /style:get {opt name} {
    return [[/display] tag cget $name -$opt]
}

proc /style:names {{pattern *}} {
    global styleslist
    set oot {}
    foreach style $styleslist {
        if {[lindex $style 0] != "gag"} {
            lappend oot [lindex $style 0]
        }
    }
    set tmplist [lsort -dictionary $oot]
    set tmplist [lrottostart $tmplist [lsearch -exact $tmplist url]]
    set tmplist [lrottostart $tmplist [lsearch -exact $tmplist results]]
    set tmplist [lrottostart $tmplist [lsearch -exact $tmplist error]]
    set tmplist [lrottostart $tmplist [lsearch -exact $tmplist hilite]]
    set tmplist [lrottostart $tmplist [lsearch -exact $tmplist normal]]
    while {[llength $tmplist] > 0 && [lindex $tmplist 0] == {}} {
        set tmplist [lreplace $tmplist 0 0]
    }
    return $tmplist
}

proc /style:resizeall {percent} {
    foreach style [/style:names] {
        if {$style != "none"} {
            set oldfont [/style:get font $style]
            if {$oldfont != ""} {
                array set tmp_font [font actual $oldfont]
                set oldsize $tmp_font(-size)
                if {$percent < 0} {
                    set newsize [expr {int(($oldsize / ((100.0 - $percent) / 100.0)) + 0.5)}]
                } else {
                    set newsize [expr {int(($oldsize * ((100.0 + $percent) / 100.0)) + 0.5)}]
                }
                if {$newsize == $oldsize} {
                    if {$percent < 0} {
                        incr newsize -1
                    } else {
                        incr newsize 1
                    }
                }
                set tmp_font(-size) $newsize
                set newfont [array get tmp_font]
                /style:add $style -font $newfont
            }
        }
    }
}

proc /style:menu {opt args} {
    dispatcher /style:menu $opt $args
}

proc /style:menu:add {style label script args} {
    global dirty_preferences; set dirty_preferences 1
    if {[llength $args] > 1} {
        # If broken prefsfile has worldname, eat it, and clear statescript.
        set statescript ""
    } else {
        set statescript [lindex $args 0]
    }
    foreach socket [concat [list ""] [/socket:names]] {
        set scr "process_commands [list $script] \[/socket:foreground\]"
        textPopup:addentry [/display $socket] $style $label $scr $statescript
    }
    return
}

proc /style:menu:delete {style label} {
    foreach socket [/socket:names] {
        textPopup:delentry [/display $socket] $style $label
    }
    global dirty_preferences; set dirty_preferences 1
    return
}

proc /style:menu:names {style} {
    return [textPopup:names [/display ""] $style]
}

proc /style:menu:exists {style label} {
    return [textPopup:exists [/display ""] $style $label]
}

proc /style:menu:list {style {pattern "*"}} {
    set wname [/display]
    set oot ""
    foreach label [/style:menu:names $style] {
        if {$oot != ""} {
            append oot "\n"
        }
        set script [textPopup:getscript $wname $style $label]
        set script [lindex $script 1]
        set state [textPopup:getstatescript $wname $style $label]
        append oot "/style menu add [list $style] [list $label] [list $script]"
        if {$state != ""} {
            append oot " [list $state]"
        }
    }
    return $oot
}

proc style:ansi_update {w} {
    global treb_fonts

    catch {
        set normfg [[/display ""] tag cget normal -foreground]
    }
    if {$normfg == ""} {
        set normfg #000
    }

    catch {
        set normbg [[/display ""] tag cget normal -background]
    }
    if {$normbg == ""} {
        set normbg #CCC
    }

    $w tag configure bg_color -background $normbg
    $w tag configure bg_colori -background $normfg
    $w tag configure bg_color0 -background #000
    $w tag configure bg_color1 -background #C00
    $w tag configure bg_color2 -background #0C0
    $w tag configure bg_color3 -background #CC0
    $w tag configure bg_color4 -background #00C
    $w tag configure bg_color5 -background #C0C
    $w tag configure bg_color6 -background #0CC
    $w tag configure bg_color7 -background #DDD

    $w tag configure bg_color_dim -background $normbg
    $w tag configure bg_colori_dim -background $normfg
    $w tag configure bg_color0_dim -background #333
    $w tag configure bg_color1_dim -background #700
    $w tag configure bg_color2_dim -background #070
    $w tag configure bg_color3_dim -background #770
    $w tag configure bg_color4_dim -background #007
    $w tag configure bg_color5_dim -background #707
    $w tag configure bg_color6_dim -background #077
    $w tag configure bg_color7_dim -background #999

    $w tag configure fg_color -foreground $normfg
    $w tag configure fg_colori -foreground $normbg
    $w tag configure fg_color0 -foreground #222
    $w tag configure fg_color1 -foreground #F33
    $w tag configure fg_color2 -foreground #0E0
    $w tag configure fg_color3 -foreground #FF0
    $w tag configure fg_color4 -foreground #33F
    $w tag configure fg_color5 -foreground #F3F
    $w tag configure fg_color6 -foreground #3FF
    $w tag configure fg_color7 -foreground #FFF

    $w tag configure fg_color_dim -foreground #777
    $w tag configure fg_colori_dim -foreground $normbg
    $w tag configure fg_color0_dim -foreground #555
    $w tag configure fg_color1_dim -foreground #A00
    $w tag configure fg_color2_dim -foreground #0A0
    $w tag configure fg_color3_dim -foreground #AA0
    $w tag configure fg_color4_dim -foreground #00A
    $w tag configure fg_color5_dim -foreground #A0A
    $w tag configure fg_color6_dim -foreground #0AA
    $w tag configure fg_color7_dim -foreground #AAA

    $w tag configure fg_color_bold -foreground $normfg
    $w tag configure fg_colori_bold -foreground $normbg
    $w tag configure fg_color0_bold -foreground #777
    $w tag configure fg_color1_bold -foreground #F77
    $w tag configure fg_color2_bold -foreground #6E6
    $w tag configure fg_color3_bold -foreground #FF7
    $w tag configure fg_color4_bold -foreground #66F
    $w tag configure fg_color5_bold -foreground #F7F
    $w tag configure fg_color6_bold -foreground #6FF
    $w tag configure fg_color7_bold -foreground #FFF

    catch {
        set normfont [[/display ""] tag cget normal -font]
    }
    if {$normfont == ""} {
        set normfont $treb_fonts(fixed)
    }
    array set bold_font [font actual $normfont]
    set bold_font(-weight) bold
    $w tag configure font_bold -font [array get bold_font]

    array set ital_font [font actual $normfont]
    set ital_font(-slant) italic
    $w tag configure font_italic -font [array get ital_font]

    $w tag configure font_underline -underline 1
    $w tag configure font_flash -foreground {} -background {}
    $w tag configure font_strike -overstrike 1
}


proc style:ansi_raise {wname {raiseabove ""}} {
    foreach attr [list "bold" "italic" "underline" "strike"] {
        if {$raiseabove != ""} {
            $wname tag raise "font_$attr" $raiseabove
        } else {
            $wname tag raise "font_$attr"
        }
    }
    foreach suffix [list {} "_dim" "_bold"] {
        $wname tag raise "fg_color$suffix" normal
    }
    foreach suffix [list {} "_dim"] {
        $wname tag raise "bg_color$suffix" normal
    }
    foreach clr [list "i" 0 1 2 3 4 5 6 7] {
        foreach suffix [list {} "_dim" "_bold"] {
            if {$raiseabove != ""} {
                $wname tag raise "fg_color$clr$suffix" $raiseabove
            } else {
                $wname tag raise "fg_color$clr$suffix"
            }
        }
        foreach suffix [list {} "_dim"] {
            if {$raiseabove != ""} {
                $wname tag raise "bg_color$clr$suffix" $raiseabove
            } else {
                $wname tag raise "bg_color$clr$suffix"
            }
        }
    }
    if {$raiseabove != ""} {
        $wname tag raise "font_flash" $raiseabove
    } else {
        $wname tag raise "font_flash"
    }
    catch {$wname tag raise sel}
}

proc style:ansi_flash {wname} {
    set currfg [$wname tag cget font_flash -background]
    if {$currfg != {}} {
        $wname tag configure font_flash -foreground {} -background {}
    } else {
        if {[/prefs:get ansi_flash_enable]} {
            set bgcolor [$wname tag cget normal -background]
            if {$bgcolor == {}} {
                set bgcolor [$wname cget -background]
            }
            $wname tag configure font_flash -foreground $bgcolor -background $bgcolor
        }
    }
}

proc style:ansi_fix {wname} {
    if {[/prefs:get ansi_over_styles]} {
        style:ansi_raise $wname
    } else {
        style:ansi_raise $wname normal
    }
    style:ansi_update $wname
}

proc style:ansi_fix_all {} {
    foreach socket [concat "" [/socket:names]] {
        set disp [/display $socket]
        style:ansi_fix $disp
    }
}

proc styleconf {tagname} {
    set oot {}
    foreach i [[/display ""] tag configure $tagname] {
        if {[lindex $i 4] != {}} {
            set oot [concat $oot [lindex $i 0] [list [lindex $i 4]]]
        }
    }
    return $oot
}

proc /style:initdisplay {wname} {
    global widget styleslist
    foreach style $styleslist {
        set name [lindex $style 0]
        foreach option [lrange $style 1 end] {
            set opt [lindex $option 0]
            set val [lindex $option 1]
            $wname tag configure $name $opt $val
        }
        foreach label [/style:menu:names $name] {
            set script [textPopup:getscript [/display ""] $name $label]
            set state [textPopup:getstatescript [/display ""] $name $label]
            textPopup:addentry $wname $name $label $script $state
        }
    }
    foreach label [/style:menu:names sel] {
        set script [textPopup:getscript [/display ""] sel $label]
        set state [textPopup:getstatescript [/display ""] sel $label]
        textPopup:addentry $wname sel $label $script $state
    }
    set inbuf [/inbuf]
    foreach opt {-font -foreground -background} {
        set val [$wname tag cget normal $opt]
        if {$val != ""} {
            $wname configure $opt $val
            $inbuf configure $opt $val
        }
    }
    catch {
        $wname tag raise url
    }
    $wname tag raise sel
    $wname tag lower normal
    style:ansi_fix $wname
    return
}

proc /style:add {name args} {
    global styleslist

    if {$name == ""} {
        return
    }
    if {$name == "none" && $args != ""} {
        return
    }
    set backdrop [/display ""]
    if {[$backdrop tag configure $name] == {}} {
        set preexistant 0
    } else {
        set preexistant 1
    }
    foreach {opt val} $args {
        $backdrop tag configure $name $opt $val
        foreach socket [/socket:names] {
            [/display $socket] tag configure $name $opt $val
        }
        #$backdrop tag configure $name $opt $val
    }
    set pos [match_by_name $name $styleslist]

    set item {}
    lappend item $name
    foreach {opt val} [styleconf $name] {
        lappend item [list $opt $val]
    }

    if {$pos >= 0} {
        set styleslist [lreplace $styleslist $pos $pos $item]
    } else {
        lappend styleslist $item
    }
    catch {
        $backdrop tag raise url
    }
    $backdrop tag raise sel
    foreach socket [/socket:names] {
        set disp [/display $socket]
        catch {
            $disp tag raise url
        }
        $disp tag raise sel
        $disp tag lower normal
        style:ansi_fix $disp
    }
    if {$name == "normal"} {
        set inbuf [/inbuf]
        set backdrop [/display ""]
        set normfont [$backdrop tag cget normal -font]
        array set bold_font  [font actual $normfont]
        array set ital_font  [font actual $normfont]
        set bold_font(-weight) bold
        set ital_font(-slant) italic
        $backdrop tag configure font_bold      -font [array get bold_font]
        $backdrop tag configure font_italic    -font [array get ital_font]
        foreach socket [/socket:names] {
            [/display $socket] tag configure font_bold      -font [array get bold_font]
            [/display $socket] tag configure font_italic    -font [array get ital_font]
        }
        foreach opt {-font -foreground -background} {
            set val [$backdrop tag cget normal $opt]
            if {$val != ""} {
                foreach socket [/socket:names] {
                    [/display $socket] configure $opt $val
                }
                $inbuf configure $opt $val
                $backdrop configure $opt $val
                if {$opt == "-foreground"} {
                    $inbuf configure -insertbackground $val
                }
            }
        }
    }
    if {$preexistant} {
        /style:notifyregistered update $name
    } else {
        /style:notifyregistered add $name
    }
    global dirty_preferences; set dirty_preferences 1
    return "Style set."
}

proc /style:exists {name} {
    global styleslist
    return [expr {[match_by_name $name $styleslist] >= 0}]
}

proc /style:delete {name} {
    global widget styleslist forcedelete
    if {$forcedelete == 0} {
        switch -exact -- $name {
            gag -
            normal -
            hilite -
            error -
            url -
            results {error "/style delete: Style '$name' can never be deleted."}
        }
    }
    foreach socket [/socket:names] {
        [/display $socket] tag delete $name
    }
    set pos [match_by_name $name $styleslist]
    if {$pos >= 0} {
        set styleslist [lreplace $styleslist $pos $pos]
        /style:notifyregistered delete $name
        global dirty_preferences; set dirty_preferences 1
        return "Style removed."
    } else {
        error "/style delete: No such style!"
    }
}

proc style:get_tag_css {style} {
    set bgcolor [/style:get background $style]
    set fgcolor [/style:get foreground $style]
    set bdwidth [/style:get borderwidth $style]
    set relief  [/style:get relief $style]
    set font    [/style:get font $style]
    set uline   [/style:get underline $style]
    set ovrstrk [/style:get overstrike $style]
    set justify [/style:get justify $style]
    set elide   [/style:get elide $style]
    if {$font != ""} {
        set fontfamily [font actual $font -family]
        set fontsize   [font actual $font -size]
        set fontweight [font actual $font -weight]
        set fontslant  [font actual $font -slant]
        set fontuline  [font actual $font -underline]
        set fontover   [font actual $font -overstrike]
    } else {
        set fontfamily ""
        set fontsize   ""
        set fontweight ""
        set fontslant  ""
        set fontuline  "0"
        set fontover   "0"
    }
    set lmargin1 [/style:get lmargin1 $style]
    set lmargin2 [/style:get lmargin2 $style]
    set rmargin  [/style:get rmargin $style]
    set spacing1 [/style:get spacing1 $style]
    set spacing2 [/style:get spacing2 $style]
    set spacing3 [/style:get spacing3 $style]

    set firstline ""
    regsub -all {[^A-Za-z0-9_]} $style "_" name
    set oot ".$name {\n"

    if {$font != ""} {
        append oot "    font-family: \"$fontfamily\", monospace;\n"
        append oot "    font-size: ${fontsize}pt;\n"
    }
    if {$fontslant == "italic"} {
        append oot "    font-style: italic;\n"
    }
    if {$fontweight == "bold"} {
        append oot "    font-weight: bold;\n"
    }

    set decorations ""
    if {$fontuline || ($uline != "" && $uline)} {
        append decorations " underline"
    }
    if {$fontover || ($ovrstrk != "" && $ovrstrk)} {
        append decorations " line-through"
    }
        if {$style == "font_flash" && [/prefs:get ansi_flash_enable]} {
        append decorations " blink"
                set fgcolor ""
                set bgcolor ""
        }
    if {$decorations != ""} {
        append oot "    text-decoration:$decorations;\n"
    }

    if {$fgcolor != ""} {
        append oot "    color: $fgcolor;\n"
    }
    if {$bgcolor != ""} {
        append oot "    background-color: $bgcolor;\n"
    }
    if {$bdwidth != ""} {
        append oot "    border-width: ${bdwidth}px;\n"
    }
    if {$relief != ""} {
        append oot "    border-style: $relief\n"
    }
    if {$justify != ""} {
        append oot "    text-align: $justify;\n"
    }
    if {$elide == 1} {
        append oot "    visibility: hidden;\n"
        append oot "    font-size: 0;\n"
    }
    if {$lmargin1 != "" || $lmargin2 != ""} {
        set lm1 $lmargin1
        if {$lm1 == ""} {
            set lm1 0
        }
        set lm2 $lmargin2
        if {$lm2 == ""} {
            set lm2 0
        }
        set margin [expr {$lm1-$lm2}]
        append oot "    text-indent: ${margin}px;\n"
        append oot "    padding-left: ${lm2}px;\n"
    }
    if {$rmargin != ""} {
        append oot "    padding-right: ${rmargin}px;\n"
    }
    if {$spacing1 != ""} {
        append firstline "    padding-top: ${spacing1}px;\n"
    }
    if {$spacing2 != ""} {
        append oot "    padding-top: ${spacing2}px;\n"
    }
    if {$spacing3 != ""} {
        append oot "    padding-bottom: ${spacing3}px;\n"
    }
    append oot "}\n"
    if {$firstline != ""} {
        append oot ".$name:first-line {\n"
        append oot $firstline
        append oot "}\n"
    }
    return $oot
}

proc /style:getcss {{pattern *}} {
    global styleslist

    set oot ""
    foreach style [/style:names $pattern] {
        append oot [style:get_tag_css $style]
    }
    return $oot
}

proc /style:getansicss {{pattern *}} {
    global styleslist

    set oot ""
    foreach type [list "bold" "italic" "underline" "flash" "strike"] {
        if {[string match $pattern "font_$type"]} {
            append oot [style:get_tag_css "font_$type"]
        }
    }
    foreach suffix [list {} "_dim" "_bold"] {
        if {[string match $pattern "fg_color$suffix"]} {
            append oot [style:get_tag_css "fg_color$suffix"]
        }
    }
    foreach suffix [list {} "_dim"] {
        if {[string match $pattern "bg_color$suffix"]} {
            append oot [style:get_tag_css "bg_color$suffix"]
        }
    }
    foreach clr [list "i" 0 1 2 3 4 5 6 7] {
        foreach suffix [list "" _dim _bold] {
            if {[string match $pattern "fg_color$clr$suffix"]} {
                append oot [style:get_tag_css "fg_color$clr$suffix"]
            }
        }
        foreach suffix [list "" _dim] {
            if {[string match $pattern "bg_color$clr$suffix"]} {
                append oot [style:get_tag_css "bg_color$clr$suffix"]
            }
        }
    }
    return $oot
}

proc /style:list {{pattern {}}} {
    global styleslist

    set oot ""
    foreach t $styleslist {
        if {$pattern == "" || [string match $pattern [lindex $t 0]]} {
            set name [lindex $t 0]
            if {$name != "gag"} {
                if {$oot != ""} {
                    append oot "\n"
                }
                append oot "/style add [list $name] [join [lrange $t 1 end]]"
                set menucfg [/style menu list $name]
                if {$menucfg != ""} {
                    if {$oot != ""} {
                        append oot "\n"
                    }
                    append oot $menucfg
                }
            }
        }
    }
    if {$pattern == ""} {
        set menucfg [/style menu list sel]
        if {$menucfg != ""} {
            if {$oot != ""} {
                append oot "\n"
            }
            append oot $menucfg
        }
    }
    return $oot
}

proc /style:notifyregistered {type name} {
    global StyleInfo
    foreach key [array names StyleInfo "reg,*"] {
        eval "$StyleInfo($key) [list $type] [list $name]"
    }
    return
}

proc /style:register {id cmd} {
    global StyleInfo
    if {[info exists StyleInfo(reg,$id)]} {
        error "/style register: That id is already registered!"
    }
    set StyleInfo(reg,$id) "$cmd"
    return
}

proc /style:deregister {id} {
    global StyleInfo
    if {[info exists StyleInfo(reg,$id)]} {
        unset StyleInfo(reg,$id)
    }
    return
}

proc /style:widgets {opt args} {
    dispatcher /style:widgets $opt $args
}

proc /style:widgets:compare {master name} {
    global StyleInfo
    if {![/style:exists $name]} { return 0 }
    set font [/style:get font $name]
    set fname ""
    set bold 0
    set italic 0
    set ostrike 0
    set uline 0
    set fntchk 0
    if {$font != {}} {
        set fntchk 1
        array set tmp_font [font actual $font]
        set fname $tmp_font(-family)
        set size $tmp_font(-size)
        if {$tmp_font(-weight) == "bold"} {
            set bold 1
        }
        if {$tmp_font(-slant) == "italic"} {
            set italic 1
        }
        set uline $tmp_font(-underline)
        set ostrike $tmp_font(-overstrike)
    }

    if {$StyleInfo($master,gui,fontchk) != $fntchk} {return 0}
    if {$StyleInfo($master,gui,fontchk)} {
        if {$StyleInfo($master,gui,font) != $fname} {return 0}
        if {$StyleInfo($master,gui,size) != $size} {return 0}
        if {$StyleInfo($master,gui,bold) != $bold} {return 0}
        if {$StyleInfo($master,gui,italic) != $italic} {return 0}
        if {$StyleInfo($master,gui,uline) != $uline} {return 0}
        if {$StyleInfo($master,gui,ostrike) != $ostrike} {return 0}
    }

    set fgcolor [/style:get foreground $name]
    if {$StyleInfo($master,gui,fgchk)} {
        if {$fgcolor == {}} {return 0}
        if {$StyleInfo($master,gui,fgcolor) != $fgcolor} {return 0}
    } else {
        if {$fgcolor != {}} {return 0}
    }

    set bgcolor [/style:get background $name]
    if {$StyleInfo($master,gui,bgchk)} {
        if {$bgcolor == {}} {return 0}
        if {$StyleInfo($master,gui,bgcolor) != $bgcolor} {return 0}
    } else {
        if {$bgcolor != {}} {return 0}
    }

    return 1
}

proc /style:widgets:getname {master} {
    global StyleInfo
    return $StyleInfo($master,gui,name)
}

proc /style:widgets:setname {master str} {
    global StyleInfo
    set StyleInfo($master,gui,name) $str
    return
}

proc /style:widgets:init {master name} {
    global StyleInfo styleslist treb_colors

    set base $master.fr

    set stylenum [match_by_name $name $styleslist]
    set style [lindex $styleslist $stylenum]

    $base.sample tag configure norm -font {} -background {} -foreground {}
    eval "$base.sample tag configure norm [join [lrange $style 1 end]]"

    set font [$base.sample tag cget norm -font]
    set bold 0
    set italic 0
    set uline 0
    set ostrike 0
    if {$font != {}} {
        array set tmp_font [font actual $font]
        set fname $tmp_font(-family)
        set size $tmp_font(-size)
        if {$tmp_font(-weight) == "bold"} {
            set bold 1
        }
        if {$tmp_font(-slant) == "italic"} {
            set italic 1
        }
        set uline $tmp_font(-underline)
        set ostrike $tmp_font(-overstrike)

        set StyleInfo($master,gui,fontchk) 1
        set StyleInfo($master,gui,font) $fname
        set StyleInfo($master,gui,size) $size
        set StyleInfo($master,gui,bold) $bold
        set StyleInfo($master,gui,italic) $italic
        set StyleInfo($master,gui,uline) $uline
        set StyleInfo($master,gui,ostrike) $ostrike
    } else {
        set StyleInfo($master,gui,fontchk) 0
    }

    set fgnorm [/style:get foreground normal]
    if {$fgnorm == {}} {
        set fgnorm $treb_colors(windowtext)
    }
    set fgcolor [/style:get foreground $name]
    set StyleInfo($master,gui,fgcolor) $fgcolor
    if {$fgcolor != {}} {
        set StyleInfo($master,gui,fgchk) 1
        $base.fgset config -background $fgcolor
    } else {
        set StyleInfo($master,gui,fgchk) 0
        $base.fgset config -background $fgnorm
    }

    set bgnorm [/style:get background normal]
    if {$bgnorm == {}} {
        set bgnorm $treb_colors(window)
    }
    set bgcolor [/style:get background $name]
    set StyleInfo($master,gui,bgcolor) $bgcolor
    if {$bgcolor != {}} {
        set StyleInfo($master,gui,bgchk) 1
        $base.bgset config -background $bgcolor
    } else {
        set StyleInfo($master,gui,bgchk) 0
        $base.bgset config -background $bgnorm
    }

    $base.sample tag config norm -background $bgcolor -foreground $fgcolor
    $base.sample config -background $bgnorm

    set StyleInfo($master,gui,name) $name
    /style:widgets:update $master
}

proc /style:widgets:mknode {master} {
    global StyleInfo
    set name     $StyleInfo($master,gui,name)
    set fgcolor  $StyleInfo($master,gui,fgcolor)
    set bgcolor  $StyleInfo($master,gui,bgcolor)
    set fontname $StyleInfo($master,gui,font)
    set size     $StyleInfo($master,gui,size)
    set bold     $StyleInfo($master,gui,bold)
    set italic   $StyleInfo($master,gui,italic)
    set uline    $StyleInfo($master,gui,uline)
    set ostrike  $StyleInfo($master,gui,ostrike)

    if {!$StyleInfo($master,gui,fgchk)} {set fgcolor {}}
    if {!$StyleInfo($master,gui,bgchk)} {set bgcolor {}}
    if {$StyleInfo($master,gui,fontchk)} {
        set font [list $fontname $size]
        if {$bold}    { lappend font "bold" }
        if {$italic}  { lappend font "italic" }
        if {$uline}   { lappend font "underline" }
        if {$ostrike} { lappend font "overstrike" }
    } else {
        set font {}
    }

    set    cmd "/style add [list $name] -font [list $font]"
    append cmd " -foreground [list $fgcolor]"
    append cmd " -background [list $bgcolor]"
    # /echo -style results $cmd
    eval "$cmd"
    return
}

proc /style:widgets:destroy {master} {
    destroy $master.fr
}

global style_known_font_sizes
global style_known_font_attributes

proc /style:widgets:update {master} {
    global StyleInfo treb_colors
    global style_known_font_sizes
    global style_known_font_attributes

    set base $master.fr
    $master.fr.sample tag config norm -font {}

    set fname  $StyleInfo($master,gui,font)
    set size   $StyleInfo($master,gui,size)
    if {![stringis integer $size]} {
        set size 9
    }
    set bold   $StyleInfo($master,gui,bold)
    set italic $StyleInfo($master,gui,italic)
    set ostrike $StyleInfo($master,gui,ostrike)
    set uline  $StyleInfo($master,gui,uline)

    set fgcolor $StyleInfo($master,gui,fgcolor)
    if {$fgcolor == {} || !$StyleInfo($master,gui,fgchk)} {
        set fgcolor [/style:get foreground normal]
        if {$fgcolor == {}} {
            set fgcolor $treb_colors(windowtext)
        }
    }
    $base.sample tag config norm -foreground $fgcolor
    if {[/style:get foreground normal] != {}} {
        $base.sample config -foreground [/style:get foreground normal]
    }

    set bgcolor $StyleInfo($master,gui,bgcolor)
    if {$bgcolor == {} || !$StyleInfo($master,gui,bgchk)} {
        set bgcolor [/style:get background normal]
        if {$bgcolor == {}} {
            set bgcolor $treb_colors(window)
        }
    }
    $base.sample tag config norm -background $bgcolor
    if {[/style:get background normal] != {}} {
        $base.sample config -background [/style:get background normal]
    }

    set font [list $fname $size]
    if {$bold}    { lappend font "bold" }
    if {$italic}  { lappend font "italic" }
    if {$uline}   { lappend font "underline" }
    if {$ostrike} { lappend font "overstrike" }

    $base.size entrydelete 0 end
    set prevsize 0
    set cando_bold 0
    set cando_italic 0
    if {[info exists style_known_font_sizes($fname)]} {
        foreach tmpsize $style_known_font_sizes($fname) {
            $base.size entryinsert end $tmpsize
        }
        if {[info exists style_known_font_attributes($fname)]} {
            set attrs $style_known_font_attributes($fname)
            if {[lsearch -exact $attrs "bold"] != -1} {
                set cando_bold 1
            }
            if {[lsearch -exact $attrs "italic"] != -1} {
                set cando_italic 1
            }
        }
    } else {
        foreach tmpsize {6 7 8 9 10 12 14 16 18 24 36 48}  {
            set tmpfont [lreplace $font 1 1 $tmpsize]
            set currsize [font actual $tmpfont -size]
            # set currsize $tmpsize
            if {$prevsize != $currsize} {
                set prevsize $currsize
                $base.size entryinsert end $currsize
                lappend style_known_font_sizes($fname) $currsize
            }
        }

        array set bold_font [font actual $font]
        set bold_font(-weight) bold
        if {[font actual [array get bold_font] -weight] == "bold"} {
            lappend style_known_font_attributes($fname) "bold"
            set cando_bold 1
        }

        array set ital_font [font actual $font]
        set ital_font(-slant) italic
        if {[font actual [array get ital_font] -slant] == "italic"} {
            lappend style_known_font_attributes($fname) "italic"
            set cando_italic 1
        }
    }
    if {$cando_bold} {
        $base.bold configure -state normal
    } else {
        $base.bold configure -state disabled
    }
    if {$cando_italic} {
        $base.italic configure -state normal
    } else {
        $base.italic configure -state disabled
    }
    if {$StyleInfo($master,gui,fontchk)} {
        $base.sample tag config norm -font $font
        $base.sample tag add norm 1.0 "end-1c"
        update idletasks
    }
    return
}

proc /style:widgets:create {master script} {
    global StyleInfo treb_colors tcl_platform
    set base $master.fr
    set updatescript "/style:widgets:update $master; $script"
    
    set StyleInfo($master,gui,name)    ""
    set StyleInfo($master,gui,fontchk) 0
    set StyleInfo($master,gui,font)    "Courier"
    set StyleInfo($master,gui,size)    8
    set StyleInfo($master,gui,bold)    0
    set StyleInfo($master,gui,italic)  0
    set StyleInfo($master,gui,uline)   0
    set StyleInfo($master,gui,ostrike) 0
    set StyleInfo($master,gui,fgchk)   0
    set StyleInfo($master,gui,fgcolor) $treb_colors(windowtext)
    set StyleInfo($master,gui,bgchk)   0
    set StyleInfo($master,gui,bgcolor) $treb_colors(buttonface)

    frame $base -relief flat -borderwidth 0

    label $base.namelbl \
        -anchor w -borderwidth 1 -text Name: 
    entry $base.name -textvariable StyleInfo($master,gui,name)
    bind $base.name <Key> "+$updatescript"

    frame $base.fontfr -borderwidth 2 -relief groove

    checkbutton $base.fontchk \
        -anchor w -text {Specify font} -variable StyleInfo($master,gui,fontchk) \
        -command "$updatescript"
    label $base.fontlbl \
        -anchor w -borderwidth 1 -text Font 
    combobox $base.font -textvariable StyleInfo($master,gui,font) \
        -changecommand "$updatescript" -editable 0 \
        -highlightbackground $treb_colors(window)

    label $base.sizelbl -text Size -anchor w -borderwidth 1
    combobox $base.size -textvariable StyleInfo($master,gui,size) \
        -changecommand "$updatescript" -width 3 \
        -highlightbackground $treb_colors(window)

    checkbutton $base.bold \
        -text Bold -variable StyleInfo($master,gui,bold) \
        -command "$updatescript"
    checkbutton $base.italic \
        -text Italic -variable StyleInfo($master,gui,italic) \
        -command "$updatescript"
    checkbutton $base.uline \
        -text Underline -variable StyleInfo($master,gui,uline) \
        -command "$updatescript"
    checkbutton $base.ostrike \
        -text Overstrike -variable StyleInfo($master,gui,ostrike) \
        -command "$updatescript"

    set fgcmd "
            set oldcolor \[$base.sample tag cget norm -foreground\]
            if \{\$oldcolor == \{\}\} \{set oldcolor black\}
            set result \[chooseColor -title \{Choose text color\} -initialcolor \$oldcolor -parent $base\]
            if \{\$result != \{\}\} \{
                set StyleInfo($master,gui,fgchk) 1
                set StyleInfo($master,gui,fgcolor) \$result
                $base.fgset config -background \$result
                $base.sample tag config norm -foreground \$result
                $updatescript
            \}
        "
    checkbutton $base.fgchk \
        -anchor w -text {Color Text} -variable StyleInfo($master,gui,fgchk) \
        -command "if \{\$StyleInfo($master,gui,fgchk)\} \{$fgcmd\} ;$updatescript"
    if {$tcl_platform(winsys) == "aqua"} {
        label $base.fgset \
            -background $StyleInfo($master,gui,fgcolor) \
            -text {} -width 5 -height 2 -borderwidth 2 -relief raised
        bind $base.fgset <ButtonPress-1> $fgcmd
    } else {
        button $base.fgset \
            -background $StyleInfo($master,gui,bgcolor) \
            -text {} -width 5 -command $fgcmd
    }

    set bgcmd "
            set oldcolor \[$base.sample tag cget norm -background\]
            if \{\$oldcolor == \{\}\} \{set oldcolor \$treb_colors(buttonface)\}
            set result \[chooseColor -title \{Choose background color\} -initialcolor \$oldcolor -parent $base\]
            if \{\$result != \{\}\} \{
                set StyleInfo($master,gui,bgchk) 1
                set StyleInfo($master,gui,bgcolor) \$result
                $base.bgset config -background \$result
                $base.sample tag config norm -background \$result
                $updatescript
            \}
        "
    checkbutton $base.bgchk \
        -anchor w -text {Color Background} -variable StyleInfo($master,gui,bgchk) \
        -command "if {\$StyleInfo($master,gui,bgchk)} {$bgcmd};$updatescript"
    if {$tcl_platform(winsys) == "aqua"} {
        label $base.bgset \
            -background $StyleInfo($master,gui,bgcolor) \
            -text {} -width 5 -height 2 -borderwidth 2 -relief raised
        bind $base.bgset <ButtonPress-1> $bgcmd
    } else {
        button $base.bgset \
            -background $StyleInfo($master,gui,bgcolor) \
            -text {} -width 5 -command $bgcmd
    }

    text $base.sample \
        -height 3 -width 20 -takefocus 0

    ###################
    # SETTING GEOMETRY
    ###################
    grid columnconf $base 4 -weight 1
    grid rowconf $base 5 -weight 1
    grid $base.namelbl \
        -column 0 -row 0 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky nesw 
    grid $base.name \
        -column 1 -row 0 -columnspan 4 -rowspan 1 -padx 5 -pady 5 \
        -sticky nesw 

    grid $base.fontfr \
        -column 0 -row 1 -columnspan 5 -rowspan 1 -padx 5 -pady 5 -sticky nsew

    grid columnconfig $base.fontfr 4 -weight 1
    grid $base.fontchk \
        -in $base.fontfr -column 0 -row 0 -columnspan 2 -rowspan 1 -padx 5 \
        -sticky nesw 
    grid $base.fontlbl \
        -in $base.fontfr -column 0 -row 1 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky nesw 
    grid $base.font \
        -in $base.fontfr -column 1 -row 1 -columnspan 4 -rowspan 1 -padx 5 \
        -pady 5 -sticky nesw 

    grid $base.sizelbl \
        -in $base.fontfr -column 0 -row 2 -columnspan 1 -rowspan 2 -padx 5 \
        -pady 10 -sticky w 
    grid $base.size \
        -in $base.fontfr -column 1 -row 2 -columnspan 1 -rowspan 2 -padx 5 \
        -pady 10 -sticky w 

    grid $base.bold \
        -in $base.fontfr -column 2 -row 2 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky w 
    grid $base.uline \
        -in $base.fontfr -column 3 -row 2 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky w 

    grid $base.italic \
        -in $base.fontfr -column 2 -row 3 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky w 
    grid $base.ostrike \
        -in $base.fontfr -column 3 -row 3 -columnspan 1 -rowspan 1 -padx 5 \
        -sticky w 

    grid $base.fgchk \
        -column 0 -row 3 -columnspan 3 -rowspan 1 -padx 5 \
        -sticky ew 
    grid $base.fgset \
        -column 3 -row 3 -columnspan 1 -rowspan 1 -padx 5 -pady 5 \
        -sticky nesw 

    grid $base.bgchk \
        -column 0 -row 4 -columnspan 3 -rowspan 1 -padx 5 \
        -sticky ew 
    grid $base.bgset \
        -column 3 -row 4 -columnspan 1 -rowspan 1 -padx 5 -pady 5 \
        -sticky nesw 

    grid $base.sample \
        -column 0 -row 5 -columnspan 5 -rowspan 1 -padx 5 -pady 5 \
        -sticky nesw 

    pack $base -fill both -expand 1
    foreach font [lsort -dictionary [font families]] {
        if {[regexp -nocase {^[A-Z0-9_][ -~]*$} $font]} {
            $base.font entryinsert end $font
        }
    }
    $base.sample insert end "This is a sample." norm
    return
}


