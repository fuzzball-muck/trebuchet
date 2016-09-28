# compat.tcl
# TCL routines that may get replaced by C extensions later.
# Or that are needed for supporting multiple versions of TCL.
#

proc stringnext {substr string index} {
    set result [string first $substr [string range $string $index end]]
    if {$result > -1} {
        incr result $index
    }
    return $result
}

# NOTE: This is not fully compatible with [string is], especially
# with regards to unicode on TCL interps before 8.3
proc stringis {type val} {
    set pattern {}
    set nocase 1
    if {![catch {[string is $type $val]} result]} {
        return $result
    }
    switch -exact $type {
        alnum {
            set pattern {[A-Z0-9]*}
        }

        alpha {
            set pattern {[A-Z]*}
        }

        ascii {
            set nocase 0
            set pattern {[\x00-\x7f]*}
        }

        boolean {
            set pattern {0|1|true|tru|tr|t|false|fals|fal|fa|f|yes|ye|y|no|n|on|off|of}
        }

        control {
            set nocase 0
            set pattern {[\x00-\x1f]*}
        }

        digit {
            set nocase 0
            set pattern {[0-9]*}
        }

        double {
            set nocase 0
            set pattern {[ 	]*[-+]?([0-9]+\.?[0-9]*|[0-9]*\.?[0-9]+)([Ee][-+]?[0-9]+)?[ 	]*}
        }

        false {
            set pattern {0|false|fals|fal|fa|f|no|n|off|of}
        }

        graph {
            set pattern {[\x21-\x7e]*}
        }

        integer {
            set pattern {[ 	]*[-+]?(0x[0-9a-f]+|[1-9][0-9]*|0[0-7]*)[ 	]*}
        }

        lower {
            set nocase 0
            set pattern {[a-z]*}
        }

        print {
            set nocase 0
            set pattern {[\x20-\x7e]*}
        }

        punct {
            set nocase 0
            set pattern {[^A-Za-z0-9]*}
        }

        space {
            set nocase 0
            set pattern {[	 ]*}
        }

        true {
            set pattern {1|true|tru|tr|t|yes|ye|y|on}
        }

        upper {
            set nocase 0
            set pattern {[A-Z]*}
        }

        wordchar {
            set pattern {[A-Z0-9_]*}
        }

        xdigit {
            set pattern {[0-9A-F]*}
        }
    }

    if {$nocase} {
        set val [string tolower $val]
    }
    return [regexp -- "^$pattern\$" $val]
}

