# Trebuchet
A MUD/MUCK/MUSH chat client with MCP/GUI support.

# What This Is:

This is Trebuchet Tk, a MUD client written purely in TCL/Tk 8

(For those of you who are wondering what a MUD is, it's kind of a chat or
role play system, somewhat like IRC.  However, MUDs have the concept of
persistent areas and objects, each with text descriptions and many ways to
interact with them.  Most MUDs also allow users to create programs to make
new ways to interact with their environment.)

Trebuchet lets you connect to various internet MUDs with a nicer interface
than the usual run of the mill telnet clients.  Trebuchet is designed to
be as powerful as (if not more than!) tinyfugue, and it will allow some-
thing that no other client I know of will: You can write GUI interfaces
with its internal TCL/Tk 8 scripting language.  This means that scripts
can be created to make it much easier to interface with the complex MUD
command line interface.

Imagine, if you will, being able to edit the objects in the world with
a GUI interface, instead of having to remember all the ugly commands.
Being able to edit lists in a nice GUI editor without having to deal
with the nasty line-at-a-time list editor that MUCKs provide.

There is nothing about the Trebuchet client that is specific to MUCK,
however.  You could use this client with MUSH, MUSE, or old TinyMUD,
and write scripts that will interface with each of them specifically.


# System Requirements

Since Trebuchet is written in the TCL/Tk language, it has been tested
under, and will run on Unix with X11, Mac OS X and Windows.

Trebuchet Tk will probably run slow on a 486, or a 68k CPU, but I
haven't tried it myself  Give it a try.  Who knows, it may still run
reasonably.  You will probably need at least 32 megs of RAM, also.


# Features:

This client has the following features (and more) currently implemented:
- Color hilighting of lines and words based on patterns
- Triggering execution of scripts based on patterns
- Keeps track of your worlds, characters, and passwords, so you don't have to keep entering them manually.
- Command line macros to help you automate complex tasks.
- Keyboard bindings to perform commands with one or two keystrokes.
- QuickButtons to perform commands at the click of a mouse button.
- Can generate dynamic GUI dialogs upon server request.
- Supports SSL encrypted connections, with the tcltls package.
- Input command line history.
- Tab word completion, based on the last N lines of scrollback.
- Simultaneous multi-connection support.
- Quoting of text files to connections.
- Nearly all GUI features have command-line equivalents.


# UNIX/Linux Installation:

This assumes that you already have TCL/Tk (AKA 'wish') already installed
on your unix/linux system, and that the 'wish' program is in your $PATH.
If you don't have wish installed, you will want to either get the TCL/Tk
packages from your OS vendor (RedHat, Debian, etc.) or you may fetch the
sources from https://www.tcl.tk/.  You need TCL/Tk version 8.0.5 or later.

Un-gzip the tarfile:

    gunzip TrebTk10aXX.tar.gz

Untar the tarfile:

    tar xf TrebTk10aXX.tar

Move the directory structure that you unpacked to someplace convenient:

    mv TrebTk10aXX /usr/local/trebtk

Make a softlink from a convenient directory that is in your $PATH, linking
to the Trebuchet.tcl file:

    cd /usr/local/bin
    ln -s /usr/local/trebtk/Trebuchet.tcl treb

Then when you want to run Trebuchet, just invoke the 'treb' softlink.
NOTE:  The Trebuchet.tcl file MUST be located in the same directory as
the 'lib' and 'docs' directories.  Otherwise it won't be able to find
the libraries it needs to run.  This is why you make a softlink to the
Trebuchet.tcl file, instead of moving it.


