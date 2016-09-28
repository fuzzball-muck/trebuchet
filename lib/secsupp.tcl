################################################
# Optional SSL interface Support, if available.
################################################

catch { package require tls }

if {[info commands tls::init] != {}} {
    proc ::tls::password {} {
        global pwvalue

        set base [toplevel .pw]
        wm title .pw "Certificate Password"
        
        label .pw.l -text "Enter the password for your SSL certificate"
        entry .pw.e
        bind .pw.e <Key-Return> ".pw.b invoke"
        button .pw.b -text "Okay" -command {set pwvalue [.pw get]}

        pack .pw.l -side top -anchor nw
        pack .pw.e -side top -fill x -expand 1
        pack .pw.b -side bottom -fill none -expand 1

        set pwvalue ""
        tkwait variable pwvalue
        destroy .pw
        set pw $pwvalue
        unset pwvalue

        return $pw
    }
}


proc tls_cn_decode {cn} {
    set out(CN) ""
    set out(O) ""
    set out(OU) ""
    set out(L) ""
    set out(ST) ""
    set out(C) ""
    set out(emailAddress) ""
    set parts [lrange [split $cn "/,"] 1 end]
    foreach part $parts {
        set name [lindex [split $part "="] 0]
        if {$name == "Email"} {
            set name "emailAddress"
        }
        set val [join [lrange [split $part "="] 1 end] "="]
        set out($name) $val
    }
    return [array get out]
}

proc tls_cn_text {cn} {
    array set c [tls_cn_decode $cn]
    set    out   "  $c(CN)"
    append out "\n  $c(O)"
    if {$c(OU) != ""} {
        append out "\n  $c(OU)"
    }
    append out "\n  $c(L), $c(ST), $c(C)"
    append out "\n  $c(emailAddress)"
    return $out
}

proc tls_error_query {world errtxt cert} {
    array set c $cert
    if {[/prefs:get ssl_dont_auth]} {
        return "yes"
    }
    if {[/world:get noauth $world]} {
        return "yes"
    }
    for {set winnum 0} {[winfo exists ".tlscertdlog$winnum"]} {incr winnum} continue
    set base ".tlscertdlog$winnum"
    
    global tls_dlog_noauth
    set tls_dlog_noauth [/world:get noauth $world]
    toplevel $base
    wm title $base "Certificate authentication"
    wm resizable $base 0 0
    place_window_default $base .mw
    label $base.errtxt     -justify "left" -text "While negotiating a secure connection, the following problem occurred:\n\n$errtxt"
    label $base.certlbl    -justify "left" -text "Certificate information:"
    label $base.certsubj   -justify "left" -text "Subject:\n[tls_cn_text $c(subject)]"
    label $base.certissuer -justify "left" -text "Issuer:\n[tls_cn_text $c(issuer)]"
    label $base.expires    -justify "left" -text "Expires: $c(notAfter)"
    label $base.question   -justify "left" -text "Do you wish to accept this certificate anyways?"
    checkbutton $base.noauth -text "Don't ask me again for this world" -variable tls_dlog_noauth
    frame $base.btnfr -relief flat -borderwidth 0

    button $base.btnfr.yes    -text "Yes"    -width 8 -underline 0 -command "set tls_dlog_result yes ; destroy $base"
    button $base.btnfr.no     -text "No"     -width 8 -underline 0 -command "set tls_dlog_result no ; destroy $base"

    bind $base <Key-y> "$base.btnfr.yes invoke ; break"
    bind $base <Key-n> "$base.btnfr.no invoke ; break"

    pack $base.errtxt       -side top    -anchor w -padx 10 -pady 10
    pack $base.certlbl      -side top    -anchor w -padx 10
    pack $base.btnfr        -side bottom -anchor s -expand 1 -fill x
    pack $base.noauth       -side bottom -anchor w -padx 40 -pady 0
    pack $base.question     -side bottom -anchor w -padx 10 -pady 5
    pack $base.expires      -side bottom -anchor w -padx 30
    pack $base.certsubj     -side left   -anchor w -padx 30
    pack $base.certissuer   -side left   -anchor w -padx 10

    pack $base.btnfr.no     -side right  -anchor e -padx 10 -pady 10
    pack $base.btnfr.yes    -side right  -anchor e -padx 10 -pady 10
    place_window_default $base ".mw"

    global tls_dlog_result
    set tls_dlog_result no
    tkwait window $base

    set result $tls_dlog_result
    unset tls_dlog_result

    if {$tls_dlog_noauth == 1 && $result == "yes"} {
        /world:set noauth $world 1
    }
    unset tls_dlog_noauth

    return $result
}

tcl::OptProc /tls:showcert {
    {-world  {} "The world to show the certificate for."}
} {
    if {$world == {}} {
        set world [/socket:foreground]
        if {$world == {}} {
            return
        }
    }
    if {[info commands tls::init] != {}} {
        if {[catch {tls::status [/socket:get socket $world]} stat]} {
            return
        }
        if {$stat == ""} {
            return
        }
        array set c $stat
        /textdlog -buttons -title "Certificate Info" \
            -width 40 -height 19 -nowrap -readonly -text \
"Subject:
[tls_cn_text $c(subject)]

Issuer:
[tls_cn_text $c(issuer)]

Serial#: $c(serial)
Valid after: $c(notBefore)
Valid until: $c(notAfter)

Cipher in use: $c(cipher)"
    }
}

proc tls_command_cb {option args} {
    set world ""
    set chan [lindex $args 0]
    set args [lrange $args 1 end]
    foreach name [/socket:names] {
        if {[/socket:get socket $name] == $chan} {
            set world $name
            break
        }
    }

    switch -- $option {
        "error" {
            foreach {msg} $args break
            /statbar 10 "TLS/$chan: error: $msg"
        }
        "verify"    {
            # poor man's lassign
            foreach {depth cert rc err} $args break
            array set c $cert
            if {$rc != "1"} {
		puts stderr $err
                switch -glob -- $err {
                    "*certificate not trusted*" -
                    "*unable to get local issuer certificate*" {
                        /statbar 10 "SSL/TLS verify $depth: Bad Cert: $err"
                        return 1
                    }
                    "*Certificate has expired*" {
                        /statbar 10 "SSL/TLS verify $depth: Expired certificate."
                        return 1
                    }
                    default {
                        /statbar 10 "SSL/TLS verify $depth: Bad Cert: $err"
                        if {[tls_error_query $world $err $cert] == "no"} {
                            return 0
                        }
                    }
                }
            } else {
                if {$depth == 0} {
                    array set subj [tls_cn_decode $c(subject)]
                    set peerinfo [fconfigure $chan -peername]
                    set peeraddr [string tolower [lindex $peerinfo 0]]
                    set peerhost [string tolower [lindex $peerinfo 1]]
                    set reqhost [string tolower [/world:get host $world]]
                    set subjCN [string tolower $subj(CN)]
                    if {$subjCN != $peerhost && $subjCN != $peeraddr && $subjCN != $reqhost} {
                        set rc 0
                        set err "certificate hostname ($subjCN) does not match connection host ($peerhost, $peeraddr)."
                        /statbar 10 "SSL/TLS verify $depth: Bad Cert: $err"
                        if {[tls_error_query $world $err $cert] == "no"} {
                            return 0
                        }
                        /statbar 10 "SSL/TLS verify $depth: Cert accepted by user anyways."
                    } else {
                        # /statbar 10 "SSL/TLS verify $depth: Good Cert\n[tls_cn_text $c(subject)]"
                    }
                } else {
                    # /statbar 10 "SSL/TLS verify $depth: Good Cert\n[tls_cn_text $c(subject)]"
                }
            }
            return 1
        }
        "info"  {
            # poor man's lassign
            foreach {major minor state msg} $args break

            if {$msg != ""} {
                append state ": $msg"
            }
        }
        default {
            return -code error "bad option \"$option\": must be one of error, info, or verify"
        }
    }
}


proc tls_status_get {sok} {
    global treb_tls_status
    if {![info exists treb_tls_status($sok)]} {
        return ""
    }
    return $treb_tls_status($sok)
}


proc tls_status_set {sok val} {
    global treb_tls_status
    set treb_tls_status($sok) $val
}


proc tls_startup {sok world} {
    global treb_cacerts_dir
    tls::import $sok -require 1 \
            -ssl2 0 -ssl3 0 -tls1 1 \
            -cadir $treb_cacerts_dir \
            -command tls_command_cb
    tls_status_set $sok "nego"
    wait_for_starttls_negotiation $sok $world
}


proc wait_for_starttls_negotiation {sok world} {
    catch { fileevent $sok readable "" }
    catch { fileevent $sok writable "" }
    if {![catch { tls::handshake $sok } sockerr]} {
        if {$sockerr == 1} {
            set goterr [catch {tls::status $sok} result]
            if {$goterr || $result == ""} {
                after 250 "catch {fileevent [list $sok] writable \"wait_for_starttls_negotiation [list $sok] [list $world]\"}"
                return
            }
            tls_status_set $sok "encr"
            fileevent $sok readable "readline [list $world]"
            /statbar 5 "Encryption negotiation complete for $world..."
            update_secure_indicator
            return
        } else {
            set sockerr {}
        }
    }
    if {$sockerr != {}} {
        switch -glob $sockerr {
            "*handshake failed: Undefined error: 0*" -
            "*handshake failed: Unknown error: 0" -
            "*handshake failed: Error 0" -
            "*handshake failed: Success*" -
            "*handshake failed: No error*" -
            "*resource temporarily unavailable*" {
                # do nothing.
            }
            default {
                if {[info commands ::tls::unimport] != ""} {
                    /statbar 10 "Encryption failed for world $world.  Falling back to unencrypted link."
                    tls::unimport $sok
                    fileevent $sok readable "readline [list $world]"
                } else {
                    /statbar 10 "Encryption failed for world $world.  Reconnecting with unencrypted link."
                    catch {/socket:disconnect $world}
                    catch {/socket:connect $world 1}
                }
                tls_status_set $sok {}
                update idletasks
                return
            }
        }
    }
    after 250 [list wait_for_starttls_negotiation $sok $world]
}


proc wait_for_ssl_negotiation {sok world} {
    if {![catch { tls::handshake $sok } sockerr]} {
        if {$sockerr == 1} {
            fileevent $sok writable ""
            fileevent $sok readable "readline [list $world]"
            update_secure_indicator
            return
        } else {
            set sockerr {}
        }
    }
    if {$sockerr != {}} {
        switch -glob $sockerr {
            "*handshake failed: Undefined error: 0*" -
            "*handshake failed: Unknown error: 0" -
            "*handshake failed: Error 0" -
            "*handshake failed: Success*" -
            "*handshake failed: No error*" -
            "*resource temporarily unavailable*" {
                # do nothing.
            }
            "*certificate verify failed*" {
                catch {/socket:disconnect $world}
                /statbar 10 "Connection to $world failed."
                update idletasks
                /error $world "Could not connect to world $world.\nTheir server's SSL certificate failed to authenticate."
                #/echo "subject = [split $data(subject) /]"
                #/echo "issuer = [split $data(issuer) /]"
                return
            }
            "*unknown protocol*" {
                catch {/socket:disconnect $world}
                /statbar 10 "Connection to $world failed."
                update idletasks
                /error $world "Could not connect to world $world.\nThat port doesn't look like it supports SSL."
                return
            }
            default {
                catch {/socket:disconnect $world}
                /statbar 10 "Connection to $world failed."
                update idletasks
                /error $world "Could not connect to world $world.\n$sockerr"
                return
            }
        }
    }
    after 250 [list wait_for_ssl_negotiation $sok $world]
}

proc update_secure_indicator {} {
    set world [/socket:foreground]
    set oldsec [.mw.statusbar.secure cget -image]
    set newsec ssl_icon_insecure

    if {[info commands tls::init] != {}} {
        if {$world != {}} {
            set stat ""
            if {![catch {tls::status [/socket:get socket $world]} stat] } {
                set newsec ssl_icon_secure
            }
        }
    }

    if {$oldsec != $newsec} {
        .mw.statusbar.secure config -image $newsec
    }
}


