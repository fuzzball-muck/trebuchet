proc /ps {} {
    set oot "PID\tCommand"
    foreach process [/process:list] {
        append oot "\n[lindex $process 0]    [lindex $process 1]"
    }
    return $oot
}

proc /ps_dlog {} {
    /selector -contentscript {/process:list} -register {/process} \
        -selectpersist -title {Process List} -caption {Select a process} \
        -selectbutton {Kill} -selectscript {/process:kill %1}
}

proc /kill {procid} {
    /process:kill $procid
}


proc /process {opt args} {
    dispatcher /process $opt $args
}

proc /process:current {} {
    global ProcessInfo
    return $ProcessInfo(current)
}

proc process:execute {procid} {
    global Process ProcessInfo
    if {![/process:exists $procid]} {
        error "process execute: No such Process!"
    }
    set Process(expired,$procid) 1
    set ProcessInfo(current) $procid

    eval $Process(cmd,$procid)

    set ProcessInfo(current) 0
    if {$Process(expired,$procid)} {
        /process:kill $procid
    }
}

proc /process:requeue {delay cmd} {
    global Process ProcessInfo
    if {$ProcessInfo(current) == 0} {
        error "/process requeue: Not currently executing a process!"
    }
    set procid [/process:current]
    set Process(cmd,$procid) $cmd
    set Process(afterid,$procid) [after [expr {int($delay * 1000)}] process:execute $procid]
    set Process(expired,$procid) 0

    return ""
}

proc /process:new {desc delay cmd} {
    global Process ProcessInfo
    if {![info exists ProcessInfo(currpid)]} {
        set ProcessInfo(currpid) 0
    }
    set currpid [incr ProcessInfo(currpid)]
    set Process(cmd,$currpid) $cmd
    set Process(desc,$currpid) $desc
    set Process(afterid,$currpid) [after [expr {int($delay * 1000)}] process:execute $currpid]
    set Process(expired,$currpid) 0

    if {![info exists ProcessInfo(processes)]} {
        set ProcessInfo(processes) {}
    }
    lappend ProcessInfo(processes) $currpid
    set ProcessInfo(processes) [lsort -integer $ProcessInfo(processes)]

    /process:notifyregistered
    return "Queued as process $currpid."
}

proc /process:kill {procid} {
    global Process ProcessInfo
    if {![/process:exists $procid]} {
        error "/process delete: No such Process!"
    }
    catch { after cancel $Process(afterid,$procid) }
    catch { unset Process(cmd,$procid) }
    catch { unset Process(desc,$procid) }
    catch { unset Process(afterid,$procid) }
    catch { unset Process(expired,$procid) }

    set pos [lsearch -exact $ProcessInfo(processes) $procid]
    set ProcessInfo(processes) [lreplace $ProcessInfo(processes) $pos $pos]

    /process:notifyregistered
    return "Process deleted."
}

proc /process:pids {} {
    global ProcessInfo
    if {![info exists ProcessInfo(processes)]} {
        set ProcessInfo(processes) {}
    }
    return [lsort -integer $ProcessInfo(processes)]
}

proc /process:exists {procid} {
    global ProcessInfo
    set pos [lsearch -exact $ProcessInfo(processes) $procid]
    if {$pos != -1} {
        return 1
    }
    return 0
}

proc /process:list {} {
    global Process
    set oot {}
    foreach process [/process:pids] {
        lappend oot [list $process $Process(desc,$process)]
    }
    return $oot
}


proc /process:notifyregistered {} {
    global ProcessInfo
    foreach key [array names ProcessInfo "reg,*"] {
        eval "$ProcessInfo($key)"
    }
    return
}

proc /process:register {id cmd} {
    global ProcessInfo
    if {[info exists ProcessInfo(reg,$id)]} {
        error "/process register: That id is already registered!"
    }
    set ProcessInfo(reg,$id) "$cmd"
    return
}

proc /process:deregister {id} {
    global ProcessInfo
    if {[info exists ProcessInfo(reg,$id)]} {
        unset ProcessInfo(reg,$id)
    }
    return
}

