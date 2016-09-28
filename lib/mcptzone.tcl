###############################
##  AWNS Timezone Interface  ##
############################################################################
##
##
############################################################################


proc awns_timezone_init {world vers} {
    set pkg "dns-com-awns-timezone"

    /mcp_send $pkg "" -world $world timezone [clock format [clock seconds] -format "%Z"]
}


proc awns_timezone {world data} {
    set pkg "dns-com-awns-timezone"

    array set arr $data
    setfrom timezone arr(timezone) {}
    # we don't do anything for this message.

    return
}


mcp_register_pkg "dns-com-awns-timezone" 1.0 1.0 awns_timezone_init
mcp_register_handler "dns-com-awns-timezone" "" awns_timezone




proc fb_timezone_init {world vers} {
    set pkg "dns-com-awns-timezone"

    set gmt   [expr "[clock format [clock seconds] -format {(1%H-100)*3600+(1%M-100)*60+(1%S-100)} -gmt 1]"]
    set local [expr "[clock format [clock seconds] -format {(1%H-100)*3600+(1%M-100)*60+(1%S-100)}]"]
    set diff  [expr {($local-$gmt)%86400}]
    if {$diff > 43200} {
        set diff [expr {$diff - 86400}]
    }
    set lzone [clock format [clock seconds] -format "%Z"]
    /mcp_send $pkg "" -world $world timezone $lzone tzoffset $diff
}


proc fb_timezone {world data} {
    set pkg "org-fuzzball-timezone"

    array set arr $data
    setfrom timezone arr(timezone) {}
    setfrom tzoffset arr(tzoffset) 0
    # we don't do anything for this message.

    return
}


mcp_register_pkg "org-fuzzball-timezone" 1.0 1.0 fb_timezone_init
mcp_register_handler "org-fuzzball-timezone" "" fb_timezone

