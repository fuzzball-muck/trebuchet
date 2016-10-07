package require http

# http://trebuchet.cvs.sourceforge.net/viewvc/trebuchet/trebuchet/changes.txt

# Go into the properties of the icon/link/thing and change the Target to
#  "C:\Program Files (x86)\Fuzzball\Trebuchet\start.tcl" and go into
#  the programs file and set the start.tcl to run in
#  "C:\Program Files (x86)\Fuzzball\Trebuchet\tclkit\tcl-kit.exe"

::tcl::OptProc /web_upgrade {
    {-nowarns          {Don't put up dialogs if we won't update.}}
    {-force            {Don't ask to update, just do it.}}
    {-timeout     0    {Timeout in milliseconds, for initial check.}}
    {?scripturl   {}   {The URL of the upgrade script to check.}}
} {
    global treb_revision
    set result "ok"
    if {$scripturl == ""} {
        set scripturl "http://raw.githubusercontent.com/revarbat/trebuchet/master/changes.txt"
    }
    set errcode [catch {/web_fetch $scripturl -title "Update" -caption "Checking for updates..." -timeout $timeout} data]
    if {$errcode != 0} {
        /web_fetch_complete
        if {[/prefs:get use_http_proxy]} {
            set mesg "Unable to connect to GitHub.\nPerhaps your proxy settings are incorrect?\nError: $data"
        } else {
            set mesg "Unable to connect to GitHub.  Please try again later,\nor contact your system's administrator if the problem persists.\nError: $data"
        }
        tk_messageBox -type ok -icon error -title "Update" -message $mesg
        return
    }
    set cfgdata [split $data "\n"]
    set newrev [lindex [split [lindex $cfgdata 0] " "] 1]
    set newrev [join [split $newrev "."] ""]
    if {$data != {} && $newrev > $treb_revision} {
        if {!$force} {
            set result [tk_messageBox -type okcancel -default ok -icon info -title "Update" -message \
                "There is a new version of Trebuchet! ($newrev)\nClick Ok to go to the download website."]
            if {$result == "cancel"} {
                return
            }
        }
        /web_view "https://github.com/revarbat/trebuchet/releases"
    } else {
        if {!$nowarns} {
            tk_messageBox -type ok -icon info -title "Update" -message "No upgrades are currently available."
        }
    }
}

proc /web_fetch_complete {} {
    destroy .webprogwin
}

proc webcache:updatelru {url} {
    global treb_web_cache_dir
    global treb_web_cache_map

    if {![info exists treb_web_cache_map(lru)]} {
        set treb_web_cache_map(lru) {}
    }
    set pos [lsearch -exact $treb_web_cache_map(lru) $url]
    if {$pos != -1} {
        if {$pos == 0} {
            set treb_web_cache_map(lru) [lrange $treb_web_cache_map(lru) 1 end]
        } else {
            set tmpstart [lrange $treb_web_cache_map(lru) 0 [expr $pos - 1]]
            set tmpend [lrange $treb_web_cache_map(lru) [expr $pos + 1] end]
            set treb_web_cache_map(lru) [concat $tmpstart $tmpend]
        }
    }
    lappend treb_web_cache_map(lru) $url
    if {[llength $treb_web_cache_map(lru)] > 128} {
        set delurl [lindex $treb_web_cache_map(lru) 0]
        set treb_web_cache_map(lru) [lrange $treb_web_cache_map(lru) 1 end]
        if {[info exists treb_web_cache_map(cachefile,$delurl)]} {
            set delfile $treb_web_cache_map(cachefile,$delurl)
            file delete -force [file join $treb_web_cache_dir $delfile]
        }
    }
}


proc webcache:checkmeta {url metadata} {
    global treb_web_cache_map
    global treb_web_cache_dir

    array set meta $metadata
    array set cachemeta $treb_web_cache_map(meta,$url)
    foreach key [list Last-Modified Content-Type] {
        if {[info exists meta($key)] && [info exists cachemeta($key)]} {
            if {$meta($key) != $cachemeta($key)} {
                return 0;
            }
        }
    }
    if {[info exists meta(Content-Length)]} {
        if {$meta(Content-Length) != 0} {
            if {$meta(Content-Length) != $cachemeta(Content-Length)} {
                return 0
            }
            set cachefile $treb_web_cache_map(cachefile,$url)
            set cachefilesize [file size [file join $treb_web_cache_dir $cachefile]]
            if {$meta(Content-Length) != $cachefilesize} {
                return 0
            }
        }
    }
    return 1;
}

proc webcache:update {url cachefile status metadata} {
    global treb_web_cache_dir
    global treb_web_cache_map
    if {$status == "ok"} {
        if {[catch {
            set treb_web_cache_map(cachefile,$url) $cachefile
            webcache:updatelru $url
            foreach {key val} $metadata {
                if {[lsearch -exact [list Content-Length Content-Type Last-Modified] $key] != -1} {
                    lappend metasave $key
                    lappend metasave $val
                }
            }
            set treb_web_cache_map(meta,$url) $metasave
        } result]} {
            set img {}
        }
    }
}


#/webcache:fetch http://www.belfry.com/ -quiet -command "/echo 1:"
#/webcache:fetch http://www.belfry.com/ -quiet -command "/echo 2:"

proc webcache:progress {url totalbytes currbytes} {
    global treb_web_cache_state
    for {set i 1} {$i <= $treb_web_cache_state(pending,$url)} {incr i} {
        if {[info exists treb_web_cache_state(progress,$i,$url)]} {
            set command $treb_web_cache_state(progress,$i,$url)
            if {[catch {
                eval "$command $totalbytes $currbytes"
            } result]} {
                global errorInfo
                /echo -style error "Error in callback:\n$errorInfo"
            }
        }
    }
}


proc webcache:finish {url cachefile status} {
    global treb_web_cache_dir
    global treb_web_cache_map
    global treb_web_cache_waitvar
    global treb_web_cache_state

    set treb_web_cache_state(status,$url) $status
    set cachefilepath [file join $treb_web_cache_dir $cachefile]
    for {set i 1} {$i <= $treb_web_cache_state(pending,$url)} {incr i} {
        set data {}
        if {$status == "ok"} {
            set targfile {}
            if {[info exists treb_web_cache_state(outfile,$i,$url)]} {
                set targfile treb_web_cache_state(outfile,$i,$url)
            }
            set byfile 0
            if {[info exists treb_web_cache_state(byfile,$i,$url)]} {
                set byfile $treb_web_cache_state(byfile,$i,$url)
            }
            if {$targfile != {}} {
                file copy $cachefilepath $targfile
                if {$byfile} {
                    set data $cachefilepath
                }
            } else {
                if {$byfile} {
                    set data $cachefilepath
                } else {
                    set f [open $cachefilepath "r"]
                    set data [read $f]
                    close $f
                }
            }
        }
        if {[info exists treb_web_cache_state(cmd,$i,$url)]} {
            set command $treb_web_cache_state(cmd,$i,$url)
            if {[catch {
                eval "$command $status [list $data]"
            } result]} {
                global errorInfo
                /echo -style error "Error in callback:\n$errorInfo"
            }
        }
        catch { unset treb_web_cache_state(cmd,$i,$url) }
        catch { unset treb_web_cache_state(progress,$i,$url) }
        catch { unset treb_web_cache_state(outfile,$i,$url) }
        catch { unset treb_web_cache_state(byfile,$i,$url) }
    }
    catch { unset treb_web_cache_state(pending,$url) }
    catch { unset treb_web_cache_state(state,$url) }
    catch { unset treb_web_cache_waitvar($url) }
}


proc webcache:complete {url cachefile status data metadata} {
    if {$status == "ok"} {
        webcache:update $url $cachefile $status $metadata
    }
    webcache:finish $url $cachefile $status
}


proc webcache:validate {url targfile cachefile command progress caption title filenum filecount bytescurr bytestotal quiet persistent byfile pendnum status data metadata} {
    if {$status == "ok"} {
        if {![webcache:checkmeta $url $metadata]} {
            set fetchcmd "/webcache:fetch [list $url]"
            append fetchcmd " -file [list $targfile]"
            append fetchcmd " -command [list $command]"
            append fetchcmd " -progress [list $progress]"
            append fetchcmd " -caption [list $caption]"
            append fetchcmd " -title [list $title]"
            append fetchcmd " -filenum [list $filenum]"
            append fetchcmd " -filecount [list $filecount]"
            append fetchcmd " -bytescurr [list $bytescurr]"
            append fetchcmd " -bytestotal [list $bytestotal]"
            append fetchcmd " -reentry $pendnum"
            append fetchcmd " -force"
            if {$quiet}      { append fetchcmd " -quiet" }
            if {$byfile}     { append fetchcmd " -byfile" }
            if {$persistent} { append fetchcmd " -persistent" }
            eval $fetchcmd
            return
        }
        webcache:updatelru $url
    }
    webcache:finish $url $cachefile $status
}


::tcl::OptProc /webcache:fetch {
    {url          {}   {The URL of the file to download.}}
    {-file        {}   {The file to save the fetched data to.}}
    {-caption     {}   {Caption to display in progress window.}}
    {-title       {}   {Title to display for the progress window.}}
    {-command     {}   {Command to run when done.  Fetch is asynch.  Three args appended to code: fetch status, data fetched, metadata.}}
    {-progress    {}   {Command to run while fetching.  Two args appended to code: total bytes, current bytes.}}
    {-filenum     1    {Which file number is being downloaded.}}
    {-filecount   1    {The total number of files in this batch.}}
    {-bytescurr   0    {How many bytes have been downloaded so far.}}
    {-bytestotal  0    {The total number of bytes in this batch.}}
    {-quiet            {Do not create the progress window.}}
    {-persistent       {Do not destroy the progress window.}}
    {-force            {Always fetch a new copy from the server.}}
    {-byfile           {Give the cachefile name as the data result.}}
    {-reentry     0    {Gives the pendnum for reentry.}}
} {
    global treb_web_cache_dir
    global treb_web_cache_map
    global treb_web_cache_waitvar
    global treb_web_cache_state

    if {!$force && [info exists treb_web_cache_state(state,$url)]} {
        set pendnum [incr treb_web_cache_state(pending,$url)]
        if {$progress != {}} {
            set treb_web_cache_state(progress,$pendnum,$url) $progress
        }
        if {$file != {}} {
            set treb_web_cache_state(outfile,$pendnum,$url) $file
        }
        if {$byfile} {
            set treb_web_cache_state(byfile,$pendnum,$url) $byfile
        }
        if {$command != {}}  {
            set treb_web_cache_state(cmd,$pendnum,$url) $command
            return
        } else {
            catch { vwait treb_web_cache_waitvar($url) }
        }
        set cachefile $treb_web_cache_map(cachefile,$url)
        set cachefilepath [file join $treb_web_cache_dir $cachefile]
        set status $treb_web_cache_state(status,$url)
        webcache:finish $url $cachefile $status
    } else {
        if {![info exists treb_web_cache_state(pending,$url)]} {
            set treb_web_cache_state(pending,$url) 1
            set pendnum 1
        } elseif {$reentry} {
            set pendnum $reentry
        } else {
            set pendnum [incr treb_web_cache_state(pending,$url)]
        }
        if {!$force && [info exists treb_web_cache_map(cachefile,$url)]} {
            set cachefile $treb_web_cache_map(cachefile,$url)
            set cachefilepath [file join $treb_web_cache_dir $cachefile]
            set metadata {}

            if {$command != {}} {
                set treb_web_cache_state(cmd,$pendnum,$url) $command
            }
            if {$progress != {}} {
                set treb_web_cache_state(progress,$pendnum,$url) $progress
            }
            if {$file != {}} {
                set treb_web_cache_state(outfile,$pendnum,$url) $file
            }
            if {$byfile} {
                set treb_web_cache_state(byfile,$pendnum,$url) $byfile
            }

            set fetchcmd "/web_fetch [list $url]"
            append fetchcmd " -caption [list $caption]"
            append fetchcmd " -title [list $title]"
            append fetchcmd " -filenum [list $filenum]"
            append fetchcmd " -filecount [list $filecount]"
            append fetchcmd " -bytescurr [list $bytescurr]"
            append fetchcmd " -bytestotal [list $bytestotal]"
            if {$command != {}} {
                append fetchcmd " -command [list [list webcache:validate $url $file $cachefile $command $progress $caption $title $filenum $filecount $bytescurr $bytestotal $quiet $persistent $byfile $pendnum]]"
            } else {
                append fetchcmd " -metavar metadata"
            }
            append fetchcmd " -validate"
            append fetchcmd " -quiet"
            set treb_web_cache_waitvar($url) 1
            set treb_web_cache_state(state,$url) "validating"
            set errcode [catch $fetchcmd result]
            if {$errcode != 0} {
                global errorInfo
                set savedInfo $errorInfo
                error $result $savedInfo $errcode
            }
            if {$command != {}} {
                return
            }
            if {$errcode || [webcache:checkmeta $url $metadata]} {
                webcache:updatelru $url
                webcache:finish $url $cachefile [lindex $result 0]
                set data {}
                if {$file == {}} {
                    set f [open $cachefilepath "r"]
                    set data [read $f]
                    close $f
                    return $data
                } else {
                    file copy $cachefilepath $file
                    return $result
                }
            }
        }

        # Load file into cache.
        if {![info exists treb_web_cache_map(cachefile,$url)]} {
            while {1} {
                set cachefile "[expr {int(rand() * 1000000000.0)}].tmp"
                if {![file exists [file join $treb_web_cache_dir $cachefile]]} {
                    break
                }
            }
        } else {
            set cachefile $treb_web_cache_map(cachefile,$url)
        }
        set cachefilepath [file join $treb_web_cache_dir $cachefile]
        set treb_web_cache_map(cachefile,$url) -
        set treb_web_cache_state(state,$url) "loading"
        set metadata {}

        if {$reentry == 0} {
            if {$command != {}} {
                set treb_web_cache_state(cmd,$pendnum,$url) $command
            }
            if {$progress != {}} {
                set treb_web_cache_state(progress,$pendnum,$url) $progress
            }
            if {$file != {}} {
                set treb_web_cache_state(outfile,$pendnum,$url) $file
            }
            if {$byfile} {
                set treb_web_cache_state(byfile,$pendnum,$url) $byfile
            }
        }
        set fetchcmd "/web_fetch [list $url]"
        append fetchcmd " -file [list $cachefilepath]"
        if {$command != {}} {
            append fetchcmd " -command [list [list webcache:complete $url $cachefile]]"
        } else {
            append fetchcmd " -metavar metadata"
        }
        append fetchcmd " -progress [list [list webcache:progress $url]]"
        append fetchcmd " -caption [list $caption]"
        append fetchcmd " -title [list $title]"
        append fetchcmd " -filenum [list $filenum]"
        append fetchcmd " -filecount [list $filecount]"
        append fetchcmd " -bytescurr [list $bytescurr]"
        append fetchcmd " -bytestotal [list $bytestotal]"
        if {$quiet}      { append fetchcmd " -quiet" }
        if {$persistent} { append fetchcmd " -persistent" }
        if {$reentry == 0} {
            set treb_web_cache_waitvar($url) 1
        }
        set errcode [catch $fetchcmd result]
        if {$errcode != 0} {
            global errorInfo
            set savedInfo $errorInfo
            catch { unset treb_web_cache_map(cachefile,$url) }
            error $result $savedInfo $errcode
        }
        if {$command != {}} {
            return
        }
        webcache:update $url $cachefile [lindex $result 0] $metadata
        webcache:finish $url $cachefile [lindex $result 0]
        if {$file == {}} {
            set f [open $cachefilepath "r"]
            set data [read $f]
            close $f
            return $data
        } else {
            file copy $cachefilepath $file
            return $result
        }
    }
}

::tcl::OptProc /web_fetch {
    {url          {}   {The URL of the file to download.}}
    {-file        {}   {The file to save the fetched data to.}}
    {-caption     {}   {Caption to display in progress window.}}
    {-title       {}   {Title to display for the progress window.}}
    {-command     {}   {Command to run when done.  Fetch is asynch.  Three args appended to code: fetch status, data fetched, metadata.}}
    {-progress    {}   {Command to run while fetching.  Two args appended to code: total bytes, current bytes.}}
    {-filenum     1    {Which file number is being downloaded.}}
    {-filecount   1    {The total number of files in this batch.}}
    {-bytescurr   0    {How many bytes have been downloaded so far.}}
    {-bytestotal  0    {The total number of bytes in this batch.}}
    {-timeout     0    {Time in millisecs before request times out.}}
    {-quiet            {A flag to tell it to not create the progress window.}}
    {-persistent       {A flag to tell it to not destroy the progress window.}}
    {-validate         {Only fetch metadata.}}
    {-metavar     {}   {Variable to store metadata list in.  Doesn't work with -command.}}
} {
    set progwin .webprogwin
    if {!$quiet} {
        if {![winfo exists $progwin]} {
            toplevel     $progwin
            wm resizable $progwin 0 0
            place_window_default $progwin
            label    $progwin.label
            label    $progwin.fetched
            canvas   $progwin.canvas -width 399 -height 19 -background white -borderwidth 1 -relief solid
            $progwin.canvas create rectangle 1 1 1 21 -fill #aaf -outline #aaf -tags filler
            $progwin.canvas create text 199 12 -fill black -tags pcnt -text "0%" -font {Helvetica 10 bold} -anchor center
            label    $progwin.filecnt
            label    $progwin.bytecnt
            canvas   $progwin.fcanvas -width 399 -height 19 -background white -borderwidth 1 -relief solid
            $progwin.fcanvas create rectangle 1 1 1 21 -fill #aaf -outline #aaf -tags filler
            $progwin.fcanvas create text 199 12 -fill black -tags pcnt -text "0%" -font {Helvetica 10 bold} -anchor center

            grid columnconfig $progwin 0 -minsize 15
            grid columnconfig $progwin 2 -minsize 15
            grid rowconfig $progwin  0 -minsize 20
            grid rowconfig $progwin  2 -minsize 5
            grid rowconfig $progwin  4 -minsize 10
            grid rowconfig $progwin  6 -minsize 20
            grid rowconfig $progwin  8 -minsize 0
            grid rowconfig $progwin 10 -minsize 10
            grid rowconfig $progwin 12 -minsize 20
            grid $progwin.label   -column 1 -row 1 -sticky w
            grid $progwin.fetched -column 1 -row 3 -sticky w
            grid $progwin.canvas  -column 1 -row 5 -sticky w
        } else {
            if {[wm state $progwin] == "withdrawn"} {
                wm deiconify $progwin
            }
        }
        set fname [lindex [split $url "/"] end]
        if {$title == {}} {
            wm title $progwin "Downloading $fname"
        } else {
            wm title $progwin $title
        }
        if {$caption == {}} {
            $progwin.label config -text "Downloading $fname..."
        } else {
            $progwin.label config -text $caption
        }
        $progwin.fetched config -text "Bytes fetched: 0"
        $progwin.canvas itemconfig pcnt -text "0%"
        $progwin.canvas coords filler 1 1 1 21

        if {$filecount > 1} {
            $progwin.filecnt config -text "Files fetched: $filenum of $filecount"
            grid $progwin.filecnt -column 1 -row 7 -sticky w
            set pcnt [expr {int(10000 * $filenum / $filecount) / 100.0}]
        } else {
            grid forget $progwin.filecnt
            grid forget $progwin.fcanvas
        }
        if {$bytestotal > 0} {
            if {$filecount > 1} {
                grid rowconfig $progwin 8 -minsize 0
            }
            $progwin.bytecnt config -text "Total bytes fetched: $bytescurr of $bytestotal"
            grid $progwin.bytecnt -column 1 -row 9 -sticky w
            set pcnt [expr {int(1000.0 * $bytescurr / $bytestotal) / 10.0}]
        } else {
            grid forget $progwin.bytecnt
        }
        if {$filecount > 1 || $bytestotal > 0} {
            set pixels [expr {int(4 * $pcnt) + 1}]
            grid $progwin.fcanvas -column 1 -row 11 -sticky w
            $progwin.fcanvas itemconfig pcnt -text "$pcnt%"
            $progwin.fcanvas coords filler 1 1 $pixels 21
        }
    }

    global treb_version
    ::http::config -useragent "Trebuchet Tk $treb_version client"
    if {[catch {/prefs:get use_http_proxy}] != 0} {
        prefs:add bool use_http_proxy 0  0     1 Http "Use HTTP Proxy Server for web fetches"
        prefs:add str  proxy_host     "" 0    40 Http "Proxy host"
        prefs:add int  proxy_port     0  0 65535 Http "Proxy port"
    }
    if {[/prefs:get use_http_proxy]} {
        ::http::config -proxyhost [/prefs:get proxy_host] -proxyport [/prefs:get proxy_port]
    } else {
        ::http::config -proxyhost "" -proxyport 0
    }

    set fetchcmd {::http::geturl $url}
    if {$file != ""} {
        set f [open $file "w"]
        append fetchcmd { -channel $f}
    } else {
        set f {}
    }
    if {$progress != {}} {
        append fetchcmd { -progress "web_fetch_progress_cb [list $progress]"}
    } elseif {!$quiet} {
        append fetchcmd { -progress "web_fetch_progress $progwin $bytestotal $bytescurr"}
    }
    if {$command != {}} {
        append fetchcmd { -command "web_fetch_complete_cb [list $file] [list $f] [list $command]"}
    }
    if {$validate} {
        append fetchcmd { -validate 1}
    }
    if {$timeout > 0} {
        append fetchcmd { -timeout $timeout}
    }
    set errcode [catch $fetchcmd token]
    if {$command != {}} {
        return
    }
    if {$errcode != 0} {
        global errorInfo
        set savedInfo $errorInfo
        if {$file != ""} {
            close $f
            file delete $file
        }
        error $token $savedInfo
    }
    if {$file != ""} {
        close $f
    }
    if {!$persistent && !$quiet} {
        /web_fetch_complete
    }
    set status [::http::status $token]
    set data {}
    if {$status == "ok"} {
        if {$file == ""} {
            set data [::http::data $token]
        }
    }
    if {$metavar != {}} {
        upvar $metavar mymeta
        upvar #0 $token state
        set mymeta $state(meta)
    }
    if {[catch {::http::cleanup $token}]} {
        catch {
            global $token
            unset $token
        }
    }
    if {$file == {}} {
        return $data
    } else {
        return $status
    }
}

proc web_fetch_complete_cb {file channel cmd token} {
    if {[catch {
        if {$channel != {}} {
            close $channel
        }
        set status [::http::status $token]
        set data {}
        set meta {}
        if {$status == "ok"} {
            upvar #0 $token state
            if {$file == {}} {
                set data [::http::data $token]
            }
            set meta $state(meta)
        } else {
            if {$file != {}} {
                file delete $file
            }
        }
        eval $cmd $status [list $data] [list $meta]
    } result]} {
        global errorInfo
        set savedInfo $errorInfo
        error $savedInfo
    }
    if {[catch {::http::cleanup $token}]} {
        catch {
            global $token
            unset $token
        }
    }
    return
}

proc web_fetch_progress_cb {cmd token total current} {
    # FOO: catch {
        eval "$cmd $total $current"
    #}
    return
}

proc web_fetch_progress {wname batchtotal batchcurr token total current} {
    upvar #0 $token state
    if {$total == 0} {
        $wname.fetched config -text "Bytes fetched: $current"
        return
    }
    $wname.fetched config -text "Bytes fetched: $current of $total"
    set pcnt [expr {int(1000.0 * $current / $total) / 10.0}]
    set pixels [expr {int(4 * $pcnt) + 1}]
    $wname.canvas itemconfig pcnt -text "$pcnt%"
    $wname.canvas coords filler 1 1 $pixels 21

    if {$batchtotal > 0} {
        set bcurr [expr {$batchcurr + $current}]
        $wname.bytecnt config -text "Total bytes fetched: $bcurr of $batchtotal"
        set pcnt [expr {int(1000.0 * $bcurr / $batchtotal) / 10.0}]
        set pixels [expr {int(4 * $pcnt) + 1}]
        $wname.fcanvas itemconfig pcnt -text "$pcnt%"
        $wname.fcanvas coords filler 1 1 $pixels 21
    }
    return
}

proc web:tinyurlize {widget url startpos endpos} {
    set url [string trim $url]
    /statbar 5 "Creating TinyURL for $url ..."
    set scripturl "http://tinyurl.com/create.php?url="
    append scripturl $url
    set errcode [catch {/web_fetch $scripturl -title "TinyURL Creator" -caption "Submitting URL for TinyURL creation..."} data]
    if {$errcode != 0} {
        /web_fetch_complete
        if {[/prefs:get use_http_proxy]} {
            set mesg "Unable to connect to the TinyURL.com.\nPerhaps your proxy settings are incorrect?\nError: $data"
        } else {
            set mesg "Unable to connect to the TinyURL.com.  Please try again later,\nor contact your system's administrator if the problem persists.\nError: $data"
        }
        tk_messageBox -type ok -icon error -title "TinyURL Creator" \
            -parent [winfo toplevel $widget] -message $mesg
        return
    }
    /web_fetch_complete
    if {![regexp -nocase -- "href=\"(\[^\"\]*)\"\[^>\]*> *Open in new window *</a>" $data dummy tinyurl]} {
        tk_messageBox -type ok -icon error -title "TinyURL Creator" \
            -parent [winfo toplevel $widget] \
            -message "Couldn't parse out tinyurl result."
    } else {
        if {[$widget cget -insertwidth] > 0} {
            $widget delete $startpos $endpos
            $widget insert $startpos $tinyurl
        } else {
            /inbuf insert insert $tinyurl
        }
    }
}


