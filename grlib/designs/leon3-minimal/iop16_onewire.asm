#include "iop16_regs.h"
#define hi(x) (((x) >> 8) & 0xff)
#define lo(x) (((x) >> 0) & 0xff)

;; Reset low impulse [us]
#define T_RST_LOW (480)

;; Presense sample time, after reset [us]
#define T_ATR (150)

;;; Slot time [us]
#define T_SLOT (120)

;;; Write 0 low time
#define T_LOW0 (60)

;;; Write 1 low time
#define T_LOW1 (5)

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
        iow c00, CPU_GPIO_DOUT
        iow c01, CPU_GPIO_DIR

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

        jsr proc_write_one
        jsr proc_write_one
        jsr proc_write_zero
        jsr proc_write_zero
        jsr proc_write_one
        jsr proc_write_one
        jsr proc_write_zero
        jsr proc_write_zero

        iow c00, CPU_REG_1
        lri r3, 8
loop_read_bits:
        adi r3, 0xff
        jsr proc_read_bit
        cmp r3, 0x00
        bne loop_read_bits

        ;; write out reply
        iow r2, CPU_REG_0
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
        lri r0, hi(T_LOW0)
        lri r1, lo(T_LOW0)
        jsr proc_load_timer
        iow c01, CPU_GPIO_DOUT
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer
        iow c00, CPU_GPIO_DOUT
        lri r0, hi(T_SLOT-T_LOW0)
        lri r1, lo(T_SLOT-T_LOW0)
        jsr proc_load_timer
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer
        rts

;;; procedure WRITE_ONE()
;;; clobber: r0, r1
proc_write_one:
        lri r0, hi(T_LOW1)
        lri r1, lo(T_LOW1)
        jsr proc_load_timer
        iow c01, CPU_GPIO_DOUT
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer
        iow c00, CPU_GPIO_DOUT
        lri r0, hi(T_SLOT-T_LOW1)
        lri r1, lo(T_SLOT-T_LOW1)
        jsr proc_load_timer
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer
        rts

;;; procedure READ_BIT()
;;; clobber: r0, r1
proc_read_bit:
        lri r0, hi(T_READ_SLOT)
        lri r1, lo(T_READ_SLOT)
        jsr proc_load_timer
        iow c01, CPU_GPIO_DOUT
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer
        iow c00, CPU_GPIO_DOUT

        lri r0, hi(T_READ_SAMP-T_READ_SLOT)
        lri r1, lo(T_READ_SAMP-T_READ_SLOT)
        jsr proc_load_timer
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer

        ior r0, CPU_GPIO_DIN
        ari r0, (1 << 1)

        ior r1, CPU_REG_1
        sll r1

        cmp r0, 0x00
        beq proc_read_bit__0
        ori r1, 0x01
proc_read_bit__0:
        iow r1, CPU_REG_1

        iow cFF, CPU_REG_DBG

        lri r0, hi(T_SLOT-T_READ_SAMP)
        lri r1, lo(T_SLOT-T_READ_SAMP)
        jsr proc_load_timer
        iow cFF, CPU_TIMER_CTRL
        jsr proc_poll_timer

        rts
