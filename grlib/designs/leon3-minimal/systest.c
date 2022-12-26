#include <stdint.h>
#include <stdlib.h>

#define IOP16_ADDR 0x80080000

#define ROM_SIZE 4096

struct iop16_ctrl_t {
  uint32_t ctrl;
  uint32_t sim;
  uint32_t __padding[8-2];
};

struct iop16_timer_t {
  uint32_t scaler_reload;
  uint32_t scaler_value;
  uint32_t timer_reload;
  uint32_t timer_value;
  uint32_t ctrl;
  uint32_t __padding[8-5];
};

struct iop16_gpio_t {
  uint32_t din;
  uint32_t dout;
  uint32_t dir;
  uint32_t __padding[8-3];
};

struct iop16_reg_t {
  uint32_t reg;
  uint32_t __padding[8-1];
};

struct iop16_t {
  union {
    struct {
      struct iop16_ctrl_t ctrl;
      struct iop16_timer_t timer;
      struct iop16_gpio_t gpio;
      struct iop16_reg_t reg;
    };
    uint32_t __padding[ROM_SIZE];
  };
  uint32_t rom[ROM_SIZE];
};


const uint16_t rom[] = {0x4107, 0xb1ff, 0xf001, 0x41ab, 0x7120, 0xd005};
const size_t rom_len = sizeof(rom)/sizeof(rom[0]);

int main() {
  volatile struct iop16_t *r = (volatile struct iop16_t *) IOP16_ADDR;

  r->ctrl.ctrl = 0x00;
  do {
    size_t i;
    for (i = 0; i < rom_len; i++) {
      r->rom[i] = (uint32_t) (rom[i]);
    }
    for (i = 0; i < rom_len; i++) {
      uint16_t t = (uint16_t) r->rom[i];
      if (t != rom[i]) {
        r->ctrl.sim =
          ((i & 0xffff) << 16) |
          (t & 0xffff);
      }
    }
  } while (0);
  r->ctrl.ctrl = 0x01;
  while (((r->reg.reg) & 0xff) != 0xab);
  r->ctrl.ctrl = 0x00;
  while(1);
  r->ctrl.sim = 0x00;
  return 0;
}
