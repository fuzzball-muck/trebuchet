# A Notebook widget for Tcl/Tk
# $Revision: 1.18 $
#
# Copyright (C) 1996,1997,1998 D. Richard Hipp
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# Current maintainer contact information:
#   revar@belfry.com
#
# Original author contact information:
#   drh@acm.org
#   http://www.hwaci.com/drh/


namespace eval NoteBook {
    namespace export notebook
    variable NBInfo

    if {[catch {package require tile} tilevers]} {
        set tilevers ""
    }
    set NBInfo(tileversion) $tilevers

    #
    # The global command to create a notebook.
    #
    proc ::notebook {w args} {
        ::NoteBook::create $w $args
    }

    #
    # Create a new notebook widget
    #
    proc create {w argarr} {
        global tcl_platform
        variable NBInfo

	if {$NBInfo(tileversion) != ""} {
	    set NBInfo($w,usetile) 1
	    ttk::notebook $w
	    set NBInfo($w,font)       Helvetica
	    set NBInfo($w,pages)      {}
	    set NBInfo($w,top)        0
	    set NBInfo($w,textpadx)   5
	    set NBInfo($w,fg,raised)  black
	    set NBInfo($w,bg,raised)  #bfbfbf
	    set NBInfo($w,fg,lowered) black
	    set NBInfo($w,bg,lowered) #afafaf
	} else {
	    set NBInfo($w,usetile) 0

	    frame $w -bd 0 -highlightthickness 0 -takefocus 0 -relief flat
	    canvas $w.canvas -bd 0 -highlightthickness 0 -takefocus 0
	    frame $w.holder -relief flat -borderwidth 0

	    set id [$w.canvas create text -500 -500 -text {Wfqpgy!} -anchor nw]
	    set tfont [font actual [$w.canvas itemcget $id -font]]
	    $w.canvas delete $id
	    set NBInfo($w,font)  $tfont
	    set NBInfo($w,width)    400
	    set NBInfo($w,height)   300
	    set NBInfo($w,pages)     {}
	    set NBInfo($w,top)        0
	    set NBInfo($w,pad)        3
	    set NBInfo($w,textpadx)   5
	    if {$tcl_platform(winsys) == "win32"} {
		set NBInfo($w,fg,raised)  systemWindowText
		set NBInfo($w,bg,raised)  [$w.canvas cget -bg]
	    } elseif {$tcl_platform(winsys) == "aqua"} {
		set NBInfo($w,fg,raised)  systemButtonText
		set NBInfo($w,bg,raised)  systemWindowBody
	    } else {
		set NBInfo($w,fg,raised)  black
		set NBInfo($w,bg,raised)  [$w.canvas cget -bg]
	    }
	    set NBInfo($w,fg,lowered) $NBInfo($w,fg,raised)
	    set NBInfo($w,bg,lowered) [_colorShade [$w.canvas cget -bg]  88]
	    set NBInfo($w,shadow)     [_colorShade [$w.canvas cget -bg]  66]
	    if {$tcl_platform(winsys) == "aqua"} {
		set NBInfo($w,hilite) $NBInfo($w,shadow)
	    } else {
		set NBInfo($w,hilite)     [_colorShade [$w.canvas cget -bg] 125]
	    }
	    bind $w.canvas <Destroy>   "::NoteBook::_destroy $w"
	    bind $w.canvas <1>         "::NoteBook::_process_click $w %x %y"
	    bind $w.canvas <Configure> "+::NoteBook::_resize $w %w %h"
	    bind [winfo toplevel $w] <Control-Tab>       "::NoteBook::_nextpage $w  1 ; break"
	    bind [winfo toplevel $w] <Shift-Control-Tab> "::NoteBook::_nextpage $w -1 ; break"
	}

        rename $w "_${w}_int"
        proc ::$w {cmd args} "return \[::NoteBook::dispatch [list $w] \$cmd \$args\]"
        _config $w $argarr

        return $w
    }


    #
    # Dispatch calls to notebook widget commands.
    #
    proc dispatch {w cmd argarr} {
        switch -exact -- $cmd {
            "conf" -
            "confi" -
            "config" -
            "configu" -
            "configur" -
            "configure" {
                return [_config $w $argarr]
            }
            "del" -
            "dele" -
            "delet" -
            "delete" -
            "deletep" -
            "deletepa" -
            "deletepag" -
            "deletepage" {
                return [_delpage $w $argarr]
            }
            "add" -
            "addp" -
            "addpa" -
            "addpag" -
            "addpage" {
                return [_addpage $w $argarr]
            }
            "rai" -
            "rais" -
            "raise" -
            "raisep" -
            "raisepa" -
            "raisepag" -
            "raisepage" {
                return [_raise_by $w [lindex $argarr 0]]
            }
            "find" -
            "findp" -
            "findpa" -
            "findpag" -
            "findpage" {
                return [_findpage $w [lindex $argarr 0]]
            }
            "pagec" -
            "pageco" -
            "pagecon" -
            "pageconf" -
            "pageconfi" -
            "pageconfig" -
            "pageconfigu" -
            "pageconfigur" -
            "pageconfigure" {
                return [_pageconfig $w $argarr]
            }
            "next" {
                _nextpage $w 1
            }
            "prev" -
            "previ" -
            "previo" -
            "previou" -
            "previous" {
                _nextpage $w -1
            }
            "cur" -
            "curr" -
            "curre" -
            "curren" -
            "current" {
                return [_currentframe $w]
            }
            default {
                return [eval "_${w}_int [list $cmd] $argarr"]
            }
        }
    }

    #
    # Add a page to the notebook widget
    #
    proc _addpage {w argarr} {
        variable NBInfo

        set name [lindex $argarr 0]
        set argarr [lrange $argarr 1 end]

        set pagenum [llength $NBInfo($w,pages)]
        set newframe [frame $w.f$pagenum -bd 0 -class "NotebookPage"]
	if {$NBInfo($w,usetile)} {
	    "_${w}_int" add $newframe -text $name -sticky nsew
	} else {
	    grid $newframe -in $w.holder -row 0 -column 0 -sticky nsew
	    grid columnconfig $w.holder 0 -weight 1
	    grid rowconfig $w.holder 0 -weight 1
	}
        set NBInfo($w,pages) [linsert $NBInfo($w,pages) end $name]
        _pageconfig $w $argarr
        _schedule_redraw $w
        # _raise_page $w $pagenum
        return $newframe
    }


    #
    # determine is a string is an integer
    #
    proc _isnumber {val} {
        if {![catch {string is integer $val} result]} {
            return $result
        }
        return [regexp -- {^[0-9][0-9]*$} $val]
    }


    #
    # Delete a page from the notebook widget
    #
    proc _delpage {w argarr} {
        variable NBInfo

        set name [lindex $argarr 0]
        set argarr [lrange $argarr 1 end]

        set i [_findpagenum $w $name]
        if {$i == ""} return

        set newpages {}
        if {$i > 0} {
            set newpages [lrange $NBInfo($w,pages) 0 [expr {$i-1}]]
        }
        if {$i < [llength $NBInfo($w,pages)]-1} {
            append newpages " "
            append newpages [lrange $NBInfo($w,pages) [expr {$i+1}] end]
        }
        set NBInfo($w,pages) $newpages
	if {$NBInfo($w,usetile)} {
	    _${w}_int forget $w.f$i
	}
        destroy $w.f$i
        foreach key [array names NBInfo "$w,p$i,*"] {
            unset NBInfo($key)
        }
        if {$i == $NBInfo($w,top)} {
            _nextpage $w 1
            _nextpage $w -1
        }
        _schedule_redraw $w
        return
    }


    #
    # Change configuration options for the notebook widget
    #
    proc _config {w argarr} {
        variable NBInfo
        if {[llength $argarr] > 1} {
	    if {$NBInfo($w,usetile)} {
		foreach {tag value} $argarr {
		    switch -- $tag {
			-changecmd  {bind $w <<NotebookTabChanged>> $value}
			-pages      {foreach page $value {_addpage $w $page}}
			-bg -
			-background {set NBInfo($w,background) $value}
			-fg -
			-foreground {set NBInfo($w,foreground) $value}
			-font -
			-loweredbg -
			-loweredfg -
			-textpadx {
			    set NBInfo($w,[string range $tag 1 end]) $value
			}
			default     {eval "_${w}_int config $argarr"}
		    }
		}
	    } else {
		foreach {tag value} $argarr {
		    switch -- $tag {
			-changecmd  { set NBInfo($w,changecmd) $value }
			-width      { set NBInfo($w,width) $value }
			-height     { set NBInfo($w,height) $value }
			-pad        { set NBInfo($w,pad) $value }
			-font       { set NBInfo($w,font) [font actual $value] }
			-bg -
			-background { set NBInfo($w,bg,raised) $value }
			-fg -
			-foreground { set NBInfo($w,fg,raised) $value }
			-loweredbg  { set NBInfo($w,bg,lowered) $value }
			-loweredfg  { set NBInfo($w,fg,lowered) $value }
			-textpadx   { set NBInfo($w,textpadx) $value }
			-pages      { foreach page $value { _addpage $w $page } }
			default     { eval "_${w}_int config $argarr" }
		    }
		}
		_schedule_redraw $w
	    }
        } else {
	    if {$NBInfo($w,usetile)} {
		set tag [lindex $argarr 0]
		switch -- $tag {
		    -changecmd  {return [bind $w <<NotebookTabChanged>>]}
		    -pages      {return $NBInfo($w,pages)}
		    -bg -
		    -background {return $NBInfo($w,background)}
		    -fg -
		    -foreground {return $NBInfo($w,foreground)}
		    -font -
		    -loweredbg -
		    -loweredfg -
		    -textpadx {
			return $NBInfo($w,[string range $tag 1 end])
		    }
		    default     {return [eval "_${w}_int config $argarr"]}
		}
	    } else {
		switch -- [lindex $argarr 0] {
		    -changecmd  { return $NBInfo($w,changecmd) }
		    -width      { return $NBInfo($w,width) }
		    -height     { return $NBInfo($w,height) }
		    -pad        { return $NBInfo($w,pad) }
		    -font       { return $NBInfo($w,font) }
		    -bg -
		    -background { return $NBInfo($w,bg,raised) }
		    -fg -
		    -foreground { return $NBInfo($w,fg,raised) }
		    -loweredbg  { return $NBInfo($w,bg,lowered) }
		    -loweredfg  { return $NBInfo($w,fg,lowered) }
		    -textpadx   { return $NBInfo($w,textpadx) }
		    -pages      { return $NBInfo($w,pages) }
		    default     { return [eval "_${w}_int config $argarr"] }
		}
	    }
        }
        return
    }


    #
    # Schedule a redraw.
    #
    proc _schedule_redraw {w} {
        variable NBInfo

	if {$NBInfo($w,usetile)} {
	    return ;# Tile widget is auto-drawn.
	}
        if {[info exists NBInfo($w,redrawid)]} {
            if {$NBInfo($w,redrawid) > 0} {
                after cancel $NBInfo($w,redrawid)
            }
        }
        set NBInfo($w,redrawid) [after idle ::NoteBook::_redraw $w]
    }


    #
    # Reconstruct and redraw the widget
    #
    proc _redraw {w} {
        variable NBInfo

	if {$NBInfo($w,usetile)} {
	    return ;# Tile widget is auto-drawn.
	}

        set pad $NBInfo($w,pad)
        set font $NBInfo($w,font)
        set textpadx $NBInfo($w,textpadx)
        set toppagenum $NBInfo($w,top)
        set height $NBInfo($w,height)
        set width $NBInfo($w,width)
        set hicolor $NBInfo($w,hilite)
        set locolor $NBInfo($w,shadow)

        $w.canvas delete all
        set id [$w.canvas create text -500 -500 -text {Wfqpgy!} -font $font -anchor nw]
        set tbox [$w.canvas bbox $id]
        set theight [expr {[lindex $tbox 3] - [lindex $tbox 1]}]
        set textheight [expr {$theight+6}]
        set NBInfo($w,textheight) $textheight
        $w.canvas delete $id

        set nbleft $pad
        set nbtop [expr {$pad+2}]
        set x2 [expr {$nbleft+2}]
        set x3 [expr {$x2+$width}]
        set x4 [expr {$x3+2}]
        set y1 $nbtop
        set tabheight $textheight
        set canvwidth [expr {$x4-$nbleft+0.0}]

        set totwidth 0
        set tabrow 1
        set tabnum 0
        set rowtabcnt 0
        set rowtabs($tabrow) {}
        set rowwidth($tabrow) 0
        foreach pagename $NBInfo($w,pages) {
            if {![info exists NBInfo($w,p$tabnum,state)]} {
                set NBInfo($w,p$tabnum,state) "enabled"
            }
            if {$NBInfo($w,p$tabnum,state) == "disabled"} {
                set pagestate "shadow"
            } else {
                set pagestate "fg,lowered"
            }
            set id [$w.canvas create text 0 0 -text $pagename -font $font -anchor nw -tags "p$tabnum t$tabnum l$tabnum" -fill $NBInfo($w,$pagestate)]
            set bbox [$w.canvas bbox $id]
            set idwidth [lindex $bbox 2]
            set NBInfo($w,p$tabnum,labelwidth) $idwidth
            set tabwidth [expr {$idwidth+2*$textpadx+5}]

            if {$totwidth + $tabwidth - 2 > $canvwidth && $rowtabcnt > 0} {
                incr tabrow
                set rowtabs($tabrow) {}
                set rowwidth($tabrow) 0
                set totwidth 0
                set rowtabcnt 0
            }
            incr totwidth $tabwidth
            incr rowwidth($tabrow) $tabwidth
            lappend rowtabs($tabrow) $tabnum
            incr tabnum
            incr rowtabcnt
        }
        set tabrows $tabrow
        set NBInfo($w,tabrows) $tabrows
        set numtabs [expr {$tabnum+1}]

        for {set iter 0} {$iter < $numtabs} {incr iter} {
            set biggestdiff 0
            set bigrow 0
            set bigdir 0
            for {set rownum 1} {$rownum < $tabrows} {incr rownum} {
                set nextrow [expr {$rownum+1}]
                set diff [expr {$rowwidth($rownum) - $rowwidth($nextrow)}]
                if {abs($diff) > $biggestdiff} {
                    set biggestdiff [expr {abs($diff)}]
                    set bigrow $rownum
                    set bigdir [expr {$diff/abs($diff)}]
                }
            }
            if {$bigrow > 0} {
                set nextrow $bigrow
                incr nextrow
                if {$bigdir > 0} {
                    set tabnum [lindex $rowtabs($bigrow) end]
                    set idwidth $NBInfo($w,p$tabnum,labelwidth)
                    set tabwidth [expr {$idwidth+2*$textpadx+5}]
                    set bigrowcnt [llength $rowtabs($bigrow)]
                    if {$rowwidth($nextrow) + $tabwidth - 2 <= $canvwidth && $bigrowcnt > 1} {
                        if {$rowwidth($nextrow) < $rowwidth($bigrow) - $tabwidth} {
                            incr rowwidth($bigrow) -$tabwidth
                            incr rowwidth($nextrow) $tabwidth
                            set rowtabs($nextrow) [concat $tabnum $rowtabs($nextrow)]
                            set rowtabs($bigrow) [lrange $rowtabs($bigrow) 0 [expr {$bigrowcnt-2}]]
                        }
                    }
                } else {
                    set tabnum [lindex $rowtabs($nextrow) 0]
                    set idwidth $NBInfo($w,p$tabnum,labelwidth)
                    set tabwidth [expr {$idwidth+2*$textpadx+5}]
                    set bigrowcnt [llength $rowtabs($nextrow)]
                    if {$rowwidth($bigrow) + $tabwidth - 2 <= $canvwidth && $bigrowcnt > 1} {
                        if {$rowwidth($bigrow) < $rowwidth($nextrow) - $tabwidth} {
                            incr rowwidth($nextrow) -$tabwidth
                            incr rowwidth($bigrow) $tabwidth
                            set rowtabs($bigrow) [concat $rowtabs($bigrow) $tabnum]
                            set rowtabs($nextrow) [lrange $rowtabs($nextrow) 1 end]
                        }
                    }
                }
            } else {
                break
            }
        }

        set rowpadx($tabrow) 0
        set toppagerow 1
        for {set rownum 1} {$rownum <= $tabrows} {incr rownum} {
            set rowtabcnt [llength $rowtabs($rownum)]
            if {$tabrows > 1} {
                set rowpadx($rownum) [expr {($canvwidth - ($rowwidth($rownum)-2)) / $rowtabcnt}]
            }
            foreach tabnum $rowtabs($rownum) {
                set NBInfo($w,p$tabnum,tabrow) $tabrow
                if {$tabnum == $toppagenum} {
                    set toppagerow $rownum
                }
            }
        }

        set roworder {}
        for {set i $toppagerow} {$i >= 1} {incr i -1} {
            if {$i != $toppagerow} {
                lappend roworder $i
            }
        }
        for {set i $tabrows} {$i >= $toppagerow} {incr i -1} {
            lappend roworder $i
        }

        grid columnconfig $w 0 -minsize [expr {$pad + 1}]
        grid columnconfig $w 1 -weight 1
        grid columnconfig $w 2 -minsize [expr {$pad + 1}]
        grid rowconfig $w 0 -minsize [expr {($tabrows * $tabheight) + $y1 + 1}]
        grid rowconfig $w 1 -weight 1
        grid rowconfig $w 2 -minsize [expr {$pad + 1}]
        grid $w.canvas -row 0 -column 0 -columnspan 3 -rowspan 3 -sticky nsew
        grid $w.holder -row 1 -column 1 -sticky nsew
        raise $w.holder

        set y $nbtop
        set expval 2
        foreach rownum $roworder {
            set firstrowtab 1
            set x $nbleft
            set y2 [expr {$y+2}]
            set y5 [expr {$y+$textheight}]
            set y6 [expr {$y5+2}]
            set y7 [expr {$y+3}]
            foreach tabnum $rowtabs($rownum) {
                set p [lindex $NBInfo($w,pages) $tabnum]
                set NBInfo($w,p$tabnum,left) $x
                set NBInfo($w,p$tabnum,top) $y
                if {$NBInfo($w,p$tabnum,state) == "disabled"} {
                    set pagestate "shadow"
                    set id [$w.canvas create text 0 0 -text $p -font $font -anchor nw -tags "p$tabnum" -fill $hicolor]
                    $w.canvas move $id [expr {$x+$textpadx+3}] [expr {$y7+1}]
                } else {
                    set pagestate "fg,lowered"
                }
                set width $NBInfo($w,p$tabnum,labelwidth)
                set tabwidth [expr {$width+2*$textpadx+$rowpadx($rownum)}]
                $w.canvas move l$tabnum [expr {$x+$textpadx+2}] $y7
                set lexp 0
                if {$tabnum == $toppagenum && $x > $nbleft} {
                    set lexp $expval
                }
                set rexp 0
                if {$tabnum == $toppagenum && int($x+$tabwidth+3.5) < $x4} {
                    set rexp $expval
                }
                set texp 0
                if {$tabnum == $toppagenum} {
                    set texp $expval
                }
                set rectbot $y5
                if {$rownum != $toppagerow} {
                    incr rectbot 2
                    incr rectbot $texp
                }
                $w.canvas create rectangle \
                    [expr {$x+1-$lexp}] [expr {$y-1}] \
                    [expr {$x+$tabwidth+3+$rexp}] $rectbot \
                    -fill $NBInfo($w,bg,lowered) -outline {} \
                    -tags [list b$tabnum t$tabnum]
                $w.canvas create line \
                    [expr {$x-$lexp}] [expr {$y5-2}] \
                    [expr {$x-$lexp}] $y2 \
                    [expr {$x+2-$lexp}] $y \
                    [expr {$x+$tabwidth+$rexp}] $y \
                    -width 2 -fill $hicolor -tags [list p$tabnum hl$tabnum]
                $w.canvas create line \
                    [expr {$x+$tabwidth+$rexp}] $y \
                    [expr {$x+$tabwidth+3+$rexp}] $y2 \
                    [expr {$x+$tabwidth+3+$rexp}] [expr {$y5-2}] \
                    -width 2 -fill $locolor -tags [list p$tabnum sl$tabnum]

                if {$x == $nbleft || $rownum != $toppagerow} {
                    $w.canvas create line \
                        [expr {$x-$lexp}] [expr {$y6-2}] \
                        [expr {$x-$lexp}] [expr {$y5-2}] \
                        -width 2 -fill $hicolor -tags [list p$tabnum sl$tabnum tu$tabnum]
                }

                if {int($x+$tabwidth+3.5) >= $x4 || $rownum != $toppagerow} {
                    $w.canvas create line \
                        [expr {$x+$tabwidth+3+$rexp}] [expr {$y6-1}] \
                        [expr {$x+$tabwidth+3+$rexp}] [expr {$y5-2}] \
                        -width 2 -fill $locolor -tags [list p$tabnum sl$tabnum tu$tabnum]
                }

                $w.canvas lower b$tabnum
                $w.canvas raise tu$tabnum

                set x [expr {$x+$tabwidth+5}]
                set NBInfo($w,p$tabnum,right) [expr {$x-2}]
                set NBInfo($w,p$tabnum,bottom) [expr {$y+$tabheight}]
                if {![winfo exists $w.f$tabnum]} {
                    frame $w.f$tabnum -bd 0 -class "NotebookPage"
                }
                $w.f$tabnum config -bg $NBInfo($w,bg,raised)
                set firstrowtab 0
            }
            incr y $tabheight
        }

        set y3 [expr {$y6+$height}]
        set y4 [expr {$y3+2}]

        # Left notebook border
        $w.canvas create line \
            $nbleft [expr {$y5-2}] \
            $nbleft $y3 \
            -width 2 -fill $hicolor

        # Bottom/right notebook border
        $w.canvas create line \
            $nbleft $y3 \
            $x2 $y4 \
            $x3 $y4 \
            $x4 $y3 \
            $x4 $y6 \
            -width 2 -fill $locolor

        # draw line under tabs, left of raised tab
        if {[info exists NBInfo($w,p$toppagenum,left)]} {
            set toppgleft $NBInfo($w,p$toppagenum,left)
        } else {
            set toppgleft $nbleft
        }
        if {$toppgleft > $nbleft} {
            set lexp $expval
            $w.canvas create line \
                $nbleft $y6 \
                $x2 $y5 \
                [expr {($toppgleft-2)-$lexp}] $y5 \
                [expr {$toppgleft-$lexp}] [expr {$y5-5}] \
                -width 2 -fill $hicolor -tags topline
        }

        # draw line under tabs, right of raised tab
        if {[info exists NBInfo($w,p$toppagenum,right)]} {
            set toppgright $NBInfo($w,p$toppagenum,right)
        } else {
            set toppgright $nbleft
        }
        if {$toppgright <= $x4-1} {
            set rexp $expval
            $w.canvas create line \
                $x4 $y6 \
                $x3 $y5 \
                -width 2 -fill $locolor
            $w.canvas create line \
                [expr {$toppgright+$rexp}] [expr {$y5-3}] \
                [expr {$toppgright+2+$rexp}] $y5 \
                $x3 $y5 \
                -width 2 -fill $hicolor -tags topline
        } else {
            $w.canvas create line \
                $x4 $y6 \
                $x4 $y5 \
                -width 2 -fill $locolor
            $w.canvas create line \
                [expr {$toppgright+$rexp}] [expr {$y6+1}] \
                [expr {$toppgright+$rexp}] [expr {$y5-2}] \
                -width 2 -fill $locolor -tags [list p$tabnum sl$tabnum tu$tabnum]
        }

        # Color raised tab if not disabled
        if {[info exists NBInfo($w,p$toppagenum,state)]} {
            if {$NBInfo($w,p$toppagenum,state) != "disabled"} {
                $w.canvas itemconfig t$toppagenum -fill $NBInfo($w,fg,raised)
            }
            $w.canvas itemconfig b$toppagenum -fill $NBInfo($w,bg,raised)
            $w.canvas move p$toppagenum 0 -2

            $w.canvas raise b$toppagenum
            $w.canvas raise p$toppagenum
            $w.canvas raise topline
            $w.canvas raise hl$toppagenum
            $w.canvas raise sl$toppagenum
            raise $w.f$toppagenum

            # Work around OS X bug with Aqua controls showing through raised frames
            after idle [list ::NoteBook::_osx_redraw_error_workaround $w.f$toppagenum]
        }

        # adjust canvas size as needed.
        if {![info exists NBInfo($w,redrawing)]} {
            $w.canvas config -width [expr {$x4+$pad}] \
                -height [expr {$y4+$pad}] \
                -bg $NBInfo($w,bg,raised)
            set NBInfo($w,redrawing) 1
        } else {
            unset NBInfo($w,redrawing)
        }

        unset NBInfo($w,redrawid)
    }


    #
    # Work around OS X bug with Aqua controls showing through raised frames
    #
    proc _osx_redraw_error_workaround {w} {
        $w configure -background [$w cget -background]
    }


    #
    # Change the page-specific configuration options for the notebook
    #
    proc _pageconfig {w argarr} {
        variable NBInfo

        set name [lindex $argarr 0]
        set argarr [lrange $argarr 1 end]

        set i [_findpagenum $w $name]
        if {$i == ""} return
	if {$NBInfo($w,usetile)} {
	    foreach {tag value} $argarr {
		switch -- $tag {
		    -state  { _${w}_int tab $w.f$i -state $value }
		    -onexit { set NBInfo($w,p$i,onexit) $value }
		}
            }
	} else {
	    foreach {tag value} $argarr {
		switch -- $tag {
		    -state  { set NBInfo($w,p$i,state)  $value }
		    -onexit { set NBInfo($w,p$i,onexit) $value }
		}
            }
	    _schedule_redraw $w
        }
    }


    #
    # This procedure raises a notebook page given its name.  But first
    # we check the "onexit" procedure for the current page (if any) and
    # if it returns false, we don't allow the raise to proceed.
    #
    proc _raise_by {w name} {
        variable NBInfo

        set i [_findpagenum $w $name]
        if {$i == ""} return
        if {[info exists NBInfo($w,p$i,onexit)]} {
            set onexit $NBInfo($w,p$i,onexit)
            if {"$onexit"!="" && [eval uplevel #0 $onexit]!=0} {
                _raise_page $w $i
            }
        } else {
            _raise_page $w $i
        }
    }


    #
    # Return the frame associated with a given page of the notebook.
    #
    proc _findpage {w name} {
        set num [_findpagenum $w $name]
        if {$num == ""} {
            return {}
        } else {
            return $w.f$num
        }
    }



    #
    # Returns true if the given control is in the currently selected page.
    #
    proc _isvisible {widget} {
        variable NBInfo

        if {$widget == {}} {
            return 0
        }
        set w $widget
        set top [winfo toplevel $w]
        while {$w != $top && [winfo class $w] != "NotebookPage"} {
            set w [winfo parent $w]
        }
        if {$w == $top} {
            return [winfo viewable $widget]
        }
        set notebook [winfo parent $w]
        if {"$notebook.f$NBInfo($notebook,top)" == $w} {
            return [_isvisible $notebook]
        }
        return 0
    }


    #
    # Change focus to the next visible control.
    #
    proc _nextfocus {lastfocus dir} {
        if {$lastfocus == {}} {
            set lastfocus [focus]
            if {$lastfocus == {}} {
                return {}
            }
        }
        if {$dir >= 0} {
            set nextfocus [tk_focusNext $lastfocus]
        } else {
            set nextfocus [tk_focusPrev $lastfocus]
        }
        set lastfocus $nextfocus
        while {![_isvisible $nextfocus]} {
            if {$dir >= 0} {
                set nextfocus [tk_focusNext $nextfocus]
            } else {
                set nextfocus [tk_focusPrev $nextfocus]
            }
            if {$nextfocus == $lastfocus} {
                break;
            }
        }
        return $nextfocus
    }


    #
    # Returns the current page showing
    #
    proc _currentframe {w} {
        variable NBInfo
        set top $NBInfo($w,top)
        return $top
    }


    #
    # Change to the previous/next page in the notebook.
    #
    proc _nextpage {w dir} {
        variable NBInfo
        set max [llength $NBInfo($w,pages)]
        set top $NBInfo($w,top)
        set next [expr {(($top + $max) + $dir) % $max}]
        _raise_page $w $next
    }


    #
    # This routine is called whenever the mouse-button is pressed over
    # the notebook.  It determines if any page should be raised and raises
    # that page.
    #
    proc _process_click {w x y} {
        variable NBInfo
        set N [llength $NBInfo($w,pages)]
        for {set i 0} {$i<$N} {incr i} {
            if {$x>=$NBInfo($w,p$i,left) && $x<=$NBInfo($w,p$i,right)} {
                if {$y>=$NBInfo($w,p$i,top) && $y<=$NBInfo($w,p$i,bottom)} {
                    _raise_page $w $i
                    break
                }
            }
        }
    }


    #
    # For internal use only.  This procedure cleans up data for the notebook
    # when it is destroyed.
    #
    proc _destroy {w} {
        variable NBInfo
        foreach key [array names NBInfo "$w,*"] {
            unset NBInfo($key)
        }
    }


    #
    # For internal use only.  This procedure finds the number of the page
    # corresponding to the given name, number, or windowname.
    # 
    proc _findpagenum {w name} {
        variable NBInfo

        if {$name == "curr"} {
            set i $NBInfo($w,top)
        } elseif {[_isnumber $name]} {
            set i $name
        } else {
            if {[winfo exists $name] && [winfo class $name] == "NotebookPage"} {
                set len [string length "$w.p"]
                set num [string range $name $len end]
                if {[_isnumber $num]} {
                    set i $num
                }
            } else {
                set i [lsearch $NBInfo($w,pages) $name]
            }
        }
        if {$i>=0 && $i<[llength $NBInfo($w,pages)]} {
            return $i
        } else {
            return {}
        }
    }



    #
    # For internal use only.  This procedure raised the n-th page of
    # the notebook
    #
    proc _raise_page {w n} {
        variable NBInfo
        if {$n<0 || $n>=[llength $NBInfo($w,pages)]} return
        if {[info exists NBInfo($w,lastraised)]} {
            if {$n != $NBInfo($w,lastraised)} {
                if {[info exists NBInfo($w,changecmd)]} {
                    uplevel #0 $NBInfo($w,changecmd)
                }
            }
        }
        set NBInfo($w,lastraised) $n
        set NBInfo($w,top) $n
	if {$NBInfo($w,usetile)} {
	    _${w}_int select $w.f$n
	} else {
	    _schedule_redraw $w
	    if {![_isvisible [focus]]} {
		focus [_nextfocus [focus] 1]
	    }
	}
    }


    #
    # For internal use only.  Handles resizing of the notebook widget, resizing
    # all the frames, as apropriate.
    #
    proc _resize {w width height} {
        variable NBInfo
        if {![info exists NBInfo($w,resizelock)]} {
            set NBInfo($w,resizelock) 1
			set width [winfo reqwidth $w]
			set height [winfo reqheight $w]
            incr width -[expr {2*$NBInfo($w,pad)+4}]
            incr height -[expr {2*$NBInfo($w,pad)+6+$NBInfo($w,tabrows)*$NBInfo($w,textheight)}]
            set NBInfo($w,width) $width
            set NBInfo($w,height) $height
            _schedule_redraw $w
            unset NBInfo($w,resizelock)
        }
    }


    #
    # Calculates a new color, darkened or lightened from an existing color.
    #
    proc _colorShade {color percent} {
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
}

bind all <Shift-Key-Tab> {focus [::NoteBook::_nextfocus %W -1];break}
bind all <Key-Tab> {focus [::NoteBook::_nextfocus %W 1];break}


global treb_version
if {![info exists treb_version]} {
    #################################
    # The following code implements an example of using the
    # notebook widget.
    #

    notebook .n
    pack .n -expand 1 -fill both
    set w [.n addpage One]
    label $w.l -text "Hello.\nThis is page One."
    pack $w.l -side top -padx 10 -pady 50
    set w [.n addpage Two]
    frame $w.fr -relief sunken -borderwidth 2
    pack $w.fr -side left -fill both -expand 1 -padx 5 -pady 5
    scrollbar $w.fr.sb -orient vertical -command "$w.fr.t yview"
    pack $w.fr.sb -side right -fill y -expand 0
    text $w.fr.t -font fixed -yscrollcommand "$w.fr.sb set" -width 40 -relief flat -borderwidth 0
    $w.fr.t insert end "This is a text widget.  Type in it, if you want\n"
    pack $w.fr.t -side right -fill both -expand 1
    focus $w.fr.t
    set w [.n addpage Three]
    set p3 black
    frame $w.f
    pack $w.f -padx 20 -pady 20
    foreach c {black red orange yellow green blue violet white} {
        radiobutton $w.f.$c -fg $c -text $c -variable p3 -value $c -anchor w -command {
            .n config -fg $p3
        }
        pack $w.f.$c -side top -fill x -expand 0
    }
    set w [.n addpage Four]
    frame $w.f
    pack $w.f -padx 30 -pady 30
    button $w.f.b -text {Goto} -command [format {
        set i [%s cursel]
        if {[string length $i]>0} {
            .n raise [%s get $i]
        }
    } $w.f.lb $w.f.lb]
    pack $w.f.b -side bottom -expand 1 -pady 5
    scrollbar $w.f.sb -orient vertical -command "$w.f.lb yview"
    listbox $w.f.lb -yscrollcommand "$w.f.sb set"
    pack $w.f.sb -side right -fill y -expand 0
    pack $w.f.lb -side right -expand 1 -fill both
    $w.f.lb insert end One Two Three Four Five
    set w [.n addpage Five]
    button $w.b -text Exit -command exit
    pack $w.b -side top -expand 1
    .n pageconfig Four -state disabled
}

