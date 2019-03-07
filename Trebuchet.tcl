#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

#############################################################################
#
# Trebuchet Tk
# copyright 1997-2016 by Fuzzball Software
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#############################################################################

package require opt
catch { package require Img }
catch { package require sound }
catch { package require griffin }

#################################
# GLOBAL VARIABLES
#
global treb_revision; set treb_revision 1081
global treb_version; set treb_version "1.[format %03d [expr {$treb_revision - 1000}]]"
global treb_name; set treb_name "Trebuchet Tk"
global wordchars; set wordchars {-A-Za-z0-9_\'\\.}
global wordchar; set wordchar "\[$wordchars\]"
global nonwordchar; set nonwordchar "\[^$wordchars\]"

set domain_chars {[a-z0-9_.-]}
set domain_start "\[a-z0-9_-\]$domain_chars*\[a-z0-9_-\]"
set domain_end {\.[a-z][a-z]+}
set url_end {[^() ]*[a-z0-9_/]}
set ftp_regexp "ftp://$url_end|ftp\\.$url_end"
set web_regexp "http://$url_end"
append web_regexp "|$domain_start\\.$domain_start$domain_end"
append web_regexp "|$domain_start\\.$domain_start$domain_end$url_end"
append web_regexp "|$domain_start\\.$domain_start$domain_end\[\[:>:\]\]"
append web_regexp "|$domain_start\\.$domain_start$domain_end\[\[:>:\]\]$url_end"
append web_regexp "|\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+"
append web_regexp "|\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+$url_end"
append web_regexp "|\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\[\[:>:\]\]"
append web_regexp "|\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\\.\[\\d\]+\[\[:>:\]\]$url_end"
set web2_regexp "https://$url_end"
set rtsp_regexp "rtsp://$url_end"
set mail_regexp "mailto:\[a-z0-9_+.-\]*\[a-z0-9\]@\[a-z0-9\]$domain_chars*$domain_end\[^ \"\]*"
set mail_regexp2 "\[a-z0-9_+.-\]*\[a-z0-9\]@$domain_start$domain_end"
global url_regexp
set url_regexp "$ftp_regexp|$web_regexp|$web2_regexp|$mail_regexp|$mail_regexp2|$rtsp_regexp"

global errors_nonfatal; set errors_nonfatal 0
global cmdhist; set cmdhist {}
global cmdhistnum; set cmdhistnum -1
global defpri; set defpri {10}
global mpid; set mpid 1
global dirty_preferences; set dirty_preferences 0
global styleslist; set styleslist {}
global forcedelete; set forcedelete 0
global widget; 
    set widget(bars)      {.mw.bars}
    set widget(compass)   {.mw.bars.compass}
    set widget(qbuttons)  {.mw.bars.qbuttons}
    set widget(disp)      {.mw.top.disp}
    set widget(backdrop)  {.mw.top.disp.backdrop}
    set widget(worldsbar) {.mw.top.worlds}
    set widget(inbuf)     {.mw.bot.inbuf}
    set widget(statbar)   {.mw.top.status}
    set widget(loglight)  {.mw.statusbar.log}
global treb_colors

#################################

proc find_windows_prefsfile {} {
    global treb_prefs_dir treb_root_dir treb_save_file

    set treb_save_file {}
    package require registry 1.0
    set key "HKEY_CURRENT_USER\\Software\\Fuzzball Software\\Trebuchet Tk\\1.0"
    if {![catch {registry get $key "prefsfile"} file]} {
        if {[file isfile $file]} {
            if {[file readable $file]} {
                set treb_save_file $file
                return ""
            } else {
                tk_messageBox -type "ok" -title "Preferences File Unreadable" \
                    -message "The file '$file' isn't readable.  Please specify a different file, or fix the permissions."
            }
        }
    } else {
        # No registry entry.  Probably first time run on this machine.
        return ""
    }

    # Prefs file was moved or is now unreadable.
    set filetypes {
        {{Trebuchet Preferences Files}       {.trc}    TEXT}
    }
    set initdir $treb_prefs_dir
    set initfile "trebprefs.trc"
    if {$file != "" && [file isfile $file]} {
        set initdir [file dirname $file]
        set initfile [file tail $file]
    } elseif {[file isfile [file join $treb_root_dir "trebpref.trc"]]} {
        set initdir $treb_root_dir
    }
    while (1) {
        set dofind [tk_messageBox -title {Trebuchet Preferences File} \
                        -message "Unable to open Trebuchet's preferences file.  Would you like to specify its location?" \
                        -type yesno -icon warning -default "no"]

        if {$dofind == "no"} {
            catch {registry delete $key "prefsfile"}
            set treb_save_file {}
            return ""
        }

        set treb_save_file [tk_getOpenFile -defaultextension .trc \
                                -initialdir $initdir \
                                -initialfile "trebpref.trc" \
                                -title {Specify Trebuchet Preferences File} \
                                -filetypes $filetypes]

        if {$treb_save_file != ""} {
            set dir [file dirname $treb_save_file]
            if {![file isdirectory $dir]} {
                tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                    -message "The directory '$dir' does not exist."
            } elseif {![file writable $dir]} {
                tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                    -message "You do not have permission to write to the directory '$dir'.  You will need to save your prefs to a different directory or, fix the directory permissions."
            } elseif {![file readable $treb_save_file]} {
                tk_messageBox -type "ok" -title "Preferences File Unreadable" \
                    -message "The file '$file' isn't readable.  Please specify a different file, or fix the permissions."
            } elseif {![file writable $treb_save_file]} {
                tk_messageBox -type "ok" -title "Preferences File Unwritable" \
                    -message "You do not have permission to write to the file '$file'.  You will need to save your prefs to a different file, later, or fix the file permissions."
            } else {
                registry set $key "prefsfile" $treb_save_file
                return ""
            }
        }
    }
}


proc /clock_clicks {} {
    if {![catch {clock clicks -milliseconds} millis]} {
        return $millis
    } else {
        return [clock clicks]
    }
}

proc calculate_clicks_per_second {} {
    global clicks_per_second

    if {![catch {clock clicks -milliseconds}]} {
        set clicks_per_second 1000
    } else {
        set now [clock seconds]
        while {$now == [clock seconds]} {
            set sclick [clock clicks]
        }
        set now [clock seconds]
        while {$now == [clock seconds]} {
            set eclick [clock clicks]
        }
        set clicks_per_second [expr {$eclick - $sclick}]
    }
}

proc timetest {args} {
    global clicks_per_second
    set st [/clock_clicks]
    set result [uplevel 1 $args]
    set en [/clock_clicks]
    set secs [expr {int((($en-$st)*1000.0)/($clicks_per_second*1.0))}]
    /echo -style results [format "%5d ms:  %s" $secs $args]
    return $result
}


proc init {argc argv} {
    global tcl_platform tcl_version
    global treb_colors treb_save_file
    global treb_root_dir treb_lib_dir
    global treb_docs_dir treb_document_dir
    global treb_tool_dir treb_temp_dir
    global treb_cacerts_dir treb_prefs_dir
    global argv0 env treb_fonts

    set tclpatchlevel [info patchlevel]
    set pattern {^([0-9][0-9]*)[^0-9]([0-9][0-9]*)([^0-9])([0-9][0-9]*)}
    regexp $pattern $tclpatchlevel dummy vermajor verminor separ patchlevel
    if {$separ != "."} {
        set patchlevel 0
    }
    set tcl_platform(vermajor) $vermajor
    set tcl_platform(verminor) $verminor
    set tcl_platform(patchlevel) $patchlevel

    if {[catch {tk windowingsystem} winsys]} {
        if {$tcl_platform(os) == "Darwin"} {
            set winsys "aqua"
        } elseif {$tcl_platform(platform) == "windows"} {
            set winsys "win32"
        } elseif {$tcl_platform(platform) == "macintosh"} {
            set winsys "classic"
        } else {
            set winsys "x11"
        }
    }
    set tcl_platform(winsys) $winsys

    if {[info exists env(TREB_ROOT_DIR)]} {
        set treb_root_dir $env(TREB_ROOT_DIR)
    } elseif {$argv0 != {}} {
        set myexec $argv0

        # Make sure we find the REAL Trebuchet.tcl, and not a softlink.
        while {![catch {file readlink $myexec}]} {
            set myexec [file join \
                [file dirname $myexec] \
                [file readlink $myexec]]
        }

        # The root trebuchet dir is the dir that Trebuchet.tcl is in.
        set treb_root_dir [file dirname $myexec]
        if {$myexec == "Trebuchet.tcl"} {
            set treb_root_dir ""
        } elseif {$tcl_platform(winsys) == "aqua"} {
            set treb_root_dir [file join $treb_root_dir .. .. .. trebuchet]
        }
    } else {
        tk_messageBox -default ok -type ok -icon error \
            -title {Trebuchet error} -message "Trebuchet was unable to find its libraries.\nYou may need to set your TREB_ROOT_DIR environment variable."
        exit
    }

    if {$tcl_platform(os) == "Darwin"} {
        # The "correct" place for document files on the mac (OS X)
        # is in ~/Library/Preferences folder
        set treb_document_dir [file join $env(HOME) Documents]
    } elseif {$tcl_platform(platform) == "macintosh"} {
        # The "correct" place for document files on the mac (OS 9)
        # is in the application's directory.
        set treb_document_dir $env(HOME)
    } elseif {[info exists env(HOME)]} {
        # For Windows and Unix, use the user's home dir.
        set treb_document_dir $env(HOME)
        if {![file exists $treb_document_dir]} {
            set treb_document_dir $treb_root_dir
        }
    } else {
        set treb_document_dir $treb_root_dir
    }

    if {$tcl_platform(os) == "Darwin"} {
        # The "correct" place for preferences files on the mac (OS X)
        # is in ~/Library/Preferences folder
        set treb_prefs_dir [file join $env(HOME) Library Preferences]
    } elseif {$tcl_platform(platform) == "macintosh"} {
        # The "correct" place for preferences files on the mac (OS 9)
        # is in the preferences folder
        set treb_prefs_dir $env(PREF_FOLDER)
    } elseif {[info exists env(HOME)]} {
        set treb_prefs_dir $env(HOME)
        if {$tcl_platform(platform) == "windows"} {
            if {![file exists $treb_prefs_dir]} {
                set treb_prefs_dir $treb_root_dir
            }
        }
    } else {
        set treb_prefs_dir $treb_root_dir
    }

    set treb_lib_dir [file join $treb_root_dir lib]
    set treb_docs_dir [file join $treb_root_dir docs]
    set treb_tool_dir [file join $treb_root_dir pkgs]

# Windows Tk (8.3.3) generally gets 96 DPI.
# Linux Tk (8.3.3) uses the DPI the X server tells it, usually misconfigured.
# OS X Aqua Tk (8.4.4) is hardcoded to 72 DPI, regardless of what the OS says.
# Grrr.

    if {$tcl_platform(winsys) == "aqua"} {
        # Because OS X assumes 72 DPI, and windows usually assumes 96,
        # Lets scale OS X fonts to match the Windows size, so folks
        # can swap between machines using the same prefs.
        tk scaling 1.3333333333333
    }

    label .fontcheck
    array set tmp_font [font actual [lrange [.fontcheck cget -font] 0 1]]
    set sansfont [list $tmp_font(-family) $tmp_font(-size)]
    set sansh [font metrics $sansfont -linespace]
    if {[font metrics $sansfont -fixed]} {
        array set tmp_font [font actual [list Helvetica -$sansh]]
        set sansfont [list $tmp_font(-family) $tmp_font(-size)]
    }
    set treb_fonts(sansserif) $sansfont
    set small_size [expr {int(0.8*$tmp_font(-size))}]
    if {$small_size < 8} {
        set small_size 8
    }
    array set tmp_font [font actual [list $tmp_font(-family) $small_size]]
    set bbarfont [list $tmp_font(-family) $tmp_font(-size)]
    set treb_fonts(bbar) $bbarfont
    destroy .fontcheck
    unset tmp_font

    text .fontcheck
    array set tmp_font [font actual [lrange [.fontcheck cget -font] 0 1]]
    set fixedfont [list $tmp_font(-family) $tmp_font(-size)]
    # set fixedh [font metrics $fixedfont -linespace]
    set fixedh $tmp_font(-size)
    if {![font metrics $fixedfont -fixed]} {
        array set tmp_font [font actual [list Courier $fixedh]]
        set fixedfont [list $tmp_font(-family) $tmp_font(-size)]
    }
    set treb_fonts(fixed) $fixedfont
    destroy .fontcheck
    unset tmp_font

    array set tmp_font [font actual [list Times -$sansh]]
    set treb_fonts(serif) [list $tmp_font(-family) $tmp_font(-size)]
    unset tmp_font

    array set tmp_font [font actual [concat $treb_fonts(sansserif) bold underline]]
    set treb_fonts(url) [list $tmp_font(-family) $tmp_font(-size) bold underline]
    unset tmp_font

    set treb_fonts(worldbar) $treb_fonts(sansserif)
    if {$tcl_platform(winsys) == "aqua"} {
        set treb_fonts(worldbar) $treb_fonts(bbar)
    }

    if {[lsearch -exact $argv "--tkshell"] != -1} {
        return
    }

    source [file join $treb_lib_dir webview.tcl]

    if {($vermajor != 8 || $verminor < 3)} {
        set mesg "Trebuchet Tk requires TCL/Tk version 8.3 or later to run."
        if {$tcl_platform(winsys) == "x11"} {
            append mesg "\nPlease fetch and install the latest TCL/Tk 8 interpreter for your operating system."
        } else {
            append mesg "\nPlease fetch and install the latest version of Trebuchet from:"
        }
        set tclurl "https://sourceforge.net/projects/trebuchet/"
        label .icon -bitmap error -foreground red
        label .text -text $mesg -anchor sw -justify left -font $treb_fonts(sansserif)
        label .url -text $tclurl -anchor nw -justify left -foreground blue -font $treb_fonts(url) -cursor hand2
        button .btn -text Okay -command exit
        bind .url <ButtonPress-1> "
                .url config -foreground red
                /web_view [list $tclurl]
                after 250 .url config -foreground blue
            "
        pack .btn -side bottom -anchor s -padx 10 -pady 10
        pack .icon -side left -anchor w -padx 10 -pady 10
        pack .text -side top -anchor w -expand 1 -fill x -padx 10 -pady 5
        if {$tcl_platform(winsys) != "x11"} {
            pack .url -side top -anchor nw -expand 1 -fill both -padx 10 -pady 0
        }
        wm title . "TCL Version Error"
        bell
        vwait tcl_version
        exit
    }

    wm withdraw .
    global treb_web_cache_dir
    global treb_web_cache_map
    if {$tcl_platform(platform) == "unix"} {
        set treb_web_cache_dir [file join $treb_prefs_dir .trebtk-web-cache]
    } else {
        set treb_web_cache_dir [file join $treb_prefs_dir trebcache]
    }
    if {![file exists $treb_web_cache_dir]} {
        file mkdir $treb_web_cache_dir
    }
    global treb_web_cache_index
    set treb_web_cache_index [file join $treb_web_cache_dir index]
    if {[file exists $treb_web_cache_index]} {
        set f [open $treb_web_cache_index "r"]
        set map_version [gets $f]
        switch -exact $map_version {
            "1" { array set treb_web_cache_map [read $f] }
        }
        close $f
    }

    switch -exact -- $tcl_platform(winsys) {
        win32 {
            set treb_colors(buttonface) systemButtonFace
            set treb_colors(window)     systemWindow
            set treb_colors(windowtext) systemWindowText

            if {[catch {event add <<ContextMenu>> <Button-3> <Key-App>}]} {
                event add <<ContextMenu>> <Button-3>
            }
            bind Text <ButtonRelease-1> {+
                if {[/prefs:get copy_on_select]} {
                    event generate %W <<Copy>>
                }
            }
            bind Text <ButtonPress-2> {+
                if {[/prefs:get button2_paste]} {
                    catch {event delete <<PasteSelection>>}
                    event generate %W <<PasteAt>> -x %x -y %y
                    break
                }
            }
            event add <<Cut>>   <Control-Key-x> <Shift-Key-Delete>
            event add <<Copy>>  <Control-Key-c> <Control-Key-Insert>
            event add <<Paste>> <Control-Key-v> <Shift-Key-Insert>
            event add <<SelectAll>> <Control-Shift-Key-A> 
        }
        aqua {
            set treb_colors(buttonface) systemButtonFace
            set treb_colors(window)     systemWindowBody
            set treb_colors(windowtext) #000000
            event add <<Cut>>       <Command-Key-x> 
            event add <<Copy>>      <Command-Key-c> 
            event add <<Paste>>     <Command-Key-v> 
            event add <<SelectAll>> <Command-Key-a> 
            bind Text <Button-2> {}
            bind Text <Control-Button-1> {}
            event add <<ContextMenu>> <Control-Button-1> <Button-2>
            if {![info exists env(TREB_MAC_THEME_FIX)]} {
                tk_setPalette $treb_colors(window)
                option add "*Text*background" "white" 60
                option add "*Entry*background" "white" 60
                option add "*Listbox*background" "white" 60
                option add "*Listbox*selectBackground" "#cfcfff" 60
                option add "*Checkbutton*highlightColor" "#cfcfff" 60
                option add "*Text*relief" "sunken" widgetDefault
                option add "*Entry*relief" "sunken" widgetDefault
                option add "*Text*borderWidth" 2 widgetDefault
                option add "*Text*highlightThickness" 1 widgetDefault
                option add "*Entry*highlightThickness" 1 widgetDefault
                option add "*Checkbutton*highlightThickness" 1 widgetDefault
            }
            catch {event delete <<PasteSelection>>}
            # Workaround for a Tk8.4a4 bug on mac.
            catch {namespace eval tk set Priv(repeated) 0}
        }
        default {
            set treb_colors(buttonface) [. cget -bg]
            option add *HighlightBackground [. cget -bg]

            entry .flee
            set treb_colors(window)     [.flee cget -bg]
            set treb_colors(windowtext) [.flee cget -fg]
            destroy .flee

            if {[catch {event add <<ContextMenu>> <Button-3> <Key-App>}]} {
                event add <<ContextMenu>> <Button-3>
            }

            bind Text <ButtonRelease-1> {+
                if {[/prefs:get copy_on_select]} {
                    event generate %W <<Copy>>
                }
            }
            bind Text <ButtonPress-2> {+
                if {[/prefs:get button2_paste]} {
                    catch {event delete <<PasteSelection>>}
                    event generate %W <<PasteAt>> -x %x -y %y
                    break
                } else {
                    catch {event add <<PasteSelection>> <ButtonRelease-2>}
                }
            }

            bind Text <Control-Key-v> {}
            event add <<Cut>>   <Control-Key-x> 
            event add <<Copy>>  <Control-Key-c> 
            event add <<Paste>> <Control-Key-v> 
            event add <<SelectAll>> <Control-Shift-Key-A> 

            bind Text    <Button-4> {%W yview scroll -4 units}
            bind Text    <Button-5> {%W yview scroll  4 units}
            bind Listbox <Button-4> {%W yview scroll -4 units}
            bind Listbox <Button-5> {%W yview scroll  4 units}
            bind Canvas  <Button-4> {%W yview scroll -4 units}
            bind Canvas  <Button-5> {%W yview scroll  4 units}
        }
    }

    switch -glob -- $tcl_platform(os) {
        Win* {
            find_windows_prefsfile

            if {[info exists env(TEMP)]} {
                set treb_temp_dir $env(TEMP)
            } else {
                set treb_temp_dir $treb_root_dir
            }
        }
        Darwin* -
        Mac* {
            set treb_save_file [file join $treb_prefs_dir "Trebuchet Data"]
            set treb_temp_dir $treb_root_dir
        }
        default {
            set treb_save_file [file join $treb_prefs_dir ".trebtkrc"]
            set treb_temp_dir "/tmp"
        }
    }

    catch {
        bind Text <MouseWheel> {
            if {%D > 0} {
                %W yview scroll -4 units
            } else {
                %W yview scroll 4 units
            }
        }
        bind Listbox <MouseWheel> {
            if {%D > 0} {
                %W yview scroll -4 units
            } else {
                %W yview scroll 4 units
            }
        }
        bind Canvas <MouseWheel> {
            if {%D > 0} {
                %W yview scroll -4 units
            } else {
                %W yview scroll 4 units
            }
        }
    }

    bind Listbox <Key> {gdm:ListBox:Keypress %W %K %A ; break}
    bind Listbox <Key-Shift_L> {continue}
    bind Listbox <Key-Shift_R> {continue}
    bind Listbox <Key-Control_L> {continue}
    bind Listbox <Key-Control_R> {continue}
    bind Listbox <Key-Alt_L> {continue}
    bind Listbox <Key-Alt_R> {continue}
    bind Listbox <Alt-Key> {continue}
    bind Listbox <Key-Tab> {continue}
    bind Listbox <Shift-Key-Tab> {continue}
    bind Listbox <Control-Key-Tab> {continue}
    bind Listbox <Control-Shift-Key-Tab> {continue}

    bind Text <<Beep>> {/bell ; break}
    event add <<Beep>> <Control-Key-g>

    bind Text <<Cut>> {editCut %W ; break}
    bind Text <<Copy>> {editCopy %W ; break}
    bind Text <<Paste>> {editPaste %W ; break}
    bind Text <<PasteAt>> {editPasteAt %W %x %y ; break}
    bind Text <<SelectAll>> {editSelectAll %W ; break}

    bind Entry <<Cut>> {editCut %W ; break}
    bind Entry <<Copy>> {editCopy %W ; break}
    bind Entry <<Paste>> {editPaste %W ; break}
    bind Entry <<PasteAt>> {editPasteAt %W %x %y ; break}
    bind Entry <<SelectAll>> {editSelectAll %W ; break}

    set treb_lib_dir [file join $treb_root_dir lib]
    set treb_docs_dir [file join $treb_root_dir docs]
    set treb_tool_dir [file join $treb_root_dir pkgs]
    set treb_cacerts_dir [file join $treb_root_dir cacerts]

    image create photo ssl_icon_secure -file [file join $treb_lib_dir images locked.gif]
    image create photo ssl_icon_insecure -file [file join $treb_lib_dir images unlocked.gif]

    source [file join $treb_lib_dir bitmaps.tcl]
    source [file join $treb_lib_dir errors.tcl]
    source [file join $treb_lib_dir spinner.tcl]
    source [file join $treb_lib_dir groupbox.tcl]
    source [file join $treb_lib_dir combobox.tcl]
    source [file join $treb_lib_dir notebook.tcl]
    source [file join $treb_lib_dir tree.tcl]
    source [file join $treb_lib_dir colorwheel.tcl]
    source [file join $treb_lib_dir btnbar.tcl]
    source [file join $treb_lib_dir compass.tcl]
    source [file join $treb_lib_dir textpups.tcl]
    source [file join $treb_lib_dir selector.tcl]
    source [file join $treb_lib_dir editdlog.tcl]
    source [file join $treb_lib_dir textmods.tcl]
    source [file join $treb_lib_dir textdlog.tcl]
    source [file join $treb_lib_dir finddlog.tcl]
    source [file join $treb_lib_dir prefs.tcl]
    source [file join $treb_lib_dir commands.tcl]
    source [file join $treb_lib_dir telnet.tcl]
    source [file join $treb_lib_dir secsupp.tcl]
    source [file join $treb_lib_dir menus.tcl]
    source [file join $treb_lib_dir mcpmgr.tcl]
    source [file join $treb_lib_dir displays.tcl]
    source [file join $treb_lib_dir worldbtn.tcl]
    source [file join $treb_lib_dir spellchk.tcl]
    source [file join $treb_lib_dir remote.tcl]
    source [file join $treb_lib_dir socks.tcl]

    if {![info exists treb_version_c] || $treb_version != $treb_version_c} {
        source [file join $treb_lib_dir compat.tcl]
    }

    calculate_clicks_per_second
    mcp_initialize /socket:sendln_raw
    textmods:init
    display:init
    prefs:init
    remote:init $argc $argv
}


if {[catch {init $argc $argv} mesg]} {
    global errorInfo
    set savedInfo $errorInfo

    set top [toplevel .tle]
    wm title $top "Trebuchet Error"
    text $top.t -font {Courier 10} -yscrollcommand {$top.sb set}
    scrollbar $top.sb -command {$top.t yview} -orient vert
    button $top.b -text "Ok" -width 6 -command {exit} -default active

    grid columnconfigure $top 0 -weight 1
    grid rowconfigure $top 0 -weight 1
    grid rowconfigure $top 1 -minsize 5
    grid $top.t -sticky nsew
    grid $top.sb -row 0 -column 1 -sticky ns
    grid $top.b -row 2 -column 0

    $top.t insert end $savedInfo
    focus $top.b
    tkwait window $top
    exit
}


proc bgerror {mesg} {
    global errorInfo
    set savedInfo $errorInfo
    if {[string match "SSL channel \"*\": *" $mesg]} {
        return ""
    }
    /error [/socket:current] $mesg $savedInfo
    /socket:setforeground
    return ""
}


proc gdm:ListBox:Keypress {wname keycode key} {
    global gdmListBox
    set mylist [$wname get 0 end]
    set lastpos [$wname index anchor]

    if {$keycode == "Up"} {
        set newpos $lastpos
        incr newpos -1
        if {$newpos < 0} {
            set newpos 0
        }
        if {[info exists gdmListBox($wname,typedchars)]} {
            unset gdmListBox($wname,typedchars)
        }
        if {[info exists gdmListBox($wname,keytimer)]} {
            after cancel $gdmListBox($wname,keytimer)
            unset gdmListBox($wname,keytimer)
        }
    } elseif {$keycode == "Down"} {
        set newpos $lastpos
        incr newpos
        if {$newpos > [$wname index end]} {
            set newpos [$wname index end]
        }
        if {[info exists gdmListBox($wname,typedchars)]} {
            unset gdmListBox($wname,typedchars)
        }
        if {[info exists gdmListBox($wname,keytimer)]} {
            after cancel $gdmListBox($wname,keytimer)
            unset gdmListBox($wname,keytimer)
        }
    } else {
        if {![regexp -nocase -- {[ -~]} $key]} {
            if {[info exists gdmListBox($wname,typedchars)]} {
                unset gdmListBox($wname,typedchars)
            }
            if {[info exists gdmListBox($wname,keytimer)]} {
                after cancel $gdmListBox($wname,keytimer)
                unset gdmListBox($wname,keytimer)
            }
            return
        }
        if {[info exists gdmListBox($wname,keytimer)]} {
            after cancel $gdmListBox($wname,keytimer)
        }
        set gdmListBox($wname,keytimer) [
            after 750 "
                if {\[info exists gdmListBox($wname,typedchars)\]} {
                    unset gdmListBox($wname,typedchars)
                }
            "
        ]
        set chars {}
        if {[info exists gdmListBox($wname,typedchars)]} {
            set chars $gdmListBox($wname,typedchars)
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
        set gdmListBox($wname,typedchars) $chars
    }

    if {$newpos != $lastpos} {
        $wname selection clear 0 end
        $wname selection set $newpos
        $wname activate $newpos
        $wname see $newpos
    }
}


proc getColorVals {color} {
    return [winfo rgb . $color]
}

proc setvars {variables values} {
    foreach var $variables val $values {
        if {$var == ""} {
            break
        }
        upvar $var tmp
        set tmp $val
    }
    return $values
}

proc dispatcher {root opt argset} {
    if {[info procs $root:$opt] != {}} {
        set cmd "$root:$opt"
        foreach arg $argset {
            append cmd " [list $arg]"
        }
        return [eval "$cmd"]
    } else {
        set opts ""
        set rootlen [string length $root]
        incr rootlen
        foreach item [lsort -dictionary [info procs $root:*]] {
            if {$opts != ""} {
                append opts ", "
            }
            append opts [string range $item $rootlen end]
        }
        error "$root: Unknown option \"$opt\" should be one of $opts"
    }
}

proc lrotate {list first last count} {
    if {$first == "end"} {set first [expr {[llength $list] - 1}]}
    if {$last == "end"} {set last [expr {[llength $list] - 1}]}
    if {$first > $last} {
        set tmp $first
        set first $last
        set last $tmp
        set count [expr {-1 * $count}]
    }
    if {(abs($last - $first) + 1) > $count} {
        set count [expr {$count % (abs($last - $first) + 1)}]
    }
    if {$count > 0} {
        set endfirst [expr {$last - $count}]
        set startlast [expr {$last - ($count - 1)}]
    } elseif {$count < 0} {
        set endfirst [expr {$first - ($count + 1)}]
        set startlast [expr {$first - $count}]
    } else {
        return $list
    }
    set tmprng [lrange $list $startlast $last]
    set tmplist [lreplace $list $startlast $last]
    foreach item $tmprng {
        set tmplist [linsert $tmplist $first $item]
        incr first
    }
    return $tmplist
}

proc lrottostart {list pos} {
    set item [lindex $list $pos]
    return [linsert [lreplace $list $pos $pos] 0 $item]
}

proc chooseColor {args} {
    set results [eval tk_chooseColor $args]
    if {[string match "after#*" $results]} {
        regexp {after#[0-9]+([^0-9].*$)} "$results" {} results
    }
    return $results
}

proc editSelectAll {w} {
    if {[winfo class $w] == "Text"} {
        catch {$w tag add sel 1.0 end}
    } elseif {[winfo class $w] == "Entry"} {
        catch {$w selection range 0 end}
    }
}

proc editCopy {w} {
    if {[winfo class $w] == "Text"} {
        if {[$w tag ranges sel] != "[$w index end-1c] [$w index end]"} {
            if {![catch {set data [$w get sel.first sel.last]}]} {
                if {$data != {}} {
                    clipboard clear -displayof $w
                    clipboard append -displayof $w -- $data
                }
            }
        }
    } elseif {[winfo class $w] == "Entry"} {
        if {![catch {set data [selection get -displayof $w -selection PRIMARY]}]} {
            if {$data != {}} {
                clipboard clear -displayof $w
                clipboard append -displayof $w -- $data
            }
        }
    }
}

proc editCut {w} {
    if {[winfo class $w] == "Text" || $w == [/display]} {
        if {[$w tag ranges sel] != "[$w index end-1c] [$w index end]"} {
            if {![catch {set data [$w get sel.first sel.last]}]} {
                if {$data != {}} {
                    clipboard clear -displayof $w
                    clipboard append -displayof $w -- $data
                    $w delete sel.first sel.last
                }
            }
        }
    } elseif {[winfo class $w] == "Entry"} {
        if {![catch {set data [selection get -displayof $w -selection PRIMARY]}]} {
            if {$data != {}} {
                clipboard clear -displayof $w
                clipboard append -displayof $w -- $data
                $w delete sel.first sel.last
            }
        }
    }
}

proc editPaste {w} {
    if {$w == [/display]} {
        set w [/inbuf]
        #/statbar 5 "You can't paste into the output display."
        #/bell
        #return
    }
    catch {
        catch {
            $w delete sel.first sel.last
        }
        set data [selection get -displayof $w -selection CLIPBOARD]
        $w insert insert $data
    }
}

proc editPasteAt {w x y} {
    if {$w == [/display]} {
        /statbar 5 "You can't paste into the output display."
        /bell
        return
    }
    catch {
        if {[winfo class $w] == "Text"} {
            catch { $w tag remove sel.first sel.last }
        } elseif {[winfo class $w] == "Entry"} {
            catch { $w selection clear }
        }
        $w insert @$x,$y [selection get -displayof $w -selection CLIPBOARD]
        if {[winfo class $w] == "Text"} {
            $w mark set insert @%x,%y
        } elseif {[winfo class $w] == "Entry"} {
            $w icursor @%x,%y
        }
    }
}

proc match_text_word {wname pos {end {}}} {
    global nonwordchar
    set first [$wname search -backwards -regexp -nocase -- "$nonwordchar|^" "$pos + 1 chars"]
    if {[$wname compare $first != "$first linestart"]} {
        set first "$first + 1 chars"
    }

    if {$end != {}} {
        set last $end
    } else {
        set last [$wname search -forwards -regexp -nocase -- "$nonwordchar|$" $pos]
    }
    return [$wname get $first "$last"]
}

proc complete_word {wname word} {
    global nonwordchar wordchar
    regsub -all {[]\$.*()|?+^; []} $word {\\&} word
    set limindex "end - [/prefs:get completion_lines] lines"
    set lastindex "end"
    # FIXME: we need $oldindex else, sometimes, the routine would enter an
    # infinite loop... This behaviour was encountered on a Talker, with
    # completion on ANSIfied text.
    set oldindex ""
    set shortword ""
    set shortlen 0
    set wordslist {}
    set wordlen [string length $word]
    while {$lastindex != "" && $lastindex != $oldindex} {
        set oldindex $lastindex
        set lastindex [$wname search -backwards -regexp -nocase -- \
            "$nonwordchar$word|^$word" $lastindex $limindex]
        if {$lastindex != "" && $lastindex != $oldindex} {
            if {[$wname compare $lastindex != "$lastindex linestart"]} {
                set wordstart "$lastindex + 1 chars"
            } else {
                set wordstart "$lastindex"
            }
            set foundword [match_text_word $wname "$wordstart"]
            if {$shortword == ""} {
                set shortword $foundword
                set shortlen [string length $shortword]
                lappend wordslist [string tolower "$foundword"]
            } else {
                if {[lsearch -exact "$wordslist" [string tolower "$foundword"]] == -1} {
                    lappend wordslist [string tolower "$foundword"]
                }
                set tmpword [string range $foundword 0 [expr {$shortlen - 1}]]
                while {[string tolower $shortword] != [string tolower $tmpword]} {
                    incr shortlen -1
                    set tmplen [expr {$shortlen - 1}]
                    set tmpword [string range $tmpword 0 $tmplen]
                    set shortword [string range $shortword 0 $tmplen]
                }
            }
            set lastindex "$lastindex - 1 chars"
        }
    }
    # This is a bug, so don't rely on what was found as it is not what we were
    # searching for...
    if {$lastindex == $oldindex} {
        return ""
    } else {
        return [list $shortword [lsort -dictionary $wordslist]]
    }
}

proc complete_word_proc {} {
    global wordchar nonwordchar
    /statbar 0 {}
    set matchedword [match_text_word [/inbuf] "insert - 1 chars" "insert"]
    if {![regexp -nocase -- "$wordchar+" "$matchedword"]} {
        /bell
        /statbar 5 "No word to complete."
        return ""
    }
    set results [complete_word [/display] $matchedword]
    set newword [lindex $results 0]
    if {$newword != ""} {
        [/inbuf] delete "insert - [string length $matchedword] chars" insert
        [/inbuf] insert insert "$newword"
        set wordslist [lindex $results 1]
        if {[llength $wordslist] > 1} {
            /bell
            /statbar 5 "Ambiguous: $wordslist"
        } else {
            [/inbuf] insert insert " "
        }
    } else {
        /bell
        /statbar 5 "No matches for '$matchedword'"
    }
    return ""
}


proc init_menus {window} {
    init_main_menus $window
    return ""
}

proc /show_copyright {} {
    global treb_root_dir
    /textdlog -buttons -title "GNU General Public License" \
        -width 80 -height 24 -nowrap -readonly \
        -file [file join $treb_root_dir LICENSE]
}

proc /show_about {} {
    global treb_version treb_name
    tk_messageBox -default ok -type ok -title {About Trebuchet} -message \
        "$treb_name  $treb_version\nCopyright 1998-2016 by Fuzzball Software\nReleased under the GNU Public License\n\n\"An Excellent Way to Sling Mud!\""
    focus [/inbuf]
    return ""
}

proc match_by_name {name list} {
    set cnt 0
    foreach item "$list" {
        if {[lindex $item 0] == $name} {
            return $cnt
        }
        incr cnt
    }
    return -1
}


proc process_command {text {socket {}}} {
    global widget errorInfo errorCode

    if {$socket == {}} {
        set socket [/socket:current]
        set oldsocket {}
    } else {
        set oldsocket [/socket:current]
        if {$oldsocket == $socket} {
            set oldsocket {}
        } else {
            /socket:setcurrent $socket
        }
    }
    set statbar $widget(statbar)
    set inbuf [/inbuf]
    set disp [/display]
    set result ""

    if {[string range "$text" 0 0] == "/"} {
        if {[string length $text] == 1 || [string range "$text" 0 1] == "/ "} {
            # Ignore line as a comment.
        } elseif {[string range "$text" 0 1] != "//"} {
            set cmd [string range "$text" 1 end]
            set pos [string first " " $cmd]
            if {$pos > 0} {
                set macroname [string range $cmd 0 [expr {$pos-1}]]
                set restofline [string range $cmd [expr {$pos+1}] end]
            } else {
                set macroname $cmd
                set restofline ""
            }
            if {[/macro:exists $macroname]} {
                set ret [catch {/macro:execute $macroname $restofline} result]
                if {$ret != 0} {
                    set savedInfo $errorInfo
                    if {$oldsocket != {}} {
                        /socket:setcurrent $oldsocket
                    }
                    set lines [split $savedInfo "\n"]
                    set cnt [llength $lines]
                    incr cnt -4
                    set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                    error $result $savedInfo $errorCode
                }
            } else {
                set ret [catch {uplevel #0 "/$cmd"} result]
                if {$ret != 0} {
                    set savedInfo $errorInfo
                    if {$oldsocket != {}} {
                        /socket:setcurrent $oldsocket
                    }
                    set lines [split $savedInfo "\n"]
                    set cnt [llength $lines]
                    incr cnt -4
                    set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                    error $result $savedInfo $errorCode
                }
            }
        } else {
            /socket:sendln $socket [string range $text 1 end]
        }
    } elseif {[string range "$text" 0 0] == "\\"} {
        if {[string range "$text" 0 1] != "\\\\"} {
            set cmd [string range "$text" 1 end]
            set ret [catch {uplevel #0 "/socket:sendln [list $socket] \"$cmd\""} result]
            if {$ret != 0} {
                set savedInfo $errorInfo
                if {$oldsocket != {}} {
                    /socket:setcurrent $oldsocket
                }
                set lines [split $savedInfo "\n"]
                set cnt [llength $lines]
                incr cnt -4
                set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                error $result $savedInfo $errorCode
            }
            set result ""
        } else {
            /socket:sendln $socket [string range $text 1 end]
        }
    } else {
        /socket:sendln $socket "$text"
    }
    if {$oldsocket != {}} {
        /socket:setcurrent $oldsocket
    }
    return $result
}

proc process_commands {text {socket {}}} {
    global errors_nonfatal errorInfo errorCode
    if {$socket == {}} {
        set socket [/socket:current]
        set oldsocket {}
    } else {
        set oldsocket [/socket:current]
        if {$oldsocket == $socket} {
            set oldsocket {}
        } else {
            /socket:setcurrent $socket
        }
    }
    if {[string first "\n" $text] >= 0} {
        set cmds [split $text "\n"]
        set ccmd ""
        foreach cmd $cmds {
            if {$ccmd != ""} {
                append ccmd "\n"
            }
            append ccmd $cmd
            if {[info complete $ccmd]} {
                set ret [catch {process_command $ccmd $socket} result]
                if {$ret != 0} {
                    set savedInfo $errorInfo
                    if {!$errors_nonfatal} {
                        if {$oldsocket != {}} {
                            /socket:setcurrent $oldsocket
                        }
                        # set lines [split $savedInfo "\n"]
                        # set cnt [llength $lines]
                        # incr cnt -4
                        # set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                        return -code $ret -errorinfo $savedInfo -errorcode $errorCode $result
                        error $result $savedInfo $errorCode
                    }
                    /nonmodalerror $socket $result
                }
                set ccmd ""
            }
            if {[/world:get type $socket] == "talker"} {
                # Talkers are slow and loose lines when they are sent too
                # quickly one after the other.
                after 200
            }
        }
        if {$ccmd != ""} {
            set ret [catch {process_command $ccmd $socket} result]
            if {$ret != 0} {
                set savedInfo $errorInfo
                if {!$errors_nonfatal} {
                    if {$oldsocket != {}} {
                        /socket:setcurrent $oldsocket
                    }
                    # set lines [split $savedInfo "\n"]
                    # set cnt [llength $lines]
                    # incr cnt -4
                    # set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                    return -code $ret -errorinfo $savedInfo -errorcode $errorCode $result
                    error $result $savedInfo $errorCode
                }
                /nonmodalerror $socket $result
            }
            set ccmd ""
        }
    } else {
        set ret [catch {process_command $text $socket} result]
        if {$ret != 0} {
            set savedInfo $errorInfo
            if {!$errors_nonfatal} {
                if {$oldsocket != {}} {
                    /socket:setcurrent $oldsocket
                }
                # set lines [split $savedInfo "\n"]
                # set cnt [llength $lines]
                # incr cnt -4
                # set savedInfo [join [lrange $lines 0 $cnt] "\n"]
                return -code $ret -errorinfo $savedInfo -errorcode $errorCode $result
                error $result $savedInfo $errorCode
            }
            /nonmodalerror $socket $result
        }
    }
    if {$oldsocket != {}} {
        /socket:setcurrent $oldsocket
    }
    return $result
}

proc proxyconnect {sok world notls} {
    fileevent $sok writable ""
    /socket:setcurrent $world

    if {![catch {fconfigure $sok -error} sokerr]} {
        if {$sokerr != {} } {
            /socket:disconnect $world
            /statbar 10 "Connection to proxy for $world failed."
            update idletasks
            /error $world "Could not connect to proxy for world $world.\n$sokerr"
            return
        }
    }

    set host [/world:get host $world]
    set port [/world:get port $world]
    set user [/prefs:get socks_user]
    set pass [/prefs:get socks_pass]
    if { $user != "" } {
        set errMsg [socks:init $sok $host $port 1 $user $pass]
    } else {
        set errMsg [socks:init $sok $host $port 0 "" ""]
    }

    if { $errMsg != "OK" } {
        /socket:disconnect $world
        /statbar 10 "SOCKS 5 connection to $world failed."
        update idletasks
        /error $world "Could not connect via SOCKS 5 to world $world.\n$errMsg"
    } else {
        directconnect $sok $world $notls
    }
}

proc directconnect {sok world notls} {
    fileevent $sok writable ""

    if {![catch {fconfigure $sok -error} sokerr]} {
        if {$sokerr != {} } {
            /socket:disconnect $world
            /statbar 10 "Connection to $world failed."
            update idletasks
            /error $world "Could not connect to world $world.\n$sokerr"
            return
        }
    }

    if {[/world:get type $world] == "talker"} {
        set buffering "line"
    } else {
        set buffering "none"
    }
    if {[catch {
        fconfigure $sok -blocking false -buffering $buffering -encoding binary -translation {lf crlf}
    }]} {
        fconfigure $sok -blocking false -buffering $buffering -translation {lf crlf}
    }
    telnet_socket_init $sok $notls

    if {[info commands tls::init] != {}} {
        if {[/world:get secure $world]} {
            /statbar 30 "Negotiating SSL for $world..."
            update idletasks
            global treb_cacerts_dir
            set cafile [file join $treb_cacerts_dir "ca-bundle.crt"]
            tls::import $sok -require 1 -cafile $cafile -cadir $treb_cacerts_dir -ssl2 0 -ssl3 0 -tls1 1 -command tls_command_cb
            wait_for_ssl_negotiation $sok $world
            return
        }
    }

    fileevent $sok readable "readline [list $world]"
}

proc connect_complete {sok world} {
    fileevent $sok writable ""
    if {[info commands tls::init] != {}} {
        if {[/world:get secure $world]} {
            set goterr [catch {tls::status $sok} result]
            if {$goterr || $result == ""} {
                after 100 "catch {fileevent [list $sok] writable \"connect_complete [list $sok] [list $world]\"}"
                return
            }
        }
    }

    /socket:set state $world "Connected"
    /statbar 5 "Connection to $world established..."

    set wtype  [/world:get type $world]
    set char   [/world:get charname $world]
    set pass   [/world:get password $world]
    if {$char != {}} {
        if {$wtype == "tiny"} {
            /socket:sendln $world "connect $char $pass"
        } elseif {$wtype == "lp" || $wtype == "lpp"} {
            /socket:sendln $world "$char"
            /socket:sendln $world "$pass"
        } elseif {$wtype == "talker"} {
            /socket:sendln $world "$char"
            after 500
            /socket:sendln $world "$pass"
        } else {
            /socket:sendln $world "connect $char $pass"
        }
    }

    set logtype [/world:get log $world]
    set logfile [/world:get logfile $world]
    set timestamp [/world:get timestamp $world]
    if {$logtype != "off"} {
        set ext [file extension $logfile]
        set logfile [file rootname $logfile]
        set html 0
        if {$logtype == "html"} {
            set html 1
        }
        set dated 0
        if {$timestamp == "date"} {
            append logfile "-%Y%m%d"
            set dated 1
        } elseif {$timestamp == "datetime"} {
            append logfile "-%Y%m%d-%H%M"
            set dated 1
        }
        append logfile $ext
        /log -world $world -html $html -dated $dated $logfile
    }

    set script [/world:get script $world]
    set astcl  [/world:get tcl $world]
    if {$astcl} {
        eval $script
    } else {
        process_commands $script $world
    }

    /socket:setlight $world green
}

proc readline {world {forced_data ""}} {
    global treb_have_logged_in
    global treb_readlines
    global treb_partial_line_timer

    hilite:update_match_proc

    set sok [/socket:get socket $world]
    set isSecure [/world:get secure $world]

    if {$forced_data != ""} {
        set newdata $forced_data
    } else {
        if {[info commands tls::init] != {}} {
            if {$isSecure} {
                if {[catch {tls::status $sok} result]} {
                    fileevent $sok readable ""
                    after 100 "catch {fileevent [list $sok] readable \"readline [list $world]\"}"
                    return
                } elseif {$result == {}} {
                    fileevent $sok readable ""
                    after 100 "catch {fileevent [list $sok] readable \"readline [list $world]\"}"
                    return
                }
            }
        }
        if {![catch {fconfigure $sok -error} sokerr]} {
            if {$sokerr != {} } {
                if {[/socket:get state $world] == "Connected"} {
                    /socket:disconnect $world
                    /statbar 10 "Disconnected from $world."
                    update idletasks
                    /error $world "Your connection to world $world has been lost.\n$sokerr"
                } else {
                    /socket:disconnect $world
                    /statbar 10 "Connection to $world failed."
                    update idletasks
                    /error $world "Could not connect to world $world.\n$sokerr"
                }
                return
            }
        }
        if {[eof $sok]} {
            /socket:disconnect $world
            return
        }
        set maxchars 8192
        if {[telnet_wants_single_chars $sok]} {
            set maxchars 1
        }
        set newdata [read $sok $maxchars]
    }

    if {![info exists treb_partial_line_timer($sok)]} {
        set treb_partial_line_timer($sok) 0
    }

    telnet_process $sok $newdata

    set partline [telnet_partial_line_get $sok]

    if {![info exists treb_have_logged_in($sok)]} {
        if {[string trim $partline] != ""} {
            set treb_have_logged_in($sok) 1
            connect_complete $sok $world
        }
    }

    set lines [split $partline "\n"]
    set linecount [expr {[llength $lines] - 1}]
    telnet_partial_line_set $sok [lindex $lines $linecount]

    for {set iline 0} {$iline< $linecount} {incr iline} {
        display:clearpartial [/display $world]
        set treb_partial_line_timer($sok) 0
        set line [lindex $lines $iline]

        if {$line != ""} {
            if {[catch {set line [mcp_process_input $world $line]} errMesg]} {
                /statbar 5 $errMesg
            }
            if {$line == {}} continue
        }
        if {[info exists treb_readlines(pattern,$world)]} {
            set pat $treb_readlines(pattern,$world)
            set cmd $treb_readlines(command,$world)
            if {$pat != ""} {
                if {[string match $pat [string tolower $line]]} {
                    if {!$treb_readlines(nolast,$world)} {
                        lappend treb_readlines(text,$world) $line
                    }
                    set cmd [/line_subst $cmd $treb_readlines(text,$world)]
                    unset treb_readlines(pattern,$world)
                    unset treb_readlines(command,$world)
                    unset treb_readlines(text,$world)
                    unset treb_readlines(nolast,$world)
                    /socket:setcurrent $world
                    if {[catch {eval $cmd} errMsg]} {
                        global errorInfo
                        /error $world $errMsg $errorInfo
                    }
                } else {
                    lappend treb_readlines(text,$world) $line
                }
                continue
            }
        }
        set encoding [/world:get encoding $world]
        if {$encoding == "identity"} {
            set encoding "utf-8"
        }
        set line [encoding convertfrom $encoding $line]
        if {[string first "\a" "$line"] != -1} {
            /bell
            regsub -all -- "\a" $line "" line
        }
        /hilite:processline $world $line
    }
    return
}

proc update_charcount {} {
    set pos [split [[/inbuf] index insert] .]
    set line L[lindex $pos 0]
    set char C[lindex $pos 1]
    set lastline [.mw.statusbar.pos.line cget -text]
    set lastchar [.mw.statusbar.pos.char cget -text]
    if {$line != $lastline} {
        set width [.mw.statusbar.pos.line cget -width]
        set len [string length $line]
        if {$len > $width} {
            set width $len
        }
        .mw.statusbar.pos.line configure -text $line -width $width
    }
    if {$char != $lastchar} {
        set width [.mw.statusbar.pos.char cget -width]
        set len [string length $char]
        if {$len > $width} {
            set width $len
        }
        .mw.statusbar.pos.char configure -text $char -width $width
    }
}


proc update_qbutton_minwidth {} {
    global widget
    set base $widget(qbuttons)
    set curminwidth [buttonbar:get_minwidth $base]
    set newminwidth [/prefs:get qbutton_minwidth]
    if {$curminwidth != $newminwidth} {
        buttonbar:set_minwidth $base $newminwidth
    }
}


proc update_antialiasing {} {
    global tcl_platform
    if {$tcl_platform(winsys) == "aqua"} {
        upvar #0 ::tk::mac::antialiasedtext aliasing
        if {$aliasing != [/prefs:get antialias_fonts]} {
            set aliasing [/prefs:get antialias_fonts]
            if {$aliasing} {
                /statbar 5 "Enabling font anti-aliasing."
            } else {
                /statbar 5 "Disabling font anti-aliasing."
            }
            wm withdraw .mw
            wm deiconify .mw
        }
    }
}

set standard_timer_counter 0
proc standard_timer {} {
    global standard_timer_counter
    set count [incr standard_timer_counter]

    global treb_partial_line
    global treb_partial_line_timer
    foreach cworld [/socket:connectednames] {
        catch {
            set wtype [/world:get type $cworld]
            if {$wtype == "lp" || $wtype == "talker"} {
                set sok [/socket:get socket $cworld]
                if {[info exists treb_partial_line_timer($sok)]} {
                    set timerval [incr treb_partial_line_timer($sok)]
                    if {$timerval == [/prefs:get lpprompt_delay]} {
                        set partline $treb_partial_line($sok)
                        if {$partline != "" && ($wtype != "talker" || $partline != "\033\1330m")} {
                            readline $cworld "\n"
                            # /hilite:processline $cworld $partline 1
                        }
                    }
                }
            }
        }
    }

    hilite:update_match_proc
    update_charcount
    update_secure_indicator
    update_antialiasing
    update_qbutton_minwidth
    socket:send_keepalives

    if {$count % 3 == 0} {
        style:ansi_flash [/display]
    }
    if {$count % 2 == 0} {
        socket:blink_lights
    }
    if {$count % 10 == 0} {
        # Only do these once every second or so.
        /menu:update
        if {[/prefs:get spell_as_you_type]} {
            /spell:showbad_if_needed
        }
    }

    after 100 standard_timer
    return ""
}


#
# Calculates a new color by averaging to two existing colors.
#
proc colorAverage {color1 color2} {
    set rgb1 [winfo rgb . $color1]
    set red1 [lindex $rgb1 0]
    set grn1 [lindex $rgb1 1]
    set blu1 [lindex $rgb1 2]

    set rgb2 [winfo rgb . $color2]
    set red2 [lindex $rgb2 0]
    set grn2 [lindex $rgb2 1]
    set blu2 [lindex $rgb2 2]

    set red [expr {($red1 + $red2) / 2}]
    set grn [expr {($grn1 + $grn2) / 2}]
    set blu [expr {($blu1 + $blu2) / 2}]

    return [format #%04x%04x%04x $red $grn $blu]
}


#
# Calculates a new color, darkened or lightened from an existing color.
#
proc colorShade {color percent} {
    set rgb [winfo rgb . $color]
    set red [lindex $rgb 0]
    set grn [lindex $rgb 1]
    set blu [lindex $rgb 2]

    set max $red
    if {$grn > $max} {set max $grn}
    if {$blu > $max} {set max $blu}

    set delta [expr {int($max * ($percent - 100) / 100)}]
    set red [expr {$red + $delta}]
    set grn [expr {$grn + $delta}]
    set blu [expr {$blu + $delta}]

    if {$red < 0} {set red 0}
    if {$grn < 0} {set grn 0}
    if {$blu < 0} {set blu 0}

    if {$red > 0xffff} {set red 0xffff}
    if {$grn > 0xffff} {set grn 0xffff}
    if {$blu > 0xffff} {set blu 0xffff}

    return [format #%04x%04x%04x $red $grn $blu]
}


set gdm_window_placement_offset_x 0
set gdm_window_placement_offset_y 0

proc place_window_default {window {parent ""}} {
    global gdm_window_placement_offset_x
    global gdm_window_placement_offset_y
    if {$parent == ""} {
        set parent ".mw"
    }
    if {![winfo exists $parent]} {
        set parent .mw
    }

    incr gdm_window_placement_offset_x 25
    incr gdm_window_placement_offset_y 25
    if {$gdm_window_placement_offset_x > 150} {
        set gdm_window_placement_offset_x 25
        set gdm_window_placement_offset_y 25
    } elseif {$gdm_window_placement_offset_y > 150} {
        set gdm_window_placement_offset_x 25
        set gdm_window_placement_offset_y 25
    }

    set ptop [winfo toplevel $parent]

    set x [expr {[winfo rootx $ptop] + $gdm_window_placement_offset_x}]
    set y [expr {[winfo rooty $ptop] + $gdm_window_placement_offset_y}]

    set width [winfo reqwidth $window]
    set screenwidth [winfo screenwidth $window]
    if {$x + $width > $screenwidth - 20} {
        incr x [expr {($screenwidth - 20) - ($x + $width)}]
    }

    set height [winfo reqheight $window]
    set screenheight [winfo screenheight $window]
    if {$y + $height > $screenheight - 45} {
        incr y [expr {($screenheight - 45) - ($y + $height)}]
    }

    wm geometry $window "+$x+$y"
    wm deiconify $window
    wm sizefrom $window program
    wm positionfrom $window program
}


proc tkshellcmd {command} {
    if {[eof stdin]} {
        exit
    }
    gets stdin line
    if {$command != ""} {
        append command "\n"
    }
    append command $line
    if {[info complete $command]} {
        if {[catch {uplevel #0 $command} result]} {
            global errorInfo
            puts stderr $errorInfo
            flush stderr
        } else {
            puts stdout $result
        }
        set command ""
        puts -nonewline stdout "% "
        flush stdout
    } else {
        puts -nonewline stdout "> "
        flush stdout
    }
    fileevent stdin readable [list tkshellcmd $command] 
}


proc main {argc argv} {
    global env treb_version treb_save_file forcedelete
    global treb_revision
    global tcl_platform treb_fonts treb_lib_dir
    if {[lsearch -exact $argv "--tkshell"] != -1} {
        puts -nonewline stdout "% "
        fileevent stdin readable [list tkshellcmd ""] 
        return
    }

    set starttime [clock sec]

    Window show .mw
    if {[llength [info procs vTcl*]] < 20} {
        standard_timer
    }

    /statbar 0 "Loading preferences..."

    if {$treb_revision < 1067} {
        /bind add <Control-Key-k> {/dokey history_stack}
    }

    # If someone deletes their Return key bindings, re-create it on startup.
    /bind add <Key-KP_Enter> {/dokey enter}
    /bind add <Key-Return>   {/dokey enter}

    global treb_no_prefs_loaded
    set treb_no_prefs_loaded 0
    if {![/load $treb_save_file]} {
        /bind add <Control-Key-Return>    {/dokey insert_enter}
        /bind add <Control-Key-Next>      {/dokey scroll_line_dn}
        /bind add <Control-Key-Prior>     {/dokey scroll_line_up}
        /bind add <Shift-Key-Next>        {/dokey scroll_line_dn}
        /bind add <Shift-Key-Prior>       {/dokey scroll_line_up}
        /bind add <Key-Next>              {/dokey scroll_page_dn}
        /bind add <Key-Prior>             {/dokey scroll_page_up}
        /bind add <Key-Tab>               {/dokey complete_word}
        /bind add <Control-Key-Tab>       {/dokey socket_next}
        /bind add <Control-Shift-Key-Tab> {/dokey socket_prev}
        /bind add <Control-Key-l>         {/dokey clear_screen}
        /bind add <Control-Key-u>         {/dokey del_to_start}
        /bind add <Control-Key-w>         {/dokey delete_word}
        /bind add <Control-Key-n>         {/dokey history_next}
        /bind add <Control-Key-p>         {/dokey history_prev}
        /bind add <Control-Key-k>         {/dokey history_stack}

        /qbutton:add Example       {/echo "Example Quickbutton 1!"}
        /qbutton:add QuickButtons. {/echo "Example Quickbutton 2!"}
        /qbutton:add {Right-Click} {/echo "Example Quickbutton 3!"}
        /qbutton:add {To Edit.}    {/echo "Example Quickbutton 4!"}

        set treb_no_prefs_loaded 1
    }

    if {![/style:exists normal]} {
        /style add normal -lmargin2 10 -background black -foreground white -font $treb_fonts(fixed)
    }
    if {![/style:exists hilite]} {
        /style add hilite -background yellow -foreground black -font [concat $treb_fonts(fixed) bold]
    }
    if {![/style:exists error]} {
        /style add error -background black -foreground red -font [concat $treb_fonts(fixed) bold]
    }
    if {![/style:exists results]} {
        /style add results -background black -foreground green -font [concat $treb_fonts(fixed) bold]
    }
    if {![/style:exists url]} {
        /style add url -foreground blue2 -font $treb_fonts(url) -relief flat -borderwidth 0
        /style menu add url {Copy URL to clipboard} {/clipboard:copy %!}
        /style menu add url {Open URL...} {/web_view %!}
        /style menu add url {<<Click>>} {/web_view %!}
    }
    if {[/style:exists gag]} {
        set forcedelete 1
        /style delete gag
        set forcedelete 0
    }
    /style add gag -elide 1

    /qbutton:hideshow
    /compass:hideshow

    /statbar 0 "Running user defined startup commands..."
    catch [/prefs:get startup_script]

    #############################################
    # Add tags to show the default title screen #
    #############################################
    [/display] tag configure _wordtreb -font {Times -12 bold italic}
    [/display] tag configure _deftreb  -font {Times -12} -lmargin1 20 -lmargin2 40
    [/display] tag configure _bigtreb \
        -font {Helvetica -48 bold italic} -foreground blue4 -justify center
    [/display] tag configure _medtreb \
        -font {Helvetica -24 bold} -foreground green4 -justify center
    [/display] tag configure _smltreb \
        -font {Times -12 bold italic} -foreground gray50 -justify center
    [/display] tag configure _hinttreb  -font {Courier -12} -foreground #b00000 -justify center

    /echo -style _wordtreb {Treb'u*chet}
    /echo -style _deftreb -newline 0 { (Treb-oo-shay), n.}
    /echo -style _deftreb {1. A military engine used in the Middle Ages for throwing stones, etc. It acted by means of a great weight fastened to the short arm of a lever, which, being let fall, raised the end of the long arm with great velocity, hurling stones with much force.}
    /echo -style _deftreb {2. A MUCK client program by Fuzzball Software.}
    /echo
    /echo -style _medtreb "Fuzzball Software Presents:"
    /echo -style _bigtreb "Trebuchet Tk"
    /echo -style _medtreb "Version $treb_version"
    /echo -style _smltreb {"An excellent way to sling MUD."}
    /echo
    /echo
    /echo
    /echo -style _hinttreb "Commands and shortcuts (^ = CTRL key):                                           "
    /echo
    /echo -style _hinttreb "^W    - Delete word      Tab  - Autocomplete word      Enter     - Send line     "
    /echo -style _hinttreb "^L    - Clear screen     ^Tab - Change worlds          ^Enter    - Insert newline"
    /echo -style _hinttreb "^P/^N - Command history  ^K   - Push into cmd history  PgUp/PgDn - Scrollback    "
    /echo

    /statbar 0 "Trebuchet is now ready to use."

    global dirty_preferences
    set dirty_preferences 0

    set warnver 8.030301
    set currver [format "%d.%02d%02d%02d" $tcl_platform(vermajor) $tcl_platform(verminor) $tcl_platform(patchlevel) 1]
    if {$currver < $warnver && [/prefs:get version_warning] < $warnver} {
        set mesg "You should use TCL/Tk 8.3.3, or a more recent interpreter to\n"
        append mesg "run TrebuchetTk. You can still run Trebuchet with an older 8.0\n"
        append mesg "interpreter, but you may experience slightly buggy behaviour,\n"
        append mesg "and you won't be able to use some features like SSL encryption.\n"
        append mesg "\n"
        append mesg "You can fetch and install the latest TCL/Tk interpreter from"
        set tclurl "https://sourceforge.net/projects/trebuchet/"
        set mesg2 "This warning won't be shown again, once you save preferences."
        set base [toplevel .verwarn]
        label $base.icon -bitmap warning -foreground "#990"
        label $base.text -text $mesg -anchor sw -justify left -font $treb_fonts(sansserif)
        label $base.url -text $tclurl -anchor nw -justify left -foreground blue -font [concat $treb_fonts(sansserif) underline] -cursor hand2
        label $base.text2 -text $mesg2 -anchor nw -justify left -font $treb_fonts(sansserif)
        button $base.btn -text Okay -command "destroy $base"
        bind $base.url <ButtonPress-1> "
                $base.url config -foreground red
                /web_view [list $tclurl]
                after 250 $base.url config -foreground blue
            "
        pack $base.btn  -side bottom -anchor s -padx 10 -pady 10
        pack $base.icon  -side left -anchor w -padx 10 -pady 10
        pack $base.text  -side top -anchor w -expand 1 -fill x -padx 10 -pady 5
        pack $base.url   -side top -anchor nw -expand 1 -fill x -padx 10 -pady 0
        pack $base.text2 -side top -anchor nw -expand 1 -fill both -padx 10 -pady 5
        wm title $base "TCL Version [info tclversion]"
        tkwait window $base

        /prefs:set version_warning $warnver
    }

    global treb_revision
    set lastrunver [/prefs:get lastrun_version]
    if {$lastrunver != "" && $lastrunver != 0 && $lastrunver < 124} {
        if {$tcl_platform(platform) == "unix" && $tcl_platform(os) != "Darwin"} {
            /style:resizeall 60
        }
    }
    if {$tcl_platform(winsys) == "aqua"} {
        if {[/prefs:get lastrun_version] > 0} {
            if {[info exists env(TREB_MAC_DPI_FIX)]} {
                if {[/prefs:get mac_dpi_corrected] < $env(TREB_MAC_DPI_FIX)} {
                    if {[/prefs:get mac_dpi_corrected] < 2} {
                        tk_messageBox -type ok -default ok \
                            -icon warning -title {Trebuchet Fonts Warning} \
                            -message "Due to an earlier bug in Aqua Tk, you might need to resize all your style fonts if they seem too small or large.  You can do this from the 'Fonts' pane of the preferences dialog."
                        /prefs:set mac_dpi_corrected 2
                    }
                }
            }
        }
    }
    if {[/prefs:get lastrun_version] != $treb_revision} {
        /prefs:set lastrun_version $treb_revision
    }

    if {[/prefs:get hide_splash]} {
        /tool:load
        main2 $argc $argv
    } else {
        Window show .
        /tool:load
        after 5000 "
            wm withdraw .
            destroy .splash
            image delete trebfling
            main2 [list $argc] [list $argv]
        "
    }
}

proc main2 {argc argv} {
    update_antialiasing
    wm deiconify .mw
    update idletasks
    update idletasks
    focus -force [/inbuf]

    global treb_no_prefs_loaded

    if {[/prefs:get autoup_firsttime]} {
        set result [tk_messageBox -default yes -type yesno -icon question \
            -parent .mw \
            -title "Network Update Check" -message "Would you like Trebuchet to automatically check for upgrades when it starts up in the future?\nThis dialog will not be shown again, once you save your preferences."]
        if {$result == "yes"} {
            /prefs:set autoupdate_check 1
        } else {
            /prefs:set autoupdate_check 0
        }
        /prefs:set autoup_firsttime 0
    }
    if {[/prefs:get autoupdate_check]} {
        /statbar 5 "Contacting Belfry.com to check for Network Updates."
        /web_upgrade -nowarns -timeout 10000
    }
    if {[/prefs:get startup_con_dlog]} {
        /selector -contentscript {/world names} -register {/world} \
            -title "Connect to world" \
            -caption {Select a world to connect to} \
            -selectbutton "Connect" -selectscript {/connect %!} \
            -editbutton "Edit" -editscript {/world:edit %!} -editpersist
    }
}

proc Window {args} {
    global vTcl
    set cmd [lindex $args 0]
    set name [lindex $args 1]
    set newname [lindex $args 2]
    set rest [lrange $args 3 end]
    if {$name == "" || $cmd == ""} {return}
    if {$newname == ""} {
        set newname $name
    }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists == "1" && $name != "."} {wm deiconify $name; return}
            if {[info procs vTclWindow(pre)$name] != ""} {
                eval "vTclWindow(pre)$name $newname $rest"
            }
            if {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[info procs vTclWindow(post)$name] != ""} {
                eval "vTclWindow(post)$name $newname $rest"
            }
        }
        hide    { if {$exists} {wm withdraw $newname; return} }
        iconify { if {$exists} {wm iconify $newname; return} }
        destroy { if {$exists} {destroy $newname; return} }
    }
}

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    global treb_version treb_lib_dir

    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm withdraw $base
    wm resizable $base 0 0
    wm title $base "Trebuchet Tk"
    wm protocol $base WM_DELETE_WINDOW /quit

    . config -relief solid -borderwidth 0
    frame .splash -relief raised -borderwidth 4
    frame .splash.border -relief flat -borderwidth 4
    image create photo trebfling -file [file join $treb_lib_dir images trbsplsh.gif]
    label .splash.img -image trebfling -relief sunken -borderwidth 1
    pack .splash
    pack .splash.border
    pack .splash.img -in .splash.border

    set newx [expr {([winfo screenwidth .] / 2) - ([image width trebfling] / 2) - 5}]
    set newy [expr {([winfo screenheight .] / 2) - ([image height trebfling] / 2) - 25}]

    wm overrideredirect $base 1
    wm deiconify $base
    wm geometry $base +$newx+$newy
    update
    ###################
    # SETTING GEOMETRY
    ###################
}

proc vTclWindow.mw {base} {
    global argv0 env treb_fonts
    global tcl_platform
    if {$base == ""} {
        set base .mw
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    ###################
    # CREATING WIDGETS
    ###################
    toplevel $base -class Toplevel -borderwidth 0
    wm withdraw $base
    wm focusmodel $base passive
    wm geometry $base 640x480
    wm minsize $base 160 240
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base "Trebuchet Tk"
    wm iconname $base "TrebTk"
    wm group $base $base
    wm command $base $argv0
    wm protocol $base WM_DELETE_WINDOW /quit

    set bars [frame $base.bars -borderwidth 0 -height 1]
    compass:new $bars.compass
    frame $bars.spacer -borderwidth 0 -width 1 -height 1
    if {$tcl_platform(platform) == "windows"} {
        set relief "sunken"
    } else {
        set relief "flat"
    }
    buttonbar:new $bars.qbuttons "QuickButtons toolbar" \
        -borderwidth 1 -relief $relief \
        -menuitems {
            "New QuickButton..."         {/newdlog QuickButton /qbutton}
            "Edit this QuickButton..."   {/qbutton:edit %!}
            "Edit QuickButtons..."       {/qbutton:edit}
            "---"                        ""
            "Delete this QuickButton..." {/qbutton:delete_confirm %!}
        }
    /qbutton:hidebar

    set top [frame $base.top -borderwidth 1 -relief sunken]
    frame $top.disp \
        -borderwidth 0 -relief flat
    buttonbar:new $top.worlds "Worlds" \
        -borderwidth 0 -relief flat \
        -menuitems {
            "Reconnect World"     {/reconnect %!}
            "Disconnect World"    {/dc %!}
            "Close World"         {/close %!}
            "---"                 ""
            "Edit this World..."  {/world:edit %!}
            "Edit Worlds..."      {/world:edit}
            "New World..."        {/newdlog World /world}
        }
    /qbutton:showbar

    if {$tcl_platform(winsys) == "aqua"} {
        set bot [frame $base.bot -relief sunken -borderwidth 1]
    } else {
        set bot [frame $base.bot -relief sunken -borderwidth 2]
    }
    set sbarbw 0
    if {$tcl_platform(winsys) == "x11"} {
        set sbarbw 1
    }
    scrollbar $bot.scroll \
        -command "$bot.inbuf yview" -orient vert \
        -borderwidth $sbarbw -relief raised
    text $bot.inbuf \
        -font $treb_fonts(fixed) -height 6 -width 8 \
        -relief flat -borderwidth 0 \
        -yscrollcommand "$bot.scroll set" \
        -highlightthickness 0 -insertwidth 2
    textmods:set_match_mode $bot.inbuf [/prefs:get last_edit_mode]
    textPopup:new $bot.inbuf
    catch {
        if {[catch {bind $bot.inbuf <MouseWheel>}]} {
            # MouseWheel binding isn't valid.  Probably older X11.
            # Bind to button 4 and 5 instead.
            bind $bot.inbuf <Button-4> {
                /dokey scroll_line_up
                /dokey scroll_line_up
                /dokey scroll_line_up
                /dokey scroll_line_up
            }
            bind $bot.inbuf <Button-5> {
                /dokey scroll_line_dn
                /dokey scroll_line_dn
                /dokey scroll_line_dn
                /dokey scroll_line_dn
            }
        } else {
            bind $bot.inbuf <MouseWheel> {
                if {%D > 0} {
                    /dokey scroll_line_up
                    /dokey scroll_line_up
                    /dokey scroll_line_up
                    /dokey scroll_line_up
                } else {
                    /dokey scroll_line_dn
                    /dokey scroll_line_dn
                    /dokey scroll_line_dn
                    /dokey scroll_line_dn
                }
            }
        }
    }

    bind $bot.inbuf <Key> {+
        after 10 update_charcount
        /spell:needs_checking
    }
    bind $bot.inbuf <Button-1> {+
        after 10 update_charcount
        /spell:needs_checking
    }
    bind $bot.inbuf <<Cut>> {+
        after 10 update_charcount
        /spell:needs_checking
    }
    bind $bot.inbuf <<Paste>> {+
        after 10 update_charcount
        /spell:needs_checking
    }
    if {$tcl_platform(winsys) == "aqua"} {
        set statrel "flat"
    } else {
        set statrel "sunken"
    }
    set sbar $base.statusbar
    frame $sbar \
        -height 30 -width 30 -relief flat -borderwidth 0
    button $sbar.histbtn \
        -width 11 -image [gdm:Bitmap get incr] -padx 0 -pady 0 -command {
            /results -title "Status bar message history" -showend [/statbar:list]
        }
    label $sbar.note \
        -text {} -relief flat -borderwidth 1 -anchor w
    label $sbar.secure \
        -image ssl_icon_insecure -relief $statrel -borderwidth 1 -anchor center
    label $sbar.log \
        -text {} -relief $statrel -borderwidth 1 -width 5 -anchor center
    frame $sbar.pos \
        -relief $statrel -borderwidth 1
    label $sbar.pos.line \
        -text {} -relief flat -borderwidth 0 -width 3 -anchor w
    label $sbar.pos.char \
        -text {} -relief flat -borderwidth 0 -width 4 -anchor w

    set sbarimg [gdm:Bitmap get statbar]
    label $sbar.corner \
        -image $sbarimg -relief flat -borderwidth 0 -padx 0 -pady 0

    if {$tcl_platform(winsys) != "aqua"} {
        switch -exact -- $tcl_platform(winsys) {
            win32 {$sbar.corner conf -cursor fleur}
            x11   {$sbar.corner conf -cursor bottom_right_corner}
        }

        set treb_window_resizing_offset {0 0}
        set treb_window_resizing_pos +0+0

        bind $sbar.corner <ButtonPress-1> {movebox:btnpress %W %X %Y}
        proc movebox:btnpress {wname mousex mousey} {
            global tcl_platform
            upvar #0 treb_window_resizing_offset offset
            upvar #0 treb_window_resizing_pos pos
            set top [winfo toplevel $wname]
            set x [winfo rootx $top]
            set y [winfo rooty $top]
            set xoff [expr {$mousex - $x - [winfo width $top]}]
            set yoff [expr {$mousey - $y - [winfo height $top]}]
            set offset [list $xoff $yoff]
            if {$tcl_platform(winsys) == "x11"} {
                set topgeom [wm geom $top]
                set topy [lindex [split $topgeom "+"] 2]
                set topydelt [expr {$topy - [winfo rooty $top]}]
                incr y $topydelt
            }
            set pos +$x+$y
        }

        bind $sbar.corner <B1-Motion> {movebox:motion %W %X %Y}
        proc movebox:motion {wname mousex mousey} {
            upvar #0 treb_window_resizing_offset offset
            upvar #0 treb_window_resizing_pos pos
            set top [winfo toplevel $wname]
            set x [winfo rootx $top]
            set y [winfo rooty $top]
            set w [expr {$mousex - [lindex $offset 0] - $x}]
            set h [expr {$mousey - [lindex $offset 1] - $y}]
            set minsize [wm minsize $top]
            set minw [lindex $minsize 0]
            set minh [lindex $minsize 1]
            if {$w < $minw} { set w $minw }
            if {$h < $minh} { set h $minh }
            wm geometry $top ${w}x${h}${pos}
        }
    }

    bind $sbar.secure <1> {
        /tls:showcert
    }

    frame $base.thumb \
        -borderwidth 1 -cursor sb_v_double_arrow \
        -relief raised -height 3
    bind $base.thumb <B1-Motion> {pane:movethumb .mw %Y}

    proc pane:movethumb {root y} {
        if {$y < [winfo rooty $root] + 200} {
            return
        }
        set inbuf [/inbuf]
        set scroll "[winfo parent $inbuf].scroll"
        set bufheight [$inbuf cget -height]
        set fontheight [font metrics [$inbuf cget -font] -linespace]
        set buftop [winfo rooty $inbuf]
        set delta [expr {int((($buftop-$y)/$fontheight)+0.5)}]
        incr bufheight $delta
        if {$bufheight >= 1} {
            if {$bufheight * $fontheight + 2 >= [winfo reqheight $scroll]} {
                if {[$inbuf cget -height] != $bufheight} {
                    $inbuf configure -height $bufheight
                    update idletasks
                }
            }
        }
    }

    ###################
    # SETTING GEOMETRY
    ###################
    pack $sbar.pos.char \
        -anchor se -expand 0 -fill none -side right -padx 1
    pack $sbar.pos.line \
        -anchor se -expand 0 -fill none -side right -padx 1

    grid columnconfigure $sbar 0 -weight 1
    grid $sbar.note $sbar.histbtn $sbar.pos $sbar.log $sbar.secure $sbar.corner
    grid $sbar.note -sticky ew
    grid $sbar.histbtn $sbar.pos $sbar.log $sbar.secure -padx 1
    grid $sbar.corner

    pack $bars \
        -side top -anchor nw -fill x
    pack $sbar \
        -side bottom -anchor s -fill x
    pack $bot \
        -side bottom -anchor sw -fill x
    pack $base.thumb \
        -side bottom -anchor sw -fill x
    pack $top \
        -side bottom -anchor sw -fill both -expand 1


    grid $bars.compass $bars.spacer $bars.qbuttons

    grid columnconfigure $bars 2 -weight 1
    grid $bars.compass -sticky nw -padx 1
    grid $bars.spacer -sticky nw
    grid $bars.qbuttons -sticky nesw -padx 1

    pack $top.worlds \
        -anchor s -expand 0 -fill x -side bottom
    pack $top.disp \
        -anchor center -side bottom -expand 1 -fill both -padx 0

    grid columnconf $bot 0 -weight 1
    grid rowconf $bot 0 -weight 1
    grid columnconf $bot 0 -weight 1
    grid rowconf $bot 0 -weight 1
    grid $bot.scroll \
        -column 1 -row 0 -columnspan 1 -rowspan 1 -sticky ns 
    grid $bot.inbuf \
        -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky nesw

    display:mkdisplay $top.disp.backdrop
    pack $top.disp.backdrop \
        -anchor center -expand 1 -fill both -side top
    init_menus $base
    update idletasks

    after 100 "bind $bot.inbuf <Configure> {+after 10 show_mainwin_size}"
}



proc mainwin:syntax:changemode {value} {
    set w [/inbuf]
    textmods:set_match_mode $w [/prefs:get last_edit_mode]
    textmods:match_clear $w
    textmods:match_braces_if_short $w -1
}



proc get_display_size {} {
    set disp [/display]
    set dwidth [winfo width $disp]
    set dheight [winfo height $disp]
    set dwidth [expr {$dwidth - 2*[$disp cget -borderwidth]}]
    set dwidth [expr {$dwidth - 2*[$disp cget -highlightthickness]}]
    set dwidth [expr {$dwidth - 2*[$disp cget -padx]}]
    set dheight [expr {$dheight - 2*[$disp cget -borderwidth]}]
    set dheight [expr {$dheight - 2*[$disp cget -highlightthickness]}]
    set dheight [expr {$dheight - 2*[$disp cget -pady]}]
    set font [$disp cget -font]
    set fwidth [font measure $font "0"]
    set fheight [font metrics $font -linespace]
    set height [expr {int($dheight / $fheight)}]
    set width [expr {int($dwidth / $fwidth)}]
    return [list $width $height]
}


proc show_mainwin_size {} {
    foreach {width height} [get_display_size] break;
    /statbar -nolog 3 "${width}x${height}"
    telnet_send_naws
}

main $argc $argv


