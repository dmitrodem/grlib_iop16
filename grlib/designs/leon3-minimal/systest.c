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


extern const uint16_t iop16_rom[];
extern const size_t iop16_rom_len;

int main() {
  volatile struct iop16_t *r = (volatile struct iop16_t *) IOP16_ADDR;

  r->ctrl.ctrl = 0x00;
  r->timer.scaler_reload = 10-1;
  r->timer.scaler_value = 10-1;
  do {
    size_t i;
    for (i = 0; i < iop16_rom_len; i++) {
      r->rom[i] = (uint32_t) (iop16_rom[i]);
    }
  } while (0);
  r->reg.reg = 0x80;
  r->ctrl.ctrl = 0x01;
  while (((r->reg.reg) & 0x80));
  r->ctrl.ctrl = 0x00;
  r->ctrl.sim = (r->reg.reg) & 0x01;
  return 0;
}
