#include "iop16_regs.h"
#define hi(x) (((x) >> 8) & 0xff)
#define lo(x) (((x) >> 0) & 0xff)

;; Reset low impulse [us]
#define T_RST_LOW (477)

;; Presense sample time, after reset [us]
#define T_ATR (150)

;;; Slot time [us]
#define T_SLOT (120)

;;; Write 0 low time
#define T_LOW0 (60)

;;; Write 1 low time
#define T_LOW1 (4)

;;; Read impulse time
#define T_READ_SLOT (1)

;;; Read sample time
#define T_READ_SAMP (10)

#define c00  r8
#define c01  r9
#define cFF  rF

start:
        ;; set BUSY flag
        lri r0, 0x80
        iow r0, CPU_REG_0

        ;; GPIO setup
        ;; GPIO[0] -- output
        ;; GPIO[1] -- input
        ;; GPIO[2] -- output (debug)
        iow c00, CPU_GPIO_DOUT
        lri r0, ((1 << 2) | (1 << 0))
        iow r0, CPU_GPIO_DIR

        ;; load reset timer
        lri r0, hi(T_RST_LOW)
        lri r1, lo(T_RST_LOW)
        jsr proc_load_timer

        ;; reset_impulse
        iow r9, CPU_GPIO_DOUT
        iow rF, CPU_TIMER_CTRL

        ;; wait for timer
        jsr proc_poll_timer

        ;; finish_reset_impulse
        iow r8, CPU_GPIO_DOUT

        ;; load_atr_timer
        lri r0, hi(T_ATR)
        lri r1, lo(T_ATR)
        jsr proc_load_timer
        iow rF, CPU_TIMER_CTRL
        jsr proc_poll_timer

        ;; sample_presense:
        ior r2, CPU_GPIO_DIN
        slr r2
        xri r2, 0xff
        ari r2, 0x01

        ;; wait for trailer:
        lri r0, hi(T_RST_LOW - T_ATR)
        lri r1, lo(T_RST_LOW - T_ATR)
        jsr proc_load_timer
        iow rF, CPU_TIMER_CTRL
        jsr proc_poll_timer

        jsr proc_write_zero
        jsr proc_write_zero
        jsr proc_write_zero
        jsr proc_write_zero
        jsr proc_write_one
        jsr proc_write_one
        jsr proc_write_one
        jsr proc_write_one

search_loop:
        lri r1, 0x00
        jsr proc_read_bit
        jsr proc_read_bit

        cmp r1, 0x00
        beq search_collision
        cmp r1, 0x01
        beq search_zero
        cmp r1, 0x02
        beq search_one
        cmp r1, 0x03
        beq search_none

search_collision:
        ior r0, CPU_REG_1
        ior r1, CPU_REG_1
        slr r1
        iow r1, CPU_REG_1
        ari r0, 0x01
        bnz search_collision__one
        ior r0, CPU_REG_0
        ori r0, 0x01
        iow r0, CPU_REG_0
        jmp search_zero
search_collision__one:
        jmp search_one

search_zero:
        lri r0, 0x00
        iow r0, CPU_SHREG_MSB
        jsr proc_write_zero
        jmp search_loop
search_one:
        lri r0, 0x01
        iow r0, CPU_SHREG_MSB
        jsr proc_write_one
        jmp search_loop
search_none:
        ;; write out reply
        ior r0, CPU_REG_0
        ari r0, 0x7F
        iow r0, CPU_REG_0
exit:
        jmp exit

;;; PROCEDURES ;;;

;;; procedure LOAD_TIMER(r0, r1)
;;; clobber: none
proc_load_timer:
        iow r0, CPU_TIMER_TIMER_VALUE_H
        iow r1, CPU_TIMER_TIMER_VALUE_L
        rts

;;; procedure POLL_TIMER()
;;; clobber: r0
proc_poll_timer:
        ior r0, CPU_TIMER_CTRL
        cmp r0, 0x01
        bez proc_poll_timer
        rts

;;; procedure WRITE_ZERO()
;;; clobber: r0, r1
proc_write_zero:
        iow c01, CPU_GPIO_DOUT
        lri r0, 0x55
proc_write_zero__loop_0:
        adi r0, 0xff
        bnz proc_write_zero__loop_0
        iow c00, CPU_GPIO_DOUT
        lri r0, 0x01
proc_write_zero__loop_1:
        adi r0, 0xff
        bnz proc_write_zero__loop_1
        rts

;;; procedure WRITE_ONE()
;;; clobber: r0, r1
proc_write_one:
        iow c01, CPU_GPIO_DOUT
        lri r0, 0x6
proc_write_one__loop_0:
        adi r0, 0xff
        bnz proc_write_one__loop_0
        iow c00, CPU_GPIO_DOUT
        lri r0, 0x50
proc_write_one__loop_1:
        adi r0, 0xff
        bnz proc_write_one__loop_1
        rts

;;; procedure READ_BIT()
;;; clobber: r0, r1
proc_read_bit:
        iow c01, CPU_GPIO_DOUT
        xri c00, 0x00
        xri c00, 0x00
        iow c00, CPU_GPIO_DOUT

        lri r0, 0xa
proc_read_bit__loop_0:
        adi r0, 0xff
        bnz proc_read_bit__loop_0

        sll r1
        ior r0, CPU_GPIO_DIN
        ari r0, (1<<1)
        beq proc_read_bit__zero
        ori r1, 0x01
proc_read_bit__zero:

        lri r0, 0x46
proc_read_bit__loop_1:
        adi r0, 0xff
        bnz proc_read_bit__loop_1

        rts
