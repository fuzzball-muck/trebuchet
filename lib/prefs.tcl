#################################
# Preferences Dialog
#

global treb_prefs_list

# This list specifies all preferences options that are available to Trebuchet.
# The Preferences dialog will list all these controls in the order given here,
#  under the notebook tab specified here.  NOTE: A null tabname means that that
#  preference is internal only, and it won't show up in the Preferences dialog.
#  A tabname of "-" is internal only, won't be shown in the prefs dialog, won't
#  be listed in a /prefs:list, and won't be saved to disk.  If a preference
#  name starts with win_ or unix_ or mac_, then it will only be shown in dia-
#  logs on the apropriate platform.

# For OSes, W = Windows, U = Unix, M = MacOS 9, D = Darwin/OS X, - = All
# type name             val min   max tabname  OSes caption
set treb_prefs_list {
  cust stdfontsedit "prefs:mkcust_fontsedit"  0 0 Fonts - ""
  cust fontresize   "prefs:mkcust_fontresize" 0 0 Fonts - ""
  bool antialias_fonts    1   0     1 Fonts    D  "Enable Antialiased Fonts"
  int  menu_font_size     0   8    24 Fonts    -  "Menu font size"
  int  scrollback_lines 500 100 99999 Display  -  "Maximum scrollback length"
  bool pager_flag         0   0     1 Display  -  "Stop scrolling when display fills"
  bool jumpscroll_flag    1   0     1 Display  -  "Enable jump-scrolling"
  bool bell_audible       1   1     0 Display  -  "Visual bell"
  str  unix_beep_cmd     ""   0    40 Display  U  "Beep Command"
  bool activity_flash_title 0 0     1 Display  WU "Flash window title on activity when backgrounded"
  int  statbar_histlen   50   1 99999 Display  -  "Statusbar message history length"
  bool ansi_over_styles   1   0     1 Display  -  "ANSI colors override hilite styles"
  bool ansi_flash_enable  1   0     1 Display  -  "Enable ANSI flashing text"
  int  command_lines     20   0 99999 Input    -  "Maximum command history length"
  int  completion_lines 100  10 99999 Input    -  "Lines to search for word completion"
  bool echo_flag          0   0     1 Input    -  "Echo commands to display"
  bool eatblanks_flag     0   0     1 Input    -  "Don't send blank lines"
  bool echoblanks_flag    1   0     1 Input    -  "Echo blank lines to display"
  str  spell_check_cmd   "aspell list --lang=en"                 0 40 Spelling - "Spelling checker command"
  str  spell_suggest_cmd "aspell -a --lang=en --sug-mode=normal" 0 40 Spelling - "Spelling suggestions command"
  bool spell_as_you_type  0   0     1 Spelling -  "Enable spellcheck-as-you-type in input window."
  str  unix_browser_cmd "xdg-open %u" 0 40 HTTP U "Browser command"
  bool use_http_proxy     0   0     1 HTTP     -  "Use HTTP Proxy Server for web fetches"
  str  proxy_host        ""   0    40 HTTP     -  "Proxy host"
  int  proxy_port         0   0 65535 HTTP     -  "Proxy port"
  bool empty_web_cache    0   0     1 HTTP     -  "Empty the web cache on exit"
  bool hide_splash        0   0     1 Startup  -  "Don't display splash screen at startup"
  bool autoupdate_check   1   0     1 Startup  -  "Check net for updates on startup"
  bool startup_con_dlog   0   0     1 Startup  -  "Start up with connect dialog open"
  bool ssl_dont_auth      1   0     1 Connection -  "Don't authenticate SSL server certificates (insecure!)"
  int  keepalive_delay  600  15  7200 Connection -  "Delay in seconds between KeepAlives or pings"
  str  socks_host        ""   0    40 Connection -  "SOCKS 5 proxy host"
  int  socks_port         0   0 65535 Connection -  "SOCKS 5 proxy port"
  str  socks_user        ""   0    20 Connection -  "SOCKS 5 username"
  str  socks_pass        ""   0    20 Connection -  "SOCKS 5 password"
  bool enable_msp_sounds  1   0     1 MCP      -  "Enable MSP sound playing"
  bool show_mcp_traffic   0   0     1 MCP      -  "Show hidden Mud Client Protocol traffic"
  bool unix_editor_use    0   0     1 MCP      UD "Use external editor for MCP editing"
  str  unix_editor_cmd "xterm +sb -T %t -e vi %f" 0 40 MCP UD "External editor command"
  int  qbutton_minwidth  40   0   200 Misc     -  "Minimum QuickButton width in pixels"
  bool ask_confirmation   1   0     1 Misc     -  "Ask for confirmation when performing risky actions"
  int  lpprompt_delay     7   1   999 Misc     -  "Tenths of a second before deciding a partial line is complete"
  bool copy_on_select     0   0     1 Misc     -  "Copy to clipboard when selecting text"
  bool button2_paste      0   0     1 Misc     -  "Paste with middle button"
  bool save_position      1   0     1 Misc     -  "Save window position with preferences"
  bool show_qbuttons      1   0     1 {}       -  "Remembers quickbutton visibility setting"
  bool show_compass       1   0     1 {}       -  "Remembers compass visibility setting"
  multi startup_script   {}  {}    40 {}       -  "Startup script"
  str  version_warning  0.0   0    40 {}       -  "Remember TCL version warning number"
  bool autoup_firsttime   1   0     1 {}       -  "If first launch, ask about autoupdate."
  int  mac_dpi_corrected  0   0     1 {}       D  "Remember if we corrected fonts for the DPI on OS X."
  int  lastrun_version    0   0 99999 {}       -  "Remember last used Treb version."
  str  last_edit_mode "none"  0    40 {}       -  "Remember main window edit mode."
  str  last_sent_file    ""   0   128 -        -  "Remember pathname of last 'Sent' file."
  str  last_sent_prepend ""   0   128 -        -  "Remember prepend of last 'Sent' file."
  str  last_sent_append  ""   0   128 -        -  "Remember append of last 'Sent' file."
  str  last_sent_delay  0.0   0   128 -        -  "Remember delay of last 'Sent' file."
  str  last_sent_after   ""   0  1024 -        -  "Remember after command of last 'Sent' file."
  str  last_find_pattern ""   0   128 -        -  "Remember pattern of last find."
  str  last_find_direct "forwards" 0 128 -     -  "Remember direction of last find."
  bool last_find_nocase   0   0     1 -        -  "Remember case sensitivity of last find."
  bool last_find_regexp   0   0     1 -        -  "Remember pattern type of last find."
  bool send_keepalives    0   0     1 -        -  "OBSOLETE - NO LONGER USED"
}

if {[info exists env(TREB_MAC_DOCK_BOUNCE)]} {
    lappend treb_prefs_list \
        bool activity_notify    0   0     1 Display  D  "Bounce dock icon on activity when backgrounded"
} else {
    lappend treb_prefs_list \
        bool activity_notify    0   0     1 {}       D  "Bounce dock icon on activity when backgrounded"
}

if {[info commands snack::sound] == {}} {
    lappend treb_prefs_list \
        str  msp_sound_cmd  ""  0  40  MCP  -   "Sound player command"
}

proc prefs:init {} {
    global treb_prefs_list
    foreach {type name val min max tab oses caption} $treb_prefs_list {
        prefs:add $type $name $val $min $max $tab $oses $caption
    }
}

proc prefs:add {type name val min max tab oses caption} {
    upvar #0 trebuchet_preferences var
    if {![info exists var(namelist)]} {
        set var(namelist) {}
    }
    if {![info exists var(tablist)]} {
        set var(tablist) {}
    }
    if {![info exists var(tabitems,$tab)]} {
        set var(tabitems,$tab) {}
    }
    if {[lsearch -exact $var(namelist) $name] == -1} {
        lappend var(namelist) $name
    }
    if {[lsearch -exact $var(tablist) $tab] == -1} {
        lappend var(tablist) $tab
    }
    if {[lsearch -exact $var(tabitems,$tab) $name] == -1} {
        lappend var(tabitems,$tab) $name
    }
    set var(type,$name)    $type
    set var(value,$name)   $val
    set var(min,$name)     $min
    set var(max,$name)     $max
    set var(tab,$name)     $tab
    set var(oses,$name)    $oses
    set var(caption,$name) $caption
}

proc /prefs:exists {name} {
    upvar #0 trebuchet_preferences var
    if {[info exists var(value,$name)]} {
        return 1;
    }
    return 0;
}

proc /prefs:get {name} {
    upvar #0 trebuchet_preferences var
    if {![/prefs:exists $name]} {
        error "No such preference exists."
    } else {
        return $var(value,$name)
    }
}

proc /prefs:getvar {name} {
    if {![/prefs:exists $name]} {
        error "No such preference exists."
    } else {
        return "trebuchet_preferences(value,$name)"
    }
}

proc /prefs:set {name val} {
    upvar #0 trebuchet_preferences var
    global dirty_preferences
    if {![/prefs:exists $name]} {
        tk_messageBox -type ok -icon warning -title "Bad preference" -message "$name : Obsolete or non-existent preference setting. Ignored."
        set dirty_preferences 1
    } else {
        if {$var(type,$name) == "cust"} {
            return
        }
        set var(value,$name) $val
        if {$var(tab,$name) != "-"} {
            set dirty_preferences 1
        }
        if {$name == "menu_font_size"} {
            font configure default_system_font -size $val
        }
    }
    return
}

proc /prefs:list {{pattern *}} {
    upvar #0 trebuchet_preferences var
    set oot {}

    foreach name $var(namelist) {
        if {$name != "" &&
            $var(tab,$name) != "-" &&
            $var(type,$name) != "cust"
        } {
            if {$oot != ""} {
                append oot "\n"
            }
            append oot "/prefs:set [list $name] [list [/prefs:get $name]]"
        }
    }
    return $oot
}

tcl::OptProc /saveprefs {
    {-request      "If given, pop up a GUI dialog to choose the file to save to."}
    {-all          "If given, save all data types."}
    {-worlds       "If given, save Worlds data."}
    {-tools        "If given, save Tools data."}
    {-qbuttons     "If given, save Quickbuttons data."}
    {-macros       "If given, save Macros data."}
    {-hilites      "If given, save Hilites data."}
    {-styles       "If given, save Styles data."}
    {-keybinds     "If given, save Keyboard Bindings data."}
    {-configs      "If given, save general Trebuchet configuration data."}
    {?file?    {}  "The file to save the prefs in."}
} {
    global treb_save_file tcl_platform treb_prefs_dir treb_root_dir env
    if {!$worlds && !$tools && !$qbuttons && !$macros && !$hilites && !$styles && !$keybinds && !$configs} {
        set all 1
    }
    if {$all} {
        set worlds   1
        set tools    1
        set qbuttons 1
        set macros   1
        set hilites  1
        set styles   1
        set keybinds 1
        set configs  1
    }
    if {$request} {
        set filetypes {
            {{Trebuchet Config Files} {.trc}    TEXT}
            {{Text Files}             {.txt}    TEXT}
            {{All Files}              *             }
        }
        set defaultfile "TrebConfig"
        set defaultext "trc"
        set file [tk_getSaveFile -defaultextension .$defaultext \
                    -initialfile $defaultfile.$defaultext \
                    -title {Export configuration to file} \
                    -filetypes $filetypes]
        if {$file == ""} {
            return ""
        }
    }
    set store_in_reg 0
    set key "HKEY_CURRENT_USER\\Software\\Fuzzball Software\\Trebuchet Tk\\1.0"
    if {$file == {}} {
        if {$tcl_platform(platform) == "windows"} {
            package require registry 1.0
            if {[catch {registry get $key "prefsfile"} file]} {
                set file $treb_save_file
            }
        } else {
            set file $treb_save_file
        }
        while {1} {
            if {$file == ""} {
                set initdir $treb_prefs_dir
                if {[info exists env(HOME)]} {
                    set initdir $env(HOME)
                } elseif {$tcl_platform(platform) == "windows"} {
                    if {[file isdirectory "C:\\My Documents"]} {
                        set initdir "C:\\My Documents"
                    } else {
                        set initdir $treb_root_dir
                    }
                } else {
                    set initdir $treb_root_dir
                }
                set file "${initdir}\\trebprefs.trc"
                set dir [file dirname $file]
            } else {
                set dir [file dirname $file]
                if {![file isdirectory $dir]} {
                    tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                        -message "The directory '$dir' does not exist."
                } elseif {![file writable $dir]} {
                    tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                        -message "You do not have permission to write to the directory '$dir'.  You will need to save your prefs to a different directory or, fix the directory permissions."
                } elseif {[file exists $file] && ![file writable $file]} {
                    tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                        -message "You do not have permission to write to the file '$file'.  You will need to save your prefs to a different file, or fix the file permissions."
                } else {
                    set treb_save_file $file
                    break
                }
            }
            set file [tk_getSaveFile -defaultextension .trc -initialdir $dir \
                        -title "Save preferences as" \
                        -filetypes {{{Trebuchet Preference Files} {.trc} }} \
                        -initialfile "trebpref.trc"]
            if {$file == ""} {
                return ""
            }
            
            set store_in_reg 1
        }
    }
    if {[catch {set f [open $file.tmp w 0600]} errMsg]} {
        error "/saveprefs: $errMsg"
        return ""
    }
    set errval [catch {
        if {$file == $treb_save_file} {
            puts $f "# Automatically generated on [clock format [clock seconds]]."
            puts $f "# Do not make changes to this file, they will be lost.  Make the changes in"
            puts $f "# Trebuchet, or add lines to trebuche.trc\n"
        }

        if {$configs && [/prefs:get save_position]} {
            puts $f "# Window geometry follows."
            puts $f "/geometry:set [/geometry:get]\n"
            puts $f "/inbuf:setsize [/inbuf:getsize]\n"
            flush $f
        }

        if {$keybinds} {
            puts $f "# Bindings follow."
            puts $f "[/bind list]\n"
            flush $f
        }

        if {$tools} {
            puts $f "# Tools follow."
            puts $f "[/tool list]\n"
            flush $f
        }

        if {$styles} {
            puts $f "# Styles follow."
            puts $f "[/style list]\n"
            flush $f
        }

        if {$hilites} {
            puts $f "# Hilites and Triggers follow."
            puts $f "[/hilite list]\n"
            flush $f
        }

        if {$macros} {
            puts $f "# Macros follow."
            puts $f "[/macro list]\n"
            flush $f
        }

        if {$qbuttons} {
            puts $f "# QuickButtons follow."
            puts $f "[/qbutton list]\n"
            flush $f
        }

        if {$worlds} {
            puts $f "# Worlds follow."
            puts $f "[/world list]\n"
            flush $f
        }

        if {$configs} {
            puts $f "# Misc. preference settings follow."
            puts $f "[/prefs:list]\n"
            flush $f
        }
    } errMsg]

    flush $f
    close $f

    if {$errval} {
        file delete -force -- $file.tmp
        error "/saveprefs: $errMsg"
        return ""
    } else {
        file rename -force -- $file.tmp $file
        if {$store_in_reg} {
            registry set $key "prefsfile" $treb_save_file
        }
    }
    global dirty_preferences
    set dirty_preferences 0
    /statbar 5 "Preferences saved!"
    return ""
}


proc /jump {args} {
    if {[llength $args] > 1} {
        error "/jump: usage is /jump \[on/off\]"
    }
    if {[llength $args] == 0} {
        if {[/prefs:get jumpscroll_flag]} {
            return "on"
        } else {
            return "off"
        }
    }
    switch -exact -- [lindex $args 0] {
        on {
            /prefs:set jumpscroll_flag 1
        }
        off {
            /prefs:set jumpscroll_flag 0
        }
        default {
            error "/jump: usage is /jump \[on/off\]"
        }
    }
    return ""
}


proc /more {args} {
    if {[llength $args] > 1} {
        error "/more: usage is /more \[on/off\]"
    }
    if {[llength $args] == 0} {
        if {[/prefs:get pager_flag]} {
            return "on"
        } else {
            return "off"
        }
    }
    switch -exact -- [lindex $args 0] {
        on {
            /prefs:set pager_flag 1
        }
        off {
            /prefs:set pager_flag 0
        }
        default {
            error "/more: usage is /more \[on/off\]"
        }
    }
    return ""
}

global bell_count; set bell_count 0
global bell_event; set bell_event ""

proc bell:ring {} {
    if {[/prefs:get bell_audible]} {
        set beep_command [/prefs:get unix_beep_cmd]
        if {$beep_command != ""} {
            if {[catch "exec $beep_command"]} {
                bell
            }
        } else {
            bell
        }
    } else {
        set display [/display]
        set oldcolor [$display cget -background]
        set oldnormbg [$display tag cget normal -background]
        $display configure -background white
        $display tag configure normal -background white
        update idletasks
        $display configure -background black
        $display tag configure normal -background black
        update idletasks
        $display configure -background $oldcolor
        $display tag configure normal -background $oldnormbg
    }
}

proc bell:repeat {} {
    global bell_count
    global bell_event
    set bell_event ""
    if {$bell_count > 0} {
        bell:ring
        incr bell_count -1
        set bell_event [after 200 bell:repeat]
    }
}

proc /bell {args} {
    global bell_count
    global bell_event

    set count [lindex $args 0]
    if {[llength $args] > 1} {
        error "/bell: Too many arguments!"
    }
    if {$count == "off"} {
        /prefs:set bell_audible 0
    } elseif {$count == "on"} {
        /prefs:set bell_audible 1
    } elseif {$count == "get"} {
        if {[/prefs:get bell_audible]} {
            return "on"
        } else {
            return "off"
        }
    } elseif {$count == ""} {
        incr bell_count 1
        if {$bell_event == ""} {
            bell:repeat
        }
    } else {
        incr bell_count $count
        if {$bell_event == ""} {
            bell:repeat
        }
    }
    return ""
}



proc prefs:mkpage {w page} {
    upvar #0 trebuchet_preferences var
    global TrebPrefs
    global tcl_platform

    set master [winfo parent [winfo parent $w]]
    grid columnconfig $w  0 -minsize 25
    grid columnconfig $w 99 -minsize 25 -weight 1
    grid rowconfig $w  0 -minsize 25
    grid rowconfig $w 99 -minsize 25 -weight 1

    set row 1
    set prevspacing {}
    set spacing 25
    set quantum 30

    foreach name $var(tabitems,$page) {
        set TrebPrefs($master,$name) $var(value,$name)
        set prevspacing $spacing
        set oses $var(oses,$name)

        if {$oses != "-"} {
            switch -exact $tcl_platform(platform) {
                unix {
                    if {$tcl_platform(os) == "Darwin"} {
                        if {[string first "D" $oses] == -1} {
                            continue
                        }
                    } else {
                        if {[string first "U" $oses] == -1} {
                            continue
                        }
                    }
                }
                windows {
                    if {[string first "W" $oses] == -1} {
                        continue
                    }
                }
                mac {
                    if {[string first "M" $oses] == -1} {
                        continue
                    }
                }
                Darwin {
                    if {[string first "D" $oses] == -1} {
                        continue
                    }
                }
            }
        }

        switch -exact $var(type,$name) {
            cust {
                set cmd $var(value,$name)
                append cmd " "
                append cmd $w.$name
                eval $cmd
                set spacing 0
            }
            bool {
                checkbutton $w.$name \
                        -text $var(caption,$name) \
                        -variable TrebPrefs($master,$name) \
                        -command "prefs:dirty $master" \
                        -offvalue $var(min,$name) \
                        -onvalue $var(max,$name)
                set spacing 5
            }
            int {
                set width [string length $var(min,$name)]
                if {$width < [string length $var(max,$name)]} {
                    set width [string length $var(max,$name)]
                }
                frame $w.$name -relief flat -borderwidth 0
                label $w.$name.l -text $var(caption,$name) \
                        -relief flat -borderwidth 0 -anchor w
                spinner $w.$name.s \
                        -variable TrebPrefs($master,$name) \
                        -value $TrebPrefs($master,$name) \
                        -command "prefs:dirty $master" \
                        -min $var(min,$name) -max $var(max,$name) \
                        -width $width

                set font [$w.$name.l cget -font]
                set width [font measure $font $var(caption,$name)]
                set width [expr {$quantum * (1 + int(($width+5) / $quantum))}]

                grid columnconfig $w.$name 0 -weight 0 -minsize $width
                grid columnconfig $w.$name 1 -weight 1
                grid $w.$name.l -row 0 -column 0 -sticky w
                grid $w.$name.s -row 0 -column 1 -sticky ew
                set spacing 0
            }
            str {
                set width [string length $var(min,$name)]
                if {$width < [string length $var(max,$name)]} {
                    set width [string length $var(max,$name)]
                }
                frame $w.$name -relief flat -borderwidth 0
                label $w.$name.l -text $var(caption,$name) \
                        -relief flat -borderwidth 0 -anchor w
                entry $w.$name.e \
                        -width $var(max,$name) \
                        -textvariable TrebPrefs($master,$name)
                bind $w.$name.e <Key> "+prefs:dirty $master"

                set font [$w.$name.l cget -font]
                set width [font measure $font $var(caption,$name)]
                set width [expr {$quantum * (1 + int(($width+5) / $quantum))}]

                grid columnconfig $w.$name 0 -weight 0 -minsize $width
                grid columnconfig $w.$name 1 -weight 1
                grid $w.$name.l -row 0 -column 0 -sticky w
                grid $w.$name.e -row 0 -column 1 -sticky ew
                set spacing 0
            }
            multi {
                button $w.$name -text $var(caption,$name) -command "
                    /textdlog -modal -buttons -width 60 -height 12 -nowrap \
                        -autoindent -title [list $var(caption,$name)] \
                        -text \$TrebPrefs($master,$name) \
                        -variable TrebPrefs($master,$name)
                    prefs:dirty $master
                "
                set spacing 0
            }
            default {
                error "Bad preference value type.  Must be 'bool', 'int', 'str' or 'multi'."
            }
        }
        grid $w.$name -column 1 -row $row -sticky w
        set divspace [expr {15 - $spacing - $prevspacing}]
        if {$divspace < 0} {
            set divspace 0
        }
        if {$row > 1} {
            grid rowconfig $w [expr {$row - 1}] -minsize $divspace
        }
        incr row 2
    }
}


proc prefs:mkcust_fontsedit {w} {
    global TrebPrefs

    set fontcont [groupbox $w -text "Standard Fonts and Colors"]
    button $fontcont.normal  -width 15 -text "Set Normal" -command "/style:edit normal"
    button $fontcont.hilite  -width 15 -text "Set Hilite" -command "/style:edit hilite"
    button $fontcont.error   -width 15 -text "Set Error"  -command "/style:edit error"
    button $fontcont.results -width 15 -text "Set Result" -command "/style:edit results"

    grid columnconfig $fontcont 0 -minsize 15 -weight 1
    grid columnconfig $fontcont 2 -minsize 15
    grid columnconfig $fontcont 4 -minsize 15 -weight 1
    grid rowconfig $fontcont 0 -minsize 10 -weight 1
    grid rowconfig $fontcont 2 -minsize 10
    grid rowconfig $fontcont 4 -minsize 10 -weight 1

    grid $fontcont.normal  -row 1 -column 1 -sticky nsew
    grid $fontcont.hilite  -row 1 -column 3 -sticky nsew
    grid $fontcont.error   -row 3 -column 1 -sticky nsew
    grid $fontcont.results -row 3 -column 3 -sticky nsew
}


proc prefs:mkcust_fontresize {w} {
    set resizecont [groupbox $w -text "Resize All Fonts/Styles"]
    button $resizecont.smaller -width 15 -text "Smaller" -command "/style:resizeall -10"
    button $resizecont.larger  -width 15 -text "Larger"  -command "/style:resizeall 10"

    grid columnconfig $resizecont 0 -minsize 15 -weight 1
    grid columnconfig $resizecont 2 -minsize 15
    grid columnconfig $resizecont 4 -minsize 15 -weight 1
    grid rowconfig $resizecont 0 -minsize 10 -weight 1
    grid rowconfig $resizecont 2 -minsize 10 -weight 1

    grid $resizecont.smaller -row 1 -column 1 -sticky nsew
    grid $resizecont.larger  -row 1 -column 3 -sticky nsew
}


proc prefs:apply {w} {
    global TrebPrefs
    upvar #0 trebuchet_preferences var
    foreach name $var(namelist) {
        if {$var(tab,$name) != {} && $var(tab,$name) != "-"} {
            /prefs:set $name $TrebPrefs($w,$name)
        }
    }

    # FIXME: The following really should use some generic callback mechanism.
    style:ansi_fix_all

    if {[$w.apply cget -state] != "disabled"} {
        global dirty_preferences; set dirty_preferences 1
        $w.apply config -state disabled
    }
}


proc prefs:dirty {w} {
    if {[winfo exists $w]} {
        $w.apply config -state normal
    }
}

proc prefs:close {w} {
    destroy $w
}


proc /prefs:edit {} {
    set base .mw.prefs
    if {[winfo exists $base]} {
        wm deiconify $base
        focus $base
    } else {
        set parent [focus]
        if {$parent != {}} {
            set parent [winfo toplevel $parent]
        }

        toplevel $base
        wm resizable $base 0 0
        wm protocol $base WM_DELETE_WINDOW "$base.cancel invoke"
        wm title $base "Preferences"

        place_window_default $base $parent

        upvar #0 trebuchet_preferences var
        set nb $base.nb

        notebook $nb

        foreach tabname $var(tablist) {
            if {$tabname != {} && $tabname != "-"} {
                set pwidget [$nb addpage $tabname]
                prefs:mkpage $pwidget $tabname
            }
        }

        button $base.ok     -text Ok     -width 10 \
                -command "prefs:apply $base ; prefs:close $base" -default active
        button $base.cancel -text Cancel -width 10 \
                -command "prefs:close $base"
        button $base.apply  -text Apply  -width 10 \
                -command "prefs:apply $base" -state disabled


        grid columnconfig $base 0 -minsize 15
        grid columnconfig $base 1 -minsize 5 -weight 1
        grid columnconfig $base 2 -minsize 5
        grid columnconfig $base 4 -minsize 10
        grid columnconfig $base 6 -minsize 10
        grid columnconfig $base 8 -minsize 15

        grid rowconfig $base 0 -minsize 15
        grid rowconfig $base 1 -minsize 5 -weight 1
        grid rowconfig $base 2 -minsize 10
        grid rowconfig $base 4 -minsize 15

        grid $nb -row 1 -column 1 -columnspan 7 -sticky nsew
        grid $base.ok     -row 3 -column 3 -sticky nsew
        grid $base.cancel -row 3 -column 5 -sticky nsew
        grid $base.apply  -row 3 -column 7 -sticky nsew

        bind $base <Key-Escape> "$base.cancel invoke"
        bind $base <Key-Return> "$base.ok invoke"
        $nb raise "Fonts"

        focus $base.ok
    }
}

if {$tcl_platform(winsys) == "aqua"} {
    namespace eval ::tk::mac {
        proc ShowPreferences {} {
            /prefs:edit
        }
    }
}

