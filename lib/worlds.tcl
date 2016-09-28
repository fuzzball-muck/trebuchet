global treb_world_type_map
set treb_world_type_map() [list tiny lp lpp talker]
set treb_world_type_map(tiny) "TinyMU*/MOO"
set treb_world_type_map(lp)   "LP/Diku/Aber"
set treb_world_type_map(lpp)  "LP/Diku with GOAHEAD/EOR"
set treb_world_type_map(talker)  "Talker"

global treb_log_type_map
set treb_log_type_map() [list off text html]
set treb_log_type_map(off) "Off"
set treb_log_type_map(text) "Text"
set treb_log_type_map(html) "HTML"

global treb_log_timestamp_map
set treb_log_timestamp_map() [list none date datetime]
set treb_log_timestamp_map(none) "Off"
set treb_log_timestamp_map(date) "Date"
set treb_log_timestamp_map(datetime) "Date and Time"

package require opt

proc /world {opt args} {
    dispatcher /world $opt $args
}


proc /world:edit {{item ""}} {
    if {$item == ""} {
        /editdlog Worlds World /world
    } else {
        /newdlog World /world $item
    }
}


proc world:fields {} {
    return [list host port charname password encoding tcl script secure noauth socks type keepalive pingcmd log logfile timestamp temp]
}


tcl::OptProc /world:add {
    {name     ""        "The name of the world."}
    {host     ""        "The host machine to connect to."}
    {port     -int 4201 "The port number to connect to."}
    {?char?   ""        "The character name."}
    {?passwd? ""        "The character password."}
    {-encoding "iso8859-1" "The character encoding of text from/to the server."}
    {-secure  -bool 0   "Encrypt connection with SSL or TLS."}
    {-noauth  -bool 0   "Allow unauthenticated encrypted connections."}
    {-socks   -bool 0   "To enable SOCKS 5 proxified connections."}
    {-keepalive -bool 0 "To enable keepalive (or ping command) sending."}
    {-pingcmd ""        "Optional ping command."}
    {-script  ""        "The script to evaluate after connecting."}
    {-tcl     -bool 0   "Evaluate script as TCL if set to true."}
    {-type -choice {tiny lp lpp talker} "MUD server type.  lp, lpp & talker allow unterminated prompt.  lp & talker use timeouts.  talker uses a delay at login between name and password, and a line buffering scheme."}
    {-log -choice {off text html} "Autostart logging on connect, either as text or HTML."}
    {-logfile ""        "Base filename to to log to."}
    {-timestamp -choice {none date datetime} "If logging, add date or timestamp to logfile name."}
    {-temp    -bool 0   "This world is temporary and shouldn't be saved."}
} {
    global worldsInfo
    set preexistant 0
    if {$name == ""} {
        return
    }
    if {[/world:exists $name]} {
        set preexistant 1
    } else {
        lappend worldsInfo(worlds) $name
    }
    foreach field [world:fields] {
        set var $field
        switch -exact -- $field {
            password { set var passwd }
            charname { set var char }
        }
        set worldsInfo($name-$field) [set $var]
    }
    if {$preexistant} {
        /world:notifyregistered update $name
    } else {
        /world:notifyregistered add $name
    }
    if {!$temp} {
        global dirty_preferences; set dirty_preferences 1
    }
    return "World added."
}


proc /world:delete {name} {
    global worldsInfo
    if {![/world:exists $name]} {
        error "/world delete: No such World!"
    }
    set pos [lsearch -exact $worldsInfo(worlds) $name]
    set worldsInfo(worlds) [lreplace $worldsInfo(worlds) $pos $pos]
    foreach field [world:fields] {
        unset worldsInfo($name-$field)
    }
    /world:notifyregistered delete $name
    global dirty_preferences; set dirty_preferences 1
    return "World deleted."
}


proc /world:names {{pattern *}} {
    global worldsInfo
    if {![info exists worldsInfo(worlds)]} {
        return {}
    }
    set out {}
    foreach world [lsort -dictionary $worldsInfo(worlds)] {
        if {[string match $pattern $world]} {
            lappend out $world
        }
    }
    return $out
}


proc /world:exists {name} {
    global worldsInfo
    return [info exists worldsInfo($name-host)]
}


proc /world:get {entry name} {
    global worldsInfo
    if {![/world:exists $name]} {
        error "/world get: No such world \"$name\"!"
    }
    set fields [world:fields]
    if {[lsearch -exact $fields $entry] == -1} {
        error "/world get: Entry '$entry' must be one of $fields"
    }
    return $worldsInfo($name-$entry)
}


proc /world:set {entry name value} {
    global worldsInfo
    if {![/world:exists $name]} {
        error "/world set: No such World!"
    }
    set fields [world:fields]
    if {[lsearch -exact $fields $entry] == -1} {
        error "/world set: Entry '$entry' must be one of $fields"
    }
    set worldsInfo($name-$entry) $value
    global dirty_preferences; set dirty_preferences 1
    return ""
}


proc /world:list {{pattern *}} {
    set oot ""
    foreach world [/world:names $pattern] {
        if {![/world:get temp $world]} {
            if {$oot != ""} {
                append oot "\n"
            }
            append oot "/world add [list $world]"
            append oot " [list [/world:get host $world]]"
            append oot " [list [/world:get port $world]]"
            append oot " [list [/world:get charname $world]]"
            append oot " [list [/world:get password $world]]"
            if {[/world:get encoding $world] != "iso8859-1"} { append oot " -encoding [list [/world:get encoding $world]]" }
            if {[/world:get tcl $world] != 0} { append oot " -tcl [list [/world:get tcl $world]]" }
            if {[/world:get script $world] != {}} { append oot " -script [list [/world:get script $world]]" }
            if {[/world:get secure $world] != 0} { append oot " -secure [list [/world:get secure $world]]" }
            if {[/world:get noauth $world] != 0} { append oot " -noauth [list [/world:get noauth $world]]" }
            if {[/world:get socks $world] != 0} { append oot " -socks [list [/world:get socks $world]]" }
            if {[/world:get keepalive $world] != 0} { append oot " -keepalive [list [/world:get keepalive $world]]" }
            if {[/world:get pingcmd $world] != ""} { append oot " -pingcmd [list [/world:get pingcmd $world]]" }
            if {[/world:get type $world] != "tiny"} { append oot " -type [list [/world:get type $world]]" }
            if {[/world:get log $world] != "off"} { append oot " -log [list [/world:get log $world]]" }
            if {[/world:get logfile $world] != ""} { append oot " -logfile [list [/world:get logfile $world]]" }
            if {[/world:get timestamp $world] != "none"} { append oot " -timestamp [list [/world:get timestamp $world]]" }
        }
    }
    return "$oot"
}


proc /world:raise {name} {
    if {![/world:exists $name]} {
        error "/world raise: No such World!"
    }
    set disp [/socket:get display $name]
    display:select $disp
    return ""
}


proc /world:connect {name} {
    if {![/world:exists $name]} {
        error "/world connect: No such World!"
    }
    /socket:open $name
    return ""
}


proc /world:notifyregistered {type name} {
    global WorldInfo
    foreach key [array names WorldInfo "reg,*"] {
        eval "$WorldInfo($key) [list $type] [list $name]"
    }
    return
}


proc /world:register {id cmd} {
    global WorldInfo
    if {[info exists WorldInfo(reg,$id)]} {
        error "/world register: That id is already registered!"
    }
    set WorldInfo(reg,$id) "$cmd"
    return
}


proc /world:deregister {id} {
    global WorldInfo
    if {[info exists WorldInfo(reg,$id)]} {
        unset WorldInfo(reg,$id)
    }
    return
}


proc /world:widgets {opt args} {
    dispatcher /world:widgets $opt $args
}


proc /world:widgets:create {master updatescript} {
    global WorldInfo
    global treb_world_type_map
    global treb_log_type_map
    global treb_log_timestamp_map

    append updatescript "; after idle world:widgets:update $master"
    set base $master.fr

    frame $base -relief flat -borderwidth 2

    label $base.namelbl -text {World Name} -anchor w
    entry $base.name -textvariable WorldInfo($master,gui,name) -width 32

    label $base.hostlbl -text {Host Name} -anchor w
    entry $base.host -textvariable WorldInfo($master,gui,host) -width 32

    label $base.portlbl -text {Port Number} -anchor w
    entry $base.port -textvariable WorldInfo($master,gui,port) -width 5
    checkbutton $base.secure -text "Encrypted port" -command $updatescript \
        -variable WorldInfo($master,gui,secure)

    checkbutton $base.noauth -command $updatescript \
        -text "Allow unauthenticated encryption" \
        -variable WorldInfo($master,gui,noauth)

    checkbutton $base.socks -command $updatescript \
        -text "Use the SOCKS 5 proxy" \
        -variable WorldInfo($master,gui,socks)

    checkbutton $base.keepalive -command $updatescript \
        -text "Enable telnet keep-alive sending" \
        -variable WorldInfo($master,gui,keepalive)

    label $base.pinglbl -text {Ping command} -anchor w
    entry $base.ping -textvariable WorldInfo($master,gui,pingcmd) -width 20

    label $base.typelbl -text {Mud Type} -anchor w
    combobox $base.type -textvariable WorldInfo($master,gui,type) \
        -changecommand "$updatescript" -editable 0
    foreach worldtype $treb_world_type_map() {
        $base.type entryinsert end $treb_world_type_map($worldtype)
    }
    $base.type delete 0 end
    $base.type insert end $treb_world_type_map(tiny)

    label $base.charlbl -text {Player Name} -anchor w
    entry $base.char -textvariable WorldInfo($master,gui,char) -width 32

    label $base.passlbl -text {Password} -anchor w
    entry $base.pass -textvariable WorldInfo($master,gui,pass) -show "*" -width 32

    label $base.loglbl -text {Auto-Log}
    combobox $base.log -textvariable WorldInfo($master,gui,logtype) \
        -changecommand "$updatescript" -editable 0 -width 4
    foreach logtype $treb_log_type_map() {
        $base.log entryinsert end $treb_log_type_map($logtype)
    }
    $base.log delete 0 end
    $base.log insert end $treb_log_type_map(off)

    button $base.logfile -text "Select File..." \
        -command "world:widgets:selectlogfile $master; $updatescript"
    set WorldInfo($master,gui,logfile) ""

    label $base.tslbl -text {Timestamp Log}
    combobox $base.timestamp \
        -textvariable WorldInfo($master,gui,timestamp) \
        -changecommand "$updatescript" -editable 0 -width 13
    foreach tstype $treb_log_timestamp_map() {
        $base.timestamp entryinsert end $treb_log_timestamp_map($tstype)
    }
    $base.timestamp delete 0 end
    $base.timestamp insert end $treb_log_timestamp_map(none)

    label $base.enclbl -text {Encoding}
    combobox $base.encoding -textvariable WorldInfo($master,gui,encoding) \
        -changecommand "$updatescript" -editable 0
    set excludeencs {mac* symbol dingbats ebcdic identity}
    set maxencwidth 0
    foreach encname [lsort -dictionary [encoding names]] {
	set doexcl 0
	foreach exenc $excludeencs {
	    if {[string match -nocase $exenc $encname]} {
	        set doexcl 1
		break
	    }
	}
	if {!$doexcl} {
	    $base.encoding entryinsert end $encname
	    if {[string length $encname] > $maxencwidth} {
		set maxencwidth [string length $encname]
	    }
	}
    }
    $base.encoding configure -width $maxencwidth
    $base.encoding delete 0 end
    $base.encoding insert end "iso8859-1"

    set scrfr [frame $base.script -relief flat -borderwidth 0]
    label $scrfr.lbl -text {Connect Script} -anchor w
    checkbutton $scrfr.tclcb -text {Evaluate as TCL} -onval 1 -offval 0 \
        -variable WorldInfo($master,gui,tcl) -command $updatescript
    text $scrfr.script -width 40 -height 5 -yscrollcommand "$scrfr.scroll set"
    scrollbar $scrfr.scroll -orient vert -command "$scrfr.script yview"

    world:widgets:update $master

    bind $scrfr.script <Key> +$updatescript
    bind $scrfr.script <<Cut>> +$updatescript
    bind $scrfr.script <<Paste>> +$updatescript
    bind $base.name <Key> +$updatescript
    bind $base.host <Key> +$updatescript
    bind $base.port <Key> +$updatescript
    bind $base.char <Key> +$updatescript
    bind $base.pass <Key> +$updatescript
    bind $base.ping <Key> +$updatescript
    bind $base.name <<Cut>> +$updatescript
    bind $base.host <<Cut>> +$updatescript
    bind $base.port <<Cut>> +$updatescript
    bind $base.char <<Cut>> +$updatescript
    bind $base.pass <<Cut>> +$updatescript
    bind $base.ping <<Cut>> +$updatescript
    bind $base.name <<Paste>> +$updatescript
    bind $base.host <<Paste>> +$updatescript
    bind $base.port <<Paste>> +$updatescript
    bind $base.char <<Paste>> +$updatescript
    bind $base.pass <<Paste>> +$updatescript
    bind $base.ping <<Paste>> +$updatescript

    if {[info commands tls::init] == {}} {
        foreach cbctrl [list secure noauth] {
            $base.$cbctrl config -state disabled
            bind $base.$cbctrl <Button-1> "
                tk_messageBox -type ok -parent [winfo toplevel $master] \
                    -title {Trebuchet Notice} -icon warning \
                    -message {SSL support has not been installed.  Check http://www.belfry.com/fuzzball/trebuchet/ for info on installing SSL support.}
            "
        }
    }

    grid columnconfig $scrfr 0 -minsize 10
    grid columnconfig $scrfr 2 -minsize 10 -weight 1
    grid columnconfig $scrfr 5 -minsize 10
    grid rowconfig $scrfr 0 -minsize 10
    grid rowconfig $scrfr 2 -weight 1

    grid x $scrfr.lbl    x $scrfr.tclcb -             x -row 1
    grid x $scrfr.script - -            $scrfr.scroll x

    grid $scrfr.lbl -sticky w
    grid $scrfr.tclcb  -sticky ew
    grid $scrfr.script -sticky nsew
    grid $scrfr.scroll -sticky ns

    grid columnconfig $base 0 -minsize 20
    grid columnconfig $base 4 -weight 1
    grid columnconfig $base 5 -minsize 20
    grid columnconfig $base 6 -minsize 20
    grid columnconfig $base 7 -minsize 20
    grid rowconfig $base  0 -minsize 10
    grid rowconfig $base 12 -weight 1
    grid rowconfig $base 13 -minsize 10

    grid x $base.namelbl $base.name      -             -               x -row 1
    grid x $base.hostlbl $base.host      -             -               x
    grid x $base.portlbl $base.port      $base.secure  -               x
    grid x x             $base.noauth    -             -               x
    grid x x             $base.socks     -             -               x
    grid x x             $base.keepalive -             -               x
    grid x $base.pinglbl $base.ping      -             -               x
    grid x $base.typelbl $base.type      -             -               x
    grid x $base.charlbl $base.char      -             -               x
    grid x $base.passlbl $base.pass      -             -               x
    grid x $base.loglbl  $base.log       $base.logfile -               x
    grid x x             $base.tslbl     -             $base.timestamp x
    grid x $base.enclbl  $base.encoding  -             -               x
    grid x $base.script  -               -             -               x
    
    grid $base.namelbl $base.hostlbl $base.portlbl $base.enclbl -sticky w -padx 3 -pady 3
    grid $base.typelbl $base.charlbl $base.passlbl $base.pinglbl -sticky w -padx 3 -pady 3
    grid $base.loglbl $base.tslbl -sticky w -padx 3 -pady 3
    grid $base.name $base.host $base.port $base.ping $base.char $base.pass -sticky ew -padx 3 -pady 3
    grid $base.secure $base.noauth $base.socks $base.type $base.keepalive -sticky w -padx 3 -pady 3
    grid $base.log $base.logfile $base.tslbl $base.timestamp $base.encoding -sticky w -padx 3 -pady 3
    grid $base.script -sticky nsew -padx 3 -pady 3

    grid rowconf $master 1 -weight 1
    grid columnconf $master 1 -weight 1
    grid $base -pady 5 -row 0 -column 0 -sticky nsew

    return $base
}


proc world:widgets:update {master} {
    global WorldInfo
    set logtype $WorldInfo($master,gui,logtype)
    if {$logtype == "Off"} {
        set newstate "disabled"
    } else {
        set newstate "normal"
    }
    set base $master.fr
    $base.logfile configure -state $newstate -text "Select File..."
    $base.tslbl configure -state $newstate
    $base.timestamp configure -state $newstate
    set pingcmd $WorldInfo($master,gui,pingcmd)
    if {$pingcmd != ""} {
        $base.keepalive configure -state disabled
    } else {
        $base.keepalive configure -state normal
    }
}


proc world:widgets:selectlogfile {master} {
    global WorldInfo
    set name $WorldInfo($master,gui,name)
    set logtype $WorldInfo($master,gui,logtype)
    set logfile $WorldInfo($master,gui,logfile)
    if {$logtype == "HTML"} {
        set filetypes {
            {{HTML Files}       {.html}   TEXT}
        }
        set defaultext "html"
    } else {
        set filetypes {
            {{Text Files}       {.txt}    TEXT}
            {{Log Files}        {.log}    TEXT}
        }
        set defaultext "log"
    }
    if {$logfile != ""} {
        set dirname [file dirname $logfile]
        set logfile [file tail $logfile]
    } else {
        set dirname "~/Documents"
        set logfile "$name.$defaultext"
    }
    set logfile [tk_getSaveFile -defaultextension .$defaultext \
                -initialfile $logfile -initialdir $dirname \
                -title {Log to file} -filetypes $filetypes]

    if {$logfile != ""} {
        set WorldInfo($master,gui,logfile) $logfile
    }
    return
}


proc /world:widgets:destroy {master} {
    destroy $master.fr
    return
}


proc /world:widgets:clear {master} {
    global WorldInfo
    set WorldInfo($master,gui,name)   ""
    set WorldInfo($master,gui,host)   ""
    set WorldInfo($master,gui,port)   4201
    set WorldInfo($master,gui,secure) 0
    set WorldInfo($master,gui,noauth) 0
    set WorldInfo($master,gui,socks) 0
    set WorldInfo($master,gui,keepalive) 0
    set WorldInfo($master,gui,pingcmd) ""
    set WorldInfo($master,gui,char)   ""
    set WorldInfo($master,gui,pass)   ""
    set WorldInfo($master,gui,tcl)    0
    set WorldInfo($master,gui,script) ""
    set WorldInfo($master,gui,encoding) "iso8859-1"
    set WorldInfo($master,gui,type)   "TinyMU*/MOO"
    set WorldInfo($master,gui,logtype) "Off"
    set WorldInfo($master,gui,logfile) ""
    set WorldInfo($master,gui,timestamp) "Off"
    return
}


proc /world:widgets:init {master name} {
    global WorldInfo
    global treb_world_type_map
    global treb_log_type_map
    global treb_log_timestamp_map

    set type [/world get type $name]
    set logtype [/world get log $name]
    set logts [/world get timestamp $name]
    set encoding [/world get encoding $name]
    if {$encoding == "identity"} {
        set encoding "utf-8"
    }

    set WorldInfo($master,gui,name)      $name
    set WorldInfo($master,gui,host)      [/world get host $name]
    set WorldInfo($master,gui,port)      [/world get port $name]
    set WorldInfo($master,gui,secure)    [/world get secure $name]
    set WorldInfo($master,gui,noauth)    [/world get noauth $name]
    set WorldInfo($master,gui,socks)     [/world get socks $name]
    set WorldInfo($master,gui,keepalive) [/world get keepalive $name]
    set WorldInfo($master,gui,pingcmd)   [/world get pingcmd $name]
    set WorldInfo($master,gui,char)      [/world get charname $name]
    set WorldInfo($master,gui,pass)      [/world get password $name]
    set WorldInfo($master,gui,tcl)       [/world get tcl $name]
    set WorldInfo($master,gui,type)      $treb_world_type_map($type)
    set WorldInfo($master,gui,logtype)   $treb_log_type_map($logtype)
    set WorldInfo($master,gui,logfile)   [/world get logfile $name]
    set WorldInfo($master,gui,timestamp) $treb_log_timestamp_map($logts)
    set WorldInfo($master,gui,encoding)  $encoding
    $master.fr.script.script delete 1.0 end
    $master.fr.script.script insert end [/world get script $name]
    world:widgets:update $master
    return
}


proc /world:widgets:mknode {master} {
    global WorldInfo
    global treb_world_type_map
    global treb_log_type_map
    global treb_log_timestamp_map

    foreach {key val} [array get treb_world_type_map] {
        set typemap($val) $key
    }
    foreach {key val} [array get treb_log_type_map] {
        set logmap($val) $key
    }
    foreach {key val} [array get treb_log_timestamp_map] {
        set tsmap($val) $key
    }
    set type $WorldInfo($master,gui,type)
    set logtype $WorldInfo($master,gui,logtype)
    set logts $WorldInfo($master,gui,timestamp)

    /world:add $WorldInfo($master,gui,name) \
        $WorldInfo($master,gui,host) \
        $WorldInfo($master,gui,port) \
        $WorldInfo($master,gui,char) \
        $WorldInfo($master,gui,pass) \
        -secure $WorldInfo($master,gui,secure) \
        -noauth $WorldInfo($master,gui,noauth) \
        -socks $WorldInfo($master,gui,socks) \
        -keepalive $WorldInfo($master,gui,keepalive) \
        -pingcmd $WorldInfo($master,gui,pingcmd) \
        -tcl $WorldInfo($master,gui,tcl) \
        -script [$master.fr.script.script get 1.0 end-1c] \
        -type $typemap($type) \
        -log $logmap($logtype) \
        -logfile $WorldInfo($master,gui,logfile) \
        -encoding $WorldInfo($master,gui,encoding) \
        -timestamp $tsmap($logts)
    return
}


proc /world:widgets:getname {master} {
    global WorldInfo
    return $WorldInfo($master,gui,name)
}


proc /world:widgets:setname {master name} {
    global WorldInfo
    set WorldInfo($master,gui,name) $name
    return
}


proc /world:widgets:compare {master name} {
    global WorldInfo
    global treb_world_type_map
    global treb_log_type_map
    global treb_log_timestamp_map
    set type [/world:get type $name]
    set logtype [/world:get log $name]
    set tstype [/world:get timestamp $name]

    if {![/world:exists $name]} { return 0 }
    if {[/world:get host $name] != $WorldInfo($master,gui,host)} { return 0 }
    if {[/world:get port $name] != $WorldInfo($master,gui,port)} { return 0 }
    if {[/world:get charname $name] != $WorldInfo($master,gui,char)} { return 0 }
    if {[/world:get password $name] != $WorldInfo($master,gui,pass)} { return 0 }
    if {[/world:get secure $name] != $WorldInfo($master,gui,secure)} { return 0 }
    if {[/world:get noauth $name] != $WorldInfo($master,gui,noauth)} { return 0 }
    if {[/world:get socks $name] != $WorldInfo($master,gui,socks)} { return 0 }
    if {[/world:get keepalive $name] != $WorldInfo($master,gui,keepalive)} { return 0 }
    if {[/world:get pingcmd $name] != $WorldInfo($master,gui,pingcmd)} { return 0 }
    if {[/world:get encoding $name] != $WorldInfo($master,gui,encoding)} { return 0 }
    if {[/world:get tcl $name] != $WorldInfo($master,gui,tcl)} { return 0 }
    if {[/world:get script $name] != [$master.fr.script.script get 1.0 end-1c]} { return 0 }
    if {$treb_world_type_map($type) != $WorldInfo($master,gui,type)} { return 0 }
    if {$treb_log_type_map($logtype) != $WorldInfo($master,gui,logtype)} { return 0 }
    if {[/world get logfile $name] != $WorldInfo($master,gui,logfile)} { return 0 }
    if {$treb_log_timestamp_map($tstype) != $WorldInfo($master,gui,timestamp)} { return 0 }
    return 1
}


