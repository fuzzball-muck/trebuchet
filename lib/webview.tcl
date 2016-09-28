proc /web_view {url} {
    global tcl_platform
    switch -glob -- [string tolower $tcl_platform(platform)] {
        windows {
            webview:windows $url
        }
        unix {
            if {$tcl_platform(os) == "Darwin"} {
                webview:macos_x $url
            } else {
                webview:unix $url
            }
        }
        default {
            set mesg "Sorry, but I don't know how to launch a browser for this Operating System."
            if {[catch {error $mesg}]} {
                tk_messageBox -title "Trebuchet error" -message $mesg -icon error -type ok
            }
        }
    }
    return
}


proc webview:macos_x {url} {
    global mail_regexp2
    update idletasks
    update idletasks
    regsub -all {\)} $url {%29} url
    # regsub -all {,} $url {%2C} url
    if {![regexp {^[a-zA-Z]+:} $url]} {
        if {[regexp "^$mail_regexp2\$" $url]} {
            set url mailto:$url
        } elseif {[regexp {^ftp} [string tolower $url]]} {
            set url ftp://$url
        } else {
            set url http://$url
        }
    }

    catch {/statbar 5 "Spawning browser to view URL."}
    if {[catch {exec open $url} result]} {
        catch {/statbar 5 "Unable to spawn web browser: $result"}
    }
}

proc webview:unix {url} {
    set browsing "new-window"
    global mail_regexp2
    update idletasks
    update idletasks
    regsub -all {\)} $url {%29} url
    # regsub -all {,} $url {%2C} url
    if {![regexp {^[a-zA-Z]+:} $url]} {
        if {[regexp "^$mail_regexp2\$" $url]} {
            set url mailto:$url
        } elseif {[regexp {^ftp} [string tolower $url]]} {
            set url ftp://$url
        } else {
            set url http://$url
        }
    }
    set cmd {}
    catch {set cmd [/prefs:get unix_browser_cmd]}
    if {$cmd == {} || [regexp {netscape.*} $cmd]} {
        catch {/statbar 5 "Passing URL to netscape."}
        if {[catch {exec netscape -remote openURL($url,new-window)}]} {
            catch {/statbar 5 "Spawning netscape to view URL."}
            if {[catch {exec netscape "$url" &}]} {
                catch {/statbar 5 "Passing URL to mozilla."}
                if {[catch {exec mozilla -remote openURL($url,new-window)}]} {
                    catch {/statbar 5 "Spawning mozilla to view URL."}
                    if {[catch {exec mozilla "$url" &}]} {
                        catch {/statbar 5 "Unable to spawn web browser."}
                    }
                }
            }
        }
    } else {
        if {[regexp {mozilla.*} $cmd]} {
            catch {/statbar 5 "Passing URL to mozilla."}
            if {[regexp {.*new-tab.*} $cmd]} {
            	set browsing "new-tab"
            }
            if {[catch {exec mozilla -remote openURL($url,$browsing)}]} {
                catch {/statbar 5 "Spawning mozilla to view URL."}
                if {[catch {exec mozilla "$url" &}]} {
                    catch {/statbar 5 "Unable to spawn web browser."}
                }
            }
        } else {
            regsub -all {\\} "[list $url]" {\\\\} escurl
            regsub -all {&} $escurl {\\\&} escurl
            if {![regsub -all {%u} $cmd $escurl cmd]} {
                append cmd " [list $url]"
            }
            catch {/statbar 5 "Spawning browser to view URL."}
            if {[catch {eval "exec $cmd &"} result]} {
                catch {/statbar 5 "Unable to spawn web browsers: $result"}
            }
        }
    }
}


proc windows:openfile {file {ext ""}} {
    package require registry 1.0
    
    if {$ext == ""} {
        set ext [file extension $file]
    } elseif {[string index $ext 0] != "."} {
        set ext ".$ext"
    }
    if {$ext == "."} {
        set ext ""
    }
    set ext [string tolower $ext]
    if {$ext == ""} {
        error "Cannot open file with unknown extension type."
    }

    if {$ext == ".com" || $ext == ".exe"} {
        set appcmd $file
    } else {
        set key "HKEY_CLASSES_ROOT\\$ext"
        set appkey [registry get $key ""]
        if {$appkey == ""} {
            error "Cannot open file with unregistered extension type."
        }

        set key "HKEY_CLASSES_ROOT\\$appkey\\shell\\open\\command"
        set appcmd [registry get $key ""]
        if {$appcmd == ""} {
            error "Cannot open file with unregistered extension type."
        }

        regsub -all {[[\$\|\&\%\"<>\\]} $file {\\\0} file
        regsub -all {[[\$\|\&<>\\]} $appcmd {\\\0} appcmd
        regsub -all "%1\$" $appcmd {"%1"} appcmd
        regsub -all "%1(\[^\"\])" $appcmd {"%1"\1} appcmd
        if {[string index $appcmd 0] != "\""} {
            regsub -all {^(.*)\.([Cc][Oo][Mm]|[Ee][Xx][Ee])} $appcmd "\"\\1.\\2\"" appcmd
        }
        if {[string first {%1} $appcmd] != -1} {
            regsub -all {%1} $appcmd $file appcmd
        } else {
            append appcmd " \"$file\""
        }
    }

    eval exec $appcmd &
}


proc webview:windows {url} {
    global mail_regexp2

    # regsub -all "\"" $url {%22} url
    regsub -all {\)} $url {%29} url
    # regsub -all {,} $url {%2C} url
    set ext ".html"
    if {![regexp {^[a-zA-Z]+:} $url]} {
        if {[regexp "^$mail_regexp2\$" $url]} {
            set url mailto:$url
        } elseif {[regexp {^ftp} [string tolower $url]]} {
            set url ftp://$url
        } else {
            set url http://$url
        }
    }
    windows:openfile $url $ext
}

