#############################################################################
# Spinner, by Garth Minette.  Released into the public domain 11/19/97.
# This is a Windows-95 style spinner control for TCL/Tk 8.0 or better.
#############################################################################


global gdmSpinnerModuleLoaded
if {![info exists gdmSpinnerModuleLoaded]} {
set gdmSpinnerModuleLoaded true

if {![info exists treb_lib_dir]} {
    set treb_lib_dir .
}
source [file join $treb_lib_dir bitmaps.tcl]

proc gdm:Spinner:Button {wname dir cnt} {
    global gdmSpinner

    set min $gdmSpinner($wname,min)
    set max $gdmSpinner($wname,max)
    set curval [$wname.entry get]

    focus $wname.entry
    if {$dir > 0} {
        set btn $wname.incrbtn
        if {$curval >= $max} {
            bind $btn <ButtonRelease-1> {}
            return
        }
    } else {
        set btn $wname.decrbtn
        if {$curval <= $min} {
            bind $btn <ButtonRelease-1> {}
            return
        }
    }
    gdm:Spinner:ArrowKey $wname $dir
    if {$cnt == 0} {
        set delay 500
    } elseif {$cnt < 64} {
        set delay [expr {64 - $cnt}]
    } else {
        set delay 1
        if {$dir > 0} {
            set dir [expr {int(pow(2,($cnt / 64) - 1))}]
        } else {
            set dir [expr {0 - int(pow(2,($cnt / 64) - 1))}]
        }
    }
    if {$dir > 1000000000} {
        set dir 1000000000
    } elseif {$dir < -1000000000} {
        set dir -1000000000
    }
    incr cnt
    set aid [after $delay gdm:Spinner:Button $wname $dir $cnt]
    bind $btn <ButtonRelease-1> "after cancel $aid ; bind $btn <ButtonRelease-1> {}"
}

proc gdm:Spinner:ArrowKey {wname dir} {
    global gdmSpinner

    set min $gdmSpinner($wname,min)
    set max $gdmSpinner($wname,max)
    set curval [$wname.entry get]
    set startval $curval

    if {$curval == {}} {
        set curval 0
    }
    set curval [expr {$curval + $dir}]
    if {$curval < $min} {
        set curval $min
    } elseif {$curval > $max} {
        set curval $max
    }
    if {$curval != $startval} {
        $wname.entry delete 0 end
        $wname.entry insert end $curval
        $wname.entry selection range 0 end

        upvar #0 $gdmSpinner($wname,varname) myval
        set myval $curval
        spinner:change $wname
    }
}

proc spinner {wname args} {
    global gdmSpinner gdmBitMaps
    if {[info commands spinbox] != ""} {
        spinbox $wname -validate all -invalidcommand /bell \
	    -validatecommand {regexp -nocase -- {^-?[0-9]*\.?[0-9]*$} %P}
	set gdmSpinner($wname,changecmd) {}
        bind $wname <Key> "+spinner:change $wname"
    } else {
	set frame $wname
	set entry $frame.entry
	set incrbtn $frame.incrbtn
	set decrbtn $frame.decrbtn

	set incrimg [gdm:Bitmap get incr]
	set decrimg [gdm:Bitmap get decr]

	set gdmSpinner($wname,varname) {}
	set gdmSpinner($wname,changecmd) {}
	set gdmSpinner($wname,min) 0
	set gdmSpinner($wname,max) 100
	set step 1
	set startval 0

	set badkeys {
	    a b c d e f g h i j k l m n o p q r s t u v w x y z
	    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
	    quoteleft equal bracketleft bracketright
	    semicolon quoteright comma period slash backslash space
	    asciitilde exclam at numbersign dollar percent asciicircum
	    ampersand asterisk parenleft parenright underscore plus
	    braceleft braceright colon quotedbl less greater question bar
	}

	frame $frame -relief flat -bd 0 -height 25 -width 50
	entry $entry -justify right -relief sunken -bd 2
	foreach key $badkeys {
	    bind $entry <Key-$key> {bell; break}
	}
	bind $entry <Key-minus> {
	    if {[%W index insert] != 0 || [string index [%W get] 0] == "-"} {
		bell
		break
	    } else {
		continue
	    }
	}
	global tcl_platform
	if {$tcl_platform(winsys) == "aqua"} {
	    label $incrbtn -width 12 -relief raised -borderwidth 1 -highlightthickness 0 -takefocus 0 -image $incrimg
	    label $decrbtn -width 12 -relief raised -borderwidth 1 -highlightthickness 0 -takefocus 0 -image $decrimg
	} else {
	    button $incrbtn -width 12 -highlightthickness 0 -takefocus 0 -image $incrimg
	    button $decrbtn -width 12 -highlightthickness 0 -takefocus 0 -image $decrimg
	}

	grid columnconf $frame 0 -weight 0
	grid columnconf $frame 1 -minsize 15 -weight 0
	grid rowconf $frame 0 -weight 0
	grid rowconf $frame 1 -weight 0

	grid $entry   -in $frame -row 0 -column 0 -rowspan 2 -sticky nesw
	grid $incrbtn -in $frame -row 0 -column 1 -rowspan 1 -sticky nesw
	grid $decrbtn -in $frame -row 1 -column 1 -rowspan 1 -sticky nesw
    }

    rename $wname widgetcmd:frame:$wname
    proc $wname {opt args} "
        eval \"spinner:widgetcmd [list [list $wname]] \[list \$opt\] \$args\"
    "
    eval "$wname config $args"
    if {[info commands spinbox] != ""} {
	after idle $wname selection range 0 end
    } else {
	after idle $entry selection range 0 end
    }

    return $wname
}

proc spinner:change {wname args} {
    global gdmSpinner
    set cmd $gdmSpinner($wname,changecmd)
    if {[catch "uplevel #0 [list $cmd]" result]} {
        global errorInfo
        set savedInfo $errorInfo
        error $result $savedInfo
    }
    return ""
}

proc spinner:widgetcmd {wname opt args} {
    global gdmSpinner gdmBitMaps

    set frame widgetcmd:frame:$wname
    set entry $wname.entry
    set incrbtn $wname.incrbtn
    set decrbtn $wname.decrbtn

    switch -exact -- $opt {
        set {
	    if {[info commands spinbox] != ""} {
		set w widgetcmd:frame:$wname
		$w delete 0 end
		$w insert end [lindex $args 0]
		return [lindex $args 0]
	    } else {
		set $gdmSpinner($wname,textvar) [lindex $args 0]
		return [lindex $args 0]
	    }
        }
        get {
	    if {[info commands spinbox] != ""} {
		set w widgetcmd:frame:$wname
		return [$w get]
	    } else {
		upvar #0 $gdmSpinner($wname,textvar) value
		return $value
	    }
        }
        cget {
            set opt [lindex $args 0]
	    if {[info commands spinbox] != ""} {
		set w widgetcmd:frame:$wname
		switch -glob -- $opt {
		    -min      {return [$w cget -from]}
		    -max      {return [$w cget -to]}
		    -step     {return [$w cget -increment]}
		    -val -
		    -value    {return [$w get 0 end]}
		    -variable {return [$w cget -textvariable]}
		    -activefg -
		    -activeforeground {return ""}
		    -activebg -
		    -activebackground {return [$w cget -activebackground]}
		    -bg -
		    -background {return [$w cget -background]}
		    -fg -
		    -foreground {return [$w cget -foreground]}
		    default {return [$w cget $opt]}
		}
	    } else {
		switch -glob -- $opt {
		    -min      { return $gdmSpinner($wname,min) }
		    -max      { return $gdmSpinner($wname,max) }
		    -step     { return $gdmSpinner($wname,step) }
		    -val -
		    -value    { return [$entry get 0 end] }
		    -variable { set textvar $variable }
		    -width    { return [$entry cget -width] }
		    -command  { return $gdmSpinner($wname,changecmd) }
		    -activefg -
		    -activeforeground {return [$decrbtn cget -activeforeground]}
		    -activebg -
		    -activebackground {return [$decrbtn cget -activebackground]}
		    -bg -
		    -background { return [$entry cget -background] }
		    -fg -
		    -foreground { return [$entry cget -foreground] }

		    default { error "$wname: invalid option $opt" }
		}
	    }
        }
        configure -
        configur  -
        configu   -
        config    -
        confi     -
        conf {
            set step 1
            set startval {}
            set textvar gdmSpinner($wname,value)
            uplevel #0 set $textvar 0

	    if {[info commands spinbox] != ""} {
		set w widgetcmd:frame:$wname
		set startval [$w get]
		set minval [$w cget -from]
		set maxval [$w cget -to]
		foreach {opt val} $args {
		    switch -glob -- $opt {
			-min      {set minval $val}
			-max      {set maxval $val}
			-step     {$w configure -increment $val}
			-val -
			-value    {set startval $val}
			-variable {$w configure -textvariable $val; set textvar $val}
			-activefg -
			-activeforeground {}
			-activebg -
			-activebackground {$w configure -activebackground $val}
			-bg -
			-background {$w configure -background $val}
			-fg -
			-foreground {$w configure -foreground $val}
			default {$w config $opt $val}
		    }
		}
		$w configure -from $minval -to $maxval
		uplevel #0 set $textvar $startval
	    } else {
		set comboargs {}
		set frameargs {}
		set entryargs {}
		set incrbtnargs {}
		set decrbtnargs {}
		set allargs {}

		foreach {opt val} $args {
		    switch -glob -- $opt {
			-min      { set gdmSpinner($wname,min) $val }
			-max      { set gdmSpinner($wname,max) $val }
			-step     { set step $val }
			-val -
			-value    { set startval $val }
			-variable { set textvar $val }
			-width    { lappend entryargs -width $val }
			-command  { set gdmSpinner($wname,changecmd) $val }
			-activefg -
			-activeforeground {
				lappend incrbtnargs -activeforeground $val
				lappend decrbtnargs -activeforeground $val
			    }
			-activebg -
			-activebackground {
				lappend incrbtnargs -activebackground $val
				lappend decrbtnargs -activebackground $val
			    }
			-bg -
			-background {
				lappend allargs -background $val
				lappend allargs -highlightbackground $val
			    }
			-fg -
			-foreground { lappend allargs -foreground $val }
			default { error "$wname: invalid option $opt" }
		    }
		}
		if {$startval != {}} {
		    uplevel #0 set $textvar $startval
		}
		lappend entryargs -textvariable $textvar
		set gdmSpinner($wname,textvar) $textvar
		set gdmSpinner($wname,step) $step

		foreach {arg val} [concat $allargs $frameargs] {
		    $frame config $arg $val
		}
		foreach {arg val} [concat $allargs $entryargs] {
		    $entry config $arg $val
		}
		foreach {arg val} [concat $allargs $incrbtnargs] {
		    $incrbtn config $arg $val
		}
		foreach {arg val} [concat $allargs $decrbtnargs] {
		    $decrbtn config $arg $val
		}

		if {$gdmSpinner($wname,changecmd) != ""} {
		    bind $entry <Key> "+after idle spinner:change $wname"
		}
		bind $incrbtn <ButtonPress-1> "gdm:Spinner:Button $wname $step 0 ; break"
		bind $entry <Key-Up> "gdm:Spinner:ArrowKey $wname $step ; break"

		bind $decrbtn <ButtonPress-1> "gdm:Spinner:Button $wname -$step 0 ; break"
		bind $entry <Key-Down> "gdm:Spinner:ArrowKey $wname -$step ; break"
	    }
        }
	default {
	    if {[info commands spinbox] != ""} {
		set w widgetcmd:frame:$wname
	        return [eval [list $w] [list $opt] $args]
	    }
	}
    }
    return $wname
}




if {0} {
    set foo(3) 8
    spinner .spin -max 1000000 -val 0 -min 0 -width 7 \
        -variable foo(3) \
        -command {.label2 config -text [.spin get]}
    label .label -textvariable foo(3)
    label .label2 -text {}
    pack .spin -side top
    pack .label -side top
    pack .label2 -side top
}

}

