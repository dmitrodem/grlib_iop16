-------------------------------------------------------------------------------
--! @file      iop16_ctrl_pkg.vhd
--! @brief     IOP16 control reg
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

package iop16_ctrl_pkg is

  type ctrl_registers_t is record
    run : std_logic;
    disas : std_logic;
  end record ctrl_registers_t;

  constant RES_ctrl_registers : ctrl_registers_t := (
    run => '0', disas => '0');

  procedure handle_cpu_ctrl (
    signal r              : in    ctrl_registers_t;
    variable v            : inout ctrl_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0));

end package iop16_ctrl_pkg;

package body iop16_ctrl_pkg is

  procedure handle_cpu_ctrl (
    signal r              : in    ctrl_registers_t;
    variable v            : inout ctrl_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0)) is
    variable xcpu_readdata : std_logic_vector (7 downto 0);
    variable xapb_readdata : std_logic_vector (31 downto 0);
  begin  -- procedure handle_cpu_ctrl
    -- Function
    -- CPU bus
    xcpu_readdata := (others => '0');
    if cpu_sel = '1' then
      cpu_readdata := xcpu_readdata;
    end if;

    -- APB bus
    xapb_readdata := (others => '0');
    case apbi.paddr (2 downto 2) is
      when "0"    => xapb_readdata := x"000000" & "000000" & r.disas & r.run;
      when "1"    => null;
      when others => null;
    end case;

    if (apb_sel and apbi.pwrite) = '1' then
      case apbi.paddr (3 downto 2) is
        when "00"   => v.run := apbi.pwdata(0);
        when "01"   => grlib.testlib.print("MSG = " & tost (apbi.pwdata));
        when "10"   => assert false report "End of simulation, code = " & tost (apbi.pwdata) severity failure;
        when others => null;
      end case;
    end if;

    if apb_sel = '1' then
      apb_readdata := xapb_readdata;
    end if;
  end procedure handle_cpu_ctrl;

end package body iop16_ctrl_pkg;
