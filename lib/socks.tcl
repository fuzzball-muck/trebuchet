##############################################################################
# Socks5 Client Library v1.1
#     (C)2000 Kerem 'Waster_' HADIMLI
#
# How to use:
#   1) Create your socket connected to the Socks server.
#   2) Call socks:init procedure with these 6 parameters:
#        1- Socket ID : The socket identifier that's connected to the socks5 server.
#        2- Server hostname : The main (not socks) server you want to connect
#        3- Server port : The port you want to connect on the main server
#        4- Authentication : If you want username/password authentication enabled, set this to 1, otherwise 0.
#        5- Username : Username to use on Socks Server if authentication is enabled. NULL if authentication is not enabled.
#        6- Password : Password to use on Socks Server if authentication is enabled. NULL if authentication is not enabled.
#   3) It'll return you a string starting with:
#        a- "OK" if successful, now you can send/receive any data from the socket.
#        b- "ERROR:$explanation" if unsuccessful, $explanation is the explanation like "Host not found". The socket will be automatically closed on an error.
#
#
# Notes:
#   - This library enters vwait loop (see Tcl man pages), and returns only
#     when SOCKS initialization is complete.
#   - This library uses a global array: socks_idlist. Make sure your program
#     doesn't use that.
#   - NEVER use file IDs instead of socket IDs!
#   - NEVER bind the socket (fileevent) before calling socks:init procedure.
##############################################################################
#
# Author contact information:
#   E-mail :  waster@iname.com
#   ICQ#   :  27216346
#   Jabber :  waster@jabber.org   (New IM System - http://www.jabber.org)
#
##############################################################################
#
#set socks_idlist(stat,$sck) ...
#set socks_idlist(data,$sck) ...

proc socks:init {sck addr port auth user pass} {
global socks_freeid socks_idlist

#  if { [catch {fconfigure $sck}] != 0 } {return "ERROR:Connection closed with Socks Server!"}    ;# Socket doesn't exist

  set ver "\x05"               ;#Socks version
  if {$auth==0} {set method "\x00"; set nmethods "\x01"} \
	elseif {$auth==1} {set method "\x00\x02"; set nmethods "\x02"} \
	else {return "ERROR:"}
  set nomatchingmethod "\xFF"  ;#No matching methods

  set cmd_connect "\x01"  ;#Connect command
  set rsv "\x00"          ;#Reserved
  set atyp "\x03"         ;#Address Type (domain)
  set dlen "[binary format c [string length $addr]]" ;#Domain length (binary 1 byte)
  set port [binary format S $port] ;#Network byte-ordered port (2 binary-bytes)

  set authver "\x01"  ;#User/Pass auth. version
  set ulen "[binary format c [string length $user]]"  ;#Username length (binary 1 byte)
  set plen "[binary format c [string length $pass]]"  ;#Password length (binary 1 byte)

  set a ""

  set socks_idlist(stat,$sck) 0
  set socks_idlist(data,$sck) ""

  fconfigure $sck -translation {binary binary} -blocking 0
  fileevent $sck readable "socks:readable $sck"

  puts -nonewline $sck "$ver$nmethods$method"
  flush $sck

  vwait socks_idlist(stat,$sck)
  set a $socks_idlist(data,$sck)
  if {[eof $sck]} {catch {close $sck}; return "ERROR:Connection closed with Socks Server!"}

  set serv_ver ""; set method $nomatchingmethod
  binary scan $a "cc" serv_ver smethod

  if {$serv_ver!=5} {catch {close $sck}; return "ERROR:Socks Server isn't version 5!"}

  if {$smethod==0} {} \
  elseif {$smethod==2} {  ;#User/Pass authorization required
	if {$auth==0} {catch {close $sck}; return "ERROR:Method not supported by Socks Server!"}

	puts -nonewline $sck "$authver$ulen$user$plen$pass"
	flush $sck

	vwait socks_idlist(stat,$sck)
	set a $socks_idlist(data,$sck)
	if {[eof $sck]} {catch {close $sck}; return "ERROR:Connection closed with Socks Server!"}

	set auth_ver ""; set status "\x00"
	binary scan $a "cc" auth_ver status

	if {$auth_ver!=1} {catch {close $sck}; return "ERROR:Socks Server's authentication isn't supported!"}
	if {$status!=0} {catch {close $sck}; return "ERROR:Wrong username or password!"}

  } else {
	fileevent $sck readable {}
	unset socks_idlist(stat,$sck)
	unset socks_idlist(data,$sck)
	catch {close $sck}
	return "ERROR:Method not supported by Socks Server!"
  }

#
# We send request4connect
#
  puts -nonewline $sck "$ver$cmd_connect$rsv$atyp$dlen$addr$port"
  flush $sck

  vwait socks_idlist(stat,$sck)
  set a $socks_idlist(data,$sck)
  if {[eof $sck]} {catch {close $sck}; return "ERROR:Connection closed with Socks Server!"}

  fileevent $sck readable {}
  unset socks_idlist(stat,$sck)
  unset socks_idlist(data,$sck)

  set serv_ver ""; set rep ""
  binary scan $a cc serv_ver rep
  if {$serv_ver!=5} {catch {close $sck}; return "ERROR:Socks Server isn't version 5!"}

  if {$rep==0} {fconfigure $sck -translation {auto auto}; return "OK"} \
    elseif {$rep==1} {catch {close $sck}; return "ERROR:Socks server responded:\nGeneral SOCKS server failure"} \
    elseif {$rep==2} {catch {close $sck}; return "ERROR:Socks server responded:\nConnection not allowed by ruleset"} \
    elseif {$rep==3} {catch {close $sck}; return "ERROR:Socks server responded:\nNetwork unreachable"} \
    elseif {$rep==4} {catch {close $sck}; return "ERROR:Socks server responded:\nHost unreachable"} \
    elseif {$rep==5} {catch {close $sck}; return "ERROR:Socks server responded:\nConnection refused"} \
    elseif {$rep==6} {catch {close $sck}; return "ERROR:Socks server responded:\nTTL expired"} \
    elseif {$rep==7} {catch {close $sck}; return "ERROR:Socks server responded:\nCommand not supported"} \
    elseif {$rep==8} {catch {close $sck}; return "ERROR:Socks server responded:\nAddress type not supported"} \
      else {catch {close $sck}; return "ERROR:Socks server responded:\nUnknown Error"}
}

#
# Change the variable value, so 'vwait' loop will end in socks:init procedure.
#
proc socks:readable {sck} {
global socks_idlist
  incr socks_idlist(stat,$sck)
  set socks_idlist(data,$sck) [read $sck]
}
