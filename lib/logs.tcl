
tcl::OptProc /log {
    {-world           {} "The world that the logging takes place in."}
    {-request            "If given, pop up a GUI dialog to choose the logfile name."}
    {-html   -boolean 0  "If true, log in HTML format."}
    {-dated  -boolean 0  "If true, process file name as by [clock format] or strftime()."}
    {-scrollback -int 0  "If nonzero, log last N lines of scrollback first."}
    {?file?           {} "Specify the file to log to, or 'off' to stop logging."}
} {
    if {$world == {}} {
        set world [/socket:current]
    }
    if {$request} {
        if {$html} {
            set filetypes {
                {{HTML Files}       {.html}   TEXT}
                {{All Files}        *             }
            }
            set defaultext "html"
        } else {
            set filetypes {
                {{Text Files}       {.txt}    TEXT}
                {{Log Files}        {.log}    TEXT}
                {{All Files}        *             }
            }
            set defaultext "log"
        }
        set file [tk_getSaveFile -defaultextension .$defaultext \
                    -initialfile $world.$defaultext \
                    -title {Log to file} -filetypes $filetypes]
        if {$file == ""} {
            return ""
        }
    }
    if {$file == ""} {
        set file [/socket:get logfile $world]
        if {$file != ""} {
            return "Currently logging to '$file'."
        } else {
            return "Logging is off."
        }
    } else {
        if {$file == "off"} {
            set file ""
        }
        /socket:log -html $html -dated $dated -scrollback $scrollback $world $file
    }
    return ""
}


proc log:html_header {world} {
    append out "<html><head><title>Log of world $world</title>\n"
    append out "<style type=\"text/css\"><!-- \n"
    append out "P { margin: 0px; padding: 0px; }\n"
    append out ".normal { margin: 0px; padding: 0px; }\n"
    append out "[/style:getcss]\n"
    append out "[/style:getansicss]\n"
    append out " --></style></head><body class=\"normal\"><p>"
    return $out
}


proc log:write_line {world text tagspans} {
    set logfd [/socket:get logfd $world]
    if {$logfd != ""} {
        set loghtml [/socket:get loghtml $world]
        if {!$loghtml} {
            set lineout $text
        } else {
            set lineout ""
            lappend tagspans [list 0 end normal]
            set normspans {}
            foreach tag $tagspans {
                if {$tag != {}} {
                    set start [lindex $tag 0]
                    set end   [lindex $tag 1]
                    set style [lindex $tag 2]
                    regsub -all {[^A-Za-z0-9_]} $style "_" style
                    if {$start == "end"} {
                        set start [string length $text]
                    }
                    if {$end == "end"} {
                        set end [string length $text]
                    } else {
                        incr end $start
                    }
                    if {$style != "normal"} {
                        lappend normspans [list $start $end $style]
                    }
                }
            }
            set srtspans [lsort -command socket:comptags $normspans]
            set activespans {}
            set activestyles {}
            set interrupted {}
            set prevpos 0
            set textlen [string length $text]
            while {$prevpos < $textlen} {
                set tag [lindex $srtspans 0]
                if {$tag != {}} {
                    set spos [lindex $tag 0]
                } else {
                    set spos $textlen
                }
                if {$activespans != {}} {
                    set epos [lindex [lindex $activespans 0] 0]
                } else {
                    set epos $textlen
                }
                set npos $spos
                if {$epos < $npos} {
                    set npos $epos
                }
                if {$npos != $prevpos} {
                    set endpos [expr {$npos-1}]
                    set textout [string range $text $prevpos $endpos]
                    regsub -all "&"   $textout "\\&amp;"   textout
                    regsub -all "<"   $textout "\\&lt;"    textout
                    regsub -all ">"   $textout "\\&gt;"    textout
                    regsub -all "^ "  $textout "\\&nbsp;"  textout
                    regsub -all "  "  $textout " \\&nbsp;" textout
                    regsub -all "\\n" $textout "\\&nbsp;</p>\n<p>" textout
                    append lineout $textout 
                }
                if {$spos == $npos} {
                    set done 0
                    while {!$done} {
                        set done 1
                        for {set i 0} {$i < [llength $srtspans]} {incr i} {
                            set span [lindex $srtspans $i]
                            if {[lindex $span 0] != $npos} {
                                break
                            }
                            set end   [lindex $span 1]
                            set style [lindex $span 2]
                            set findact [lsearch -glob $activespans [list * 0 $style]]
                            if {$findact != -1} {
                                set actspan [lindex $activespans $findact]
                                if {[lindex $actspan 0] < $end} {
                                    set activespans [lreplace $activespans $findact $findact [list $end 0 $style]]
                                    set activespans [lsort -command socket:comptags $activespans]
                                }
                                set srtspans [lreplace $srtspans $i $i]
                                set done 1
                                break
                            }
                        }
                    }
                }
                if {$epos == $npos} {
                    while {$activespans != {}} {
                        set active [lindex $activespans 0]
                        if {$npos != $textlen && [lindex $active 0] != $npos} {
                            break
                        }
                        set activespans [lreplace $activespans 0 0]
                        set end   [lindex $active 0]
                        set style [lindex $active 2]
                        set fpos [lsearch -exact $interrupted $style]
                        if {$fpos != -1} {
                            set interrupted [lreplace $interrupted $fpos $fpos]
                        } else {
                            while {$activestyles != {}} {
                                append lineout "</span>"
                                set stktop [lindex $activestyles end]
                                set activestyles [lreplace $activestyles end end]
                                if {$style == $stktop} {
                                    break
                                } else {
                                    lappend interrupted $stktop
                                }
                            }
                        }
                    }
                }
                if {$npos != $textlen} {
                    if {$interrupted != {}} {
                        foreach istyle $interrupted {
                            append lineout "<span class=\"$istyle\">"
                            lappend activestyles $istyle
                        }
                        set interrupted {}
                    }
                    if {$spos == $npos} {
                        while {$srtspans != {}} {
                            set span [lindex $srtspans 0]
                            if {[lindex $span 0] != $npos} {
                                break
                            }
                            set srtspans [lreplace $srtspans 0 0]
                            set start [lindex $span 0]
                            set end   [lindex $span 1]
                            set style [lindex $span 2]
                            if {$start == $end} {
                                continue
                            }
                            lappend activespans [list $end 0 $style]
                            set activespans [lsort -command socket:comptags $activespans]
                            append lineout "<span class=\"$style\">"
                            lappend activestyles $style
                        }
                    }
                }
                set prevpos $npos
            }
        }
        puts -nonewline $logfd $lineout
        flush $logfd
    }
}


proc log:dump_scrollback_html {world firstline lastline} {
    set disp [/display $world]
    set firstline [$disp index $firstline]
    set lastline [$disp index $lastline]
    set curr $firstline
    while {[$disp compare $curr < $lastline]} {
        catch {unset activetags}
        set tagspans {}
        set linetext ""
        set currpos 0
        set start [$disp index $curr]
        set end [$disp index "$curr lineend"]
        if {[$disp compare $end > $lastline]} {
            set end $lastline
        }
        foreach {key val idx} [$disp dump -text -tag $start $end] {
            switch -exact $key {
                text {
                    append linetext $val
                    incr currpos [string length $val]
                }
                tagon {
                    if {![info exists activetags($val)]} {
                        set activetags($val) $currpos
                    }
                }
                tagoff {
                    if {[info exists activetags($val)]} {
                        set spos $activetags($val)
                        set elen [expr {$currpos-$spos}]
                        lappend tagspans [list $spos $elen $val]
                        unset activetags($val)
                    }
                }
            }
        }
        foreach val [array names activetags] {
            set spos $activetags($val)
            set elen [expr {$currpos-$spos}]
            lappend tagspans [list $spos $elen $val]
            unset activetags($val)
        }
        log:write_line $world "\n" {}
        log:write_line $world $linetext $tagspans
        set curr [$disp index "$curr linestart +1lines"]
    }
}


tcl::OptProc /loadlog {
    {-world   {} "The world that the logging takes place in."}
    {-request    "If given, pop up a GUI dialog to choose the logfile name."}
    {file     {} "Specify the log file to load from."}
} {
    if {$world == {}} {
        set world [/socket:current]
    }
    if {$request} {
        set filetypes {
            {{Text Files}       {.txt}    TEXT}
            {{Log Files}        {.log}    TEXT}
            {{HTML Files}       {.html}   TEXT}
            {{All Files}        *             }
        }
        set defaultext "html"
        set file [tk_getOpenFile -defaultextension .$defaultext \
                    -initialfile {} \
                    -title {Load log file} -filetypes $filetypes]
        if {$file == ""} {
            return ""
        }
    }
    set tagset {}
    set f [open $file "r"]
    set ishtml 0
    set firstline 1
    set disp [/display $world]
    while {![eof $f]} {
        set lines ""
        for {set i 0} {$i < 32} {incr i} {
            if {[eof $f]} {
                break
            } else {
                gets $f line
                if {!$ishtml && $lines != ""} {
                    append lines "\n"
                }
                append lines $line
            }
        }
        if {$firstline} {
            if {[regexp -nocase {<html>} $lines]} {
                set ishtml 1
            }
            set firstline 0
        }
        if {$ishtml} {
            set tagset [log:parse_html $world $lines $tagset]
        } else {
            display:write $disp "\n" {{0 end normal}}
            display:write $disp $lines {{0 end normal}}
        }
    }
    close $f
}


proc log:html_open_append {file} {
    set dir [file dirname $file]
    if {![file isdirectory $dir]} {
        error "That directory doesn't exist."
    }
    if {![file writable $dir]} {
        error "Cannot create file, because you do not have write permissions for that directory."
    }
    set f [open $file "a+" 0600]
    set pos [tell $f]
    while {$pos > 0} {
        incr pos -512
        if {$pos < 0} {
            set pos 0
        }
        seek $f $pos
        set data [read $f 528]
        set mpos [string last "</body>" [string tolower $data]]
        if {$mpos != -1} {
            incr pos $mpos
            seek $f $pos
            return $f
        }
    }
    seek $f 0 end
    return $f
}


proc log:parse_html {world data {tagset {}}} {
    set disp [/display $world]
    set cmdargs ""
    set headermarker "--<HEAD>--"
    set inheader 0
    if {[lsearch -exact $tagset $headermarker] != -1} {
        set inheader 1
    }
    lappend tagset normal
    while {$data != {}} {
        set didmatch [regexp -nocase {^([^<]*)<(/?)([a-z0-9][a-z0-9]*)([^>]*)>(.*)$} $data dummy pretext tagslash tagname tagargs postdata]
        if {$didmatch} {
            if {!$inheader && $pretext != ""} {
                if {[string first "&" $pretext] != -1} {
                    regsub -all -nocase "\n"     $pretext " "   pretext
                    regsub -all -nocase "  *"    $pretext " "   pretext
                    regsub -all -nocase "&lt;"   $pretext "<"   pretext
                    regsub -all -nocase "&gt;"   $pretext ">"   pretext
                    regsub -all -nocase "&nbsp;" $pretext " "   pretext
                    regsub -all -nocase "&amp;"  $pretext "\\&" pretext
                }
                append cmdargs " [list $pretext] [list $tagset]"
            }
            if {$tagslash == "/"} {
                if {$tagname == "span"} {
                    set tagset [lreplace $tagset end end]
                } elseif {$tagname == "head"} {
                    set pos [lsearch -exact $tagset $headermarker]
                    if {$pos != -1} {
                        set tagset [lreplace $tagset $pos $pos]
                    }
                    set inheader 0
                }
            } else {
                if {$tagname == "span"} {
                    regexp -nocase "class=\"(\[^\"\]*)\"" $tagargs dummy class
                    lappend tagset $class
                } elseif {$tagname == "p"} {
                    append cmdargs " [list \n] normal"
                } elseif {$tagname == "head"} {
                    lappend tagset $headermarker
                    set inheader 1
                }
            }
            set data $postdata
        } else {
            if {!$inheader} {
                if {[string first "&" $data] != -1} {
                    regsub -all -nocase "\n"     $data " " data
                    regsub -all -nocase "  *"    $data " " data
                    regsub -all -nocase "&lt;"   $data "<" data
                    regsub -all -nocase "&gt;"   $data ">" data
                    regsub -all -nocase "&nbsp;" $data " " data
                    regsub -all -nocase "&amp;"  $data "\\&" data
                }
                append cmdargs " [list $data] [list $tagset]"
            }
            set data {}
        }
    }
    if {$cmdargs != ""} {
        eval "[list $disp] insert end $cmdargs"
    }
    return $tagset
}


proc log_dlog:do_log {wname parent world} {
    global LogInfo

    set file     [$wname.fileentry get]
    set dohtml   $LogInfo($wname,dohtml)
    set scrollbk [$wname.scrollbk get]

    foreach name [array names LogInfo "$wname,*"] {
        unset LogInfo($name)
    }

    destroy $wname
    textdlog:refocus $parent
    /log -world $world -html $dohtml -scrollback $scrollbk $file
}


proc log_dlog:select_file {wname world} {
    global LogInfo treb_document_dir

    set filetypes {
        {{Text Files} .txt TEXT}
        {{HTML Files} .html TEXT}
        {{Log Files} .log TEXT}
        {{All Files} * }
    }

    set file [$wname.fileentry get]
    if {$file != ""} {
        set initialdir [file dirname $file]
        set initialfile [file tail $file]
    } else {
        set initialdir $treb_document_dir
        set initialfile $world.html
    }

    set file [tk_getSaveFile -title {Save log to file...} \
                -initialdir $initialdir \
                -initialfile $initialfile \
                -parent $wname.fileentry \
                -filetypes $filetypes]

    if {$file != {}} {
        $wname.fileentry delete 0 end
        $wname.fileentry insert end $file
        if {[string tolower [file extension $file]] == ".html"} {
            set LogInfo($wname,dohtml) 1
        } else {
            set LogInfo($wname,dohtml) 0
        }
    }
}


proc log_dlog:toggle_html {wname} {
    global LogInfo

    set file [$wname.fileentry get]
    if {$file != {}} {
        if {$LogInfo($wname,dohtml)} {
            set file "[file rootname $file].html"
        } else {
            set file "[file rootname $file].txt"
        }
        $wname.fileentry delete 0 end
        $wname.fileentry insert end $file
    }
}


tcl::OptProc /log_dlog {
    {-wname      {}                 "Toplevel window widget name"}
    {-parent     {}                 "Widget to focus on after exiting"}
    {-title      {}                 "Toplevel window title"}
    {-html       -boolean 0         "The initial html logging flag value."}
    {-scrollback -int 0             "The initial scrollback lines value."}
    {-world      {}                 "The initial world value."}
    {-file       {}                 "The initial file to log to."}
} {
    global LogInfo treb_document_dir
    if {$world == {}} {
        set world [/socket:current]
    }
    if {$parent == {}} {
        set parent [focus]
        if {$parent == {}} {
            set parent [/inbuf]
        }
    }
    if {![winfo exists $parent]} {
        set parent [/inbuf]
    }
    if {$wname == {}} {
        if {![info exists LogInfo(dlognum)]} {
            set LogInfo(dlognum) 0
        }
        incr LogInfo(dlognum)
        set wname $wname.logdlog$LogInfo(dlognum)
    }
    if {$title == {}} {
        set title "Log $world to file..."
    }

    if {[winfo exists $wname]} {
        wm deiconify $wname
        focus $wname.fileentry
    } else {
        ###################
        # CREATING WIDGETS
        ###################
        toplevel $wname
        place_window_default $wname $parent
        wm resizable $wname 0 0
        wm title $wname $title
        label $wname.filelbl \
            -anchor w -borderwidth 1 -text {File} -underline 1 
        entry $wname.fileentry -width 40
        button $wname.filebrowse -text {Browse...} -underline 0 -command [list log_dlog:select_file $wname $world]
        label $wname.scrollbklbl -text {Lines of scrollback to also save} -underline 0 -anchor w
        spinner $wname.scrollbk -min 0 -max 99999 -val $scrollback -step 1 -width 6
        checkbutton $wname.dohtml -text {Log as HTML} -variable LogInfo($wname,dohtml) -command [list log_dlog:toggle_html $wname]

        frame $wname.buttons \
            -borderwidth 2 -height 30 -width 125 
        button $wname.buttons.startlog \
            -text {Start Logging} -underline 0 -default active -command [list log_dlog:do_log $wname $parent $world]
        button $wname.buttons.cancel \
            -text Cancel -width 6 -command "destroy $wname ; textdlog:refocus $parent"
        ###################
        # SETTING GEOMETRY
        ###################
        grid columnconf $wname  0 -minsize 10
        grid columnconf $wname  2 -minsize 10
        grid columnconf $wname  4 -minsize 10
        grid columnconf $wname  5 -weight 1
        grid columnconf $wname  6 -minsize 10
        grid columnconf $wname  8 -minsize 10
        grid columnconf $wname 10 -minsize 10

        grid rowconf $wname  0 -minsize 10
        grid rowconf $wname  2 -minsize 10
        grid rowconf $wname  4 -minsize 15
        grid rowconf $wname  6 -minsize 10

        grid $wname.filelbl      -column 1 -row  1 -sticky w 
        grid $wname.fileentry    -column 3 -row  1 -sticky ew   -columnspan 5
        grid $wname.filebrowse   -column 9 -row  1 -sticky nsew
        grid $wname.scrollbklbl  -column 1 -row  3 -sticky w -columnspan 3
        grid $wname.scrollbk     -column 5 -row  3 -sticky w
        grid $wname.dohtml       -column 9 -row  3 -sticky nsew
        grid $wname.buttons      -column 1 -row  5 -sticky nsew -columnspan 9

        grid columnconf $wname.buttons 0 -weight 1
        grid columnconf $wname.buttons 2 -minsize 10
        grid $wname.buttons.cancel -column 1 -row 1 -sticky nsew
        grid $wname.buttons.startlog -column 3 -row 1 -sticky nesw 
        bind $wname <Key-Escape> "$wname.buttons.cancel invoke"
        bind $wname <Alt-Key-s> "$wname.buttons.startlog invoke"
    }

    wm title $wname $title

    if {$file == {}} {
        if {$html} {
            set file [file join $treb_document_dir $world.html]
        } else {
            set file [file join $treb_document_dir $world.txt]
        }
    }

    if {$file != {}} {
        $wname.fileentry delete 0 end
        $wname.fileentry insert end $file
    }
    set LogInfo($wname,dohtml) $html

    focus $wname.fileentry
    return
}


