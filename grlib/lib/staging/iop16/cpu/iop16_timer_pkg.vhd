-------------------------------------------------------------------------------
--! @file      iop16_timer_pkg.vhd
--! @brief     IOP16 timer unit
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

package iop16_timer_pkg is

  constant SCALER_BITS : integer := 16;
  constant TIMER_BITS  : integer := 16;

  type timer_registers_t is record
    scaler_reload : std_logic_vector (SCALER_BITS-1 downto 0);
    scaler_value  : std_logic_vector (SCALER_BITS-1 downto 0);
    timer_reload  : std_logic_vector (TIMER_BITS-1 downto 0);
    timer_value   : std_logic_vector (TIMER_BITS-1 downto 0);
    running       : std_logic;
  end record timer_registers_t;

  constant RES_timer_registers : timer_registers_t := (
    scaler_reload => (others => '0'),
    scaler_value  => (others => '0'),
    timer_reload  => (others => '0'),
    timer_value   => (others => '0'),
    running       => '0');

  procedure handle_cpu_timer (
    signal r              : in    timer_registers_t;
    variable v            : inout timer_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0));

end package iop16_timer_pkg;

package body iop16_timer_pkg is

  procedure handle_cpu_timer (
    signal r              : in    timer_registers_t;
    variable v            : inout timer_registers_t;
    variable cpu_sel      : in    std_logic;
    variable apb_sel      : in    std_logic;
    signal cpuo           : in    iop16_cpu_out;
    signal apbi           : in    apb_slv_in_type;
    variable cpu_readdata : out   std_logic_vector (7 downto 0);
    variable apb_readdata : out   std_logic_vector (31 downto 0)) is
    variable tick : std_logic;
    variable xcpu_readdata : std_logic_vector (7 downto 0);
    variable xapb_readdata : std_logic_vector (31 downto 0);
  begin  -- procedure handle_cpu_timer
    -- Function
    tick := '0';
    if r.running = '1' then
      if orv(r.scaler_value) = '0' then
        tick := '1';
        v.scaler_value := r.scaler_reload;
      else
        v.scaler_value := r.scaler_value - 1;
      end if;

      if tick = '1' then
        if orv(r.timer_value) = '0' then
          v.running := '0';
        else
          v.timer_value := r.timer_value - 1;
        end if;
      end if;
    end if;

    -- CPU bus
    xcpu_readdata := (others => '0');
    case cpuo.perip_address (3 downto 0) is
      when "0000" => xcpu_readdata := r.scaler_reload (15 downto 8);
      when "0001" => xcpu_readdata := r.scaler_reload (7 downto 0);
      when "0010" => xcpu_readdata := r.scaler_value (15 downto 8);
      when "0011" => xcpu_readdata := r.scaler_value (7 downto 0);
      when "0100" => xcpu_readdata := r.timer_reload (15 downto 8);
      when "0101" => xcpu_readdata := r.timer_reload (7 downto 0);
      when "0110" => xcpu_readdata := r.timer_value (15 downto 8);
      when "0111" => xcpu_readdata := r.timer_value (7 downto 0);
      when "1000" => xcpu_readdata := "0000000" & r.running;
      when others => null;
    end case;
    if (cpu_sel and cpuo.perip_wr) = '1' then
      case cpuo.perip_address (3 downto 0) is
        when "0000" => v.scaler_reload (15 downto 8) := cpuo.perip_data;
        when "0001" => v.scaler_reload (7 downto 0)  := cpuo.perip_data;
        when "0010" => v.scaler_value (15 downto 8)  := cpuo.perip_data;
        when "0011" => v.scaler_value (7 downto 0)   := cpuo.perip_data;
        when "0100" => v.timer_reload (15 downto 8)  := cpuo.perip_data;
        when "0101" => v.timer_reload (7 downto 0)   := cpuo.perip_data;
        when "0110" => v.timer_value (15 downto 8)   := cpuo.perip_data;
        when "0111" => v.timer_value (7 downto 0)    := cpuo.perip_data;
        when "1000" => v.running                     := cpuo.perip_data(0);
        when others => null;
      end case;
    end if;
    if cpu_sel = '1' then
      cpu_readdata := xcpu_readdata;
    end if;

    -- APB bus
    xapb_readdata := (others => '0');
    case apbi.paddr (4 downto 2) is
      when "000" => xapb_readdata := x"0000" & r.scaler_reload;
      when "001" => xapb_readdata := x"0000" & r.scaler_value;
      when "010" => xapb_readdata := x"0000" & r.timer_reload;
      when "011" => xapb_readdata := x"0000" & r.timer_value;
      when "100" => xapb_readdata := x"000000" & "0000000" & r.running;
      when others => null;
    end case;
    if (apb_sel and apbi.pwrite) = '1' then
      case apbi.paddr (4 downto 2) is
        when "000" => v.scaler_reload := apbi.pwdata(15 downto 0);
        when "001" => v.scaler_value  := apbi.pwdata(15 downto 0);
        when "010" => v.timer_reload  := apbi.pwdata(15 downto 0);
        when "011" => v.timer_value   := apbi.pwdata(15 downto 0);
        when "100" => v.running       := apbi.pwdata(0);
        when others => null;
      end case;
    end if;
    if apb_sel = '1' then
      apb_readdata := xapb_readdata;
    end if;

  end procedure handle_cpu_timer;


end package body iop16_timer_pkg;
