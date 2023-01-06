GRLIB = ../..
TOP = leon3mp

VHDLSYNFILES = config.vhd ahbrom.vhd leon3mp.vhd
VHDLSIMFILES = testbench.vhd
SIMTOP = testbench
CLEAN = soft-clean
TECHLIBS = inferred

# Libraries, directories and files in GRLIB that should not be compiled for this design
LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip ihp usbhc spw
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
	usb grusbhc spacewire ascs slink hcan \
	leon4v0 l2cache pwm gr1553b iommu
FILESKIP = grcan.vhd

EXTRA_PROGS = iop16_rom

include $(GRLIB)/bin/Makefile 
include $(GRLIB)/software/leon3/Makefile

##################  project specific targets ##########################
prom.exe: prom.h prom.S
ahbrom.vhd: prom.exe
vsim: ahbrom.vhd

iop16_rom.c: iop16_onewire.asm
	./iop16_asm -f c -w 8 -b iop16 -o iop16_rom.c iop16_onewire.asm

clean_iop16_soft:
	-rm -rf iop16_rom.c

.PHONY: clean_iop16_soft

soft-clean: clean_iop16_soft
