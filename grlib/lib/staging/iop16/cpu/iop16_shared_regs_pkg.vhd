-------------------------------------------------------------------------------
--! @file      iop16_shared_regs_pkg.vhd
--! @brief     IOP16 shared registers
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-26
--! @modified  2022-12-31
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

package iop16_shared_regs_pkg is

  type shared_registers_t is record
    reg0 : std_logic_vector (7 downto 0);
    reg1 : std_logic_vector (7 downto 0);
    reg2 : std_logic_vector (7 downto 0);
    reg3 : std_logic_vector (7 downto 0);
  end record shared_registers_t;

  constant RES_shared_registers : shared_registers_t := (
    reg0 => x"00", reg1 => x"00", reg2 => x"00", reg3 => x"00");

  procedure handle_cpu_shared_regs (
    signal r              : in    shared_registers_t;
    variable v            : inout shared_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0));

end package iop16_shared_regs_pkg;

package body iop16_shared_regs_pkg is

  procedure handle_cpu_shared_regs (
    signal r              : in    shared_registers_t;
    variable v            : inout shared_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0)) is
    variable xcpu_readdata : std_logic_vector (7 downto 0);
    variable xapb_readdata : std_logic_vector (31 downto 0);
  begin  -- procedure handle_cpu_shared_regs
    -- Function
    -- CPU bus
    xcpu_readdata := (others => '0');
    case cpuo.perip_address (1 downto 0) is
      when "00"   => xcpu_readdata := r.reg0;
      when "01"   => xcpu_readdata := r.reg1;
      when "10"   => xcpu_readdata := r.reg2;
      when "11"   => xcpu_readdata := r.reg3;
      when others => null;
    end case;
    if (cpu_sel and cpuo.perip_wr) = '1' then
      case cpuo.perip_address (2 downto 0) is
        when "000"   => v.reg0 := cpuo.perip_data;
        when "001"   => v.reg1 := cpuo.perip_data;
        when "010"   => v.reg2 := cpuo.perip_data;
        when "011"   => v.reg3 := cpuo.perip_data;
        when others  => assert false report "CPU halt, code = " & tost(cpuo.perip_data) severity failure;
      end case;
    end if;
    if cpu_sel = '1' then
      cpu_readdata := xcpu_readdata;
    end if;

    -- APB bus
    xapb_readdata := (others => '0');
    xapb_readdata := r.reg3 &
                     r.reg2 &
                     r.reg1 &
                     r.reg0;
    if (apb_sel and apbi.pwrite) = '1' then
      v.reg3 := apbi.pwdata(31 downto 24);
      v.reg2 := apbi.pwdata(23 downto 16);
      v.reg1 := apbi.pwdata(15 downto  8);
      v.reg0 := apbi.pwdata(7  downto  0);
    end if;
    if apb_sel = '1' then
      apb_readdata := xapb_readdata;
    end if;
  end procedure handle_cpu_shared_regs;

end package body iop16_shared_regs_pkg;
