%define name       trebuchet
%define version    1.082
%define release    1

Name: 		%{name}
Version:	%{version}
Release:	%{release}
Group: 		Networking/Chat
Summary:	The Trebuchet MUCK client
License:	GPL
Url: 		http://sourceforge.net/projects/trebuchet/
Source:		%{name}-%{version}.tar.bz2
Packager:	Henri <voraphile@yahoo.com>
Vendor:		FuzzBall Software
BuildRoot:	/var/tmp/%{name}_root
Requires:	tcl >= 8.3, tk >= 8.3
BuildArch:	noarch

%description
Trebuchet is a 100% TCL cross-platform GUI MU* client, designed to be powerful
and extensible, yet easy to use. This client also has support for advanced
features, such as SSL encryption, and server requested GUI dialogs. This client
is being developed alongside the Fuzzball Muck 6 server project, so that both
can be reference implementations of new protocols.

%prep
rm -rf $RPM_BUILD_ROOT
%setup -q
find . -name "CVS" -type "d" -print | xargs rm -rf
find . -type "f" -print | xargs chmod -x 
chmod +x mkdir_recursive Trebuchet.tcl

%build
%make
csplit -s %{name}.spec "/%changelog/+1" "{1}"
mv -f xx02 patches.txt
rm -f xx*

%install
%makeinstall
mkdir -p $RPM_BUILD_ROOT/%_prefix/libexec/trebuchet/cacerts
cp -af ding.wav icons cacerts LICENSE *.txt $RPM_BUILD_ROOT/%_prefix/libexec/trebuchet/

mkdir -p $RPM_BUILD_ROOT/%_iconsdir
cp -af icons/Treb2.png $RPM_BUILD_ROOT/%_iconsdir/Trebuchet.png

mkdir -p $RPM_BUILD_ROOT%_datadir/applications
cat << EOF >$RPM_BUILD_ROOT%_datadir/applications/%name.desktop
[Desktop Entry]
Version=1.0
Name=Trebuchet
GenericName=Trebuchet MUCK client
Comment=MUCK/MUSH/MUX/MUD client
Exec=treb
Terminal=false
Type=Application
Icon=Trebuchet
Categories=Network;Chat;
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%_bindir/treb
%_prefix/libexec/trebuchet/*
%_iconsdir/*
%_datadir/applications/%name.desktop

%changelog
* Sun Dec 04 2016 Henri @ Voregotten Realm
- Trebuchet v1.082.
- Reintroduced changes accidentally overwritten by Revar's latest commits.

* Thu Mar 30 2015 Henri @ Voregotten Realm
- Trebuchet v1.081.
- Added icon and desktop files to the binary rpm.

* Thu Mar 26 2015 Henri @ Voregotten Realm
- Trebuchet v1.080.

* Thu Nov 4 2010 Henri @ Voregotten Realm
- Trebuchet v1.077.

* Thu Nov 4 2010 Henri @ Voregotten Realm
- Trebuchet v1.076.

* Wed May 11 2010 Revar Desmera <revar@belfry.com>
- Trebuchet v1.075.
- Merged Henri's and my tree.

* Wed Dec 9 2009 Henri @ Voregotten Realm
- Trebuchet v1.074.

* Mon Apr 27 2009 Henri @ Voregotten Realm
- Trebuchet v1.073.

* Wed Sep 27 2006 Henri @ Voregotten Realm
- Trebuchet v1.072. All previous patches have been integrated into v1.072.

* Thu Aug 03 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 14).
- Replaced the "talker" patch with "talker_after_socks5" patch. The new patch
  fixes the remaining problems which used to be encountered on talkers (such as
  the impossibility to create a new character from Trebuchet). This patch can
  only be applied after the "socks5" patch, thus its name...
- Added the "multiple_ping_cmds" patch, allowing to setup multiple ping
  commands on worlds trying to boot you when you use an anti-idle timer. Simply
  set a list of commands in the "Ping command" field of the world, separating
  each one from the next with a "|" symbol (example: who|ex|l).

* Fri Jun 26 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 13).
- Added the "word_completion" patch to work around a crash bug which occured
  in some instances, when completing ANSIfied names on some Talkers.

* Fri Jun 16 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 12).
- Better "msp" patch with support for Snack sound TCL extension.

* Sun Jun 11 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 11).
- Added the "msp" patch implementing MCP-encapsulated MSP (MUD Sound Protocol)
  support (zMud alike), enabling Trebuchet with sound/music playing ability.

* Thu Jun 08 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 10).
- Added the "loadimage" patch implementing a new MCP module which enables
  Trebuchet with loading of images stored on web sites into its output
  display.

* Fri May 26 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 9).
- Added the "socks5" patch to add SOCKS5 proxyfied connections support (note
  that this patch removes the old, obscure telnet proxy code which was not
  supported by the GUI anyway and thus most probably unused). 

* Tue Apr 18 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 8).
- Added the "talker" patch to fix the login problems with Talkers. This patch 
  adds a new "talker" MUD type in the New/Edit worlds menus.

* Sat Apr 15 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 7).
- Changed the cosmetic patch to fix the font size problem in the quick buttons
  bar.

* Fri Apr 14 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 6).
- Replaced the "context_find" patch with the "context_find_and_send" patch, to
  add a "Send to the MUCK" item to the context menu for selected text in
  display and input windows.

* Sun Mar 19 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 5).
- Added the "win_button2_paste" patch to fix a problem under Windoze where the
  text was pasted twice when the "Paste with middle button" preference was
  selected.
- Added the "empty_worlds_editdlog" patch to fix a bug triggered when pressing
  the "Done" button of the worlds edit dialog while there is no configured
  world yet.

* Fri Mar 17 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 4).
- Added the "brace_matching" patch to fix the brace matching problem where the
  highligting was only occuring after a backspace or a double quote.

* Tue Mar 14 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 3).
- Better "gag_words" patch.
- Added the "context_find" patch to add a "Find..." option in the context pop
  up menu for the display and input windows.
- Changed the cosmetic patch to capitalize the "Http" tab of the preferences
  menu.

* Sun Mar 12 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 2).
- Added the "gag_words" patch to enable the "Only to matched words" option for
  the "gag" style.

* Mon Mar 06 2006 Henri @ Voregotten Realm
- Trebuchet v1.071 (build 1).
- Latest CVS sources.

* Thu Dec 08 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 9).
- Latest CVS sources.

* Sun Nov 20 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 8).
- Latest CVS sources.

* Sat Nov 19 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 7).
- Added the spell_default patch to avoid problems on first start, on platforms
  without aspell installed.
- Changed the cosmetic patch to allow a better initial window sizing at first
  start (defaults at 640x480 instead of forcing a 80 columns mode which results
  in very weird sizing on 16/10 screens, or too small a sizing on large, 4/3
  ones).

* Mon Aug 22 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 6).
- Added the empty_web_cache patch (adds code and the corresponding "Empty the
  web cache on exit" option to the HTTP tab of the preferences menu).

* Fri Jul 08 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 5).
- Damn it: wrong version of the "url_regexp" in build 4... This time, it's the
  good one...

* Fri Jul 08 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 4).
- Added the "url_regexp" patch for better and faster URL regexp matching (it
  should not highlight ASCII art as URL any more now, and more (all ?) URLs
  will be properly recognized and highlighted).

* Sun Jun 26 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 3).
- Latest CVS sources.
- Removed the now useless "default_size" patch.
- Added the "btnbar" patch to revert to the old code as there is now a qbuttons
  wrapping problem with the new btnbar.tcl code...
- Added the "senddlog" patch to re-enable the file types selection in the "Send
  File" file selector (why the Hell was this removed ?...).

* Fri Jun 03 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 2).
- Latest CVS sources.
- Removed the now included "aspell_default_cmd" patch.
- Added the "default_size" patch to fix the main window sizing problem on first
  use of Trebuchet.

* Thu May 31 2005 Henri @ Voregotten Realm
- Trebuchet v1.070 (build 1).
- Latest CVS sources.
- Added the "aspell_default_cmd patch", because the latest versions of aspell
  do not accept the -l switch anymore for the 'list' command.

* Tue Apr 26 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 9).
- Latest CVS sources.

* Tue Mar 29 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 8).
- Latest CVS sources.
- Replaced the "compass" patch with the "toolbar" patch: this patch reverts
  to the old widget packing method (with the fix which was part of the
  "compass" patch), because the grid placing method is not working properly
  under Tcl/Tk 8.3 (when the compass is not shown, the qbuttons bar sometimes
  appears on two rows while one would be enough to hold all the buttons).

* Mon Mar 28 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 7).
- Added the icons.

* Thu Mar 24 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 6).
- Removed the now included "stackcmd" patch.
- Cut down the "cosmetic" and "compass" patches as most of their code was
  adopted.

* Wed Mar 23 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 5).
- Reworked the "compass" patch again: the frame now actually disappears when no
  qbuttons or compass are shown, instead of getting its height reduced to one
  pixel.

* Wed Mar 23 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 4).
- Reworked the "compass" patch to fix the bug where the frame for the qbuttons
  and compass won't disappear when neither are shown.

* Tue Mar 22 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 3).
- Latest CVS sources.
- Removed the now included "remote" patch.

* Tue Mar 22 2005 Henri @ Voregotten Realm
- Trebuchet v1.067 (build 2).
- Latest CVS sources.
- Added the compass patch (bugfix and MU* compatibility).
- Added the stackcmd patch (new feature: command stacking !).
- Reworked the warn_on_updates patch to add an unofficial patch history entry
  in the Help menubar entry. Reworked the spec file to build the patches.txt
  file from the spec changelog.

* Sat Mar 19 2005 Henri @ Voregotten Realm
- Trebuchet v1.067.
- Latest CVS sources.

* Sat Mar 19 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 8).
- Latest CVS sources.
- Reworked the cosmetic patch.

* Thu Mar 10 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 7).
- Latest CVS sources.

* Sat Mar 05 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 6).
- Added the remote patch, to allow remote connection control of Trebuchet.
  "treb --connect host port" or "treb --connect host:port" will open a new
  world in any existing copy of Trebuchet (or will open that world in a new
  copy if no instance existed when the command was issued). With this feature
  you may configure some browsers (such as Firefox) to use Trebuchet instead
  of a dumb telnet client for opening telnet:// links.

* Fri Mar 04 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 5).
- Latest CVS sources.
- Removed the callbacks and spellcheck patches as they are now part of the CVS
  sources.

* Thu Mar 03 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 4).
- Latest CVS sources.
- Stripped down the spellcheck patch to reflect adopted changes in the official
  sources.
- Reworked the callbacks patch to reflect the future changes in next the CVS
  sources. :-)
- Removed the image_dlg patch as it was included in the latest CVS sources.

* Wed Mar 02 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 3).
- Latest CVS sources.
- Reworked the spellchecker patch.
- Added the callbacks patch to fix bugs in some menu callbacks.
- Added the certificate directory to the distribution.

* Sun Feb 27 2005 Henri @ Voregotten Realm
- Trebuchet v1.066 (build 2).
- Bugfix in spellchecker patch (running Trebuchet on an aspell-less Windoze
  system would make it enter an infinite loop).

* Sat Feb 26 2005 Henri @ Voregotten Realm
- Trebuchet v1.066.
- spellchecker patch rewrote for the new, official spell-checker.

* Fri Feb 25 2005 Henri @ Voregotten Realm
- Trebuchet v1.065 (build 6).
- spellchecker patch adapted for Tcl/Tk v8.3 and for Windoze.

* Thu Feb 24 2005 Henri @ Voregotten Realm
- Trebuchet v1.065 (build 5).
- Proper spellchecker with suggestions and word replacement implemented via the
  spellcheck patch.

* Thu Feb 24 2005 Henri @ Voregotten Realm
- Trebuchet v1.065 (build 4).
- Latest CVS sources.
- Removed the tk83 and cut-in-output-window patches, as they were included in
  the latest CVS sources.
- Corrected a bug in the spellcheck patch which didn't work when either the
  TMP or the TEMP environment variables were set.

* Wed Feb 23 2005 Henri @ Voregotten Realm
- Trebuchet v1.065 (build 3).
- Added the tk83 patch IOT allow Trebuchet to run under Tcl/Tk v8.3x.
- Added aspell/ispell spell-checker support to Trebuchet (tested under Linux
  and should work under any UNIX-like OS, including MacOS-X).

* Mon Feb 21 2005 Henri @ Voregotten Realm
- Trebuchet v1.065 (build 2).
- Latest CVS sources.
- Added the image_dlg patch to allow proper image displaying via MCP (used to
  be limited to 512x512 pixels).

* Sun Feb 20 2005 Henri @ Voregotten Realm
- Trebuchet v1.065.
- Removed the altgr and textmods patches, as the associated bugs were fixed.
- Added the cut-in-output-window patch to allow removing spam/irrelevant posts
  from the output display.

* Thu Feb 17 2005 Henri @ Voregotten Realm
- Trebuchet v1.064 (build 4).
- ARGHH !... Fixed typos in the textmods patch...

* Thu Feb 17 2005 Henri @ Voregotten Realm
- Trebuchet v1.064 (build 3).
- Added the textmods patch to cure the bug where an error would be reported
  under certain conditions after closing dialogs with text input fields.

* Thu Feb 17 2005 Henri @ Voregotten Realm
- Trebuchet v1.064 (build 2).
- Added the altgr patch to cure the bug where AltGr characters would replace
  selected text in the output window when the latter is focused.

* Wed Feb 16 2005 Henri @ Voregotten Realm
- Trebuchet v1.064.

* Mon Feb 14 2005 Henri @ Voregotten Realm
- Trebuchet v1.063 (build 2).
- Use of the official release sources.
- Removed the now integrated "prefs" patch.

* Thu Feb 03 2005 Henri @ Voregotten Realm
- Trebuchet v1.063.
- Removed the now integrated "richview_cursor" patch.
- Added the "prefs" patch to fix a bug and reorganize the prefs.

* Tue Feb 01 2005 Henri @ Voregotten Realm
- Trebuchet v1.062 (build 2).
- Added the "richview_cursor" patch to fix the bug about the invalid "ibeam"
  cursor under Linux/UNIX.
- Added the warn_on_updates patch (warns the user when they try to do a live
  update from Revar's site, as this would make them loose all the patches...).

* Mon Jan 31 2005 Henri @ Voregotten Realm
- Trebuchet v1.062.
- Removed all the patches which were adopted by Revar and included into v1.062.
- Made the "cosmetic" patch: gives small and cute quick-buttons in the toolbar
  under UNIX instead of big ugly ones, reorganizes the New/Edit World dialogs
  into a more logical layout (the keep alive/ping stuff is kept next to the
  connection settings), moves the general ping/keepalive settings into the
  "Misc" tab of the preferences menu (getting rid of the badly named "Firewall"
  tab in the process), and uses a white font on a black background for the
  default "normal" font style (suitable for ANSI MU*s, unlike the black font on
  grey background which the original Trebuchet sources use as a default.).

* Sat Jan 29 2005 Henri @ Voregotten Realm
- Trebuchet v1.061 (reworked the patches).
- Added the tk83 patch IOT allow Trebuchet to run under Tcl/Tk v8.3x.

* Fri May 21 2004 Henri @ Voregotten Realm
- Trebuchet v1.060.

* Fri Apr 02 2004 Henri @ Voregotten Realm
- Trebuchet v1.059.
- added again the email_regexp patch, because wrong hilighting happens
  otherwise (example: "anything.@-something" is NOT a valid email)...
- made webview-patch aware of tabbed browsing for mozilla.

* Tue Dec 04 2003 Henri @ Voregotten Realm
- Trebuchet v1.057 (build 5).
- latest CVS sources.
- replaced keepalive_bugfix.patch with keepalive_and_ping.patch, which
  implements a per-world force-keep-alive setting and optional ping command.

* Tue Dec 04 2003 Henri @ Voregotten Realm
- Trebuchet v1.057 (build 4).
- corrected a typo in the keepalive_bugfix.patch... GRRR !

* Wed Dec 03 2003 Henri @ Voregotten Realm
- Trebuchet v1.057 (build 3).
- changed the keepalive_bugfix.patch again, adding the ping command option
  into the prefs dialog: when telnet keep alives are not supported by the
  server (type set to TinyMUX), the ping command is sent, if set, else an
  empty telnet packet is set (previous behaviour, which was inefficient to
  keep the link alive, most of the time). A suggested ping command for MUXes
  is "@@". Also fixed a bug in the previous patch which prevented to save the
  TinyMUX type in the prefs file.

* Thu Dec 02 2003 Henri @ Voregotten Realm
- Trebuchet v1.057 (build 2).
- changed the keepalive_bugfix.patch (new policy: use the new TinyMUX type
  for server not accepting telnet keepalive).

* Fri Nov 28 2003 Henri @ Voregotten Realm
- Trebuchet v1.057.

* Thu Nov 13 2003 Henri @ Voregotten Realm
- Trebuchet v1.056.
- Removed the now useless email_regexp and unix_paste_selection patches.

* Sun Nov 02 2003 Henri @ Voregotten Realm
- Trebuchet v1.055 (build 2).
- Fixed a bug introduced in v1.055: unix_paste_selection patch added, which
  also enables properly the "copy_on_select" and "button2_paste" preferences
  under UNIX.

* Wed Oct 29 2003 Henri @ Voregotten Realm
- Trebuchet v1.055.
- small_qbutton patch adapted to v1.055.
- typo fixed in regexp matching of the webview patch.
- Added the rm -rf .../.../trebuchet/trebuchet as a quick fix to a problem
  with v1.055 make install...

* Fri Oct 10 2003 Henri @ Voregotten Realm
- Trebuchet v1.054 (build 2).
- Changed the small_qbutton patch to allow full use of the window width by the
  button bar.

* Tue Oct 07 2003 Henri @ Voregotten Realm
- Trebuchet v1.054.

* Mon Sep 15 2003 Henri @ Voregotten Realm
- Trebuchet v1.053.

* Fri Sep 12 2003 Henri @ Voregotten Realm
- Trebuchet v1.051 + beep patch (adds a configurable beep command).

* Mon Jul 28 2003 Henri @ Voregotten Realm
- Trebuchet v1.051.

* Sat Jul 26 2003 Henri @ Voregotten Realm
- Trebuchet v1.050 (build 2).
- Fixed the bug preventing the keep alive to work by reverting to the old
  routine (keepalive_bugfix patch).

* Tue Jul 22 2003 Henri @ Voregotten Realm
- Trebuchet v1.050.

* Wed Jul 10 2003 Henri @ Voregotten Realm
- Trebuchet v1.047 (build 2).
- Added the email_regexp patch.

* Wed Jul 09 2003 Henri @ Voregotten Realm
- Trebuchet v1.047. Latest CVS sources.
- Removed the now useless scrollbars patch.

* Tue Jul 01 2003 Henri @ Voregotten Realm
- Trebuchet v1.044 (build 3). Latest CVS sources.
- Added the scrollbars patch to reinstate proper scrollbars style in the
  main window.

* Fri Jun 27 2003 Henri @ Voregotten Realm
- Trebuchet v1.044 (build 2). Latest CVS sources.

* Fri Jun 21 2003 Henri @ Voregotten Realm
- Trebuchet v1.044.

* Fri May 16 2003 Henri @ Voregotten Realm
- Trebuchet v1.042.

* Wed Apr 02 2003 Henri @ Voregotten Realm
- Trebuchet v1.038 (build 3). Compiled from the latest CVS release.

* Tue Feb 25 2003 Henri @ Voregotten Realm
- Trebuchet v1.038.

* Mon Feb 03 2003 Henri @ Voregotten Realm
- Trebuchet v1.036.

* Mon Dec 16 2002 Henri @ Voregotten Realm
- Trebuchet v1.034.

* Mon Nov 18 2002 Henri @ Voregotten Realm
- Trebuchet v1.031.

* Wed May 11 2001 Revar Desmera <revar@belfry.com>
- Automated updating of spec file via makefile.

* Wed Apr 20 2001 Revar Desmera <revar@belfry.com>
- First try at making the packages
