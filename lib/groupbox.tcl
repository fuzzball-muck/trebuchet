#############################################################################
# Groupbox, by Garth Minette.  Released into the public domain 4/12/97.
# This is a Windows-95 style group box control for TCL/Tk 8.0 or better.
#############################################################################


global gdmGroupboxModuleLoaded
if {![info exists gdmGroupboxModuleLoaded]} {
set gdmGroupboxModuleLoaded true

package require opt

tcl::OptProc groupbox:config {
    {widget       ""         "The widget to configure"}
    {-text        ".NoTeXt." "The group box label text."}
    {-background  ".NoTeXt." "The background color."}
    {-bg          ".NoTeXt." "The background color."}
} {
    if {$text != ".NoTeXt."} {
        $widget.label config -text $text
    }
    if {$background != ".NoTeXt."} {
        set bg $background
    }
    if {$bg != ".NoTeXt."} {
        _old_$widget config -bg $bg
        $widget.label config -bg $bg
        $widget.border config -bg $bg
        $border.cont config -bg $bg
    }
}

proc groupbox:widgetcmd {w cmd args} {
    switch -exact $cmd {
        "container" {
            return $w.border.cont
        }
        "config" {
            return [eval "groupbox:config $w $args"]
        }
        default {
            return [eval "_old_$w $args"]
        }
    }
}

proc groupbox:handleresize {w label} {
    set halfheight [expr {([winfo height $label] + 1) / 2}]

    grid rowconfig $w 0 -minsize $halfheight -weight 0
    grid rowconfig $w 1 -minsize $halfheight -weight 0
    raise $label $w.border
    
    return ""
}

tcl::OptProc groupbox {
    {widget "" "The name of the groupbox to create."}
    {-text  "" "Text to label the groupbox with"}
} {
    set fr [frame $widget -borderwidth 0 -relief flat]
    set label [label $fr.label -text $text]
    set border [frame $fr.border -borderwidth 2 -relief groove]
    set content [frame $border.cont -borderwidth 0 -relief flat]

    grid columnconfig $fr 0 -weight 1
    grid rowconfig $fr 0 -minsize 5 -weight 0
    grid rowconfig $fr 1 -minsize 5 -weight 0
    grid rowconfig $fr 2 -weight 1
    grid $border -column 0 -row 1 -rowspan 2 -sticky nsew
    grid $label -in $fr -column 0 -row 0 -rowspan 2 -padx 5 -sticky nw

    grid columnconfig $border 0 -weight 1
    grid rowconfig $border 0 -weight 0 -minsize 2
    grid rowconfig $border 1 -weight 1
    grid $content -row 1 -column 0 -sticky nsew

    bind $fr <Configure> "+groupbox:handleresize $fr $label"

    rename $fr _old_$fr
    proc $fr {args} "
        return \[eval \"groupbox:widgetcmd $fr \$args\"\]
    "
    return $content
}


if {0} {
    set cont [groupbox .foo -text "Foobert"]
    button $cont.b -text "Exit!" -command {exit}
    pack $cont.b -padx 10 -pady 10 -fill both -expand 1
    set cont [groupbox .foo2 -text "Fleebert"]
    button $cont.b -text "Exit 2!" -command {exit}
    pack $cont.b -padx 10 -pady 10 -fill both -expand 1
    pack .foo -padx 8 -pady 8 -fill both -expand 1
    pack .foo2 -padx 8 -pady 8 -fill both -expand 1
}

}

