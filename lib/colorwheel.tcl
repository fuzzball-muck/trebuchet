#
# A much nicer color picker dialog for unix.
# This is a drop-in replacement for tk_chooseColor
# Copyright 2002 by Revar Desmera <revar@belfry.com>
#

global tcl_platform
if {$tcl_platform(winsys) == "x11"} {

    package require opt

    namespace eval ColorWheel {
        variable current_hue
        variable current_saturation
        variable current_value
        variable current_red
        variable current_green
        variable current_blue
        variable startingcolor
        variable currentcolor
        variable resultcolor

        proc rgb2hsv {red grn blu} {
            set min $red
            if {$grn < $min} {
                set min $grn
            }
            if {$blu < $min} {
                set min $blu
            }

            set max $red
            if {$grn > $max} {
                set max $grn
            }
            if {$blu > $max} {
                set max $blu
            }

            if {$max == 0.0} {
                return [list 0.0 0.0 0.0]
            }

            set val $max
            set sat [expr {($max - $min) / $max}]
            if {$sat == 0.0} {
                set hue 0.0
            } else {
                set delta [expr {$max - $min}]
                if {$red == $max} {
                    set hue [expr {($grn - $blu) / $delta}]
                } elseif {$grn == $max} {
                    set hue [expr {2 + (($blu - $red) / $delta)}]
                } else {
                    set hue [expr {4 + (($red - $grn) / $delta)}]
                }
                set hue [expr {$hue * 60}]
                if {$hue < 0} {
                    set hue [expr {$hue + 360}]
                }
            }
            return [list $hue $sat $val]
        }


        proc hsv2rgb {hue sat val} {
            if {$sat == 0.0} {
                set red $val
                set grn $val
                set blu $val
            } else {
                set hue [expr {fmod($hue,360.0)/60.0}]
                set i [expr {int($hue)}]
                set f [expr {$hue-$i}]
                set p [expr {$val * (1 - $sat)}]
                set q [expr {$val * (1 - ($sat * $f))}]
                set t [expr {$val * (1 - ($sat * (1 - $f)))}]
                switch -exact -- $i {
                    0 { set red $val; set grn $t; set blu $p }
                    1 { set red $q; set grn $val; set blu $p }
                    2 { set red $p; set grn $val; set blu $t }
                    3 { set red $p; set grn $q; set blu $val }
                    4 { set red $t; set grn $p; set blu $val }
                    5 { set red $val; set grn $p; set blu $q }
                    default { error "Augh!" }
                }
            }
            return [list $red $grn $blu]
        }


        proc xy2hs {x y} {
            set pi 3.14159265358979

            set y [expr {-1 * $y}]
            set sat [expr {sqrt(($x*$x)+($y*$y))/63.0}]
            set hue [expr {fmod((360.0*atan2($y,$x)/(2*$pi))+270,360)}]
            if {$sat > 1.0} {
                set sat 1.0
            }

            return [list $hue $sat]
        }


        proc hs2xy {hue sat} {
            set pi 3.14159265358979

            set hue [expr {fmod(90+$hue,360)}]
            set x [expr {int(64 * $sat * cos(2 * $pi * $hue / 360.0))}]
            set y [expr {int(-64 * $sat * sin(2 * $pi * $hue / 360.0))}]

            return [list $x $y]
        }


        proc name2rgb {w color} {
            foreach {red grn blu} [winfo rgb $w $color] break
            set red [expr {$red / 65535.0}]
            set grn [expr {$grn / 65535.0}]
            set blu [expr {$blu / 65535.0}]

            return [list $red $grn $blu]
        }


        proc rgb2name {red grn blu} {
            set red [expr {int(255 * $red)}]
            set grn [expr {int(255 * $grn)}]
            set blu [expr {int(255 * $blu)}]

            return [format "#%02x%02x%02x" $red $grn $blu]
        }


        proc update_hsv_entries {w hue sat val} {
            $w.sc.huee config -state normal
            $w.sc.sate config -state normal
            $w.sc.vale config -state normal
            $w.sc.huee delete 0 end
            $w.sc.sate delete 0 end
            $w.sc.vale delete 0 end
            $w.sc.huee insert end [format "%.0f" $hue]
            $w.sc.sate insert end [format "%.3f" $sat]
            $w.sc.vale insert end [format "%.3f" $val]
            $w.sc.huee config -state disabled
            $w.sc.sate config -state disabled
            $w.sc.vale config -state disabled
        }


        proc update_value_slider {w hue sat val} {
            for {set i 0} {$i < 16} {incr i} {
                set nuval [expr {$i / 16.0}]
                foreach {nured nugrn nublu} [hsv2rgb $hue $sat $nuval] break
                set color [rgb2name $nured $nugrn $nublu]
                $w.c itemconfig "val_$i" -fill $color -outline $color
            }
            $w.c coords pointer 75 [expr {64-$val*128}]
        }


        proc update_hsv_scales {w hue sat val} {
            variable current_hue
            variable current_saturation
            variable current_value

            set current_hue $hue
            set current_saturation $sat
            set current_value $val

            update_hsv_entries $w $hue $sat $val
            update_value_slider $w $hue $sat $val
        }


        proc update_rgb_entries {w red grn blu} {
            $w.sc.rede config -state normal
            $w.sc.grne config -state normal
            $w.sc.blue config -state normal
            $w.sc.rede delete 0 end
            $w.sc.grne delete 0 end
            $w.sc.blue delete 0 end
            $w.sc.rede insert end [format "%.3f" $red]
            $w.sc.grne insert end [format "%.3f" $grn]
            $w.sc.blue insert end [format "%.3f" $blu]
            $w.sc.rede config -state disabled
            $w.sc.grne config -state disabled
            $w.sc.blue config -state disabled
        }


        proc update_rgb_scales {w red grn blu} {
            variable current_red
            variable current_green
            variable current_blue

            foreach {hue sat val} [rgb2hsv $red $grn $blu] break

            set current_red $red
            set current_green $grn
            set current_blue $blu

            update_rgb_entries $w $red $grn $blu
            update_value_slider $w $hue $sat $val
        }


        proc handle_hsv_scales {w dummyval} {
            variable current_hue
            variable current_saturation
            variable current_value

            foreach {red grn blu} [hsv2rgb $current_hue $current_saturation $current_value] break
            update_rgb_scales $w $red $grn $blu
            update_hsv_entries $w $current_hue $current_saturation $current_value
            update_rgb_entries $w $red $grn $blu
            setcolor $w $red $grn $blu
        }


        proc handle_rgb_scales {w dummyval} {
            variable current_red
            variable current_green
            variable current_blue

            foreach {hue sat val} [rgb2hsv $current_red $current_green $current_blue] break
            set color [rgb2name $current_red $current_green $current_blue]
            update_hsv_scales $w $hue $sat $val
            update_hsv_entries $w $hue $sat $val
            update_rgb_entries $w $current_red $current_green $current_blue
            setcolor $w $current_red $current_green $current_blue
        }


        proc resetcolor {w} {
            variable startingcolor

            foreach {red grn blu} [name2rgb $w $startingcolor] break
            foreach {hue sat val} [rgb2hsv $red $grn $blu] break
            update_hsv_scales $w $hue $sat $val
            update_rgb_scales $w $red $grn $blu
            setcolor $w $red $grn $blu
        }


        proc setcolor {w red grn blu} {
            variable currentcolor

            foreach {hue sat val} [rgb2hsv $red $grn $blu] break
            foreach {nux nuy} [hs2xy $hue $sat] break
            $w.c coords peephole $nux $nuy

            set color [rgb2name $red $grn $blu]
            $w.color config -background $color
            $w.colorl config -text $color

            set currentcolor $color
        }


        proc pointermotion {w x y} {
            variable currentcolor
            variable current_hue
            variable current_saturation

            set hue $current_hue
            set sat $current_saturation

            incr y -2
            set y [expr {64-($y-70)}]
            set val [expr {$y/128.0}]
            if {$val < 0.0} {
                set val 0.0
            }
            if {$val > 1.0} {
                set val 1.0
            }

            foreach {red grn blu} [hsv2rgb $hue $sat $val] break
            set color [rgb2name $red $grn $blu]
            $w.color config -background $color
            $w.colorl config -text $color

            update_hsv_scales $w $hue $sat $val
            update_rgb_scales $w $red $grn $blu

            set currentcolor $color
        }


        proc peepmotion {w x y} {
            variable currentcolor
            variable current_value

            incr x -72
            incr y -72
            foreach {hue sat} [xy2hs $x $y] break
            foreach {nux nuy} [hs2xy $hue $sat] break
            $w.c coords peephole $nux $nuy

            foreach {red grn blu} [hsv2rgb $hue $sat $current_value] break
            set color [rgb2name $red $grn $blu]
            $w.color config -background $color
            $w.colorl config -text $color

            update_hsv_scales $w $hue $sat $current_value
            update_rgb_scales $w $red $grn $blu

            set currentcolor $color
        }


        proc finish {w} {
            variable currentcolor
            variable resultcolor

            set resultcolor $currentcolor
            destroy $w
        }


        proc choose {initialcolor title parent} {
            global treb_lib_dir
            variable currentcolor
            variable resultcolor
            variable startingcolor

            if {![info exists treb_lib_dir]} {
                set treb_lib_dir .
            }

            image create photo colorwheel_wheel -file $treb_lib_dir/images/colorwheel.gif
            image create photo colorwheel_peep -file $treb_lib_dir/images/peephole.gif
            image create photo colorwheel_pointer -file $treb_lib_dir/images/rpointer.gif

            set cwnum 1
            while {1} {
                set base ".colorWheel$cwnum"
                if {![winfo exists $base]} {
                    break;
                }
                incr cwnum
            }
            toplevel $base
            wm title $base $title
            wm resizable $base 0 0
            if {$parent != ""} {
                wm transient $base $parent
            }
            place_window_default $base $parent

            canvas $base.c -width 170 -height 140 -relief flat \
                -scrollregion {-70 -70 100 70}
            frame $base.colori -background $initialcolor -relief solid \
                -borderwidth 1 -width 40 -height 20
            frame $base.color -background $initialcolor -relief solid \
                -borderwidth 1 -width 40 -height 20
            label $base.colorl -text "#000000"
            bind $base.colori <1> [list ::ColorWheel::resetcolor $base]

            frame $base.sc -relief flat

            label $base.sc.huel -text "H"
            label $base.sc.satl -text "S"
            label $base.sc.vall -text "V"
            label $base.sc.redl -text "R"
            label $base.sc.grnl -text "G"
            label $base.sc.blul -text "B"

            scale $base.sc.hue -from 0 -to 360 -resolution 1 -orient horiz -showvalue 0 -variable ::ColorWheel::current_hue -command [list ::ColorWheel::handle_hsv_scales $base]
            scale $base.sc.sat -from 0.0 -to 1.0 -resolution 0.001 -orient horiz -showvalue 0 -variable ::ColorWheel::current_saturation -command [list ::ColorWheel::handle_hsv_scales $base]
            scale $base.sc.val -from 0.0 -to 1.0 -resolution 0.001 -orient horiz -showvalue 0 -variable ::ColorWheel::current_value -command [list ::ColorWheel::handle_hsv_scales $base]
            scale $base.sc.red -from 0.0 -to 1.0 -resolution 0.001 -orient horiz -showvalue 0 -variable ::ColorWheel::current_red -command [list ::ColorWheel::handle_rgb_scales $base]
            scale $base.sc.grn -from 0.0 -to 1.0 -resolution 0.001 -orient horiz -showvalue 0 -variable ::ColorWheel::current_green -command [list ::ColorWheel::handle_rgb_scales $base]
            scale $base.sc.blu -from 0.0 -to 1.0 -resolution 0.001 -orient horiz -showvalue 0 -variable ::ColorWheel::current_blue -command [list ::ColorWheel::handle_rgb_scales $base]

            entry $base.sc.huee -width 5
            entry $base.sc.sate -width 5
            entry $base.sc.vale -width 5
            entry $base.sc.rede -width 5
            entry $base.sc.grne -width 5
            entry $base.sc.blue -width 5

            foreach scl [list hue sat val red grn blu] {
                bind $base.sc.$scl <1> "+focus %W; continue;"
            }

            frame $base.btnfr -relief flat
            button $base.btnfr.okay -text "Okay" -width 6 -default active -command [list ::ColorWheel::finish $base]
            button $base.btnfr.cancel -text "Cancel" -width 6 -default normal -command [list destroy $base]
            bind $base <Key-Return> [list $base.btnfr.okay invoke]
            bind $base <Key-Escape> [list $base.btnfr.cancel invoke]

            $base.c create image  0 0 -image colorwheel_wheel -tags {wheel hue_sat_pallate}
            $base.c create image  0 0 -image colorwheel_peep -tags {peephole hue_sat_pallate}
            $base.c create image 75 0 -image colorwheel_pointer -tags {pointer val_pallate} -anchor "e"
            for {set i 0} {$i < 16} {incr i} {
                set top [expr {64 - $i * 8}]
                set bottom [expr {$top - 8}]
                set clr [expr {$i / 16.0}]
                set color [rgb2name $clr $clr $clr]
                $base.c create rectangle 75 $top 95 $bottom -fill $color -outline $color -tag [list "val_$i" "val_pallate"]
            }

            $base.c bind hue_sat_pallate <Button1-Motion> [list ::ColorWheel::peepmotion $base %x %y]
            $base.c bind hue_sat_pallate <1> [list ::ColorWheel::peepmotion $base %x %y]
            $base.c bind val_pallate <Button1-Motion> [list ::ColorWheel::pointermotion $base %x %y]
            $base.c bind val_pallate <1> [list ::ColorWheel::pointermotion $base %x %y]

            grid rowconfig $base 0 -minsize 5
            grid rowconfig $base 2 -minsize 5
            grid rowconfig $base 4 -minsize 5
            grid rowconfig $base 6 -minsize 5
            grid columnconfig $base 0 -minsize 5
            grid columnconfig $base 3 -weight 1
            grid columnconfig $base 4 -minsize 5
            grid columnconfig $base 6 -minsize 5

            grid $base.c -row 1 -column 1 -columnspan 3
            grid $base.colori -row 3 -column 1 -sticky "nsew"
            grid $base.color -row 3 -column 2 -sticky "nsew"
            grid $base.colorl -row 3 -column 3 -sticky "w"
            grid $base.sc -row 1 -column 5 -rowspan 3 -sticky "nsew"
            grid $base.btnfr -row 5 -column 0 -columnspan 7 -sticky "ew"

            grid $base.sc.huel -row  1 -column 1
            grid $base.sc.satl -row  3 -column 1
            grid $base.sc.vall -row  5 -column 1
            grid $base.sc.redl -row  7 -column 1
            grid $base.sc.grnl -row  9 -column 1
            grid $base.sc.blul -row 11 -column 1

            grid $base.sc.hue -row  1 -column 3 -sticky "ew"
            grid $base.sc.sat -row  3 -column 3 -sticky "ew"
            grid $base.sc.val -row  5 -column 3 -sticky "ew"
            grid $base.sc.red -row  7 -column 3 -sticky "ew"
            grid $base.sc.grn -row  9 -column 3 -sticky "ew"
            grid $base.sc.blu -row 11 -column 3 -sticky "ew"

            grid $base.sc.huee -row  1 -column 5 -sticky "ew"
            grid $base.sc.sate -row  3 -column 5 -sticky "ew"
            grid $base.sc.vale -row  5 -column 5 -sticky "ew"
            grid $base.sc.rede -row  7 -column 5 -sticky "ew"
            grid $base.sc.grne -row  9 -column 5 -sticky "ew"
            grid $base.sc.blue -row 11 -column 5 -sticky "ew"

            grid rowconfig $base.btnfr 0 -minsize 0
            grid rowconfig $base.btnfr 3 -minsize 0
            grid columnconfig $base.btnfr 0 -minsize 0
            grid columnconfig $base.btnfr 3 -minsize 0
            grid columnconfig $base.btnfr 5 -minsize 0

            pack $base.btnfr.cancel -side right -padx 10
            pack $base.btnfr.okay -side right

            set resultcolor ""
            set startingcolor $initialcolor
            foreach {red grn blu} [name2rgb $base $initialcolor] break
            foreach {hue sat val} [rgb2hsv $red $grn $blu] break
            update_hsv_scales $base $hue $sat $val
            update_rgb_scales $base $red $grn $blu
            setcolor $base $red $grn $blu

            grab set $base
            tkwait window $base
            grab release $base
            return $resultcolor
        }
    }

    tcl::OptProc tk_chooseColor {
        {-initialcolor "#ffffff" "The starting color value."}
        {-title {Choose a color} "The title of the color dialog."}
        {-parent {} "The logical parent window of ths color dialog."}
    } {
        return [::ColorWheel::choose $initialcolor $title $parent]
    }
}



if {![info exists treb_lib_dir]} {
    puts stdout [tk_chooseColor -parent . -title "Color selector" -initialcolor "purple"]
    exit
}


