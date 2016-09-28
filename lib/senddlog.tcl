proc send_dlog:do_quote {wname parent} {
    set world   [$wname.world get]
    set prepend [$wname.prependentry get]
    set append  [$wname.appendentry get]
    set file    [$wname.fileentry get]
    set delay   [$wname.delay get]
    set after   [$wname.after get 1.0 "end-1c"]

    destroy $wname
    textdlog:refocus $parent
    /prefs:set last_sent_file $file
    /prefs:set last_sent_prepend $prepend
    /prefs:set last_sent_append $append
    /prefs:set last_sent_delay $delay
    /prefs:set last_sent_after $after

    /quote -world $world -prefix $prepend -suffix $append -file $file -delay $delay -after $after
}


proc send_dlog:browse {wname} {
    set lastsent [/prefs:get last_sent_file]
    set filetypes {
         {{All Files}        *             }
         {{Text Files}       {.txt}    TEXT}
         {{MUF Files}        {.muf}    TEXT}
         {{MPI Files}        {.mpi}    TEXT}
    }
    set file [tk_getOpenFile -title {Select a file to send} \
                -filetypes $filetypes \
		-initialdir [file dirname $lastsent] \
		-initialfile [file tail $lastsent] \
		-parent $wname.fileentry]
    if {$file != {}} {
	$wname.fileentry delete 0 end
	$wname.fileentry insert end $file
    }
}


tcl::OptProc /send_dlog {
    {-wname   {}                "Toplevel window widget name"}
    {-parent  {}                "Widget to focus on after exiting"}
    {-title   {Send file to...} "Toplevel window title"}
    {-world   {}                "The world to send the data to."}
    {-delay   -float -1.0       "The time between lines sent, in seconds."}
    {-prefix  {}                "String to prepend to each line."}
    {-suffix  {}                "String to append to each line."}
    {-command {}                "A command to perform on each line."}
    {-file    {}                "The file to quote to the given world."}
    {-after   {}                "A command to run after the quote finishes."}
} {
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
        global SendDlogNumber
        if {![info exists SendDlogNumber]} {
            set SendDlogNumber 0
        }
        incr SendDlogNumber
        set wname $wname.senddlog$SendDlogNumber
    }

    if {[winfo exists $wname]} {
        wm deiconify $wname
        focus $wname.world.entry
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
        entry $wname.fileentry -width 50
        button $wname.filebrowse -text Browse... -underline 0 \
	    -command [list send_dlog:browse $wname]

        label $wname.worldlbl -anchor w -borderwidth 1 -text {World} -underline 0 
        combobox $wname.world -editable 0
        label $wname.delaylbl -text {Seconds delay per line} -underline 8 -anchor w
        spinner $wname.delay -min 0.0 -max 9999.9 -val 0.0 -step 0.1 \
            -width 6

        label $wname.prependlbl \
            -anchor w -borderwidth 1 -text {Prepend to each line} -underline 1 
        entry $wname.prependentry
        label $wname.appendlbl \
            -borderwidth 1 -text {Append to each line} -underline 0 
        entry $wname.appendentry
        label $wname.afterlbl \
            -borderwidth 1 -text {Commands to run after quoting finishes} \
            -underline 16
        text $wname.after \
            -width 40 -height 4
        frame $wname.buttons \
            -borderwidth 2 -height 30 -width 125 
        button $wname.buttons.send \
            -text Send -underline 0 -width 6  -command "send_dlog:do_quote $wname $parent"
        button $wname.buttons.cancel \
            -text Cancel -width 6 -command "destroy $wname ; textdlog:refocus $parent"
        ###################
        # SETTING GEOMETRY
        ###################
        grid columnconf $wname  0 -minsize 20
        grid columnconf $wname  3 -weight 1
        grid columnconf $wname 10 -minsize 20
        grid rowconf $wname 0 -minsize 20
        grid rowconf $wname 6 -weight 1
        grid rowconf $wname 8 -minsize 15

        grid x $wname.filelbl    $wname.fileentry -                   -               $wname.filebrowse x -row 1
        grid x $wname.worldlbl   $wname.world     -                   $wname.delaylbl $wname.delay      x
        grid x $wname.prependlbl -                $wname.prependentry -               -                 x 
        grid x $wname.appendlbl  -                $wname.appendentry  -               -                 x 
        grid x $wname.afterlbl   -                -                   x               x                 x
        grid x x                 $wname.after     -                   -               -                 x
        grid x $wname.buttons    -                -                   -               -                 x 

        grid $wname.fileentry $wname.world $wname.prependentry $wname.appendentry -sticky ew -pady 8 -padx 10
        grid $wname.filelbl $wname.worldlbl $wname.prependlbl $wname.appendlbl $wname.afterlbl -sticky w
        grid $wname.delaylbl -sticky e -padx 10
        grid $wname.delay $wname.buttons -sticky ew -pady 8
        grid $wname.after -sticky nsew -padx 10

        grid columnconf $wname.buttons 0 -weight 1
        grid columnconf $wname.buttons 2 -minsize 10
        grid $wname.buttons.cancel -column 1 -row 1 -sticky nsew
        grid $wname.buttons.send   -column 3 -row 1 -sticky nesw 

        bind $wname <Key-Escape> "$wname.buttons.cancel invoke"
        bind $wname <Alt-Key-s> "$wname.buttons.send invoke"
    }

    wm title $wname $title

    $wname.world entrydelete 0 end
    foreach wrld [/socket:connectednames] {
        $wname.world entryinsert end $wrld
    }
    if {$world == ""} {
        set world [/socket:current]
    } elseif {[lsearch -exact [/socket:connectednames] $world] == -1} {
        set world [/socket:current]
    }
    $wname.world delete 0 end
    $wname.world insert end $world

    if {$delay > 0.0} {
        $wname.delay set $delay
    }

    if {$file != {}} {
        $wname.fileentry delete 0 end
        $wname.fileentry insert end $file
    }

    if {$prefix != {}} {
        $wname.prependentry delete 0 end
        $wname.prependentry insert end $prefix
    }

    if {$suffix != {}} {
        $wname.appendentry delete 0 end
        $wname.appendentry insert end $suffix
    }

    if {$after != {}} {
        $wname.after delete 1.0 end
        $wname.after insert 1.0 $after
    }

    focus $wname.fileentry
    return
}


proc /sendfile_dlog {} {
    /send_dlog -wname .quotedlog \
            -world [/socket:foreground] \
            -file [/prefs:get last_sent_file] \
            -delay [/prefs:get last_sent_delay] \
            -prefix [/prefs:get last_sent_prepend] \
            -suffix [/prefs:get last_sent_append]
}

