 ############################
##  FuzzBall GUI Interface  ##
############################################################################
##
##  Things to finish:
##    fbgui-add-ctrl: fix layout to skip already used cells.
##    fbgui-dlog-create: Add support for the Wizard/Helper interface.
##    fbgui-ctrl-listbox: add horiz scrollbar to listbox.
##    fbgui-ctrl-multiedit: add horiz scrollbar to text box.
##    mcp-gui document: Add WIDTH arg to spinner.
##    mcp-gui document: Add WIDTH arg to button.
##
############################################################################

 ###########################################
# Supported controls and their arguments.  ##
############################################################################
# datum      dlogid id value
# hrule      dlogid [id] [height]
# vrule      dlogid [id] [width]
# image      dlogid [id] value width height [report]
# text       dlogid [id] value [maxwidth]
# button     dlogid id text [dismiss] [width]
# edit       dlogid id [text] [value] [width] [maxlen] [validchars] [report]
# multiedit  dlogid id [value] [width] [height] [font]
# checkbox   dlogid id [text] [value] [onvalue] [offvalue] [report]
# radio      dlogid id [text] [value] selvalue valname [report]
# scale      dlogid id [text] [value] [minval] [maxval] [length] [width]
#               [orient] [digits] [resolution] [bigincrement] [interval] [report]
# spinner    dlogid id [text] [value] [minval] [maxval] [width] [report]
# combobox   dlogid id [text] [value] [width] [options] [editable] [report]
#               [sorted]
# listbox    dlogid id [value] [options] [width] [height] [selectmode]
#               [font] [report]
# frame      dlogid [id] [text] [visible] [collapsible] [collapsed]
# notebook   dlogid id panes names [height] [width]
############################################################################

 ###################################################
# Supported control-commands and their arguments.  ##
############################################################################
# insert dlogid id values [before]
# delete dlogid id items           (For listboxes.)
# delete dlogid id first [last]    (For all other control types.)
# select dlogid id items           (For listboxes.)
# select dlogid id first [last]    (For all other control types.)
# show   dlogid id position
# cursor dlogid id position
# hilite-set dlogid id [tagname] start [end] [bgcolor] [fgcolor] [underline]
#                        [overstrike] [lmargin] [rmargin] [pindent] [ptoppad]
#                        [linepad] [pbottompad] [offset] [justify] [wrapmode]
#                        [tabs] [size] [font] [valname] [report]
# hilite-clear  dlogid id tagname start [end]
# hilite-delete dlogid id tagname
# enable dlogid id
# disable dlogid id
############################################################################

 ####################
# Issues and notes: ##
############################################################################
# ctrl-cmd insert combobox dropdown isn't editable.
# ctrl-cmd delete combobox dropdown isn't editable.
############################################################################


proc fbgui-safe-focus {w} {
    if {[winfo exists $w]} {
        focus $w
    }
}


proc fbgui-tree-split {item} {
    set out [string trim $item "|     \n"]
    return [split $out "|"]
}


proc fbgui-valid-id {id} {
    if {$id == {}} {
        return 0
    }
    if {[regexp -nocase -- {[^a-z0-9_]} $id]} {
        return 0
    }
    return 1
}


proc fbgui-senderr {world dlogid id errcode errtext} {
    set pkg "org-fuzzball-gui"
    /mcp_send $pkg error -world $world dlogid $dlogid id $id errcode $errcode errtext $errtext
}


proc fbgui-sendvalues {world dlogid} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"
    foreach id $McpGuiInfo($world,values,$dlogid) {
        set resultcmd $McpGuiInfo($world,resultcmd,$dlogid,$id)
        if {$resultcmd != {}} {
            catch $resultcmd val
            if {$McpGuiInfo($world,value,$dlogid,$id) != $val} {
                set McpGuiInfo($world,value,$dlogid,$id) $val
                set McpGuiInfo($world,valdirty,$dlogid,$id) 1
            }
        }
        if {$McpGuiInfo($world,valdirty,$dlogid,$id)} {
            set val $McpGuiInfo($world,value,$dlogid,$id)
            /mcp_send $pkg ctrl-value -world $world dlogid $dlogid id $id value $val
            set McpGuiInfo($world,valdirty,$dlogid,$id) 0
        }
    }
}


proc fbgui-send-event {world dlogid id event dismissed {data {}}} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"
    fbgui-sendvalues $world $dlogid
    /mcp_send $pkg ctrl-event -world $world dlogid $dlogid id $id dismissed $dismissed event $event data $data
}


proc fbgui-destroydlog {world dlogid} {
    global McpGuiInfo
    set oldfocus [focus]
    if {$oldfocus != ""} {
        set oldtop [winfo toplevel $oldfocus]
    } else {
        set oldtop ""
    }
    set toplev $McpGuiInfo($world,toplevel,$dlogid)
    destroy $toplev
    foreach url $McpGuiInfo($world,urls,$dlogid) {
        catch {
            image delete $McpGuiInfo($world,url,$dlogid,$url)
        }
        unset McpGuiInfo($world,url,$dlogid,$url)
    }
    unset McpGuiInfo($world,urls,$dlogid)
    foreach id $McpGuiInfo($world,controls,$dlogid) {
        unset McpGuiInfo($world,control,$dlogid,$id)
        unset McpGuiInfo($world,ctrltype,$dlogid,$id)
    }
    foreach id $McpGuiInfo($world,values,$dlogid) {
        unset McpGuiInfo($world,valdirty,$dlogid,$id)
        unset McpGuiInfo($world,value,$dlogid,$id)
        unset McpGuiInfo($world,resultcmd,$dlogid,$id)
        unset McpGuiInfo($world,setcmd,$dlogid,$id)
        catch { unset McpGuiInfo($world,tagnum,$dlogid,$id) }
        catch { unset McpGuiInfo($world,sorted,$dlogid,$id) }
    }
    foreach pane $McpGuiInfo($world,panes,$dlogid) {
        unset McpGuiInfo($world,pane,$dlogid,$pane)
        unset McpGuiInfo($world,panehpad,$dlogid,$pane)
        unset McpGuiInfo($world,panevpad,$dlogid,$pane)
        unset McpGuiInfo($world,currow,$dlogid,$pane)
        unset McpGuiInfo($world,curcol,$dlogid,$pane)
    }
    foreach menu $McpGuiInfo($world,menus,$dlogid) {
        unset McpGuiInfo($world,menu,$dlogid,$menu)
    }
    unset McpGuiInfo($world,menus,$dlogid)
    unset McpGuiInfo($world,controls,$dlogid)
    unset McpGuiInfo($world,values,$dlogid)
    unset McpGuiInfo($world,panes,$dlogid)
    unset McpGuiInfo($world,menu,$dlogid,)

    unset McpGuiInfo($world,toplevel,$dlogid)
    unset McpGuiInfo($world,base,$dlogid)
    unset McpGuiInfo($world,type,$dlogid)
    unset McpGuiInfo($world,curpane,$dlogid)

    update
    update
    if {[focus] == "" && $oldtop != ""} {
        if {$oldtop != $toplev} {
            fbgui-safe-focus -force $oldfocus
        }
    }
    return
}


proc fbgui-make-ctrlid {world dlogid} {
    global McpGuiInfo
    set i 1
    while {[info exists McpGuiInfo($world,control,$dlogid,__c$i)]} {incr i}
    return "__c$i"
}


proc fbgui-make-ctrlname {world arrname} {
    global McpGuiInfo
    upvar $arrname arr
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom pane arr(pane) { _NO_PANE_ }

    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }
    if {$pane != {}} {
        set base $McpGuiInfo($world,pane,$dlogid,$pane)
    } else {
        set base $McpGuiInfo($world,base,$dlogid)
    }
    if {[winfo exists $base.c$id]} {
        set i 1
        while {[winfo exists $base.c$id$i]} {incr i}
    }
    return $base.c$id
}


proc fbgui-ctrl-errcheck {world arrname} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    upvar $arrname arr
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom pane arr(pane) { _NO_PANE_ }

    if {![info exists McpGuiInfo($world,toplevel,$dlogid)]} {
        fbgui-senderr $world $dlogid $id ENODLOG "No dialog exists with that dialog id."
        return 1
    }
    if {![fbgui-valid-id $id]} {
        fbgui-senderr $world $dlogid $id EBADCTRLID "The given control id contains illegal characters."
        return 1
    }
    if {$pane != { _NO_PANE_ }} {
        set type $McpGuiInfo($world,type,$dlogid) 
        if {![info exists McpGuiInfo($world,pane,$dlogid,$pane)]} {
            if {![info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
                fbgui-senderr $world $dlogid $id EPANEINVALID "The given dialog doesn't contain a pane by that id."
                return 1
            }
        }
    }
    return 0
}

proc fbgui-bind-key {world dlogid widget keybind} {
    global McpGuiInfo
    set base $McpGuiInfo($world,base,$dlogid)
    bind [winfo toplevel $base] $keybind "$widget invoke ; fbgui-safe-focus $widget ; break"
    return
}

proc fbgui-add-ctrl {world widget arrname} {
    global McpGuiInfo

    upvar $arrname arr
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom value arr(value) {}
    setfrom valname arr(valname) {}
    setfrom row     arr(row)    -1 int
    setfrom column  arr(column) -1 int
    setfrom newline arr(newline) 1 bool
    setfrom colskip arr(colskip) 0 int
    setfrom colspan arr(colspan) 1 int
    setfrom rowspan arr(rowspan) 1 int
    setfrom sticky  arr(sticky) w
    setfrom minwidth  arr(minwidth)  0 int
    setfrom minheight arr(minheight) 0 int
    setfrom hweight arr(hweight) 0 int
    setfrom vweight arr(vweight) 0 int
    setfrom leftpad arr(leftpad) 10 int
    setfrom toppad  arr(toppad)  10 int
    setfrom pane arr(pane) { _NO_PANE_ }
    setfrom sorted arr(sorted) 0 bool
    set sticky [string tolower $sticky]

    set type $McpGuiInfo($world,type,$dlogid) 
    if {$pane != { _NO_PANE_ }} {
        if {![info exists McpGuiInfo($world,pane,$dlogid,$pane)]} {
            if {![info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
                fbgui-senderr $world $dlogid $id EPANEINVALID "The given dialog doesn't contain a pane by that id."
                return
            }
        }
    }
    set stick ""
    if {[string match "*w*" $sticky]} {
        append stick w
    }
    if {[string match "*e*" $sticky]} {
        append stick e
    }
    if {[string match "*n*" $sticky]} {
        append stick n
    }
    if {[string match "*s*" $sticky]} {
        append stick s
    }

    set curpane $McpGuiInfo($world,curpane,$dlogid)
    if {$pane != { _NO_PANE_ }} {
        set curpane $pane
        set McpGuiInfo($world,curpane,$dlogid) $curpane
    }

    if {[info exists arr(row)]} {
        set currow $arr(row)
    } else {
        set currow $McpGuiInfo($world,currow,$dlogid,$curpane)
    }

    if {[info exists arr(column)]} {
        set curcol $arr(column)
    } else {
        set curcol $McpGuiInfo($world,curcol,$dlogid,$curpane)
    }
    incr curcol $colskip

    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        lappend McpGuiInfo($world,controls,$dlogid) $id
        set McpGuiInfo($world,control,$dlogid,$id) $widget
    }
    if {$valname == {}} {
        set valname $id
    }
    if {[lsearch -exact $McpGuiInfo($world,values,$dlogid) $valname] == -1} {
        lappend McpGuiInfo($world,values,$dlogid) $valname
        if {![info exists McpGuiInfo($world,value,$dlogid,$valname)]} {
            set McpGuiInfo($world,value,$dlogid,$valname) {}
        }
        set McpGuiInfo($world,valdirty,$dlogid,$id) 0
    }
    if {[info exists arr(value)]} {
        set McpGuiInfo($world,value,$dlogid,$valname) $value
        set McpGuiInfo($world,valdirty,$dlogid,$valname) 0
    }
    set McpGuiInfo($world,sorted,$dlogid,$id) $sorted

    if {$curpane != {}} {
        set base $McpGuiInfo($world,pane,$dlogid,$curpane)
    } else {
        set base $McpGuiInfo($world,base,$dlogid)
    }

    set hpad $McpGuiInfo($world,panehpad,$dlogid,$curpane)
    set vpad $McpGuiInfo($world,panevpad,$dlogid,$curpane)

    if {$curcol == 0} {
        grid columnconfig $base [expr {$curcol * 2}] -minsize $hpad
    } else {
# FIXME: Should only change column 0's leftpad if it was never set.
        if {[info exists arr(leftpad)] || [grid columnconfig $base [expr {$curcol * 2}] -minsize] == 0} {
            grid columnconfig $base [expr {$curcol * 2}] -minsize $leftpad
        }
    }
    if {$currow == 0} {
        grid rowconfig $base [expr {$currow * 2}] -minsize $vpad
    } else {
# FIXME: Should only change row 0's toppad if it was never set.
        if {[info exists arr(toppad)] || [grid rowconfig $base [expr {$currow * 2}] -minsize] == 0} {
            grid rowconfig $base [expr {$currow * 2}] -minsize $toppad
        }
    }
    if {[info exists arr(minwidth)]} {
        grid columnconfig $base [expr $curcol * 2 + 1] -minsize $minwidth
    }
    if {[info exists arr(minheight)]} {
        grid rowconfig $base [expr $currow * 2 + 1] -minsize $minheight
    }
    if {[info exists arr(hweight)]} {
        grid columnconfig $base [expr $curcol * 2 + 1] -weight [expr 1000 * $hweight + 1]
    }
    if {[info exists arr(vweight)]} {
        grid rowconfig $base [expr $currow * 2 + 1] -weight [expr 1000 * $vweight + 1]
    }
    grid rowconfig $base [expr $currow * 2 + 1] -minsize 5

    grid columnconfig $base 99 -weight 1 -minsize $hpad
    grid rowconfig $base 99 -weight 1 -minsize $vpad

    grid $widget -row [expr $currow * 2 + 1] -column [expr $curcol * 2 + 1] \
        -rowspan [expr $rowspan * 2 - 1] -columnspan [expr $colspan * 2 - 1] \
        -sticky $stick -in $base

    if {$newline} {
        incr currow 1
        set curcol 0
    } else {
        incr curcol $colspan
    }
    set McpGuiInfo($world,currow,$dlogid,$curpane) $currow
    set McpGuiInfo($world,curcol,$dlogid,$curpane) $curcol
    return
}





proc fbgui-scrollbar-update {scroll start end} {
    #if {[winfo manager $scroll] != {}} {
    #    if {$start == 0.0 && $end == 1.0} {
    #        grid remove $scroll
    #    }
    #} else {
    #    if {$start != 0.0 || $end != 1.0} {
    #        grid $scroll
    #    }
    #}
    $scroll set $start $end
}



#####################################

proc fbgui-dlog-create {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom title  arr(title)  {}
    setfrom type   arr(type)   {}
    setfrom panes  arr(panes)  {}
    setfrom names  arr(names)  {}
    setfrom resize arr(resizable) {}
    setfrom minwidth  arr(minwidth)  30
    setfrom minheight arr(minheight) 30
    setfrom width  arr(width)  300
    setfrom height arr(height) 200
    setfrom maxwidth  arr(maxwidth)  [winfo screenwidth .mw]
    setfrom maxheight arr(maxheight) [winfo screenheight .mw]
    set panes [split $panes "\n"]
    set names [split $names "\n"]

    if {![fbgui-valid-id $dlogid]} {
        fbgui-senderr $world $dlogid $id EBADDLOGID "The given dialog id contains illegal characters."
        return
    }
    foreach pane $panes {
        if {![fbgui-valid-id $pane]} {
            fbgui-senderr $world $dlogid $id EBADPANEID "The given pane id contains illegal characters."
            return
        }
    }

    set McpGuiInfo($world,controls,$dlogid) {}
    set McpGuiInfo($world,values,$dlogid) {}
    set McpGuiInfo($world,urls,$dlogid) {}
    set McpGuiInfo($world,type,$dlogid) $type
    set McpGuiInfo($world,panes,$dlogid) {}
    set McpGuiInfo($world,menus,$dlogid) {}
    set McpGuiInfo($world,menu,$dlogid,) {}

    set toplev ".mcpguiwin"
    set i 1
    while {[winfo exists $toplev$i]} {
        incr i
    }
    set toplev $toplev$i

    set McpGuiInfo($world,toplevel,$dlogid) $toplev
    toplevel $toplev
    wm title $toplev "$world - $title"
    wm withdraw $toplev

    set resize [string tolower $resize]
    set xresize 0
    set yresize 0
    if {$resize == "x" || $resize == "xy" || $resize == "both"} {
        set xresize 1
    }
    if {$resize == "y" || $resize == "xy" || $resize == "both"} {
        set yresize 1
    }
    wm resizable $toplev $xresize $yresize
    wm minsize $toplev $minwidth $minheight
    wm maxsize $toplev $maxwidth $maxheight

    wm protocol $toplev WM_DELETE_WINDOW "
        fbgui-send-event [list $world] [list $dlogid] _closed buttonpress 1
        fbgui-destroydlog [list $world] [list $dlogid]
    "
    
    set type [string tolower $type]
    if {$type == "tabbed"} {
        set McpGuiInfo($world,base,$dlogid) $toplev
        set McpGuiInfo($world,curpane,$dlogid) {}
        lappend McpGuiInfo($world,panes,$dlogid) {}
        set McpGuiInfo($world,pane,$dlogid,) {}
        set McpGuiInfo($world,panehpad,$dlogid,) 5
        set McpGuiInfo($world,panevpad,$dlogid,) 5
        set McpGuiInfo($world,currow,$dlogid,) 0
        set McpGuiInfo($world,curcol,$dlogid,) 0

        fbgui-ctrl-notebook $world [list dlogid $dlogid panes $panes names $names height $height width $width]
        fbgui-ctrl-frame $world [list dlogid $dlogid id __bframe text {} sticky wen toppad 3]
        fbgui-ctrl-frame $world [list dlogid $dlogid id __bfiller pane __bframe newline 0 hweight 1]
        fbgui-ctrl-button $world [list dlogid $dlogid id _ok width 8 text Okay dismiss 1 newline 0]
        fbgui-ctrl-button $world [list dlogid $dlogid id _cancel width 8 text Cancel dismiss 1 newline 0]
        fbgui-ctrl-button $world [list dlogid $dlogid id _apply width 8 text Apply dismiss 0 newline 0]
        set McpGuiInfo($world,curpane,$dlogid) [lindex $panes 0]

    } elseif {$type == "helper"} {
        set wz $toplev.wz
        Wizard:Create $wz
        pack $wz -expand 1 -fill both -side top
        foreach page $names id $panes {
            set pane [Wizard:addpage $wz $page]
            lappend McpGuiInfo($world,panes,$dlogid) $id
            set McpGuiInfo($world,pane,$dlogid,$id) $pane
            set McpGuiInfo($world,panehpad,$dlogid,$id) 15
            set McpGuiInfo($world,panevpad,$dlogid,$id) 15
            set McpGuiInfo($world,currow,$dlogid,$id) 0
            set McpGuiInfo($world,curcol,$dlogid,$id) 0
        }
        set McpGuiInfo($world,base,$dlogid) $wz
        set McpGuiInfo($world,curpane,$dlogid) [lindex $panes 0]
    } else {
        set McpGuiInfo($world,base,$dlogid) $toplev
        set McpGuiInfo($world,curpane,$dlogid) {}
        lappend McpGuiInfo($world,panes,$dlogid) {}
        set McpGuiInfo($world,pane,$dlogid,) {}
        set McpGuiInfo($world,panehpad,$dlogid,) 10
        set McpGuiInfo($world,panevpad,$dlogid,) 10
        set McpGuiInfo($world,currow,$dlogid,) 0
        set McpGuiInfo($world,curcol,$dlogid,) 0
    }
    return
}


proc fbgui-dlog-show {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}

    if {![info exists McpGuiInfo($world,toplevel,$dlogid)]} {
        fbgui-senderr $world $dlogid $id ENODLOG "No dialog exists with that dialog id."
        return
    }
    place_window_default $McpGuiInfo($world,toplevel,$dlogid)
    set lastid [lindex $McpGuiInfo($world,controls,$dlogid) end]
    set lastctrl $McpGuiInfo($world,control,$dlogid,$lastid)
    update idletasks
    update idletasks
    if {$lastctrl != {}} {
        after 10 fbgui-safe-focus \[NoteBook::_nextfocus $lastctrl 1\]
    }
    return
}


proc fbgui-dlog-close {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}

    if {![info exists McpGuiInfo($world,toplevel,$dlogid)]} {
        fbgui-senderr $world $dlogid "" ENODLOG "No dialog exists with that dialog id."
        return
    }
    fbgui-destroydlog $world $dlogid
    return
}


proc fbgui-ctrl-value {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom value arr(value) {}

    if {![info exists McpGuiInfo($world,toplevel,$dlogid)]} {
        fbgui-senderr $world $dlogid $id ENODLOG "No dialog exists with that dialog id."
        return
    }
    if {![info exists McpGuiInfo($world,value,$dlogid,$id)]} {
        fbgui-senderr $world $dlogid $id ENOCONTROL "No control named $id exists in the given dialog."
        return
    }
    set McpGuiInfo($world,value,$dlogid,$id) $value
    if {$McpGuiInfo($world,setcmd,$dlogid,$id) != {}} {
        eval "$McpGuiInfo($world,setcmd,$dlogid,$id) [list $value]"
    }
    set McpGuiInfo($world,valdirty,$dlogid,$id) 0
    return
}


proc fbgui-ctrl-command {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid)  {}
    setfrom id     arr(id)      {}
    setfrom cmd    arr(command) {}

    if {![info exists McpGuiInfo($world,toplevel,$dlogid)]} {
        fbgui-senderr $world $dlogid $id ENODLOG "No dialog exists with that dialog id."
        return
    }
    if {![info exists McpGuiInfo($world,value,$dlogid,$id)]} {
        fbgui-senderr $world $dlogid $id ENOCONTROL "No control named $id exists in the given dialog."
        return
    }
    
    switch -exact -- [string tolower $cmd] {
        "insert"     { fbgui-cmd-insert $world $data }
        "delete"     { fbgui-cmd-delete $world $data }
        "select"     { fbgui-cmd-select $world $data }
        "show"       { fbgui-cmd-show   $world $data }
        "cursor"     { fbgui-cmd-cursor $world $data }
        "hilite-set" { fbgui-cmd-hilite-set $world $data }
        "hilite-clear"  { fbgui-cmd-hilite-clear $world $data }
        "hilite-delete" { fbgui-cmd-hilite-delete $world $data }
        "enable"     { fbgui-cmd-enable $world $data }
        "disable"    { fbgui-cmd-disable $world $data }
        default      { fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control-command is not recognized." }
    }
    # FIXME: do more stuff

    return
}


# This gets called when the server sends a gui-error message.
proc fbgui-error {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom errcode arr(errcode) {}
    setfrom errtext arr(errtext) {}

    # Do nothing.  Umm, any better ideas?  Why worry the user?
    # Maybe log it to the status bar.
    /statbar 5 "GUI ERROR $errcode: $errtext"
    return
}


#####################################


proc fbgui-ctrl-menu {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set McpGuiInfo($world,ctrltype,$dlogid,$id) "menu"
    set McpGuiInfo($world,sorted,$dlogid,$id) 0
    set toplev $McpGuiInfo($world,toplevel,$dlogid)
    if {[$toplev cget -menu] == {}} {
        set wmenu $toplev.__mainmenu
        menu $wmenu -tearoff 0
        $toplev config -menu $wmenu
        set McpGuiInfo($world,menu,$dlogid,) $wmenu
    }
    if {![info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
        fbgui-senderr $world $dlogid $id ENOMENU "No menu exists with that menu id."
        return
    } else {
        set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
        set w $wmenu.$id
        menu $w -tearoff 0
        set McpGuiInfo($world,menu,$dlogid,$id) $w
        lappend McpGuiInfo($world,menus,$dlogid) $id
        menu:process_name $text newname ulpos
        $wmenu add cascade -label $newname -underline $ulpos -menu $w
    }
    return
}


proc fbgui-ctrl-datum {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom value arr(value) {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    lappend McpGuiInfo($world,values,$dlogid) $id
    set McpGuiInfo($world,value,$dlogid,$id) $value
    set McpGuiInfo($world,valdirty,$dlogid,$id) 0
    set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
    set McpGuiInfo($world,ctrltype,$dlogid,$id) "datum"
    set McpGuiInfo($world,setcmd,$dlogid,$id) {}
    return
}


proc fbgui-ctrl-hrule {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom height arr(height) 2 int
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists arr(sticky)]} {
        set arr(sticky) ""
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "hrule"
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
            $wmenu add separator
            set McpGuiInfo($world,control,$dlogid,$id) [$wmenu index last]
            lappend McpGuiInfo($world,controls,$dlogid) $id
        } else {
            set w [fbgui-make-ctrlname $world arr]
            frame $w -height $height -relief sunken -borderwidth 1
            set arr(sticky) $arr(sticky)ew
            fbgui-add-ctrl $world $w arr
        }
    } else {
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            # Unsupported
        } else {
            set w $McpGuiInfo($world,control,$dlogid,$id)
        }
    }
    return
}


proc fbgui-ctrl-vrule {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom width arr(width) 2 int

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists arr(sticky)]} {
        set arr(sticky) ""
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        frame $w -width 2 -relief sunken -borderwidth 1
        set arr(sticky) $arr(sticky)ns
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "vrule"
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-text {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom value arr(value) {}
    setfrom justify arr(justify) "left"
    if {[info exists McpGuiInfo($world,base,$dlogid)]} {
        set base $McpGuiInfo($world,base,$dlogid)
    } else {
        set base .mw
    }
    setfrom width arr(maxwidth) [expr int(8 * [winfo screenwidth $base] / 10)]
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set McpGuiInfo($world,value,$dlogid,$id) $value
        set McpGuiInfo($world,valdirty,$dlogid,$id) 0
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
            $wmenu add command -state disabled -label $value
            set McpGuiInfo($world,setcmd,$dlogid,$id) "$wmenu entryconfig last -text "
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "menutext"
            set McpGuiInfo($world,curpane,$dlogid) $pane
            set McpGuiInfo($world,control,$dlogid,$id) [$wmenu index end]
            lappend McpGuiInfo($world,controls,$dlogid) $id
            lappend McpGuiInfo($world,values,$dlogid) $id
            set McpGuiInfo($world,value,$dlogid,$id) $value
        } else {
            set w [fbgui-make-ctrlname $world arr]
            label $w -text $value -wraplength $width -justify $justify
            set McpGuiInfo($world,setcmd,$dlogid,$id) "$w config -text "
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "text"
            fbgui-add-ctrl $world $w arr
        }
    } else {
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            #$wmenu entryconfig $McpGuiInfo($world,value,$dlogid,$id) -label $value
            #set w $McpGuiInfo($world,control,$dlogid,$id)
        } else {
            set w $McpGuiInfo($world,control,$dlogid,$id)
            $w config -text $value -wraplength $width -justify $justify
            fbgui-add-ctrl $world $w arr
        }
    }
    return
}


proc fbgui-image-loading {destimg total current} {
    if {[catch {image width $destimg}]} {
        return
    }
    set width [image width image_loading]
    set height [image height image_loading]
    set pixels [expr $width * $current / $total]
    $destimg copy image_loading_back -to 0 0 $pixels $height
}


proc fbgui-image-loaded {destimg url status file} {
    set img {}
    if {[catch {image width $destimg}]} {
        return
    }
    if {$status == ""} {
        return
    } elseif {$status == "ok"} {
        if {[catch {
            #set img [image create photo -file $file]
            $destimg blank
            $destimg config -file $file
            set img $destimg
        } result]} {
            if {[string match "couldn't recognize data in image file *" $result]} {
                set result "couldn't recognize data in image from \"$url\""
            }
            /echo -style error $result
            set img {}
        }
    }
    if {$img == {}} {
        global treb_lib_dir
        set file [file join $treb_lib_dir images/broken.gif]
        #set img [image create photo -file $file]
        $destimg blank
        $destimg config -file $file
    }
    #$destimg blank
    #$destimg copy $img
    #image delete $img
}


proc fbgui-image-set {world dlogid id widget width height url} {
    global McpGuiInfo treb_lib_dir

    if {![info exists McpGuiInfo($world,url,$dlogid,$url,$width,$height)]} {
        set img [image create photo -width $width -height $height]
        $img blank
        catch {
            $img put [$img data -background gray70]
        }
        $img copy image_loading
        lappend McpGuiInfo($world,urls,$dlogid) "$url,$width,$height"
        set McpGuiInfo($world,url,$dlogid,$url,$width,$height) $img
        after 50 "
            /webcache:fetch [list $url] -quiet -byfile -command \"fbgui-image-loaded [list $img] [list $url]\" -progress \"fbgui-image-loading [list $img]\"
        "
    } else {
        set img $McpGuiInfo($world,url,$dlogid,$url,$width,$height)
    }
    $widget config -image $img
}


proc fbgui-ctrl-image {world data} {
    global McpGuiInfo treb_lib_dir
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom url arr(value) {}
    setfrom report arr(report) 0 bool
    setfrom height arr(height) -1
    setfrom width arr(width) -1

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[info commands image_loading] == {}} {
        image create photo image_loading -file [file join $treb_lib_dir images/loading.gif]
        image create photo image_loading_back -file [file join $treb_lib_dir images/loadback.gif]
    }
    if {$url == {}} {
        fbgui-senderr $world $dlogid $id EIMGNOURL "The image control has no specified url value."
    }
    if {$width == -1} {
        fbgui-senderr $world $dlogid $id EIMGNOWIDTH "The image control has no specified width."
    } elseif {$width > [winfo screenwidth .mw]} {
        set width [winfo screenwidth .mw]
    }
    if {$height == -1} {
        fbgui-senderr $world $dlogid $id EIMGNOHEIGHT "The image control has no specified height."
    } elseif {$height > [winfo screenheight .mw]} {
        set height [winfo screenheight .mw]
    }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        label $w -width $width -height $height -borderwidth 0 -highlightthickness 0
        fbgui-image-set $world $dlogid $id $w $width $height $url
        if {$report} {
            bind $w <ButtonPress-1> "+fbgui-send-event [list $world] $dlogid $id buttonpress 0"
        }
        set McpGuiInfo($world,setcmd,$dlogid,$id) "fbgui-image-set [list $world] $dlogid $id $w $width $height"
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "image"
        fbgui-add-ctrl $world $w arr
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        $w config -text $value
        fbgui-add-ctrl $world $w arr
    }
    return
}


proc fbgui-ctrl-button {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom dismiss arr(dismiss) 1 bool
    setfrom deflt arr(default) 0 bool
    setfrom bindkey arr(bindkey) {}
    setfrom width arr(width) {} int
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set cmd "fbgui-send-event [list $world] $dlogid $id buttonpress $dismiss"
    if {$dismiss} {
        append cmd "; fbgui-destroydlog [list $world] $dlogid"
    }
    if {$deflt} {
        set deflt "active"
    } else {
        set deflt "normal"
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
            menu:process_name $text newname ulpos
            switch -exact $newname {
                Cut -
                Copy -
                Paste {
                    $wmenu add command -label $newname -underline $ulpos \
                        -command "event generate \[focus\] \"<<$newname>>\""
                }
                default {
                    $wmenu add command -label $newname -underline $ulpos \
                        -command $cmd
                }
            }
            if {$bindkey != ""} {
                set base $McpGuiInfo($world,base,$dlogid)
                bind [winfo toplevel $base] $bindkey "$wmenu invoke [$wmenu index last]"
            }
            set McpGuiInfo($world,setcmd,$dlogid,$id) {}
            set McpGuiInfo($world,curpane,$dlogid) $pane
            set McpGuiInfo($world,control,$dlogid,$id) [$wmenu index last]
            lappend McpGuiInfo($world,controls,$dlogid) $id
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "menubutton"
        } else {
            set w [fbgui-make-ctrlname $world arr]
            menu:process_name $text newname ulpos
            if {$width != {}} {
                button $w -text $newname -underline $ulpos -command $cmd -width $width -default $deflt
            } else {
                button $w -text $newname -underline $ulpos -command $cmd -default $deflt
            }
            if {$bindkey != ""} {
                fbgui-bind-key $world $dlogid $w $bindkey
            }
            if {$ulpos >= 0} {
                set ulchar [string index $newname $ulpos]
                fbgui-bind-key $world $dlogid $w "<Alt-Key-[string tolower $ulchar]>"
            }
            set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "button"
            set McpGuiInfo($world,setcmd,$dlogid,$id) {}
            fbgui-add-ctrl $world $w arr
        }
    } else {
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            #$wmenu entryconfig $McpGuiInfo($world,value,$dlogid,$id) -label $value
        } else {
            set w $McpGuiInfo($world,control,$dlogid,$id)
            $w config -text $text -command $cmd -width $width -default $deflt
            fbgui-add-ctrl $world $w arr
        }
    }
    return
}


proc fbgui-ctrl-password {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) {}
    setfrom maxlen arr(maxlength) 128 int
    setfrom width arr(width) 40 int

    setfrom colskip arr(colskip) 0 int
    setfrom leftpad arr(leftpad) 10 int
    setfrom rowspan arr(rowspan) 1 int
    setfrom pane arr(pane) { _NO_PANE_ }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$text != {}} {
        fbgui-ctrl-text $world [list dlogid $dlogid value $text sticky w newline 0 colskip $colskip leftpad $leftpad rowspan $rowspan pane $pane]
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        entry $w -width $width -show "*"
        bindtags $w [list [winfo toplevel $w] $w Entry all]
        bind $w <Key-Return> "/bell;break"
        bind $w <Shift-Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W -1\];break"
        bind $w <Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W 1\];break"
        $w delete 0 end
        $w insert end $value
        set McpGuiInfo($world,resultcmd,$dlogid,$id) "$w get"
        set McpGuiInfo($world,setcmd,$dlogid,$id) "$w delete 0 end;$w insert end"
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "password"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        $w config -width $width -show "*"
        $w delete 0 end
        $w insert end $value
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-setdirty {world dlogid id report delay type} {
        global McpGuiInfo
        set McpGuiInfo($world,valdirty,$dlogid,$id) 1
        if {$report} {
                if {$delay == 0} {
                        fbgui-send-event $world $dlogid $id $type 0
                } else {
                        set reportcmd "fbgui-send-event [list $world] [list $dlogid] [list $id] [list $type] 0"
                        append cmd ";after cancel $reportcmd; after $delay $reportcmd"
                }
        }
        return 1
}

proc fbgui-setdirty-checkval {world dlogid id report delay val} {
        global McpGuiInfo
        if {$val != $McpGuiInfo($world,value,$dlogid,$id)} {
                fbgui-setdirty $world $dlogid $id $report $delay valchanged
        }
        return 1
}

proc fbgui-ctrl-edit {world data} {
    global McpGuiInfo treb_fonts

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) {}
    setfrom report arr(report) 0 bool
    setfrom maxlen arr(maxlength) 1024 int
    setfrom width arr(width) 40 int
    setfrom valid arr(validchars) {}

    setfrom colskip arr(colskip) 0 int
    setfrom leftpad arr(leftpad) 10 int
    setfrom rowspan arr(rowspan) 1 int
    setfrom pane arr(pane) { _NO_PANE_ }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$text != {}} {
        fbgui-ctrl-text $world [list dlogid $dlogid value $text sticky w newline 0 colskip $colskip leftpad $leftpad rowspan $rowspan pane $pane]
    }
    set font $treb_fonts(sansserif)

    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set cmd "if {\[string length \"%P\"\] > $maxlen} {return 0}"
        if {$valid != {}} {
            #massage valid for safety and to not create invalid regexps
            set vlist [lsort [split $valid {}]]
            set vold {}
            set vcarat 0
            set vhyphen 0
            foreach vchr $vlist {
                if {$vchr == $vold} {
                    continue
                }
                set vold $vchr
                if {$vchr == "^"} {
                    set vcarat 1
                    continue
                }
                if {$vchr == "-"} {
                    set vhyphen 1
                    continue
                }
                if {$vchr == "\["} {
                    set vchr "\\\["
                }
                if {$vchr == "\]"} {
                    set vchr "\\\]"
                }
                if {$vchr == "\$"} {
                    set vchr "\\\$"
                }
                if {$vchr == "\\"} {
                    set vchr "\\\[.\\\\.\\\]"
                }
                lappend vout $vchr
            }
            if {$vcarat == 1} {
                lappend vout "^"
            }
            if {$vhyphen == 1} {
                lappend vout "-"
            }
            set valid [join $vout {}]
            set vcregexp "^\\\[$valid\\\]*\\\$"
            append cmd ";if {!(\[string length \"%s\"\] == 1 && %d == 0) && !\[regexp \"$vcregexp\" \"%P\"\]} {return 0}"
        }
        append cmd ";fbgui-setdirty-checkval [list $world] [list $dlogid] [list $id] [list $report] 2000 \"%P\""
        set McpGuiInfo($world,value,$dlogid,$id) $value
        set McpGuiInfo($world,valdirty,$dlogid,$id) 0
        if {[catch {
            entry $w -width $width -font $font -vcmd $cmd -validate key -invcmd "/bell"
        }]} {
            # Older interps won't understand -vcmd
            entry $w -width $width -font $font
        }
        bindtags $w [list [winfo toplevel $w] $w Entry all]
        bind $w <Key-Return> "/bell;break"
        bind $w <Shift-Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W -1\];break"
        bind $w <Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W 1\];break"
        $w delete 0 end
        $w insert end $value
        set McpGuiInfo($world,resultcmd,$dlogid,$id) "$w get"
        set McpGuiInfo($world,setcmd,$dlogid,$id) "$w delete 0 end;$w insert end"
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "edit"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        $w config -width $width
        $w delete 0 end
        $w insert end $value
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-multiedit {world data} {
    global McpGuiInfo treb_fonts

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom font arr(font) fixed
    setfrom value arr(value) {}
    setfrom width arr(width) 40 int
    setfrom height arr(height) 1 int 

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set wrap char
    if {$font == "fixed"} {
        set font $treb_fonts(fixed)
    } elseif {$font == "serif"} {
        set font $treb_fonts(serif)
    } else {
        set font $treb_fonts(sansserif)
    }
    if {$height == 1} {
        set wrap none
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        frame $w -relief sunken -borderwidth 2
        text $w.t -width $width -height $height -wrap $wrap -font $font \
            -borderwidth 0 -relief flat -yscrollcommand "fbgui-scrollbar-update $w.s"
        scrollbar $w.s -orient vertical -command "$w.t yview"
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
        grid $w.t $w.s -sticky nsew
        bindtags $w.t [list [winfo toplevel $w] $w Text all]
        bind $w.t <Shift-Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W -1\];break"
        bind $w.t <Key-Tab> "fbgui-safe-focus \[NoteBook::_nextfocus %W 1\];break"
        $w.t delete 0.0 end
        $w.t insert end $value
        set McpGuiInfo($world,resultcmd,$dlogid,$id) "$w.t get 0.0 end-1c"
        set McpGuiInfo($world,setcmd,$dlogid,$id) "$w.t delete 0.0 end;$w.t insert end"
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "multiedit"
        set McpGuiInfo($world,tagnum,$dlogid,$id) 0
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        $w.t config -width $width -height $height -wrap $wrap -font $font
        $w.t delete 0.0 end
        $w.t insert end $value
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-checkbox {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) 0
    setfrom report arr(report) 0 bool
    setfrom valname arr(valname) $id
    setfrom onvalue arr(onvalue) 1
    setfrom offvalue arr(offvalue) 0
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set cmd "fbgui-setdirty [list $world] [list $dlogid] [list $id] [list $report] 0 buttonpress"
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
            menu:process_name $text newname ulpos
            $wmenu add checkbutton -label $newname -onvalue $onvalue \
                    -offvalue $offvalue -underline $ulpos -command $cmd \
                    -variable McpGuiInfo($world,value,$dlogid,$valname)
            set McpGuiInfo($world,setcmd,$dlogid,$id) {}
            set McpGuiInfo($world,curpane,$dlogid) $pane
            set McpGuiInfo($world,control,$dlogid,$id) [$wmenu index last]
            lappend McpGuiInfo($world,controls,$dlogid) $id
            lappend McpGuiInfo($world,values,$dlogid) $valname
            set McpGuiInfo($world,value,$dlogid,$valname) $value
            set McpGuiInfo($world,valdirty,$dlogid,$valname) 0
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "menucheckbox"
        } else {
            set w [fbgui-make-ctrlname $world arr]
            menu:process_name $text newname ulpos
            set McpGuiInfo($world,value,$dlogid,$valname) $value
            set McpGuiInfo($world,valdirty,$dlogid,$valname) 0
            checkbutton $w -text $newname -underline $ulpos \
                -onvalue $onvalue -offvalue $offvalue \
                -variable McpGuiInfo($world,value,$dlogid,$valname) \
                -command $cmd
            if {$ulpos >= 0} {
                set ulchar [string index $newname $ulpos]
                fbgui-bind-key $world $dlogid $w "<Alt-Key-[string tolower $ulchar]>"
            }
            set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
            set McpGuiInfo($world,setcmd,$dlogid,$id) {}
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "checkbox"
            fbgui-add-ctrl $world $w arr
        }
    } else {
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            # Unsupported.
        } else {
            set w $McpGuiInfo($world,control,$dlogid,$id)
            set McpGuiInfo($world,value,$dlogid,$valname) $value
            $w config -onvalue $onvalue -offvalue $offvalue -text $text
            fbgui-add-ctrl $world $w arr
        }
    }
    return
}


proc fbgui-ctrl-radio {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) 0
    setfrom selvalue arr(selvalue) 0
    setfrom valname arr(valname) $id
    setfrom report arr(report) 0 bool
    setfrom pane arr(pane) { _NO_PANE_ }
    if {$pane == { _NO_PANE_ }} {
        set pane $McpGuiInfo($world,curpane,$dlogid)
    }

    if {![info exists arr(valname)]} {
        fbgui-senderr $world $dlogid $id ERADIONOVALNAME "A valname was not given for the radio button."
    }
    if {![info exists arr(selvalue)]} {
        fbgui-senderr $world $dlogid $id ERADIONOSELVALUE "A selvalue was not given for the radio button."
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set McpGuiInfo($world,resultcmd,$dlogid,$valname) {}
        set cmd "fbgui-setdirty [list $world] [list $dlogid] [list $id] [list $report] 0 buttonpress"
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            set wmenu $McpGuiInfo($world,menu,$dlogid,$pane)
            menu:process_name $text newname ulpos
            $wmenu add radiobutton -label $newname -underline $ulpos \
                    -command $cmd -value $selvalue \
                    -variable McpGuiInfo($world,value,$dlogid,$valname)
            set McpGuiInfo($world,setcmd,$dlogid,$valname) {}
            set McpGuiInfo($world,curpane,$dlogid) $pane
            set McpGuiInfo($world,control,$dlogid,$id) [$wmenu index last]
            lappend McpGuiInfo($world,controls,$dlogid) $id
            if {[lsearch -exact $McpGuiInfo($world,values,$dlogid) $valname] == -1} {
                lappend McpGuiInfo($world,values,$dlogid) $valname
                set McpGuiInfo($world,valdirty,$dlogid,$valname) 0
            }
            if {[info exists arr(value)]} {
                set McpGuiInfo($world,value,$dlogid,$valname) $value
            }
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "menuradio"
        } else {
            set w [fbgui-make-ctrlname $world arr]
            if {[info exists arr(value)]} {
                set McpGuiInfo($world,value,$dlogid,$valname) $value
            }
            set McpGuiInfo($world,valdirty,$dlogid,$id) 0
            menu:process_name $text newname ulpos
            radiobutton $w -text $newname -underline $ulpos -value $selvalue -command $cmd \
                -variable McpGuiInfo($world,value,$dlogid,$valname)
            if {$ulpos >= 0} {
                set ulchar [string index $newname $ulpos]
                fbgui-bind-key $world $dlogid $w "<Alt-Key-[string tolower $ulchar]>"
            }
            set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
            set McpGuiInfo($world,setcmd,$dlogid,$valname) {}
            set McpGuiInfo($world,ctrltype,$dlogid,$id) "radio"
            fbgui-add-ctrl $world $w arr
        }
    } else {
        if {$pane != {} && [info exists McpGuiInfo($world,menu,$dlogid,$pane)]} {
            # Unsupported.
        } else {
            set w $McpGuiInfo($world,control,$dlogid,$id)
            set McpGuiInfo($world,value,$dlogid,$valname) $value
            $w config -text $text
            fbgui-add-ctrl $world $w arr
        }
    }
    return
}


proc fbgui-ctrl-scale {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom res arr(resolution) 1.0 float
    setfrom digits arr(digits) 0 int
    setfrom length arr(length) 100 int
    setfrom report arr(report) 0 bool
    setfrom width arr(width) 15 int
    setfrom value arr(value) 0.0 float
    setfrom valname arr(valname) $id
    setfrom minval arr(minval) 0.0 float
    setfrom maxval arr(maxval) 100.0 float
    setfrom orient arr(orient) horiz
    setfrom interval arr(interval) 10.0 float
    setfrom biginc arr(bigincrement) [expr {($maxval - $minval) / 10.0}] float

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set McpGuiInfo($world,value,$dlogid,$valname) $value
        set cmd "fbgui-setdirty [list $world] [list $dlogid] [list $id] [list $report] 2000 valchanged"
        append cmd ";# "
        scale $w \
                -variable McpGuiInfo($world,value,$dlogid,$valname) \
                -from $minval -to $maxval -orient $orient \
                -length $length -width $width \
                -label $text -resolution $res -digits $digits \
                -command $cmd -tickinterval $interval -bigincrement $biginc
        set McpGuiInfo($world,resultcmd,$dlogid,$valname) {}
        set McpGuiInfo($world,setcmd,$dlogid,$valname) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "scale"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        set McpGuiInfo($world,value,$dlogid,$valname) $value
        $w config \
                -from $minval -to $maxval -length $length -width $width \
                -label $text -resolution $res -digits $digits \
                -tickinterval $interval -bigincrement $biginc
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-spinner {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) 0 int
    setfrom minval arr(minval) 0 int
    setfrom maxval arr(maxval) 100 int
    setfrom width arr(width) 12 int
    setfrom report arr(report) 0 bool

    setfrom colskip arr(colskip) 0 int
    setfrom leftpad arr(leftpad) 10 int
    setfrom rowspan arr(rowspan) 1 int
    setfrom pane arr(pane) { _NO_PANE_ }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$text != {}} {
        fbgui-ctrl-text $world [list dlogid $dlogid value $text sticky w newline 0 colskip $colskip leftpad $leftpad rowspan $rowspan pane $pane]
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set McpGuiInfo($world,value,$dlogid,$id) $value
        set cmd "fbgui-setdirty [list $world] [list $dlogid] [list $id] [list $report] 2000 valchanged"
        spinner $w \
                -variable McpGuiInfo($world,value,$dlogid,$id) \
                -min $minval -max $maxval -width $width \
                -command $cmd
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "spinner"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        set McpGuiInfo($world,value,$dlogid,$id) $value
        $w config -width $width -min $minval -max $maxval
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-combobox {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom value arr(value) {}
    setfrom width arr(width) 20 int
    setfrom options arr(options) {}
    setfrom editable arr(editable) 0 bool
    setfrom report arr(report) 0 bool
    setfrom sorted arr(sorted) 0 bool
    setfrom colskip arr(colskip) 0 int
    setfrom leftpad arr(leftpad) 10 int
    setfrom rowspan arr(rowspan) 1 int
    setfrom pane arr(pane) { _NO_PANE_ }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$text != {}} {
        fbgui-ctrl-text $world [list dlogid $dlogid value $text sticky w newline 0 colskip $colskip leftpad $leftpad rowspan $rowspan pane $pane]
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set McpGuiInfo($world,value,$dlogid,$id) $value
                set doreport 0
                if {$report && !$editable} {
                        set doreport 1
                }
        set cmd "fbgui-setdirty [list $world] [list $dlogid] [list $id] $doreport 0 valchanged"
        combobox $w \
                -textvariable McpGuiInfo($world,value,$dlogid,$id) \
                -width $width -changecommand $cmd \
                -editable $editable
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "combobox"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        set McpGuiInfo($world,value,$dlogid,$id) $value
        $w config -width $width
        $w config -textvariable McpGuiInfo($world,value,$dlogid,$id)
    }
    $w entrydelete 0 end
    if {$sorted} {
        set options [lsort -dictionary $options]
    }
    foreach item [split $options "\n"] {
        $w entryinsert end $item
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-listbox-select {widget values} {
    $widget selection clear 0 end
    foreach val [split $values "\n"] {
        $widget selection set $val
    }
    return
}


proc fbgui-ctrl-listbox {world data} {
    global McpGuiInfo treb_fonts

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom font arr(font) variable
    setfrom value arr(value) {}
    setfrom options arr(options) {}
    setfrom width arr(width) 40 int
    setfrom height arr(height) 10 int
    setfrom report arr(report) 0 bool
    setfrom selectmode arr(selectmode) single
    switch -exact -- $selectmode {
        single {set selectmode "browse"}
        multiple {set selectmode "multiple"}
        extended {set selectmode "extended"}
        default {set selectmode "browse"}
    }
    if {$font == "fixed"} {
        set font $treb_fonts(fixed)
    } elseif {$font == "serif"} {
        set font $treb_fonts(serif)
    } else {
        set font $treb_fonts(sansserif)
    }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set McpGuiInfo($world,value,$dlogid,$id) $value
        frame $w -relief sunken -borderwidth 2
        listbox $w.l -width $width -height $height -selectmode $selectmode \
            -exportselection 0 -font $font -borderwidth 0 -relief flat \
            -yscrollcommand "fbgui-scrollbar-update $w.s"
        bindtags $w.l [list [winfo toplevel $w.l] $w.l Listbox all]
        scrollbar $w.s -orient vertical -command "$w.l yview"
        if {$report} {
            set cmd "fbgui-send-event [list $world] $dlogid $id valchanged 0"
            bind $w.l <<ListboxSelect>> "+$cmd"
        }
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
        grid $w.l $w.s -sticky nsew
        set McpGuiInfo($world,resultcmd,$dlogid,$id) "return \[join \[$w.l curselection\] \"\\n\"\]"
        set McpGuiInfo($world,setcmd,$dlogid,$id) "fbgui-listbox-select $w.l"
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "listbox"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        set McpGuiInfo($world,value,$dlogid,$id) $value
        $w.l config -width $width -height $height -selectmode $selectmode \
            -exportselection 0 -font $font
    }
    $w.l delete 0 [expr [$w.l size] - 1]
    if {$options != {}} {
        set count 0
        set selected -1
        set options [split $options "\n"]
        foreach item $options {
            $w.l insert end $item
            if {$selectmode != "browse" || $selected == -1} {
                if {[lsearch -exact $value $count] != -1} {
                    $w.l selection set $count
                    set selected $count
                }
            }
            incr count
        }
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-frame {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom text arr(text) {}
    setfrom relief arr(relief) {groove}
    setfrom visible arr(visible) 0 bool
    setfrom width arr(width) 0 int
    setfrom height arr(height) 0 int
    setfrom collapsible arr(collapsible) 0 bool
    setfrom collapsed arr(collapsed) 0 bool

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$visible} {
        set bwidth 2
    } else {
        set bwidth 0
        set relief flat
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        if {$width > 0 && $height > 0} {
            frame $w -relief $relief -borderwidth $bwidth -height $height -width $width
        } elseif {$width > 0} {
            frame $w -relief $relief -borderwidth $bwidth -width $width
        } elseif {$height > 0} {
            frame $w -relief $relief -borderwidth $bwidth -height $height
        } else {
            frame $w -relief $relief -borderwidth $bwidth
        }
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "frame"
        lappend McpGuiInfo($world,panes,$dlogid) $id
        set McpGuiInfo($world,pane,$dlogid,$id) $w
        set pad 10
        if {!$visible} {
            set pad 0
        }
        set McpGuiInfo($world,panehpad,$dlogid,$id) $pad
        set McpGuiInfo($world,panevpad,$dlogid,$id) $pad
        set McpGuiInfo($world,currow,$dlogid,$id) 0
        set McpGuiInfo($world,curcol,$dlogid,$id) 0
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        $w config -relief $relief -borderwidth $bwidth
        catch {
            bind $w <Configure> {}
            destroy $w/caption
        }
    }
    fbgui-add-ctrl $world $w arr
    if {$text != {}} {
        label $w/caption -text $text
        if {$collapsible} {
            bind $w/caption <Enter> {%W config -relief raised}
            bind $w/caption <Leave> {%W config -relief flat}
            bind $w/caption <ButtonPress-1> {
                %W config -relief sunken
                bind %W <Enter> {%W config -relief sunken}
                bind %W <Leave> {%W config -relief raised}
            }
            bind $w/caption <ButtonRelease-1> "
                bind %W <Enter> {%W config -relief raised}
                bind %W <Leave> {%W config -relief flat}
                if {\[%W cget -relief\] == \"sunken\"} {
                    %W config -relief raised
                    if {\[winfo viewable $w\]} {
                        grid remove $w
                        bind %W <Leave> {%W config -relief raised}
                    } else {
                        grid $w 
                    }
                } else {
                    if {\[winfo viewable $w\]} {
                        %W config -relief flat
                    } else {
                        %W config -relief raised
                        bind %W <Leave> {%W config -relief raised}
                    }
                }
                "
        }
        if {$collapsed} {
            grid remove $w
        }
        bind $w <Configure> {
            after 20 {
                #update idletasks
                place %W/caption -anchor w -x [expr [winfo x %W] + 5] \
                    -y [expr [winfo y %W] - [winfo height %W/caption] / 2]
            }
        }
    }
    return
}


proc fbgui-tree-select {widget value} {
    Tree:setselection $widget $value
    return
}


proc fbgui-ctrl-tree {world data} {
    global McpGuiInfo treb_fonts

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom value arr(value) {}
    setfrom options arr(options) {}
    setfrom icons arr(icons) {}
    setfrom height arr(height) 200 int
    setfrom width  arr(width) 200 int
    setfrom report arr(report) 0 bool

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        set McpGuiInfo($world,value,$dlogid,$id) $value
        frame $w -relief sunken -borderwidth 2
        Tree:create $w.t -width $width -height $height \
            -borderwidth 0 -relief flat \
            -yscrollcommand "fbgui-scrollbar-update $w.s"
        scrollbar $w.s -orient vertical -command "$w.t yview"
        if {$report} {
            set cmd "fbgui-send-event [list $world] $dlogid $id valchanged 0"
            $w.t bind x <1> "+$cmd"
        }
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
        grid $w.t $w.s -sticky nsew
        set McpGuiInfo($world,resultcmd,$dlogid,$id) "return \[join \[Tree:getselection $w.t\] \"|\"\]"
        set McpGuiInfo($world,setcmd,$dlogid,$id) "fbgui-tree-select $w.t"
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "tree"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
        set McpGuiInfo($world,value,$dlogid,$id) $value
        Tree:config $w.t -width $width -height $height
    }
    if {$options != {}} {
        foreach child [Tree:children $w.t ""] {
            Tree:delitem $w.t $child
        }
        foreach item [split $options "\n"] icon [split $icons "\n"] {
            if {![Tree:itemexists $w.t [fbgui-tree-split $item]]} {
                switch -exact $icon {
                    item -
                    file { set icon ifile }
                    dir -
                    directory { set icon idir }
                    default { set icon {} }
                }
                if {$icon != {}} {
                    Tree:newitem $w.t [fbgui-tree-split $item] -image $icon
                } else {
                    Tree:newitem $w.t [fbgui-tree-split $item]
                }
            }
        }
        if {![Tree:itemexists $w.t [fbgui-tree-split $value]]} {
            Tree:newitem $w.t [fbgui-tree-split $value] -image ifile
        }
        Tree:setselection $w.t [fbgui-tree-split $value]
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-ctrl-notebook {world data} {
    global McpGuiInfo

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom panes arr(panes) {}
    setfrom names arr(names) {}
    setfrom height arr(height) 0 int
    setfrom width  arr(width) 0 int

    if {$id == {}} {
        set id [fbgui-make-ctrlid $world $dlogid]
        set arr(id) $id
    }
    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {![info exists McpGuiInfo($world,control,$dlogid,$id)]} {
        set w [fbgui-make-ctrlname $world arr]
        notebook $w -width $width -height $height
#            -changecmd "set [list McpGuiInfo($world,value,$dlogid,$id)] "
        foreach page [split $names "\n"] cid [split $panes "\n"] {
            set pane [$w addpage $page]
            set McpGuiInfo($world,pane,$dlogid,$cid) $pane
            lappend McpGuiInfo($world,panes,$dlogid) $cid
            set McpGuiInfo($world,panehpad,$dlogid,$cid) 15
            set McpGuiInfo($world,panevpad,$dlogid,$cid) 15
            set McpGuiInfo($world,currow,$dlogid,$cid) 0
            set McpGuiInfo($world,curcol,$dlogid,$cid) 0
        }
        set McpGuiInfo($world,resultcmd,$dlogid,$id) {}
        set McpGuiInfo($world,setcmd,$dlogid,$id) {}
        set McpGuiInfo($world,ctrltype,$dlogid,$id) "notebook"
    } else {
        set w $McpGuiInfo($world,control,$dlogid,$id)
    }
    fbgui-add-ctrl $world $w arr
    return
}


proc fbgui-cmd-insert {world data} {
# ComboBoxes: inserts text.
# Edit: inserts text.
# ListBoxes: inserts one or more list items.
# MultiEdit: inserts text.
# Tree: Adds a tree entry.
# NoteBook: Adds a notebook tab.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom values arr(values) {}
    setfrom icons arr(icons) {}
    setfrom before arr(before) "end"
    setfrom pane arr(pane) {}
    setfrom name arr(name) {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    if {$before == ""} {
        set before "end"
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)
    switch -exact -- $ctrltype {
        notebook {
            set pfr [$ctrl addpage $name]
            set McpGuiInfo($world,pane,$dlogid,$pane) $pfr
            lappend McpGuiInfo($world,panes,$dlogid) $pane
            set McpGuiInfo($world,panehpad,$dlogid,$pane) 15
            set McpGuiInfo($world,panevpad,$dlogid,$pane) 15
            set McpGuiInfo($world,currow,$dlogid,$pane) 0
            set McpGuiInfo($world,curcol,$dlogid,$pane) 0
        }
        tree {
            foreach item [split $values "\n"] icon [split $icons "\n"] {
                if {![Tree:itemexists $ctrl.t [fbgui-tree-split $item]]} {
                    switch -exact $icon {
                        item -
                        file { set icon ifile }
                        dir -
                        directory { set icon idir }
                        default { set icon {} }
                    }
                    if {$icon != {}} {
                        Tree:newitem $ctrl.t [fbgui-tree-split $item] -image $icon
                    } else {
                        Tree:newitem $ctrl.t [fbgui-tree-split $item]
                    }
                }
            }
        }
        listbox {
            foreach value [split $values "\n"] {
                $ctrl.l insert $before $value
                if {$before != "end"} {
                    set before [expr [$ctrl.l index $before] + 1]
                }
            }
        }
        combobox {
            foreach value [split $values "\n"] {
                $ctrl entryinsert $before $value
                if {$before != "end"} {
                    incr before
                }
            }
        }
        edit {
            $ctrl insert $before $values
        }
        multiedit {
            $ctrl.t insert $before $values
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the insert command."
        }
    }
    return
}



proc fbgui-cmd-delete {world data} {
# ComboBoxes: deletes range of editable text.
# Edit: deletes range of text.
# ListBoxes: deletes one or more list items.
# MultiEdit: deletes range of text.
# Tree: deletes tree item.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom items arr(items) {}
    setfrom first arr(first) {}
    setfrom last arr(last) $first

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    set first [string tolower $first]
    switch -exact -- $ctrltype {
        combobox -
        edit {
            if {![stringis integer $first] && $first != "end"} {
                fbgui-senderr $world $dlogid $id EBADSTARTINDEX "The starting index is of a bad form."
            }
            if {![stringis integer $last] && $last != "end"} {
                fbgui-senderr $world $dlogid $id EBADENDINDEX "The ending index is of a bad form."
            }
            if {[stringis integer $first] && $first < 0} {
                set first 0
            }
            if {[stringis integer $last] && $last < 0} {
                set last 0
            }
        }
        listbox {
            if {$first != {}} {
                if {![stringis integer $first] && $first != "end"} {
                    fbgui-senderr $world $dlogid $id EBADSTARTINDEX "The starting index is of a bad form."
                }
                if {![stringis integer $last] && $last != "end"} {
                    fbgui-senderr $world $dlogid $id EBADENDINDEX "The ending index is of a bad form."
                }
                if {[stringis integer $first] && $first < 0} {
                    set first 0
                }
                if {[stringis integer $last] && $last < 0} {
                    set last 0
                }
                if {$first == "end"} {
                    set first [$ctrl.l size]
                    incr first -1
                }
                if {$last == "end"} {
                    set last [$ctrl.l size]
                    incr last -1
                }
            }
            if {$items != {}} {
                set items [split $items "\n"]
            }
            if {$first != {}} {
                for {set i $first} {$i <= $last} {incr i} {
                    lappend items $i
                }
            }
            set items [lsort -decreasing $items]
            if {$items != {}} {
                set lastitem {}
                foreach item $items {
                    if {![stringis integer $item]} {
                        fbgui-senderr $world $dlogid $id EBADITEMINDEX "One of the item indexes is of a bad form."
                        return ""
                    }
                    if {$item != $lastitem} {
                        lappend outitems $item
                    }
                    set lastitem $item
                }
                set items $outitems
            }
        }
    }
    switch -exact -- $ctrltype {
        tree {
            if {[Tree:itemexists $ctrl.t [fbgui-tree-split $values]]} {
                Tree:delitem $ctrl.t [fbgui-tree-split $values]
            }
        }
        listbox {
            foreach item $items {
                $ctrl.l delete $item
            }
        }
        combobox {
            $ctrl entrydelete $first $last
        }
        edit {
            $ctrl delete $first $last
        }
        multiedit {
            $ctrl.t delete $first $last
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the delete command."
        }
    }
    return
}


proc fbgui-cmd-select {world data} {
# ComboBoxes: select range of editable text.
# ListBoxes: select one or more list items.
# Edit: select range of text.
# MultiEdit: selects range of text.
# Tree: selects tree item.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom items arr(items) {}
    setfrom item arr(item) {}
    setfrom first arr(first) {}
    setfrom last arr(last) $first

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    set first [string tolower $first]
    switch -exact -- $ctrltype {
        edit -
        combobox {
            if {![stringis integer $first] && $first != "end"} {
                fbgui-senderr $world $dlogid $id EBADSTARTINDEX "The starting index is of a bad form."
            }
            if {![stringis integer $last] && $last != "end"} {
                fbgui-senderr $world $dlogid $id EBADENDINDEX "The ending index is of a bad form."
            }
            if {[stringis integer $first] && $first < 0} {
                set first 0
            }
            if {[stringis integer $last] && $last < 0} {
                set last 0
            }
        }
    }
    switch -exact -- $ctrltype {
        tree {
            Tree:setselection $ctrl.t [fbgui-tree-split $item]
        }
        listbox {
            $ctrl.l selection clear 0 end
            foreach item [split $items "\n"] {
                $ctrl selection set $item
            }
        }
        combobox {
            $ctrl selection clear
            $ctrl selection range $first $last
        }
        edit {
            $ctrl selection clear
            $ctrl selection range $first $last
        }
        multiedit {
            $ctrl.t tag remove sel 1.0 end
            $ctrl.t tag add sel $first $last
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the select command."
        }
    }
    return
}


proc fbgui-cmd-show {world data} {
# ListBoxes: see specific item
# Edit: see specific position
# MultiEdit: see specific position
# ComboBoxes: move cursor to specific position
# NoteBook: Brings selected tab view to the front.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom position arr(position) {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    set position [string tolower $position]
    switch -exact -- $ctrltype {
        edit -
        combobox {
            if {![stringis integer $position] && $position != "end"} {
                fbgui-senderr $world $dlogid $id EBADINDEX "The index is of a bad form."
            }
            if {[stringis integer $position] && $position < 0} {
                set position 0
            }
        }
    }
    switch -exact -- $ctrltype {
        notebook {
            $ctrl raise $position
        }
        listbox {
            $ctrl.l see $position
        }
        combobox {
            $ctrl icursor $position
        }
        edit {
            $ctrl xview $position
        }
        multiedit {
            $ctrl.t see $position
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the show command."
        }
    }
    return
}


proc fbgui-cmd-cursor {world data} {
# Listbox move active marker to given list item
# Edit: move cursor to specific position
# MultiEdit: move cursor to specific position
# ComboBoxes: move cursor to specific position
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid arr(dlogid) {}
    setfrom id arr(id) {}
    setfrom position arr(position) {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    switch -exact -- $ctrltype {
        edit -
        combobox {
            if {![stringis integer $position] && $position != "end"} {
                fbgui-senderr $world $dlogid $id EBADINDEX "The index is of a bad form."
            }
            if {[stringis integer $position] && $position < 0} {
                set position 0
            }
        }
    }
    switch -exact -- $ctrltype {
        listbox {
            $ctrl.l activate $position
        }
        combobox {
            $ctrl icursor $position
        }
        edit {
            $ctrl icursor $position
        }
        multiedit {
            $ctrl.t mark set insert $position
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the cursor command."
        }
    }
    return
}


# hilite-set dlogid id start [tagname] [end] [bgcolor] [fgcolor] [underline]
#                        [overstrike] [lmargin] [rmargin] [pindent] [ptoppad]
#                        [linepad] [pbottompad] [offset] [justify] [wrapmode]
#                        [tabs] [size] [font] [valname] [report]
proc fbgui-cmd-hilite-set {world data} {
# Edit: Hilites some text.
# MultiEdit: Hilites some text.
    global McpGuiInfo treb_fonts
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid     arr(dlogid)    {}
    setfrom id         arr(id)        {}
    setfrom start      arr(start)     {}
    setfrom end        arr(end)       $start
    setfrom tagname    arr(tagname)   {}
    setfrom report     arr(report)    0 bool
    setfrom valname    arr(valname)   $id
    setfrom font       arr(font)      sansserif
    setfrom size       arr(size)      -1 int

    if {$font == "fixed"} {
        set font [lindex $treb_fonts(fixed) 0]
        if {$size == -1} {
            set size [lindex $treb_fonts(fixed) 1]
        }
    } elseif {$font == "serif"} {
        set font [lindex $treb_fonts(serif) 0]
        if {$size == -1} {
            set size [lindex $treb_fonts(serif) 1]
        }
    } else {
        set font [lindex $treb_fonts(sansserif) 0]
        if {$size == -1} {
            set size [lindex $treb_fonts(sansserif) 1]
        }
    }
    lappend font $size

    set options {
        background    bgcolor     str  {}
        foreground    fgcolor     str  {}
        underline     underline   bool 0
        overstrike    overstrike  bool 0
        lmargin2      lmargin     int  0
        rmargin       rmargin     int  0
        lmargin1      pindent     int  0
        spacing1      ptoppad     int  0
        spacing2      linepad     int  0
        spacing3      pbottompad  int  0
        offset        offset      int  0
        justify       justify     str  left
        wrap          wrapmode    str  word
        tabs          tabs        str  {}
        relief        relief      str  flat
    }
    foreach {optname optvar opttype optdef} $options {
        setfrom optvals($optvar) arr($optvar) $optdef $opttype
    }

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    if {$tagname == {}} {
        upvar McpGuiInfo($world,tagnum,$dlogid,$id) tagnum
        incr tagnum
        set tagname "tag-$tagnum"
    }

    switch -exact -- $ctrltype {
        edit -
        multiedit {
            if {$ctrltype == "multiedit"} {
                set ctrl $ctrl.t
            }
            #if {[$ctrl compare $start == $end]} {
            #    set end [$ctrl index $start+1c]
            #}
            if {[info exists arr(font)] || [info exists arr(size)]} {
                $ctrl tag config $tagname -font $font
            }
            foreach {optname optvar opttype optdef} $options {
                if {[info exists arr($optvar)]} {
                    $ctrl tag config $tagname -$optname $optvals($optvar)
                }
            }
            $ctrl tag add $tagname $start $end
            if {$report} {
                $ctrl tag bind $tagname <Enter> "$ctrl config -cursor hand2"
                $ctrl tag bind $tagname <Leave> "$ctrl config -cursor {}"
                if {$ctrltype == "edit"} {
                    $ctrl tag bind $tagname <ButtonPress-1> "
                        fbgui-send-event [list $world] [list $dlogid] [list $valname] buttonpress 0 \"[list $tagname]\n\[lindex \[split \[$ctrl index @%x,%y\] .\] 1\]\"
                    "
                } else {
                    $ctrl tag bind $tagname <ButtonPress-1> "
                        fbgui-send-event [list $world] [list $dlogid] [list $valname] buttonpress 0 \"[list $tagname]\n\[$ctrl index @%x,%y\]\"
                    "
                }
            }
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the highlight command."
            return ""    
        }
    }
    return
}



# hilite-clear dlogid id tagname start [end]
proc fbgui-cmd-hilite-clear {world data} {
# Edit: Clears hilites from text.
# MultiEdit: Clears hilites from text.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid     arr(dlogid)    {}
    setfrom id         arr(id)        {}
    setfrom start      arr(start)     {}
    setfrom end        arr(end)      $start
    setfrom tagname    arr(tagname)   {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    switch -exact -- $ctrltype {
        edit -
        multiedit {
            if {$ctrltype == "multiedit"} {
                set ctrl $ctrl.t
            }
            #if {[$ctrl compare $start == $end]} {
            #    set end [$ctrl index $start+1c]
            #}
            $ctrl tag remove $tagname $start $end
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the highlight-clear command."
            return ""
        }
    }
    return
}




# hilite-delete dlogid id tagname
proc fbgui-cmd-hilite-delete {world data} {
# Edit: Clears hilites from text.
# MultiEdit: Clears hilites from text.
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid     arr(dlogid)    {}
    setfrom id         arr(id)        {}
    setfrom tagname    arr(tagname)   {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)

    switch -exact -- $ctrltype {
        edit -
        multiedit {
            if {$ctrltype == "multiedit"} {
                set ctrl $ctrl.t
            }
            $ctrl tag delete $tagname
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the highlight-delete command."
            return ""
        }
    }
    return
}



proc fbgui-cmd-enable {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid     arr(dlogid)    {}
    setfrom id         arr(id)        {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)
    switch -exact -- $ctrltype {
        button -
        menubutton -
        menucheckbox -
        checkbox -
        radio -
        scale -
        password -
        multiedit -
        edit {
            $ctrl configure -state normal
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the enable command."
            return ""
        }
    }
}



proc fbgui-cmd-disable {world data} {
    global McpGuiInfo
    set pkg "org-fuzzball-gui"

    array set arr $data
    setfrom dlogid     arr(dlogid)    {}
    setfrom id         arr(id)        {}

    if {[fbgui-ctrl-errcheck $world arr]} {
        return
    }
    set ctrltype $McpGuiInfo($world,ctrltype,$dlogid,$id)
    set ctrl $McpGuiInfo($world,control,$dlogid,$id)
    switch -exact -- $ctrltype {
        button -
        menubutton -
        menucheckbox -
        checkbox -
        radio -
        scale -
        password -
        multiedit -
        edit {
            $ctrl configure -state disabled
        }
        default {
            fbgui-senderr $world $dlogid $id ECTRLCMDNOTSUPP "The given control doesn't support the disable command."
            return ""
        }
    }
}


proc fbgui-init {world version} {
    # HACK: This is a workaround so that Treb can recognize FB servers
    #       for purposes of allowing Telnet NOP keepalives.
    if {$version > 0} {
        set sok [/socket:get socket $world]
        catch {
            # Send demand to not echo text.  It won't anyways, but this
            # makes it reply to us with an IAC WONT ECHO, which will confirm
            # that the server handles Telnet protocol codes.
            set IAC  "\377"
            set DONT "\376"
            set ECHO "\001"
            puts -nonewline $sok "$IAC$DONT$ECHO"
        }
    }
}


set pkg "org-fuzzball-gui"
mcp_register_pkg $pkg 1.0 1.3 fbgui-init
mcp_register_handler $pkg "dlog-create"    fbgui-dlog-create
mcp_register_handler $pkg "dlog-show"      fbgui-dlog-show
mcp_register_handler $pkg "dlog-close"     fbgui-dlog-close
mcp_register_handler $pkg "ctrl-value"     fbgui-ctrl-value
mcp_register_handler $pkg "ctrl-command"   fbgui-ctrl-command
mcp_register_handler $pkg "error"          fbgui-error

mcp_register_handler $pkg "ctrl-menu"      fbgui-ctrl-menu
mcp_register_handler $pkg "ctrl-datum"     fbgui-ctrl-datum
mcp_register_handler $pkg "ctrl-hrule"     fbgui-ctrl-hrule
mcp_register_handler $pkg "ctrl-vrule"     fbgui-ctrl-vrule
mcp_register_handler $pkg "ctrl-password"  fbgui-ctrl-password
mcp_register_handler $pkg "ctrl-text"      fbgui-ctrl-text
mcp_register_handler $pkg "ctrl-image"     fbgui-ctrl-image
mcp_register_handler $pkg "ctrl-button"    fbgui-ctrl-button
mcp_register_handler $pkg "ctrl-edit"      fbgui-ctrl-edit
mcp_register_handler $pkg "ctrl-multiedit" fbgui-ctrl-multiedit
mcp_register_handler $pkg "ctrl-checkbox"  fbgui-ctrl-checkbox
mcp_register_handler $pkg "ctrl-radio"     fbgui-ctrl-radio
mcp_register_handler $pkg "ctrl-spinner"   fbgui-ctrl-spinner
mcp_register_handler $pkg "ctrl-scale"     fbgui-ctrl-scale
mcp_register_handler $pkg "ctrl-combobox"  fbgui-ctrl-combobox
mcp_register_handler $pkg "ctrl-listbox"   fbgui-ctrl-listbox
mcp_register_handler $pkg "ctrl-frame"     fbgui-ctrl-frame
mcp_register_handler $pkg "ctrl-notebook"  fbgui-ctrl-notebook
mcp_register_handler $pkg "ctrl-tree"      fbgui-ctrl-tree
unset pkg

