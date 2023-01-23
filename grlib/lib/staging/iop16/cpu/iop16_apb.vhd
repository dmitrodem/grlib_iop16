-------------------------------------------------------------------------------
--! @file      iop16_apb.vhd
--! @brief     IOP16 APB interface
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-13
--! @modified  2023-01-17
--! @version   0.1
--! @copyright Copyright (c) MIPT 2022
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.amba.all;
use grlib.devices.all;

library techmap;
use techmap.gencomp.all;

library staging;
use staging.iop16_pkg.all;
use staging.iop16_ctrl_pkg.all;
use staging.iop16_timer_pkg.all;
use staging.iop16_gpio_pkg.all;
use staging.iop16_shared_regs_pkg.all;
use staging.iop16_shiftreg_pkg.all;

entity iop16_apb is

  generic (
    oepol     : integer := 0;
    memtech   : integer := 0;
    vendor_id : integer := VENDOR_CONTRIB;
    device_id : integer := CONTRIB_CORE1;
    pindex    : integer := 0;
    paddr     : integer := 0;
    pmask     : integer := 16#f80#);

  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    apbi  : in  apb_slv_in_type;
    apbo  : out apb_slv_out_type;
    gpioi : in  iop16_gpio_in;
    gpioo : out iop16_gpio_out);

end entity iop16_apb;

architecture behav of iop16_apb is
  constant REVISION : integer := 0;
  constant PCONFIG : apb_config_type := (
    0 => ahb_device_reg(vendor_id, device_id, 0, REVISION, 0),
    1 => apb_iobar(paddr, pmask));

  type registers is record
    cpu_ctrl  : ctrl_registers_t;
    cpu_gpio  : gpio_registers_t;
    cpu_timer : timer_registers_t;
    cpu_reg   : shared_registers_t;
    cpu_shreg : shiftreg_registers_t;
    rom_data  : std_logic_vector (7 downto 0);
  end record registers;

  constant RES_registers : registers := (
    cpu_ctrl  => RES_ctrl_registers,
    cpu_gpio  => RES_gpio_registers,
    cpu_timer => RES_timer_registers,
    cpu_reg   => RES_shared_registers,
    cpu_shreg => RES_shiftreg_registers,
    rom_data  => x"00");
  signal r, rin : registers;

  type mux_t is record
    ctrl  : std_logic;
    timer : std_logic;
    gpio  : std_logic;
    reg   : std_logic;
    shreg : std_logic;
  end record mux_t;

  constant RES_mux : mux_t := (
    ctrl => '0', timer => '0', gpio => '0', reg => '0', shreg => '0');

  signal cpui : iop16_cpu_in;
  signal cpuo : iop16_cpu_out;

  signal rom_read    : std_logic;
  signal rom_write   : std_logic;
  signal rom_address : std_logic_vector (12 downto 0);
  signal rom_dataout : std_logic_vector (7 downto 0);

begin  -- architecture behav


  comb : process (apbi, cpuo, gpioi.data, r, rom_dataout, rst) is
    variable apb_read     : std_logic;
    variable apb_write    : std_logic;
    variable rom_area     : std_logic;
    variable apb_readdata : std_logic_vector (31 downto 0);
    variable cpu_readdata : std_logic_vector (7 downto 0);
    variable v            : registers;

    variable amux, cmux : mux_t;

  begin  -- process comb
    v := r;

    apb_write    := apbi.psel(pindex) and apbi.penable and apbi.pwrite;
    apb_read     := apbi.psel(pindex) and apbi.penable and (not apbi.pwrite);
    rom_area     := apbi.paddr(14);     -- 4*4096 = 2**14
    apb_readdata := (others => '0');
    cpu_readdata := (others => '0');

    cmux := RES_mux;
    case cpuo.perip_address (5 downto 4) is
      when "00"   => cmux.timer := '1';
      when "01"   => cmux.gpio  := '1';
      when "10"   => cmux.reg   := '1';
      when "11"   => cmux.shreg := '1';
      when others => null;
    end case;
    if cpuo.grey_code /= "10" then
      cmux := RES_mux;
    end if;

    amux := RES_mux;
    if (apbi.psel(pindex) and apbi.penable and (not rom_area)) = '1' then
      case apbi.paddr (7 downto 5) is
        when "000"   => amux.ctrl  := '1';
        when "001"   => amux.timer := '1';
        when "010"   => amux.gpio  := '1';
        when "011"   => amux.reg   := '1';
        when "100"   => amux.shreg := '1';
        when others => null;
      end case;
    end if;

    handle_cpu_ctrl
      (r.cpu_ctrl, v.cpu_ctrl,
       cmux.ctrl, amux.ctrl,
       cpuo, apbi,
       cpu_readdata, apb_readdata);
    handle_cpu_timer
      (r.cpu_timer, v.cpu_timer,
       cmux.timer, amux.timer,
       cpuo, apbi,
       cpu_readdata, apb_readdata);
    handle_cpu_gpio
      (r.cpu_gpio, v.cpu_gpio,
       cmux.gpio, amux.gpio,
       cpuo, apbi,
       cpu_readdata, apb_readdata,
       gpioi.data);
    handle_cpu_shared_regs
      (r.cpu_reg, v.cpu_reg,
       cmux.reg, amux.reg,
       cpuo, apbi,
       cpu_readdata, apb_readdata);
    handle_cpu_shiftreg
      (r.cpu_shreg, v.cpu_shreg,
       cmux.shreg, amux.shreg,
       cpuo, apbi,
       cpu_readdata, apb_readdata);

    if rom_area = '1' then
      apb_readdata := x"000000" & rom_dataout;
    end if;

    case cpuo.grey_code is
      when "00"   => null;
      when "01"   => v.rom_data := rom_dataout;
      when "11"   => null;
      when "10"   => null;
      when others => null;
    end case;

    if rst = '0' then
      v := RES_registers;
    end if;

    ---------------------------------------------------------------------------
    -- syncram_2p signals
    ---------------------------------------------------------------------------
    if r.cpu_ctrl.run = '1' then
      rom_read <= '1';
    else
      rom_read <= apbi.psel(pindex) and (not apbi.pwrite) and rom_area;
    end if;

    rom_write <= apb_write and rom_area and (not r.cpu_ctrl.run);

    if cpuo.grey_code = "00" then
      rom_address <= cpuo.rom_address & "0";
    else
      rom_address <= cpuo.rom_address & "1";
    end if;

    apbo <= (
      prdata  => apb_readdata,
      pirq    => (others => '0'),
      pconfig => PCONFIG,
      pindex  => pindex);

    cpui.perip_data <= cpu_readdata;
    rin             <= v;
  end process comb;

  seq : process (clk) is
  begin  -- process seq
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process seq;

  -- Drive gpio
  gpioo.data <= r.cpu_gpio.dout;
  gpioo.oen  <= r.cpu_gpio.dir when oepol = 1 else
               not r.cpu_gpio.dir;

  gen_cpu : block is
    signal rom_rdaddr : std_logic_vector (10 downto 0);
    signal cpu_reset  : std_logic;
  begin  -- block gen_rom

    cpu0 : entity staging.iop16_cpu1
      generic map (
        INST_ROM_SIZE_PASS => 4096,
        STACK_DEPTH_PASS   => 4)
      port map (
        i_clock            => clk,
        i_resetN           => cpu_reset,
        i_peripDataToCPU   => cpui.perip_data,
        o_peripAddr        => cpuo.perip_address,
        o_peripDataFromCPU => cpuo.perip_data,
        o_peripWr          => cpuo.perip_wr,
        o_peripRd          => cpuo.perip_rd,
        o_romAddr          => cpuo.rom_address,
        i_romData          => cpui.rom_data,
        o_GreyCode         => cpuo.grey_code,
        i_Disas            => cpui.disas);

    rom0 : entity techmap.syncram_2p
      generic map (
        tech  => memtech,
        abits => 11,
        dbits => 8)
      port map (
        rclk     => clk,
        renable  => rom_read,
        raddress => rom_rdaddr,
        dataout  => rom_dataout,
        wclk     => clk,
        write    => rom_write,
        waddress => apbi.paddr(12 downto 2),
        datain   => apbi.pwdata(7 downto 0),
        testin   => apbi.testin);

    cpu_reset  <= rst and r.cpu_ctrl.run;
    rom_rdaddr <= rom_address(10 downto 0) when r.cpu_ctrl.run = '1' else
                  apbi.paddr(12 downto 2);
    cpui.rom_data <= r.rom_data & rom_dataout;
    cpui.disas <= r.cpu_ctrl.disas;

  end block gen_cpu;

  -- pragma translate_off
  bootmsg : report_version
    generic map (msg1 => "iop16_" & tost(pindex) & ": " & "IOP16 Peripherial CPU");
  -- pragma translate_on

end architecture behav;
