#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
from vunit.vhdl_standard import VHDL
import os


PROJECT_ROOT = Path(__file__).parent
GRLIB_ROOT   = PROJECT_ROOT.parent.parent

os.environ["VUNIT_MODELSIM_INI"] = (GRLIB_ROOT / "bin" / "vunit_modelsim.ini").as_posix()

VU = VUnit.from_argv(compile_builtins=False)
VU.add_vhdl_builtins()

def add_grlib_lib(libname, libpath):
    lib = VU.add_library(libname)
    with open(libpath / "dirs.txt") as fd:
        dirs = [x.strip() for x in fd.readlines()]
        if libname == "techmap":
            dirs.append("maps")
        for d in dirs:
            for kind in ["vhdlsyn.txt", "vhdlsim.txt"]:
                filename = libpath / d / kind
                try:
                    with open(filename) as fd:
                        entries = [e.strip() for e in fd.readlines()]
                        entries = filter(lambda s: s and (not s.startswith("#")), entries)
                        for ekv in entries:
                            components = ekv.strip().split()
                            e = components[0]
                            attributes = {}
                            for a in components[1:]:
                                kv = a.split("=")
                                k = kv[0]
                                v = "=".join(kv[1:])
                                attributes[k] = v

                            vhdl_standard = "1993"
                            if "vhdlstd" in attributes:
                                if attributes["vhdlstd"] == "93":
                                    vhdl_standard = "1993"
                                elif attributes["vhdlstd"] == "2008":
                                    vhdl_standard = "2008"
                            source_path = libpath / d / e
                            if os.path.exists(source_path):
                                lib.add_source_file(source_path, vhdl_standard = vhdl_standard)
                except FileNotFoundError:
                    pass
    return lib

GRLIB_LIB   = add_grlib_lib("grlib",   GRLIB_ROOT / "lib" / "grlib")
TECHMAP_LIB = add_grlib_lib("techmap", GRLIB_ROOT / "lib" / "techmap")
STAGING_LIB = add_grlib_lib("staging", GRLIB_ROOT / "lib" / "staging")

VU.main()
