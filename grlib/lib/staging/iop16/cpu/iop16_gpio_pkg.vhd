-------------------------------------------------------------------------------
--! @file      iop16_gpio_pkg.vhd
--! @brief     IOP16 GPIO
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-26
--! @modified  2022-12-26
--! @version   0.1
--! @copyright Copyright (c) MIPT 2022
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.stdlib.all;
use grlib.amba.all;

library staging;
use staging.iop16_pkg.all;

package iop16_gpio_pkg is

  type gpio_registers_t is record
    din  : std_logic_vector (7 downto 0);
    dout : std_logic_vector (7 downto 0);
    dir  : std_logic_vector (7 downto 0);
  end record gpio_registers_t;

  constant RES_gpio_registers : gpio_registers_t := (
    din => x"00", dout => x"00", dir => x"00");

  procedure handle_cpu_gpio (
    signal r              : in    gpio_registers_t;
    variable v            : inout gpio_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0);
    signal gpio_din       : in    std_logic_vector (7 downto 0));

end package iop16_gpio_pkg;

package body iop16_gpio_pkg is

  procedure handle_cpu_gpio (
    signal r              : in    gpio_registers_t;
    variable v            : inout gpio_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0);
    signal gpio_din       : in    std_logic_vector (7 downto 0)) is
    variable xcpu_readdata : std_logic_vector (7 downto 0);
    variable xapb_readdata : std_logic_vector (31 downto 0);
  begin  -- procedure handle_cpu_gpio
    -- Function
    v.din := gpio_din;

    -- CPU bus
    xcpu_readdata := (others => '0');
    case cpuo.perip_address (1 downto 0) is
      when "00"   => xcpu_readdata := r.din;
      when "01"   => xcpu_readdata := r.dout;
      when "10"   => xcpu_readdata := r.dir;
      when others => null;
    end case;
    if (cpu_sel and cpuo.perip_wr) = '1' then
      case cpuo.perip_address (1 downto 0) is
        when "00"   => null;
        when "01"   => v.dout := cpuo.perip_data;
        when "10"   => v.dir  := cpuo.perip_data;
        when others => null;
      end case;
    end if;
    if cpu_sel = '1' then
      cpu_readdata := xcpu_readdata;
    end if;

    -- APB bus
    xapb_readdata := (others => '0');
    case apbi.paddr (3 downto 2) is
      when "00"   => xapb_readdata := x"000000" & r.din;
      when "01"   => xapb_readdata := x"000000" & r.dout;
      when "10"   => xapb_readdata := x"000000" & r.dir;
      when others => null;
    end case;
    if (apb_sel and apbi.pwrite) = '1' then
      case apbi.paddr (3 downto 2) is
        when "00"   => null;
        when "01"   => v.dout := apbi.pwdata (7 downto 0);
        when "10"   => v.dir  := apbi.pwdata (7 downto 0);
        when others => null;
      end case;
    end if;
    if apb_sel = '1' then
      apb_readdata := xapb_readdata;
    end if;
  end procedure handle_cpu_gpio;

end package body iop16_gpio_pkg;
