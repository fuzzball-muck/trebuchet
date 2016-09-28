#############################################################################
# Bitmap, by Garth Minette.  Released into the public domain 11/19/97.
# This module handles some standard bitmaps for TCL/Tk 8.0 or better.
# Includes: incr, decr
#############################################################################

global gdmBitmapModuleLoaded
if {![info exists gdmBitmapModuleLoaded]} {
set gdmBitmapModuleLoaded true

set gdmBitmaps(foo) {}

proc gdm:Bitmap:mkoldstatbarimg {} {
    image create bitmap -foreground grey25 -data \
{#define foo_width 16
#define foo_height 16
static char foo_bits[] = {
 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x00,0x40,0x00,
 0x20,0x00,0x10,0x00,0x88,0x00,0x44,0x00,0x22,0x00,0x11,0x80,0x88,0x40,0x44,
 0x20,0x22};}
}

proc gdm:Bitmap:mkdecrimg {} {
    image create bitmap -data \
{#define decr_width 7
#define decr_height 4
static unsigned char decr_bits[] = {
   0x7f, 0x3e, 0x1c, 0x08};}
}

proc gdm:Bitmap:mkincrimg {} {
    image create bitmap -data \
{#define incr_width 7
#define incr_height 4
static unsigned char incr_bits[] = {
   0x08, 0x1c, 0x3e, 0x7f};}
}

proc gdm:Bitmap:mkbulletimg {} {
    image create bitmap -data \
{#define foo_width 13
#define foo_height 13
static char foo_bits[] = {
 0x00,0x00,0x00,0x00,0x00,0x00,0xe0,0x00,0xf0,0x01,0xf8,0x03,0xf8,0x03,0xf8,
 0x03,0xf0,0x01,0xe0,0x00,0x00,0x00,0x00,0x00,0x00,0x00};}
}

proc gdm:Bitmap:mkstatbarimg {} {
    global treb_lib_dir
    image create photo -file [file join $treb_lib_dir images corner.gif]
}


##################################################

proc gdm:Bitmap:get {name} {
    global gdmBitmaps
    if {![info exists gdmBitmaps($name)]} {
        if {[info commands "gdm:Bitmap:mk${name}img"] != {}} {
	    set gdmBitmaps($name) [eval "gdm:Bitmap:mk${name}img"]
	} else {
	    global treb_lib_dir
	    set filename [file join $treb_lib_dir images $name.gif]
	    set gdmBitmaps($name) [image create photo -file $filename]
	}
    }
    return $gdmBitmaps($name)
}

proc gdm:Bitmap:set {name image} {
    global gdmBitmaps
    set gdmBitmaps($name) $image
}

proc gdm:Bitmap {opt args} {
    if {[info procs gdm:Bitmap:$opt] != {}} {
        return [eval "gdm:Bitmap:$opt $args"]
    } else {
        error "gdm:Bitmap: Invalid option \"$opt\" should be one of get or set."
    }
}

}

