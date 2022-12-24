set lsp_config_contents {}
set lsp_config_root [pwd]

proc create_lsp_config {} {
    upvar lsp_config_contents mgc

    lappend mgc "#Define your project's libraries and source files here."
    lappend mgc "#This section is compulsory."
    lappend mgc "Libraries:"
    return
}

proc append_lib_lsp_config {k kinfo} {
    upvar lsp_config_contents mgc
    set bn [dict get $kinfo bn]
    lappend mgc "  - name: $bn"
    lappend mgc "    paths:"
    return
}

proc append_file_lsp_config {f finfo} {
    upvar lsp_config_contents mgc
    upvar lsp_config_root cwd

    set i [dict get $finfo i]
    set bn [dict get $finfo bn]
    switch $i {
        "vhdlp1735" {
            return
        }
        "vhdlmtie" {
            return
        }
        "vhdlsynpe" {
            return
        }
        "vhdldce" {
            return
        }
        "vhdlcdse" {
            return
        }
        "vhdlxile" {
            return
        }
        "vhdlfpro" {
            return
        }
        "vhdlprec" {
            return
        }
        "vhdlsyn" {
            lappend mgc "      - \"$cwd/$f\""
            return
        }
        "vlogsyn" {
            return
        }
        "svlogsyn" {
            return
        }
        "vhdlsim" {
            lappend mgc "      - \"$cwd/$f\""
            return
        }
        "vlogsim" {
            return
        }
        "svlogsim" {
            return
        }
    }
    return
}

proc eof_lsp_config {} {
    upvar lsp_config_contents mgc
    set configfile [open "vhdltool-config.yaml" w]
    puts $configfile [join $mgc "\n"]
    close $configfile
    return
}
