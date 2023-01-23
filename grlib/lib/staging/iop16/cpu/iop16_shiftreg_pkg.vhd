-------------------------------------------------------------------------------
--! @file      iop16_shiftreg_pkg.vhd
--! @brief     IOP16 Shift Register
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-26
--! @modified  2023-01-17
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

package iop16_shiftreg_pkg is

  type shiftreg_registers_t is record
    reg  : std_logic_vector (63 downto 0);
  end record shiftreg_registers_t;

  constant RES_shiftreg_registers : shiftreg_registers_t := (
    reg => (others => '0'));

  procedure handle_cpu_shiftreg (
    signal r              : in    shiftreg_registers_t;
    variable v            : inout shiftreg_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0));

end package iop16_shiftreg_pkg;

package body iop16_shiftreg_pkg is

  procedure handle_cpu_shiftreg (
    signal r              : in    shiftreg_registers_t;
    variable v            : inout shiftreg_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0)) is
    variable xcpu_readdata : std_logic_vector (7 downto 0);
    variable xapb_readdata : std_logic_vector (31 downto 0);
  begin  -- procedure handle_cpu_gpio
    -- Function

    -- CPU bus
    xcpu_readdata := (others => '0');
    if (cpu_sel and cpuo.perip_rd) = '1' then
      case cpuo.perip_address (3 downto 0) is
        when "0000"   => xcpu_readdata := r.reg(7 downto 0);
        when "0001"   => xcpu_readdata := r.reg(15 downto 8);
        when "0010"   => xcpu_readdata := r.reg(23 downto 16);
        when "0011"   => xcpu_readdata := r.reg(31 downto 24);
        when "0100"   => xcpu_readdata := r.reg(39 downto 32);
        when "0101"   => xcpu_readdata := r.reg(47 downto 40);
        when "0110"   => xcpu_readdata := r.reg(55 downto 48);
        when "0111"   => xcpu_readdata := r.reg(63 downto 56);
        when "1000"   => xcpu_readdata(0) := r.reg(0);
                         v.reg := "0" & r.reg(63 downto 1);
        when "1001"   => xcpu_readdata(0) := r.reg(63);
                         v.reg := r.reg(62 downto 0) & "0";
        when others => null;
      end case;
    end if;

    if (cpu_sel and cpuo.perip_wr) = '1' then
      case cpuo.perip_address (3 downto 0) is
      when "0000"   => v.reg(7 downto 0)   := cpuo.perip_data;
      when "0001"   => v.reg(15 downto 8)  := cpuo.perip_data;
      when "0010"   => v.reg(23 downto 16) := cpuo.perip_data;
      when "0011"   => v.reg(31 downto 24) := cpuo.perip_data;
      when "0100"   => v.reg(39 downto 32) := cpuo.perip_data;
      when "0101"   => v.reg(47 downto 40) := cpuo.perip_data;
      when "0110"   => v.reg(55 downto 48) := cpuo.perip_data;
      when "0111"   => v.reg(63 downto 56) := cpuo.perip_data;
      when "1000"   => if cpuo.perip_data = x"00" then
                         v.reg := r.reg(62 downto 0) & "0";
                       else
                         v.reg := r.reg(62 downto 0) & "1";
                       end if;
      when "1001"   => if cpuo.perip_data = x"00" then
                         v.reg := "0" & r.reg(63 downto 1);
                       else
                         v.reg := "1" & r.reg(63 downto 1);
                       end if;
      when others => null;
      end case;
    end if;
    if cpu_sel = '1' then
      cpu_readdata := xcpu_readdata;
    end if;

    -- APB bus
    xapb_readdata := (others => '0');
    case apbi.paddr (2 downto 2) is
      when "0"   => xapb_readdata := r.reg(31 downto 0);
      when "1"   => xapb_readdata := r.reg(63 downto 32);
      when others => null;
    end case;
    if (apb_sel and apbi.pwrite) = '1' then
      case apbi.paddr (2 downto 2) is
        when "0"    => v.reg(31 downto 0)  := apbi.pwdata;
        when "1"    => v.reg(63 downto 32) := apbi.pwdata;
        when others => null;
      end case;
    end if;
    if apb_sel = '1' then
      apb_readdata := xapb_readdata;
    end if;
  end procedure handle_cpu_shiftreg;

end package body iop16_shiftreg_pkg;
