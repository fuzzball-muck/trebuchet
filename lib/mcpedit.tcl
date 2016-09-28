############################
##  SimpleEdit Interface  ##
############################################################################
##
##
############################################################################

proc fbnotify_error {world data} {
    set pkg "org-fuzzball-notify"

    array set arr $data
    setfrom topic arr(topic) {}
    setfrom text  arr(text)  {}

    set parent [focus]
    tk_messageBox -default ok -type ok -icon error \
        -title "$topic - $world" -message $text
    focus $parent
    return
}


mcp_register_pkg "org-fuzzball-notify" 1.0 1.0
mcp_register_handler "org-fuzzball-notify" "error" fbnotify_error



proc simpleedit_editor_watch {cmd file time edf} {
    set curtime [file mtime $file]
    if {$curtime > $time} {
        set time $curtime
        if {[catch {
            global simpleeditresult
            set f [open $file "r"]
            set simpleeditresult [read -nonewline $f]
            close $f
            uplevel #0 $cmd
        } errmsg]} {
            global errorInfo
            /error "" $errmsg $errorInfo
        }
    }
    if {[eof $edf]} {
        catch { close $edf }
        catch { file delete $file }
        return
    }
    after 1000 "simpleedit_editor_watch [list $cmd] [list $file] [list $time] [list $edf]"
}


proc simpleedit_slurp {edf} {
    catch {
        fileevent $edf readable ""
        if {![eof $edf]} {
            read $edf
            after 500 "catch {fileevent [list $edf] readable \"simpleedit_slurp [list $edf]\"}"
        }
    }
}


proc simpleedit_editor {world name type cmd content} {
    global tcl_platform
    if {$tcl_platform(platform) == "unix"} {
        set editcmd [/prefs:get unix_editor_cmd]
        if {$editcmd != "" && [/prefs:get unix_editor_use]} {
            switch -exact -- $type {
                muf-code { set ext ".muf" }
                moo-code { set ext ".moo" }
                default  { set ext ".txt" }
            }
            set file [format "tr%04X$ext" [expr {int(0x10000 * rand())}]]
            global treb_temp_dir
            set file [file join $treb_temp_dir $file]
            if {![catch {
                set f [open $file "w"]
                puts $f $content
                close $f
                set time [file mtime $file]
                regsub -all -- {([\\" ])} $file {\\\1} filesc
                regsub -all -- "(\[^%\])%f" $editcmd "\\1$filesc" editcmd
                regsub -all -- {([\\" ])} "Editing $name" {\\\1} namesc
                regsub -all -- "(\[^%\])%t" $editcmd "\\1$namesc" editcmd
                set edf [open |$editcmd "r"]
                fconfigure $edf -blocking 0
                fileevent $edf readable "simpleedit_slurp [list $edf]"
                after 1000 "simpleedit_editor_watch [list $cmd] [list $file] [list $time] [list $edf]"
            } errmsg]} {
                return
            } else {
                global errorInfo
                /error $world $errmsg $errorInfo
            }
        }
    }
    switch -exact -- $type {
        muf-code {
            /textdlog -text $content -notabs -thirdbutton "Compile" \
                -donecommand $cmd -thirdcmd $cmd \
                -title "SimpleEdit - $world - Editing $name" -mode muf \
                -nowrap -autoindent -buttons -variable simpleeditresult
        }
        moo-code -
        string-list {
            /textdlog -text $content \
                -title "SimpleEdit - $world - Editing $name" -mode none \
                -nowrap -autoindent -buttons -variable simpleeditresult \
                -donecommand $cmd
            return
        }
    }
}

proc simpleedit_content {world data} {
    set pkg "dns-org-mud-moo-simpleedit"

    array set arr $data
    setfrom ref     arr(reference)    {}
    setfrom name    arr(name)         {Unknown value}
    setfrom content arr(content)      {}
    setfrom type    arr(type)         {string}

    set base .simpleedit
    set i 0
    while {[winfo exists $base$i]} {incr i}
    set base $base$i

    set cmd "/mcp_send $pkg set -world [list $world] reference [list $ref] content \$simpleeditresult type [list $type]"

    switch -exact -- $type {
        string-list -
        moo-code -
        muf-code {
            simpleedit_editor $world $name $type $cmd $content
            return
        }
    }
    toplevel $base
    wm resizable $base 1 1
    wm title $base "SimpleEdit - $world"
    place_window_default $base
    wm protocol $base WM_DELETE_WINDOW "$base.cancel invoke"

    label $base.name -text "Editing $name"
    set focuswidget $base.edit
    switch -exact -- $type {
        moo-code -
        muf-code -
        string-list {
            frame $base.edit -borderwidth 0 -relief flat
            text $base.edit.text -width 80 -height 12 \
                -yscrollcommand "$base.edit.scroll set"
            scrollbar $base.edit.scroll -orient vert \
                -command "$base.edit.text yview"
            $base.edit.text insert 0.0 $content
            pack $base.edit.scroll -side right -fill y
            pack $base.edit.text -side right -fill both -expand 1
            bind $base.edit.text <Key-Tab> "$base.edit.text insert insert {    } ; break"
            set resultcmd "\[$base.edit.text get 0.0 end-1c\]"
            set focuswidget $base.edit.text
        }
        integer {
            if {[catch {expr $content + 0} content]} {
                set content 0
            }
            setfrom min arr(min) -999999999
            setfrom max arr(max) 999999999
            spinner $base.edit -min $min -max $max \
                -val $content -width 10
            set resultcmd "\[$base.edit get\]"
            bind $base <Key-Return> "$base.set invoke ; break"
            set focuswidget $base.edit.entry
        }
        string -
        default {
            text $base.edit -width 80 -height 5 -wrap char
            $base.edit insert 0.0 $content
            set resultcmd "\[$base.edit get 0.0 end-1c\]"
            bind $base <Key-Return> "$base.set invoke ; break"
            bind $base.edit <Key-Return> "$base.set invoke ; break"
            bind $base.edit <Key-Tab> "$base.edit insert insert {    } ; break"
        }
    }
    button $base.set -text Set -default active -width 7 -underline 0 -command "
        /mcp_send $pkg set -world [list $world] reference [list $ref] content $resultcmd type [list $type]
        destroy $base
    "
    bind $base <Alt-Key-Return> "$base.set invoke ; break"
    bind $base <Alt-Key-s> "$base.set invoke ; break"
    button $base.cancel -text Cancel -width 7 -command "
        destroy $base
    "
    # Evil bad to bind escape for cancel in an editor!  I lost four hours
    # work this way because I'm a vi user who habitually hits escape.
    # bind $base <Key-Escape> "$base.cancel invoke ; break"

    grid columnconfig $base 0 -minsize 10
    grid columnconfig $base 1 -weight 1
    grid columnconfig $base 2 -minsize 10
    grid columnconfig $base 4 -minsize 10
    grid columnconfig $base 6 -minsize 10

    grid rowconfig $base 0 -minsize 10
    grid rowconfig $base 2 -minsize 10
    grid rowconfig $base 3 -weight 1
    grid rowconfig $base 4 -minsize 10
    grid rowconfig $base 6 -minsize 10

    grid $base.name -row 1 -column 1 -columnspan 5 -sticky w
    grid $base.edit -row 3 -column 1 -columnspan 5 -sticky nsw
    grid $base.set  -row 5 -column 3 -sticky nsew
    grid $base.cancel -row 5 -column 5 -sticky nsew

    focus $focuswidget
    return
}

mcp_register_pkg "dns-org-mud-moo-simpleedit" 1.0 1.0
mcp_register_handler "dns-org-mud-moo-simpleedit" "content" simpleedit_content

mcp_register_pkg "org-fuzzball-simpleedit" 1.0 1.0
mcp_register_handler "org-fuzzball-simpleedit" "content" simpleedit_content

