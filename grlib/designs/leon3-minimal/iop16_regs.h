#ifndef __IOP16_REGS__
#define __IOP16_REGS__

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
#define CPU_REG_DBG               (CPU_REG_START   | 0x04)

#define CPU_SHREG_START           (0x30)
#define CPU_SHREG_0               (CPU_SHREG_START   | 0x00)
#define CPU_SHREG_1               (CPU_SHREG_START   | 0x01)
#define CPU_SHREG_2               (CPU_SHREG_START   | 0x02)
#define CPU_SHREG_3               (CPU_SHREG_START   | 0x03)
#define CPU_SHREG_4               (CPU_SHREG_START   | 0x04)
#define CPU_SHREG_5               (CPU_SHREG_START   | 0x05)
#define CPU_SHREG_6               (CPU_SHREG_START   | 0x06)
#define CPU_SHREG_7               (CPU_SHREG_START   | 0x07)
#define CPU_SHREG_LSB             (CPU_SHREG_START   | 0x08)
#define CPU_SHREG_MSB             (CPU_SHREG_START   | 0x09)

#endif /* __IOP16_REGS__ */
