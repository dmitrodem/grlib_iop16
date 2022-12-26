#define CPU_TIMER_START           (0x00)
#define CPU_TIMER_SCALER_RELOAD_H (CPU_TIMER_START | 0x00)
#define CPU_TIMER_SCALER_RELOAD_L (CPU_TIMER_START | 0x01)
#define CPU_TIMER_SCALER_VALUE_H  (CPU_TIMER_START | 0x02)
#define CPU_TIMER_SCALER_VALUE_L  (CPU_TIMER_START | 0x03)
#define CPU_TIMER_TIMER_RELOAD_H  (CPU_TIMER_START | 0x04)
#define CPU_TIMER_TIMER_RELOAD_L  (CPU_TIMER_START | 0x05)
#define CPU_TIMER_TIMER_VALUE_H   (CPU_TIMER_START | 0x06)
#define CPU_TIMER_TIMER_VALUE_L   (CPU_TIMER_START | 0x07)
#define CPU_TIMER_CTRL            (CPU_TIMER_START | 0x08)

#define CPU_GPIO_START            (0x10)
#define CPU_GPIO_DIN              (CPU_GPIO_START  | 0x00)
#define CPU_GPIO_DOUT             (CPU_GPIO_START  | 0x01)
#define CPU_GPIO_DIR              (CPU_GPIO_START  | 0x02)

#define CPU_REG_START             (0x20)
#define CPU_REG_0                 (CPU_REG_START   | 0x00)
#define CPU_REG_1                 (CPU_REG_START   | 0x01)
#define CPU_REG_2                 (CPU_REG_START   | 0x02)
#define CPU_REG_3                 (CPU_REG_START   | 0x03)

start:
        lri r1, 0x7
loop:
        adi r1, 0xff
        bnz loop
finish:
        lri r1, 0xab
        iow r1, CPU_REG_0
halt:
        jmp halt
