
package require opt

proc richview:inittags {wname} {
    global treb_fonts
    global tcl_platform
    set txt $wname.text
    $txt tag conf Header -font {Helvetica 14 bold italic} -foreground green4 -wrap word -spacing1 12 -spacing3 4
    $txt tag conf Text -font $treb_fonts(sansserif) -foreground black -wrap word
    $txt tag conf Bold -font [concat $treb_fonts(sansserif) bold] -foreground black -wrap word
    $txt tag conf Pre -font [concat $treb_fonts(fixed) bold] -foreground black -wrap none
    $txt tag conf Arg -font [concat $treb_fonts(serif) bold italic] -foreground green4 -wrap word
    $txt tag conf BNF -font [concat $treb_fonts(fixed) bold] -foreground green4 -wrap word
    $txt tag conf Lit -font [concat $treb_fonts(fixed) bold] -foreground black -wrap word
    $txt tag conf Para -spacing3 6
    $txt tag conf Brk -spacing3 0
    $txt tag conf Link -font [concat $treb_fonts(sansserif) bold underline] -foreground blue2
    $txt tag bind Link <Enter> [list $txt configure -cursor hand2]
    set os $tcl_platform(winsys)
    switch -exact $os {
        aqua {
            set ncursor "ibeam"
        }
        win32 {
            set ncursor "ibeam"
        }
        x11 {
            set ncursor "xterm"
        }
        default {
            set ncursor "arrow"
        }
    }
    $txt tag bind Link <Leave> [list $txt configure -cursor $ncursor]
    for {set i 1} {$i <= 8} {incr i} {
        $txt tag conf Indent$i -lmargin1 [expr {$i * 32}] -lmargin2 [expr {$i * 32}]
    }
    $txt tag raise sel
}

#Commands:
#  Style <stylename> {<attr> <val> ...}
#  Page <pagename> <title> {
#    Header <text>
#    Text <text>
#    Bold <text>
#    Arg <text>
#    BNF <text>
#    Lit <text>
#    Pre <text>
#    Para
#    Brk
#    Bullet
#    Indent { <data }
#    Link <text> <destpagename>
#    Popup <text> <popuptext>
#    Image <filename>
#  }

global richview_linknum
set richview_linknum 0

proc richview:showformatted {wname data} {
    global richview_linknum
    global RichViewInfo
    set txt $wname.text
    set linelen 0
    for {set argnum 0} {$argnum < [llength $data]} {incr argnum} {
        set arg [lindex $data $argnum]
        switch -exact -- $arg {
            Title {
                set text [lindex $data [incr argnum]]
                wm title $wname $text
            }
            Header {
                set text [lindex $data [incr argnum]]
                regsub -all -- "\[\t \n\]+" $text " " text
                if {$linelen != 0} {
                    $txt insert end "\n"
                }
                $txt insert end $text Header
                $txt insert end "\n"
                set linelen 0
            }
            Pre {
                set text [lindex $data [incr argnum]]
                $txt insert end $text $arg
                incr linelen [string len $text]
            }
            Para {
                $txt tag add Para "end-1c linestart" "end"
                $txt insert end "\n"
                set linelen 0
            }
            Brk {
                $txt tag add Brk "end-1c linestart" "end"
                $txt insert end "\n"
                set linelen 0
            }
            Bullet {
                set bullet [gdm:Bitmap get bullet]
                $txt image create end -image $bullet
            }
            Indent {
                set ftext [lindex $data [incr argnum]]
                set start [$txt index end-1c]
                incr RichViewInfo(indent,$wname)
                $txt tag add Para "end-1c linestart" "end"
                if {$linelen != 0} {
                    $txt insert end "\n"
                }
                set linelen 0
                richview:showformatted $wname $ftext
                set tag "Indent$RichViewInfo(indent,$wname)"
                incr RichViewInfo(indent,$wname) -1
                $txt tag add $tag $start end
                $txt tag add Para "end-1c linestart" "end"
                $txt insert end "\n"
                set linelen 0
            }
            Link {
                set text [lindex $data [incr argnum]]
                set dest [lindex $data [incr argnum]]
                set linkname "Goto$dest"
                if {!$RichViewInfo(editable,$wname)} {
                    $txt tag bind $linkname <ButtonRelease-1> \
                        "richview:goto $wname [list $dest]"
                }
                $txt insert end $text [list Link $linkname]
                incr linelen [string len $text]
            }
            Image {
                set filename [lindex $data [incr argnum]]
                if {![catch {set img [image create photo -file $filename]} errMsg]} {
                    $txt image create end -image $img
                    incr linelen
                }
            }
            Text -
            Bold -
            Lit -
            BNF -
            Arg -
            default {
                set text [lindex $data [incr argnum]]
                regsub -all -- "\[\t \n\]+" $text " " text
                $txt insert end $text $arg
                incr linelen [string len $text]
            }
        }
    }
}

proc richview:goto {wname dest} {
    global RichViewInfo
    if {[info exists RichViewInfo(screens,$wname,$dest)]} {
        $wname.text delete 0.0 end
        richview:showformatted $wname $RichViewInfo(screens,$wname,$dest)
        lappend RichViewInfo(history,$wname) $dest
        set RichViewInfo(current,$wname) $dest
        if {$RichViewInfo(prev,$wname,$dest) != ""} {
            $wname.nav.prev config -state normal
        } else {
            $wname.nav.prev config -state disabled
        }
        if {$RichViewInfo(next,$wname,$dest) != ""} {
            $wname.nav.next config -state normal
        } else {
            $wname.nav.next config -state disabled
        }
    }
    if {[llength $RichViewInfo(history,$wname)] > 1} {
        $wname.nav.back config -state normal
    } else {
        $wname.nav.back config -state disabled
    }
}

proc richview:prev {wname} {
    global RichViewInfo
    set curr $RichViewInfo(current,$wname)
    set dest $RichViewInfo(prev,$wname,$curr)
    if {$dest != ""} {
        richview:goto $wname $dest
    }
}

proc richview:next {wname} {
    global RichViewInfo
    set curr $RichViewInfo(current,$wname)
    set dest $RichViewInfo(next,$wname,$curr)
    if {$dest != ""} {
        richview:goto $wname $dest
    }
}

proc richview:back {wname} {
    global RichViewInfo
    set hist $RichViewInfo(history,$wname)
    set top [llength $hist]
    incr top -2
    set dest [lindex $hist $top]
    incr top -1
    set RichViewInfo(history,$wname) [lrange $hist 0 $top]
    richview:goto $wname $dest
    return
}

proc richview:parse {wname indata} {
    global RichViewInfo
    set prev ""
    eval "set indata [list $indata]"
    set RichViewInfo(indent,$wname) 0

    for {set argnum 0} {$argnum < [llength $indata]} {incr argnum} {
        set arg [lindex $indata $argnum]
        switch -exact -- $arg {
            Page {
                set name  [lindex $indata [incr argnum]]
                set title [lindex $indata [incr argnum]]
                set data  [lindex $indata [incr argnum]]

                set RichViewInfo(screens,$wname,$name) $data
                set RichViewInfo(title,$wname,$name)   $title
                set RichViewInfo(prev,$wname,$name)    $prev
                set RichViewInfo(next,$wname,$name)    ""
                if {$prev != ""} {
                    set RichViewInfo(next,$wname,$prev) $name
                }
                set prev $name
            }
            Title {
                if {$RichViewInfo(title,$wname) == ""} {
                    set RichViewInfo(title,$wname) [lindex $indata [incr argnum]]
                }
            }
            Style {
                set name  [lindex $indata [incr argnum]]
                set data  [lindex $indata [incr argnum]]

                set txt $wname.text
                foreach {opt val} $data {
                    eval "$txt tag config [list $name] [list $opt] [list $val]"
                }
            }
        }
    }
    return
}

proc richview:destructor {wname} {
    global RichViewInfo
    set indexes [array names RichViewInfo "*,$wname,*"]
    set indexes [concat $indexes [array names RichViewInfo "*,$wname"]]
    foreach idx $indexes {
        catch {unset RichViewInfo($idx)}
    }
}

proc richview:refocus {wname} {
    if {[winfo exists $wname]} {
        focus $wname
    } else {
        focus .mw
    }
}



# WORK NEEDED
proc richview:unparse {$wname} {
}


##################################################333
# WORK NEEDED
proc richview:filenew {wname} {
    $wname.text delete 1.0 end
}

proc richview:filesave {wname} {
    global RichViewInfo
    if {$RichViewInfo(filename,$wname) == ""} {
        richview:filesaveas $wname
    } else {
        set f [open $RichViewInfo(filename,$wname) w]
        puts $f [richview:unparse $wname]
        close $f
    }
}

proc richview:filesaveas {wname {fyle ""}} {
    set filetypes {
        {{Text Files}           {.txt}        }
        {{Trebuchet Help Files} {.thc}        }
        {{All Files}            *             }
    }
    if {$fyle == ""} {
        set fyle [tk_getSaveFile -defaultextension .trh -filetypes $filetypes \
                -initialfile Unknown.trh -title {Save File}]
    }
    global RichViewInfo
    set RichViewInfo(filename,$wname) $fyle
    if {$RichViewInfo(title,$wname) == ""} {
        set RichViewInfo(title,$wname) "RichView - $fyle"
    }
    wm title $wname $RichViewInfo(title,$wname)
    richview:filesave $wname
}

proc richview:fileopen {wname {fyle ""}} {
    global RichViewInfo
    set filetypes {
        {{Text Files}           {.txt}        }
        {{Trebuchet Help Files} {.trh}        }
        {{All Files}            *             }
    }
    if {$fyle == ""} {
        set fyle [tk_getOpenFile -filetypes $filetypes \
                -initialfile Unknown.trh -title {Open File}]
    }
    if {[file exists $fyle]} {
        richview:filenew $wname
        set f [open $fyle "r"]
        set data [read $f]
        close $f
        richview:parse $wname $data
        richview:goto $wname Main
        set RichViewInfo(filename,$wname) $fyle
        if {$RichViewInfo(title,$wname) == ""} {
            set RichViewInfo(title,$wname) "RichView - $fyle"
        }
        wm title $wname $RichViewInfo(title,$wname)
    }
}


tcl::OptProc richview:create {
    {wname    {}            "Toplevel window widget name"}
    {-parent  {}            "Widget to focus on after exiting"}
    {-title   ""            "Toplevel window title"}
    {-file    ""            "File to open.  Defaults to none."}
    {-text    {}            "Text to put in editor"}
    {-width   60            "Number of columns in editor"}
    {-height  24            "Number of rows in editor"}
    {-noautoindent          "Stops indenting new lines to match prev line."}
    {-editable              "Text is editable."}
} {
    global RichViewInfo treb_colors treb_fonts
    set RichViewInfo(title,$wname) $title

    set readonly 1
    if {$editable} {
        set readonly 0
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

    set done_cmd "richview:destructor $wname ; "

    set buttons 0
    if {$readonly} {
        set buttons 1
    }
    append done_cmd "destroy $wname ; richview:refocus $parent"

    set RichViewInfo(editable,$wname) $editable
    if {$noautoindent} {
        set RichViewInfo(autoindent,$wname) 0
    } else {
        set RichViewInfo(autoindent,$wname) 1
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

        menu $wname.mbar.file -tearoff false
            $wname.mbar.file add command -label "New"        -under 0 \
                -command "richview:filenew $wname"
            $wname.mbar.file add command -label "Open"       -under 0 \
                -command "richview:fileopen $wname"
            $wname.mbar.file add command -label "Save"       -under 0 \
                -command "richview:filesave $wname"
            $wname.mbar.file add command -label "Save as..." -under 1 \
                -command "richview:filesaveas $wname"
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
                -command "finddlog:new $wname.find $wname.text"
            $wname.mbar.edit add separator
            $wname.mbar.edit add checkbutton -label " Auto-indent"  -under 6 \
                -onvalue 1 -offvalue 0 -indicatoron 1 \
                -variable RichViewInfo(autoindent,$wname)

        frame $wname.fr -relief sunken -borderwidth 2
        frame $wname.nav -relief flat
        button $wname.nav.back -text Back -width 6 -padx 0 -pady 0 \
            -command "richview:back $wname" -underline 0
        button $wname.nav.prev -text Prev -width 6 -padx 0 -pady 0 \
            -command "richview:prev $wname" -underline 0
        button $wname.nav.next -text Next -width 6 -padx 0 -pady 0 \
            -command "richview:next $wname" -underline 0
    
        grid columnconf $wname.nav 99 -weight 1
        grid rowconf $wname.nav 0 -weight 0
        grid $wname.nav.back -row 0 -column 0 -sticky nsew
        grid $wname.nav.prev -row 0 -column 1 -sticky nsew
        grid $wname.nav.next -row 0 -column 2 -sticky nsew

        if {$readonly} {
            bind $wname <Alt-Key-b>       "richview:back $wname ; break"
            bind $wname <Alt-Key-less>    "richview:prev $wname ; break"
            bind $wname <Alt-Key-comma>   "richview:prev $wname ; break"
            bind $wname <Alt-Key-greater> "richview:next $wname ; break"
            bind $wname <Alt-Key-period>  "richview:next $wname ; break"
        }
        text $wname.text -yscrollcommand "$wname.scroll set" -wrap word \
            -width 1 -height 1 -font $treb_fonts(fixed) -relief flat
        if {$readonly} {
            $wname.text config -background $treb_colors(window)
            $wname.text config -insertwidth 0 -cursor top_left_arrow
            bindtags $wname.text [list $wname $wname.text Text]
            bind $wname.text <Key> {
                switch -exact -- %K {
                    Home	{%W see 1.0}
                    End		{%W see end}
                    Left	{%W xview scroll -1 units}
                    Right	{%W xview scroll 1 units}
                    Up		{%W yview scroll -1 units}
                    Down	{%W yview scroll 1 units}
                    Prior	{%W yview scroll -1 pages}
                    Next	{%W yview scroll 1 pages}
                    Escape	{continue}
                    Return	{continue}
                    Alt_L -
                    Alt_R	{continue}
                    default {bell ; break}
                }
                break
            }
        } else {
            bind $wname.text <Key-Return> {
                global RichViewInfo
                set wname "%W"
                set pos [expr {[string length "$wname"] - 6}]
                set wname [string range $wname 0 $pos]
                set indent ""
                if {$RichViewInfo(autoindent,$wname)} {
                    set start [%W index "insert linestart"]
                    set end $start
                    while {1} {
                        set ch [%W get $end]
                        if {$ch != " " && $ch != "	"} {
                            break
                        }
                        set end [%W index "$end + 1 chars"]
                    }
                    if {[%W compare $start < $end]} {
                        set indent [%W get $start $end]
                    }
                }
                %W insert insert "\n$indent"
                break
            }
        }
        scrollbar $wname.scroll -command "$wname.text yview"

        grid columnconf $wname.fr 0 -weight 1
        grid columnconf $wname.fr 1 -weight 0
        grid rowconf $wname.fr 0 -weight 0
        grid rowconf $wname.fr 1 -weight 1
        if {$readonly} {
            grid $wname.nav -in $wname.fr -column 0 -row 0 -sticky nsew \
                -columnspan 2
        }
        grid $wname.text   -in $wname.fr -column 0 -row 1 -sticky nsew
        grid $wname.scroll -in $wname.fr -column 1 -row 1 -sticky nsew

        grid columnconf $wname 0 -weight 1
        grid rowconf $wname 0 -weight 1
        grid $wname.fr -column 0 -row 0 -sticky nsew

        if {$buttons} {
            frame $wname.buttons -relief flat
            button $wname.buttons.done -width 7 -text "Done" -underline 0
            grid columnconfig $wname.buttons 0 -minsize 15 -weight 1
            grid columnconfig $wname.buttons 2 -minsize 15
            grid rowconfig $wname.buttons 0 -minsize 10
            grid rowconfig $wname.buttons 2 -minsize 10
            grid $wname.buttons.done   -row 1 -column 1
            bind $wname <Key-Escape> "$wname.buttons.done invoke ; break"
            bind $wname <Alt-Key-d> "$wname.buttons.done invoke ; break"

            grid $wname.buttons -row 1 -column 0 -sticky nsew
        }
    }

    wm title $wname $title
    place_window_default $wname $parent

    $wname.text config -width $width -height $height
    set RichViewInfo(filename,$wname) ""

    richview:inittags $wname
    if {$text != ""} {
        richview:parse $wname $text
        richview:goto $wname Main
    } elseif {$file != ""} {
        richview:fileopen $wname $file
    }

    $wname.mbar.file entryconfig "Exit" -command "$done_cmd"
    if {$buttons} {
        $wname.buttons.done config -command "$done_cmd"
    }

    focus $wname.text

    return $wname
}


global richview_widgetnumber
set richview_widgetnumber 0

proc /richview {args} {
    global richview_widgetnumber
    incr richview_widgetnumber
    set wname .richview$richview_widgetnumber

    eval "richview:create $wname $args"
    return
}



