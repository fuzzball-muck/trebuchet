############################
##  MCP Public Interface  ##
############################################################################
##
##      mcp_initialize           {sendcmd}
##      mcp_reset_world          {world}
## line mcp_process_input        {world line}
##      mcp_output_inband        {world line}
##      mcp_output_mesg          {world pkg mesg data}
## vers mcp_remote_pkg_supported {world pkg}
##      mcp_register_pkg         {pkg minver maxver}
##      mcp_register_handler     {pkg mesg func}
##      mcp_deregister_handler   {pkg mesg}
##
## ADD mcp_cord_register
## ADD mcp_cord_open
## ADD mcp_cord_send
## ADD mcp_cord_close
##
############################################################################

proc mcp_initialize {sendcmd} {
    global MCPInfo
    set MCPInfo(sendcmd) $sendcmd
    mcp_register_pkg "mcp-negotiate" 2.0 2.0
    mcp_register_handler "mcp" "" mcppkg_mcp
    mcp_register_handler "mcp-negotiate" "can" mcppkg_negotiate_can
    mcp_register_handler "mcp-negotiate" "end" mcppkg_negotiate_end

    global treb_lib_dir
    source [file join $treb_lib_dir mcpedit.tcl]
    source [file join $treb_lib_dir mcpgui.tcl]
    source [file join $treb_lib_dir mcptzone.tcl]
    source [file join $treb_lib_dir mcpmisc.tcl]
}

proc mcp_reset_world {world} {
    global MCPInfo
    foreach key [array names MCPInfo "*,$world,*"] {
        unset MCPInfo($key)
    }
    return
}

proc mcp_process_input {world line} {
    global MCPInfo
    if {[string range $line 0 2] == {#$#}} {
        if {[/prefs:get show_mcp_traffic]} {
            /echo -world $world -style error $line
        }
        mcp_parse_mesg $world [string range $line 3 end]
        return
    } elseif {[string range $line 0 2] == "#\$\""} {
        return [string range $line 3 end]
    } else {
        return $line
    }
}

proc mcp_output_inband {world line} {
    global MCPInfo
    if {[string match "#\$#*" $line] || [string match "#\$\"" $line]} {
        set out "#\$\"$line"
    } else {
        set out $line
    }
    mcp_sendto $world $out
    return
}

proc mcp_output_mesg {world pkg mesg args} {
    global MCPInfo
    if {![info exists MCPInfo(enabled,$world)]} {
        error "MCP Not enabled for this world."
    }
    if {[llength $args] > 1} {
        set data $args
    } else {
        set data [lindex $args 0]
    }
    set mline {}
    if {$mesg == {}} {
        set mesg "$pkg"
    } else {
        set mesg "$pkg-$mesg"
    }
    set out "#\$#$mesg"
    if {$mesg != "mcp"} {
        append out " $MCPInfo(auth,$world)"
        if {$pkg != "mcp-negotiate" && [mcp_remote_pkg_supported $world $pkg] == {}} {
            error "MCP Package '$pkg' not supported!"
        }
    }
    foreach {key val} $data {
        set lval [split $val "\n"]
        if {[llength $lval] > 1 || [string length $val] > 80} {
            append out " $key*: \"\""
            lappend mline $key
            lappend mline $lval
        } else {
            append out " $key:"
            regsub -all -- "\[\\\\\"\]" $val {\\&} lval
            append out " \"$lval\""
        }
    }
    if {$mline != {}} {
        append out " _data-tag:"
        set datatag [mcp_generate_token]
        while {[info exists MCPInfo(mesg,$world,$datatag)]} {
            set datatag [mcp_generate_token]
        }
        append out " $datatag"
    }
    if {[/prefs:get show_mcp_traffic]} {
        /echo -world $world -style results $out
    }
    mcp_sendto $world $out
    if {$mline != {}} {
        foreach {key val} $mline {
            if {[llength $val] == 0} {
                if {[/prefs:get show_mcp_traffic]} {
                    /echo -world $world -style results "#\$#* $datatag $key: "
                }
                mcp_sendto $world  "#\$#* $datatag $key: "
            } else {
                foreach line $val {
                    if {[/prefs:get show_mcp_traffic]} {
                        /echo -world $world -style results "#\$#* $datatag $key: $line"
                    }
                    mcp_sendto $world "#\$#* $datatag $key: $line"
                }
            }
        }
        if {[/prefs:get show_mcp_traffic]} {
            /echo -world $world -style results "#\$#: $datatag"
        }
        mcp_sendto $world "#\$#: $datatag"
    }
    return
}

proc mcp_register_pkg {pkg minver maxver {startcb {}}} {
    global MCPInfo
    set pkg [string tolower $pkg]
    lappend MCPInfo(pkgs) $pkg
    set MCPInfo(pkgs,maxver,$pkg) $maxver
    set MCPInfo(pkgs,minver,$pkg) $minver
    set MCPInfo(pkgs,startcb,$pkg) $startcb
}

proc mcp_remote_pkg_supported {world pkg} {
    global MCPInfo
    set pkg [string tolower $pkg]
    if {[info exists MCPInfo(rpkgs,$world,$pkg)]} {
        return $MCPInfo(rpkgs,$world,$pkg)
    } else {
        return ""
    }
}

proc mcp_packages {} {
    global MCPInfo
    set oot {}
    set len [string length "pkgs,maxver,"]
    foreach {tag val} [array get MCPInfo "pkgs,maxver,*"] {
        set key [string tolower [string range $tag $len end]]
        lappend oot $key
        lappend oot $MCPInfo(pkgs,minver,$key)
        lappend oot $val
    }
    return $oot
}

proc mcp_negotiated_pkgs {world} {
    global MCPInfo
    set len [string length "rpkgs,$world,"]
    foreach {tag val} [array get MCPInfo "rpkgs,$world,*"] {
        set key [string tolower [string range $tag $len end]]
        set oot($key) $val
    }
    if {[info exists oot]} {
        return [array get oot]
    } else {
        return
    }
}

proc mcp_register_handler {pkg mesg func} {
    global MCPInfo
    if {$mesg == {}} {
        set mesg "$pkg"
    } else {
        set mesg "$pkg-$mesg"
    }
    set MCPInfo(handler,$mesg) $func
}

proc mcp_deregister_handler {pkg mesg} {
    global MCPInfo
    if {$mesg == {}} {
        set mesg "$pkg"
    } else {
        set mesg "$pkg-$mesg"
    }
    unset MCPInfo(handler,$mesg)
}

###################
## MCP Internals ##
############################################################################

proc mcp_sendto {world line} {
    global MCPInfo
    set result [catch {
        eval "$MCPInfo(sendcmd) [list $world] [list $line]"
    } errMsg]
    if {$result} {
        /statbar 10 "MCP send: $errMsg"
    }
}

proc mcp_execute_handler {world mesg data} {
    global MCPInfo
    set argset {}
    foreach arg $data {
        lappend argset $arg
    }
    if {![info exists MCPInfo(handler,$mesg)]} {
        /statbar 10 "MCP recv: no handler for $mesg"
        return
    }
    set result [catch {
        eval "$MCPInfo(handler,$mesg) [list $world] [list $argset]"
    } errMsg]
    if {$result} {
        global errorInfo
        /error $world $errMsg $errorInfo
        /statbar 10 "MCP recv $mesg: $errMsg"
    }
    return
}

proc mcp_discard_mesg {world datatag} {
    global MCPInfo
    foreach key [array names MCPInfo "*,$world,$datatag,*"] {
        unset MCPInfo($key)
    }
    return
}

proc mcp_parse_mesg {world line} {
    global MCPInfo
    set result [regexp -nocase -- {^([a-z_][-a-z_0-9]*|\*|:) *(.*)$} $line foo mesg args]
    if {!$result} { error "Malformed MCP message (1)" }
    set mesg [string tolower $mesg]
    if {$mesg != "mcp" && ![info exists MCPInfo(enabled,$world)]} {
        error "MCP Not enabled for this world."
    }
    if {$mesg == "*"} {
        set result [regexp -nocase -- "^(\[^ \]*) *(\[a-z_\]\[-a-z_0-9\]*): (.*)\$" $args foo datatag key args]
        if {!$result} { error "Malformed MCP message (2)" }
        if {![info exists MCPInfo(mesg,$world,$datatag)]} {
            error "MCP continuation referenced nonexistent data tag"
        }
        if {![info exists MCPInfo(argisset,$world,$datatag,$key)]} {
            error "MCP continuation referenced nonexistent key"
        }
        if {!$MCPInfo(argisset,$world,$datatag,$key)} {
            set MCPInfo(args,$world,$datatag,$key) $args
            incr MCPInfo(unsetargs,$world,$datatag) -1
            set MCPInfo(argisset,$world,$datatag,$key) 1
        } else {
            append MCPInfo(args,$world,$datatag,$key) "\n"
            append MCPInfo(args,$world,$datatag,$key) $args
        }
        return
    } elseif {$mesg == ":"} {
        set result [regexp -nocase -- "^(\[^ \]*) *\$" $args foo datatag]
        if {!$result} { error "Malformed MCP message (3)" }
        if {![info exists MCPInfo(mesg,$world,$datatag)]} {
            error "MCP completion referenced nonexistent data tag"
        }
        set data [array get MCPInfo "args,$world,$datatag,*"]
        set outargs {}
        foreach {arg val} $data {
            set pos [string length "args,$world,$datatag,"]
            lappend outargs [string range $arg $pos end]
            lappend outargs $val
        }
        mcp_execute_handler $world $MCPInfo(mesg,$world,$datatag) $outargs
        mcp_discard_mesg $world $datatag
    } else {
        if {$mesg != "mcp"} {
            set result [regexp -nocase -- {^([^ ]*) *(.*)$} $args foo auth args]
            if {$auth != $MCPInfo(auth,$world)} {
                error "MCP message failed authorization test."
            }
        }
        set unsetargs 0
        while {[string length $args] > 0} {
            set result [regexp -nocase -- {^([a-z_][-a-z_0-9]*)(\*:|:) *(.*)$} $args foo key multi args]
            if {!$result} { error "Malformed MCP message (4)" }
            if {[string index $args 0] == "\""} {
                set val ""
                for {set i 1} {$i < [string length $args]} {incr i} {
                    set c [string index $args $i]
                    switch -exact -- $c {
                        "\\" {
                            incr i
                            set c [string index $args $i]
                            append val $c
                        }
                        "\"" {
                            incr i
                            while {[string index $args $i] == " "} { incr i }
                            set args [string range $args $i end]
                            break
                        }
                        default {
                            append val $c
                        }
                    }
                }
            } else {
                set result [regexp -nocase -- {^([^ ]*) *(.*)$} $args foo val args]
                if {!$result} { error "Malformed MCP message (5)" }
            }
            set key [string tolower $key]
            set outargs($key) $val
            if {$multi == "*:"} {
                set argset($key) 0
                incr unsetargs
            } else {
                set argset($key) 1
            }
        }
        if {$unsetargs == 0} {
            mcp_execute_handler $world $mesg [array get outargs]
        } else {
            if {![info exists outargs(_data-tag)]} {
                error "Multi-line MCP message is missing _data-tag."
            }
            set datatag $outargs(_data-tag)
            unset outargs(_data-tag)
            set MCPInfo(mesg,$world,$datatag) $mesg
            set MCPInfo(unsetargs,$world,$datatag) $unsetargs
            foreach {key val} [array get outargs] {
                if {$argset($key)} {
                    set MCPInfo(args,$world,$datatag,$key) $val
                } else {
                    set MCPInfo(args,$world,$datatag,$key) ""
                }
                set MCPInfo(argisset,$world,$datatag,$key) $argset($key)
            }
        }
    }
}

proc mcp_generate_token {} {
    set out [format "%04X" [expr {int(0x10000 * rand())}]]
    append out [format "%04X" [expr {int(0x10000 * rand())}]]
    return $out
}

proc mcp_version_compare {a b} {
    set tmp [split $a "."]
    set amajor [lindex $tmp 0]
    set aminor [lindex $tmp 1]
    set tmp [split $b "."]
    set bmajor [lindex $tmp 0]
    set bminor [lindex $tmp 1]
    if {$amajor != $bmajor} {
        return [expr {$amajor - $bmajor}]
    } else {
        return [expr {$aminor - $bminor}]
    }
}

######################
## MCP Base Package ##
############################################################################

proc setfrom {vartoset vartoread {default ""} {type "string"}} {
    upvar $vartoset var
    upvar $vartoread val
    if {![info exists val]} {
        set var $default
    } else {
        switch -exact -- $type {
            str -
            string {
                set var $val
            }
            int {
                if {[catch {expr {int($val + 0)}} result]} {
                    set var $default
                    error "Non-integer value for integer argument $vartoset!"
                } else {
                    set var $result
                }
            }
            float {
                if {[catch {expr {$val + 0.0}} result]} {
                    set var $default
                    error "Non-float value for floating point argument $vartoset!"
                } else {
                    set var $result
                }
            }
            bool {
                if {$val == "false" || $val == "0" || $val == ""} {
                    set var 0
                } else {
                    set var 1
                }
            }
            default {
                set var $default
                error "Internal error!  Arg type for setfrom is unknown."
            }
        }
    }
    return
}


proc mcppkg_mcp {world data} {
    array set arr $data
    setfrom version arr(version)             0.0
    setfrom to      arr(to)                  {}
    setfrom auth    arr(authentication-key)  {}
    
    global MCPInfo
    set minsupport 2.1
    set maxsupport 2.1
    if {[mcp_version_compare $version $maxsupport] > 0} {
        error "Failed to find common MCP version."
    }
    if {$to == {}} {
        set to $version
    }
    if {[mcp_version_compare $to $minsupport] < 0} {
        error "Failed to find common MCP version."
    }
    set MCPInfo(enabled,$world) 1
    if {$auth == {}} {
        set auth [mcp_generate_token]
        set MCPInfo(auth,$world) $auth
        mcp_output_mesg $world "mcp" "" authentication-key $auth version 2.1 to 2.1
    } else {
        set auth $auth
        mcp_output_mesg $world "mcp" "" version 2.1 to 2.1
    }
    foreach pkg $MCPInfo(pkgs) {
        set maxver $MCPInfo(pkgs,maxver,$pkg)
        set minver $MCPInfo(pkgs,minver,$pkg)
        set data [list package $pkg min-version $minver max-version $maxver]
        mcp_output_mesg $world "mcp-negotiate" "can" $data
    }
    mcp_output_mesg $world "mcp-negotiate" "end" ""
}


proc mcppkg_negotiate_can {world data} {
    array set arr $data
    setfrom package arr(package)             {}
    setfrom rmin    arr(min-version)         0.0
    setfrom rmax    arr(max-version)         {}

    global MCPInfo
    set pkg [string tolower $package]
    if {![info exists MCPInfo(pkgs,maxver,$pkg)]} {
        return
    }
    set maxver $MCPInfo(pkgs,maxver,$pkg)
    set minver $MCPInfo(pkgs,minver,$pkg)
    if {[mcp_version_compare $rmin $maxver] > 0} {
        set ver 0.0
    } elseif {[mcp_version_compare $rmax $minver] < 0} {
        set ver 0.0
    } elseif {[mcp_version_compare $rmax $maxver] > 0} {
        set ver $maxver
    } else {
        set ver $rmax
    }

    ## It panics too many people when they see package renegotiations.
    #if {$ver == 0.0} {
    #    /statbar 5 "MCP: Negotiated package $pkg as unsupported."
    #} else {
    #    /statbar 5 "MCP: Negotiated package $pkg v$ver"
    #}

    set oldver 0.0
    if {[info exists MCPInfo(rpkgs,$world,$pkg)]} {
        set oldver $MCPInfo(rpkgs,$world,$pkg)
    }
    set MCPInfo(rpkgs,$world,$pkg) $ver

    if {$ver != 0.0} {
        if {[info exists MCPInfo(negotiated,$world)] && $MCPInfo(negotiated,$world)} {
            if {$oldver != $ver} {
                set maxver $MCPInfo(pkgs,maxver,$pkg)
                set minver $MCPInfo(pkgs,minver,$pkg)
                set data [list package $pkg min-version $minver max-version $maxver]
                mcp_output_mesg $world "mcp-negotiate" "can" $data
            }
        }
    }
    return
}

proc mcppkg_negotiate_end {world data} {
    global MCPInfo
    set MCPInfo(negotiated,$world) 1
    foreach {pkg ver} [mcp_negotiated_pkgs $world] {
        if {$MCPInfo(pkgs,startcb,$pkg) != {}} {
            eval "$MCPInfo(pkgs,startcb,$pkg) [list $world] [list $ver]"
        }
    }
    return
}

########################
## Cords Base Package ##
############################################################################

proc mcppkg_cord_open {world data} {
    array set arr $data
    setfrom id   arr(_id)   {}
    setfrom type arr(_type) {}

    global MCPInfo
    if {$id == {} } {
        error "cord-open: _id tag not specified."
    }
    if {$type == {}} {
        error "cord-open: _type tag not specified."
    }
    if {![info exists MCPInfo(cordstart,$type)]} {
        mcp_output_mesg $world "mcp-cord" "closed" [list _id $id]
    } else {
        if {$MCPInfo(cordstart,$type) != ""} {
            eval "$MCPInfo(cordstart,$type) [list $id]"
        }
        set MCPInfo(cordtype,$id) $type
    }
}

proc mcppkg_cord {world data} {
    global MCPInfo
    array set datarr $data
    setfrom id   datarr(_id)      {}
    setfrom mesg datarr(_message) {}

    unset datarr(_id)
    unset datarr(_message)

    set type $MCPInfo(cordtype,$id)
    if {$MCPInfo(cordmesg,$type) != ""} {
        set outdata [array get $datarr]
        eval "$MCPInfo(cordmesg,$type) [list $id] [list $mesg] [list $outdata]"
    }
}

proc mcppkg_cord_closed {world data} {
    global MCPInfo
    array set datarr $data
    setfrom id datarr(_id) {}

    set type $MCPInfo(cordtype,$id)
    if {$MCPInfo(cordclose,$type) != ""} {
        eval "$MCPInfo(cordclose,$type) [list $id]"
    }
    unset MCPInfo(cordtype,$id)
}


####################
## /MCP functions ##
############################################################################

proc /mcp_send {pkg mesg args} {
    array set datarr $args
    set world {}
    if {[info exists datarr(-world)]} {
        set world $datarr(-world)
        unset datarr(-world)
    }
    if {$world == {}} {
        set world [/socket:current]
        if {$world == {}} { error "No current connection to send to" }
    }
    mcp_output_mesg $world $pkg $mesg [array get datarr]
    return
}

