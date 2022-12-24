proc lsp_create_tool {filetree fileinfo} {
    global GRLIB
    source "$GRLIB/bin/scriptgen/filebuild/lsp_config.tcl"
    create_lsp_config
    foreach k [dict keys $filetree] {
        set ktree [dict get $filetree $k]
        set kinfo [dict get $fileinfo $k]
        set bn [dict get $kinfo bn]

        set n 0
        foreach l [dict keys $ktree] {
            set filelist [dict get $ktree $l]
            foreach f $filelist {
                set finfo [dict get $fileinfo $f]
                set i [dict get $finfo i]
                switch $i {
                    "vhdlsyn" {
                        incr n
                    }
                    "vhdlsym" {
                        incr n
                    }
                }
            }
        }

        if { $n == 0 } {
            continue
        }
        
        append_lib_lsp_config $k $kinfo
        foreach l [dict keys $ktree] {
            set filelist [dict get $ktree $l]
            foreach f $filelist {
                set finfo [dict get $fileinfo $f]
                append_file_lsp_config $f $finfo
            }
        }
    }
    eof_lsp_config
}

lsp_create_tool $filetree $fileinfo
return
