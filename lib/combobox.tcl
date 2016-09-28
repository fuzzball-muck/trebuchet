#############################################################################
# ComboBox, by Garth Minette.  Released into the public domain 11/19/97.
# This is a Windows-95 style combo-box for TCL/Tk 8.0 or better.
# Features a scrollable pulldown list, and an optionally editable text field.
#############################################################################

#############################################################################
# TO DO:
#    Moving mouse over dropdown listbox actively selects item under mouse.
#    Add command hook for when entry value is changed.
#############################################################################


global CBInfoModuleLoaded
if {![info exists CBInfoModuleLoaded]} {
set CBInfoModuleLoaded true

namespace eval ComboBox {
    namespace export combobox
    variable CBInfo

    #
    # The global command to create a combobox.
    #
    proc ::combobox {w args} {
        return [::ComboBox::_create $w $args]
    }


    #
    # Dispatch calls to combobox widget commands.
    #
    proc _dispatch {wname cmd argarr} {
        variable CBInfo

        if {[_use_menubutton $wname]} {
            set varname $CBInfo($wname,variable)
            if {$varname == ""} {
                set varname CBInfo($wname,varvalue)
            }
            upvar #0 $varname value
        }

        set entries $CBInfo($wname,list)
        switch -exact -- $cmd {
            "conf" -
            "confi" -
            "config" -
            "configu" -
            "configur" -
            "configure" {
                return [_config $wname $argarr]
            }

            "cget" {
                if {[llength $argarr] != 1} {
                    error "wrong # args: should be \"$wname cget option\""
                }
                return [lindex [_config $wname $argarr] 4]
            }

            "entryins" -
            "entryinse" -
            "entryinser" -
            "entryinsert" {
                set needsinit 0 
                if {[_use_menubutton $wname]} {
                    if {[llength $entries] == 0 && $value == ""} {
                        set needsinit 1 
                    }
                }
                set CBInfo($wname,list) [eval "linsert [list $entries] $argarr"]
                set CBInfo($wname,selected) {}
                if {[_use_menubutton $wname]} {
                    _remake_menu $wname
                } else {
                    if {$CBInfo(ismapped)} {
                        return [eval "$CBInfo(listwidget) insert $argarr"]
                    }
                }
                if {$needsinit} {
                    set value [lindex $CBInfo($wname,list) 0]
                }
            }

            "entrydel" -
            "entrydele" -
            "entrydelet" -
            "entrydelete" {
                set CBInfo($wname,list) [eval "lreplace [list $entries] $argarr"]
                set CBInfo($wname,selected) {}
                if {[_use_menubutton $wname]} {
                    _remake_menu $wname
                } else {
                    if {$CBInfo(ismapped)} {
                        return [eval "$CBInfo(listwidget) delete $argarr"]
                    }
                }
            }

            "entryget" {
                if {[llength $args] == 1} {
                    return [lindex $entries [lindex $argarr 0]]
                } else {
                    return [lrange $entries [lindex $argarr 0] [lindex $argarr 1]]
                }
            }

            "siz" -
            "size" {
                return [llength $entries]
            }

            "get" {
                if {[_use_menubutton $wname]} {
                    return ["${wname}.mb" cget -text]
                } else {
                    return [eval "${wname}.entry [list $cmd] $argarr"]
                }
            }

            "ins" -
            "inse" -
            "inser" -
            "insert" {
                if {[_use_menubutton $wname]} {
                    set pos [lindex $argarr 0]
                    if {$pos == "end"} {
                        set pos [string length $value]
                    }
                    set valout [string range $value 0 [expr {$pos - 1}]]
                    append valout [lindex $argarr 1]
                    append valout [string range $value $pos end]
                    set value $valout
                    return ""
                } else {
                    return [eval "${wname}.entry [list $cmd] $argarr"]
                }
            }

            "delete" {
                if {[_use_menubutton $wname]} {
                    set pos [lindex $argarr 0]
                    set endpos $pos
                    if {[llength $argarr] > 1} {
                        set endpos [lindex $argarr 1]
                    }
                    if {$pos == "end"} {
                        set pos [string length $value]
                    }
                    if {$endpos == "end"} {
                        set endpos [string length $value]
                    }
                    set valout [string range $value 0 [expr {$pos - 1}]]
                    append valout [string range $value [expr {$endpos+1}] end]
                    set value $valout
                    return ""
                } else {
                    return [eval "${wname}.entry [list $cmd] $argarr"]
                }
            }

            default {
                if {[_use_menubutton $wname]} {
                    return [eval "${wname}.mb [list $cmd] $argarr"]
                } else {
                    return [eval "${wname}.entry [list $cmd] $argarr"]
                }
            }
        }
    }


    proc _use_entrycontrol_byclass {comboclass} {
        global tcl_platform env
        if {$tcl_platform(winsys) == "aqua" && $comboclass == "ComboBoxEditable"} {
            if {[info exists env(TREB_MAC_THEME_FIX)]} {
                return 1
            }
        }
        return 0
    }


    proc _use_entrycontrol {wname} {
        set comboclass [winfo class $wname]
        return [_use_entrycontrol_byclass $comboclass]
    }


    proc _use_menubutton_byclass {comboclass} {
        global tcl_platform env
        if {$tcl_platform(winsys) == "aqua"} {
            if {[info exists env(TREB_MAC_THEME_FIX)] || $comboclass != "ComboBoxEditable"} {
                return 1
            }
        }
        return 0
    }


    proc _use_menubutton {wname} {
        set comboclass [winfo class $wname]
        return [_use_menubutton_byclass $comboclass]
    }


    proc _remake_menu {wname} {
        variable CBInfo

        set wname [_find $wname]
        if {![_use_menubutton $wname]} {
            return ""
        }

        set varname $CBInfo($wname,variable)
        if {$varname == ""} {
            set varname CBInfo($wname,varvalue)
        }

        $wname.mb.menu delete 0 end
        foreach item $CBInfo($wname,list) {
            $wname.mb.menu add radiobutton \
                    -label $item -value $item \
                    -variable $varname \
                    -command [list ::ComboBox::_invoke $wname]
        }
        $wname.mb config -textvariable $varname -menu $wname.mb.menu
        if {[_use_entrycontrol $wname]} {
            $wname.entry config -textvariable $varname
        }
    }


    proc _dispell {wname {clicked {}}} {
        variable CBInfo
        set wname [_find $wname]
        set toplev $CBInfo(toplevel)
        if {!$CBInfo(ismapped)} {
            return ""
        }

        # $wname.dropbtn config -relief "raised"
        wm transient $toplev {}
        if {$clicked == {}} {
            focus $wname.entry
        } else {
            focus $clicked
        }
        destroy $toplev

        bind [winfo toplevel $wname] <ButtonPress-1> $CBInfo(basebind)
        bind $wname.dropbtn <ButtonPress-1> "$wname.dropbtn config -relief \"sunken\" ; ::ComboBox::_drop $wname ; break"
        if {[winfo class $wname] == "ComboBox"} {
            bind $wname.entry <ButtonPress-1> {}
        }

        set CBInfo(basebind) {}
        set CBInfo(ismapped) 0
        set CBInfo(currmaster) {}
        set CBInfo(listwidget) {}
        set CBInfo(toplevel) {}
    }


    proc _keypress {wname keycode key} {
        variable CBInfo
        set wname [_find $wname]
        if {$keycode == "Up"} {
            _arrowkey $wname -1
            return
        }
        if {$keycode == "Down"} {
            _arrowkey $wname 1
            return
        }
        if {![regexp -nocase -- {[ -~]} $key]} {
            if {[info exists CBInfo($wname,typedchars)]} {
                unset CBInfo($wname,typedchars)
            }
            if {[info exists CBInfo($wname,keytimer)]} {
                after cancel $CBInfo($wname,keytimer)
                unset CBInfo($wname,keytimer)
            }
            return
        }
        set mylist $CBInfo($wname,list)
        set lastpos $CBInfo($wname,selected)
        set lastval $CBInfo($wname,selectval)
        set curval [$wname.entry get]

        if {$curval != $lastval} {
            set lastpos {}
            set lastval {}
            set cnt 0
            foreach item $mylist {
                if {[string tolower $item] == [string tolower $curval]} {
                    set lastpos $cnt
                    set lastval [lindex $mylist $cnt]
                    set CBInfo($wname,selected) $cnt
                    set CBInfo($wname,selectval) $lastval
                    break
                }
                incr cnt
            }
        }

        if {[info exists CBInfo($wname,keytimer)]} {
            after cancel $CBInfo($wname,keytimer)
            unset CBInfo($wname,keytimer)
        }
        set CBInfo($wname,keytimer) [
            after 750 "
                if {\[info exists ::ComboBox::CBInfo($wname,typedchars)\]} {
                    unset ::ComboBox::CBInfo($wname,typedchars)
                }
            "
        ]
        set chars {}
        if {[info exists CBInfo($wname,typedchars)]} {
            set chars $CBInfo($wname,typedchars)
        }
        if {$lastpos == {}} {
            set lastpos 0
        }
        append chars $key
        set chars [string tolower $chars]

        set llen [llength $mylist]
        set slen [string length $chars]
        incr slen -1
        for {set newpos 0} {$newpos < $llen} {incr newpos} {
            set item [lindex $mylist $newpos]
            set posstr [string tolower [string range $item 0 $slen]]
            set test  [string compare $posstr $chars]
            if  {$test == 0} {
                break
            }
        }
        if {$newpos >= $llen} {
            set newpos $lastpos
        }
        set CBInfo($wname,typedchars) $chars

        $wname.entry delete 0 end
        $wname.entry insert end [lindex $mylist $newpos]
        $wname.entry selection range 0 end

        set CBInfo($wname,selected) $newpos
        set CBInfo($wname,selectval) [lindex $mylist $newpos]
        _invoke $wname
    }


    proc _arrowkey {wname dir} {
        variable CBInfo
        set wname [_find $wname]
        set mylist $CBInfo($wname,list)
        set lastpos $CBInfo($wname,selected)
        set lastval $CBInfo($wname,selectval)
        set curval [$wname.entry get]
        if {[info exists CBInfo($wname,typedchars)]} {
            unset CBInfo($wname,typedchars)
        }
        if {[info exists CBInfo($wname,keytimer)]} {
            after cancel $CBInfo($wname,keytimer)
            unset CBInfo($wname,keytimer)
        }

        if {$curval != $lastval} {
            set lastpos {}
            set lastval {}
            set cnt 0
            foreach item $mylist {
                if {$item == $curval} {
                    set lastpos $cnt
                    set lastval [lindex $mylist $cnt]
                    set CBInfo($wname,selected) $cnt
                    set CBInfo($wname,selectval) $lastval
                    break
                }
                incr cnt
            }
        }
        if {$lastpos == {}} {
            if {$dir > 0} {
                $wname.entry delete 0 end
                $wname.entry insert end [lindex $mylist 0]
                $wname.entry selection range 0 end

                set CBInfo($wname,selected) 0
                set CBInfo($wname,selectval) [lindex $mylist 0]
                _invoke $wname
            }
            return
        }
        set newpos [expr {$lastpos + $dir}]
        set llen [llength $mylist]
        if {$newpos >= $llen} {
            set newpos [expr {$llen - 1}]
        }
        if {$newpos < 0} {
            set newpos 0
        }
        $wname.entry delete 0 end
        $wname.entry insert end [lindex $mylist $newpos]
        $wname.entry selection range 0 end

        set CBInfo($wname,selected) $newpos
        set CBInfo($wname,selectval) [lindex $mylist $newpos]
        _invoke $wname
    }


    proc _motion {wname} {
        variable CBInfo
        set wname [_find $wname]
        set toplev $CBInfo(toplevel)

        set x [winfo pointerx $toplev.list]
        set y [winfo pointery $toplev.list]
        if {[winfo containing $x $y] == "$wname.dropbtn"} {
            set dstate "sunken"
        } else {
            set dstate "raised"
        }
        if {[$wname.dropbtn cget -relief] != "$dstate"} {
            $wname.dropbtn config -relief "$dstate"
        }
        incr x -[winfo rootx $toplev.list]
        incr y -[winfo rooty $toplev.list]
        if {$y < -1} {
            $toplev.list yview scroll -1 unit
        } elseif {$y > [winfo height $toplev.list]} {
            $toplev.list yview scroll 1 unit
        }
        if {$x >= 0 && $x < [winfo width $toplev.list]} {
            $toplev.list selection clear 0 end
            $toplev.list selection set @$x,$y
        }
    }


    proc _select {wname} {
        variable CBInfo
        set toplev $CBInfo(toplevel)
        set cursel [$toplev.list curselection]
        if {$cursel != {} && $cursel >= 0} {
            $wname.entry delete 0 end
            set CBInfo($wname,selected) $cursel
            set curtext [$toplev.list get $cursel]
            set CBInfo($wname,selectval) $curtext
            $wname.entry insert end $curtext
            $wname.entry selection range 0 end
            _invoke $wname
        }
        _dispell_delayed $wname
        return ""
    }


    proc _find {wname} {
        while {$wname != "."} {
            set class [winfo class $wname]
            if {$class == "Menubutton" || $class == "ComboBox" || $class == "ComboBoxEditable"} {
                return $wname
            }
            set wname [winfo parent $wname]
        }
        return ""
    }


    proc _dispell_delayed {wname} {
        after 10 "::ComboBox::_dispell $wname"
    }


    proc _focusout {toplev wname} {
        switch -glob -- [focus] {
            $toplev* { return }
            $widget* { return }
            default  {
                _dispell_delayed $wname
            }
        }
    }


    proc _drop {wname} {
        variable CBInfo
        set wname [_find $wname]
        set wtop [winfo toplevel $wname]
        set toplev .gdmcombodropdown

        if {$CBInfo(ismapped)} {
            _dispell_delayed $wname
            return ""
        }
        if {[llength $CBInfo($wname,list)] == 0} {
            $wname.dropbtn config -relief "raised"
            return ""
        }

        bind $wname.dropbtn <ButtonPress-1> "::ComboBox::_dispell_delayed $wname ; break"
        if {[winfo class $wname] == "ComboBox"} {
            bind $wname.entry <ButtonPress-1> {::ComboBox::_dispell_delayed %W ; break}
        }

        toplevel $toplev -cursor top_left_arrow
        wm overrideredirect $toplev 1
        wm transient $toplev $wtop

        set listbg [$wname.entry cget -background]
        listbox $toplev.list -exportselection 0 -background $listbg \
            -highlightthickness 0 -relief solid -borderwidth 1

        foreach item $CBInfo($wname,list) {
            $toplev.list insert end $item
        }
        set itemh [expr {[lindex [$toplev.list bbox 0] 3] + 3}]
        if {[string tolower $CBInfo($wname,selectval)] != [string tolower [$wname.entry get]]} {
            set CBInfo($wname,selected) {}
        }
        if {$CBInfo($wname,selected) == {}} {
            set curtext [$wname.entry get]
            set cnt 0
            foreach item [$toplev.list get 0 end] {
                if {[string tolower $item] == [string tolower $curtext]} {
                    set CBInfo($wname,selected) $cnt
                    break
                }
                incr cnt
            }
        }

        $toplev.list selection clear 0 end
        if {$CBInfo($wname,selected) != {}} {
            $toplev.list selection set $CBInfo($wname,selected)
            $toplev.list activate $CBInfo($wname,selected)
            $toplev.list see $CBInfo($wname,selected)
        } else {
            $toplev.list activate -1
            $toplev.list see 0
        }

        set scrollflag 0
        set x [winfo rootx ${wname}]
        set y [expr {[winfo rooty ${wname}] + [winfo height ${wname}]}]
        set w [expr {[winfo width ${wname}] - 2}]
        if {$itemh != ""} {
            set lcnt [$toplev.list size]
            set h [expr {($itemh * $lcnt) + 2}]
            if {$h > 200} {
                set h [expr {(int(200 / $itemh) * $itemh) + 2}]
                set scrollflag 1
            }
        } else {
            set h 20
            set scrollflag 1
        }
        if {$y + $h > [winfo screenheight $wname]} {
            set y [expr {$y - ($h + [winfo height $wname])}]
        }
        wm geometry $toplev ${w}x${h}+$x+$y
	raise $toplev

        bind $toplev <FocusOut> "::ComboBox::_focusout $toplev $wname"
        bind $toplev <Key-Escape> "::ComboBox::_focusout $toplev $wname"
        bind $toplev.list <ButtonRelease-1> "::ComboBox::_select $wname ; break"
        bind $toplev.list <Key-Return> "::ComboBox::_select $wname ; break"
        bind $toplev.list <B1-Motion> "::ComboBox::_motion $wname ; break"

        set CBInfo(basebind) [bind $wtop <ButtonPress-1>]
        bind $wtop <ButtonPress-1> "+::ComboBox::_dispell $wname"

        grid rowconfig $toplev 0 -weight 1
        grid columnconfig $toplev 0 -weight 1
        grid $toplev.list -row 0 -column 0 -sticky nsew
        if {$scrollflag} {
            $toplev.list configure -yscrollcommand [list $toplev.scroll set]
            scrollbar $toplev.scroll -orient vertical -width 10 -borderwidth 1 \
                -command [list $toplev.list yview]
            grid $toplev.scroll -row 0 -column 1 -sticky nse
        }

        #update idletasks
        focus $toplev.list
        # grab $toplev
        
        set CBInfo(currmaster) $wname
        set CBInfo(ismapped) 1
        set CBInfo(listwidget) $toplev.list
        set CBInfo(toplevel) $toplev

        set motioncmd "
            if {\$::ComboBox::CBInfo(ismapped) &&
                !\[string match \"$wname*\" \[winfo containing %X %Y\]\]} {
                focus $toplev.list
                event generate $toplev.list <B1-Motion> -when head
            }
            break
        "
        bind $wname.entry <B1-Motion> $motioncmd
        bind $wname.dropbtn <B1-Motion> $motioncmd

        set releasecmd "
            if {\$::ComboBox::CBInfo(ismapped) &&
                \[winfo containing %X %Y\] == \"$toplev.list\"} {
                focus $toplev.list
                event generate $toplev.list <ButtonRelease-1> -when head
            }
            $wname.dropbtn config -relief \"raised\"
            break
        "
        bind $wname.entry <ButtonRelease-1> $releasecmd
        bind $wname.dropbtn <ButtonRelease-1> $releasecmd
    }


    proc _invoke {wname} {
        variable CBInfo

        set wname [_find $wname]
        after 10 $CBInfo($wname,changecmd)
    }


    proc _list {wname opt args} {
        variable CBInfo
        set entries $CBInfo($wname,list)
        switch -exact -- $opt {
            size {
                return [llength $entries]
            }
            get {
                return [eval "lrange $entries $args"]
            }
            insert {
                set CBInfo($wname,list) [eval "linsert [list $entries] $args"]
                set CBInfo($wname,selected) {}
            }
            delete {
                set CBInfo($wname,list) [eval "lreplace [list $entries] $args"]
                set CBInfo($wname,selected) {}
            }
        }
        if {$CBInfo(ismapped)} {
            return [eval "$CBInfo(listwidget) $opt $args"]
        }
        return ""
    }


    #
    # Change configuration options for the combobox widget
    #
    proc _config {wname argarr} {
        variable CBInfo

        set frame "_${wname}_int"
        set entry $wname.entry
        set menubtn $wname.mb
        set dropbtn $wname.dropbtn

        if {[llength $argarr] > 1} {
            set allargs {}
            set frameargs {}
            set mbargs {}
            set entryargs {}
            set dropbtnargs {}

            foreach {opt val} $argarr {
                switch -- $opt {
                    -editable { error "Cannot alter the editability of a combobox after its creation." }
                    -text     { error "Use the 'insert' widget command instead of -text" }

                    -changecmd -
                    -changecommand { set CBInfo($wname,changecmd) $val }

                    -bg -
                    -background {
                        if {[_use_menubutton $wname]} {
                            lappend frameargs -background $val
                            lappend frameargs -highlightbackground $val
                            lappend mbargs -background $val
                            lappend mbargs -highlightbackground $val
                            if {[_use_entrycontrol $wname]} {
                                lappend entryargs -background $val
                                lappend entryargs -highlightbackground $val
                            }
                        } else {
                            lappend allargs -background $val
                            lappend allargs -highlightbackground $val
                        }
                    }

                    -fg -
                    -foreground {
                        if {[_use_menubutton $wname]} {
                            lappend mbargs $opt $val
                            if {[_use_entrycontrol $wname]} {
                                lappend entryargs $opt $val
                            }
                        } else {
                            lappend entryargs $opt $val
                            lappend dropbtnargs $opt $val
                        }
                    }

                    -takefocus {
                        if {[_use_menubutton $wname]} {
                            lappend mbargs $opt $val
                            if {[_use_entrycontrol $wname]} {
                                lappend entryargs $opt $val
                            }
                        } else {
                            lappend entryargs $opt $val
                        }
                    }

                    -width {
                        if {[_use_menubutton $wname]} {
                            if {[_use_entrycontrol $wname]} {
                                lappend entryargs $opt $val
                            } else {
                                lappend mbargs $opt $val
                            }
                        } else {
                            lappend entryargs $opt $val
                        }
                    }

                    -textvar -
                    -textvariable {
                        if {[_use_menubutton $wname]} {
                            set CBInfo($wname,variable) $val
                            lappend mbargs $opt $val
                            if {[_use_entrycontrol $wname]} {
                                lappend entryargs $opt $val
                            }
                        } else {
                            lappend entryargs $opt $val
                        }
                    }

                    default {
                        if {[_use_menubutton $wname]} {
                            $menubtn config $opt $val
                        } else {
                            $entry config $opt $val
                        }
                    }
                }
            }

            foreach {opt val} $allargs {
                $frame config $opt $val
                $entry config $opt $val
                $dropbtn config $opt $val
            }
            foreach {opt val} $frameargs {
                $frame config $opt $val
            }
            foreach {opt val} $entryargs {
                $entry config $opt $val
            }
            foreach {opt val} $mbargs {
                $menubtn config $opt $val
            }
            foreach {opt val} $dropbtnargs {
                $dropbtn config $opt $val
            }

        } else {
            if {$argarr != ""} {
                set opt [lindex $argarr 0]
                switch -- $opt {
                    -editable { return [list -editable editable Editable 1 [expr {[winfo class $wname] == "ComboBoxEditable"}]] }
                    -changecommand { return [list -changecommand changeCommand ChangeCommand {} $CBInfo($wname,changecmd)] }
                    default {
                        if {[_use_menubutton $wname]} {
                            return [$menubtn config $opt]
                        } else {
                            return [$entry config $opt]
                        }
                    }
                }
            } else {
                if {[_use_menubutton $wname]} {
                    set configs [$menubtn config]
                } else {
                    set configs [$entry config]
                }
                lappend configs [_config $wname {-editable}]
                lappend configs [_config $wname {-changecommand}]
                return $configs
            }
        }
        return
    }


    #
    # For internal use only.  This procedure cleans up data for the combobox
    # when it is destroyed.
    #
    proc _destroy {wname} {
        variable CBInfo
        foreach key [array names CBInfo "$wname,*"] {
            unset CBInfo($key)
        }
    }


    #
    # Creates the combobox.
    #
    proc _create {wname argsarr} {
        global tcl_platform
        variable CBInfo

        set frame ${wname}
        set entry $frame.entry
        set menubtn $frame.mb
        set dropbtn $frame.dropbtn

        image create bitmap decrimg -data \
{#define decr_width 7
#define decr_height 4
static unsigned char decr_bits[] = {
0x7f, 0x3e, 0x1c, 0x08};}

        set comboclass "ComboBoxEditable"
        set allargs {}
        set changecmd {}

        foreach {opt val} $argsarr {
            switch -glob -- $opt {
                -editable {
                    if {$val == "1" || $val == "true"} {
                        set comboclass "ComboBoxEditable"
                    } elseif {$val == "0" || $val == "false"} {
                        set comboclass "ComboBox"
                    }
                }
                default { lappend allargs $opt $val }
            }
        }

        set CBInfo($wname,varvalue) {}
        if {[_use_menubutton_byclass $comboclass]} {
            frame $frame -class $comboclass -relief flat \
                    -borderwidth 0 -padx 0 -pady 0 -highlightthickness 0
            if {[_use_entrycontrol_byclass $comboclass]} {
                entry $entry -relief sunken -borderwidth 1 \
                        -textvariable CBInfo($wname,varvalue)
                menubutton $menubtn -menu $menubtn.menu -takefocus 1 \
                        -direction left -indicatoron 0 \
                        -image decrimg -compound none \
                        -padx 2 -pady 0 -borderwidth 4 \
                        -textvariable CBInfo($wname,varvalue)
                bindtags $entry [list $entry [winfo toplevel $entry] $comboclass Entry all]
                bind $frame <FocusIn> "focus %W.entry"
            } else {
                menubutton $menubtn -menu $menubtn.menu -takefocus 1 \
                        -direction flush -indicatoron 1 \
                        -textvariable CBInfo($wname,varvalue)
                bind $frame <FocusIn> "focus %W.mb"
            }
            menu $menubtn.menu -tearoff 0

            grid columnconfig $frame 0 -weight 1
            grid rowconfig $frame 0 -weight 1
            if {[_use_entrycontrol_byclass $comboclass]} {
                grid columnconfig $frame 1 -weight 0 -minsize 0
                grid $entry -in $frame -column 0 -row 0 -sticky nsew
                grid $menubtn -in $frame -column 2 -row 0 -sticky nsew
            } else {
                grid $menubtn -in $frame -column 0 -row 0 -sticky nsew
            }
        } else {
            if {$tcl_platform(winsys) == "aqua"} {
                frame $frame -class $comboclass -relief sunken \
                        -borderwidth 1 -takefocus 0
                entry $entry -relief flat -borderwidth 0
                label $dropbtn -width 11 -highlightthickness 0 -takefocus 0 \
                        -image decrimg -relief raised -borderwidth 1
            } else {
                frame $frame -class $comboclass -relief sunken \
                        -borderwidth 2 -takefocus 0
                entry $entry -relief flat -borderwidth 0
                button $dropbtn -width 11 -highlightthickness 0 -takefocus 0 \
                        -image decrimg
            }

            bindtags $frame  [list [winfo toplevel $wname] $frame $wname $comboclass all]
            bindtags $entry  [list [winfo toplevel $wname] $entry $wname $comboclass Entry all]
            bindtags $dropbtn [list [winfo toplevel $wname] $dropbtn $wname $comboclass all]

            if {$comboclass == "ComboBox"} {
                $entry configure -takefocus 1 -highlightthickness 1 -cursor left_ptr -insertwidth 0 -insertontime 0
            }
            bind $dropbtn <ButtonPress-1> "$dropbtn config -relief \"sunken\" ; ::ComboBox::_drop $frame ; break"

            grid columnconfig $frame 0 -weight 1
            grid rowconfig $frame 0 -weight 1
            grid $entry   -in $frame -column 0 -row 0 -sticky nsew
            grid $dropbtn -in $frame -column 1 -row 0 -sticky nsew
        }
        bind $wname <Destroy>   "::ComboBox::_destroy $wname"

        set CBInfo($wname,list) {}
        set CBInfo($wname,selected) {}
        set CBInfo(ismapped) 0
        set CBInfo(currmaster) {}
        set CBInfo(listwidget) {}
        set CBInfo(toplevel) {}
        set CBInfo($wname,selectval) {}
        set CBInfo($wname,changecmd) $changecmd
        set CBInfo($wname,varvalue) {}
        set CBInfo($wname,variable) {}

        rename $wname "_${wname}_int"
        proc ::$wname {cmd args} "return \[::ComboBox::_dispatch [list $wname] \$cmd \$args\]"
        _config $wname $allargs

        return $wname
    }


    foreach comboclass [list ComboBox ComboBoxEditable] {
        if {![_use_menubutton_byclass $comboclass]} {
            bind $comboclass <Shift-Key-Tab> {continue}
            bind $comboclass <Key-Tab>     {continue}
            bind $comboclass <Alt-Key>     {continue}
            bind $comboclass <Control-Key> {continue}
            bind $comboclass <Key-Escape>  {continue}
        }
    }
    if {![_use_menubutton_byclass "ComboBox"]} {
        bind ComboBox <ButtonPress-1>    {::ComboBox::_drop %W ; break}
        bind ComboBox <Key>              {::ComboBox::_keypress %W %K %A ; break}
    }
    bind ComboBoxEditable <Key-Up>   {::ComboBox::_arrowkey %W -1 ; break}
    bind ComboBoxEditable <Key-Down> {::ComboBox::_arrowkey %W 1 ; break}
    bind ComboBoxEditable <Key>      {::ComboBox::_invoke %W; continue}
}


if {0} {
    global footext onet twot
    label .fool -textvariable footext
    pack .fool -padx 10 -pady 10

    set onet "Eight"
    combobox .chkbx -textvariable onet \
        -changecommand {global onet footext; set footext $onet}
    foreach item {One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen Fifteen} {
        .chkbx entryinsert end $item
    }
    pack .chkbx -padx 10 -pady 0 -fill x

    set twot "Cee"
    combobox .cb -textvariable twot -editable 0 \
        -changecommand {global twot footext; set footext $twot}
    foreach item {Aye Bee Cee Dee Eee Eff Jee Ach Eiy Jay Kay Ell} {
        .cb entryinsert end $item
    }
    pack .cb -padx 10 -pady 10 -fill x
}

}

