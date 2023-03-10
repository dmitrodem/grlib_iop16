-----------------------------------------------------------------------------
--  LEON3 Demonstration design test bench
--  Copyright (C) 2004 Jiri Gaisler, Gaisler Research
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2022, Cobham Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library gaisler;
use gaisler.libdcom.all;
use gaisler.sim.all;
library techmap;
use techmap.gencomp.all;
library micron;
use micron.components.all;

library staging;

use work.debug.all;
use work.config.all;

entity testbench is
  generic (
    fabtech   : integer := CFG_FABTECH;
    memtech   : integer := CFG_MEMTECH;
    padtech   : integer := CFG_PADTECH;
    clktech   : integer := CFG_CLKTECH;
    clkperiod : integer := 10           -- system clock period
    );
end;

architecture behav of testbench is
  constant promfile  : string  := "prom.srec";      -- rom contents
  constant sdramfile : string  := "ram.srec";       -- sdram contents

  constant ct       : integer := clkperiod/2;

  signal clk        : std_logic := '0';
  signal rst        : std_logic := '0';
  signal rstn      : std_logic;
  signal error      : std_logic;

  -- PROM flash
  signal address    : std_logic_vector(26 downto 0):=(others =>'0');
  signal data       : std_logic_vector(31 downto 0);
  signal RamCE      : std_logic;
  signal oen        : std_ulogic;
  signal writen     : std_ulogic;

  -- Debug support unit
  signal dsubre     : std_ulogic;

  -- AHB Uart
  signal dsurx      : std_ulogic;
  signal dsutx      : std_ulogic;

  -- APB Uart
  signal urxd       : std_ulogic;
  signal utxd       : std_ulogic;

  -- Output signals for LEDs
  signal led       : std_logic_vector(15 downto 0);

  signal gpio : std_logic_vector (7 downto 0);
  signal w_onewire : std_logic;
begin
  -- clock and reset
  clk        <= not clk after ct * 1 ns;
  rst        <= '1', '0' after 100 ns;
  rstn       <= not rst;
  dsubre     <= '0';
  urxd       <= 'H';
  gpio(7 downto 2) <= (others => 'H');
  d3 : entity work.leon3mp
    generic map (fabtech, memtech, padtech, clktech)
    port map (
      clk     => clk,
      btnCpuResetn => rstn,
      
      -- PROM
      address   => address(22 downto 0),
      data      => data(31 downto 16),
      
      RamOE     => oen,
      RamWE     => writen,
      RamCE     => RamCE,
  
      -- AHB Uart
      RsRx     => dsurx,
      RsTx     => dsutx,

      -- Output signals for LEDs
      led       => led,

      gpio => gpio
      );

  w_onewire <= '0' when gpio(0) = '1' else
               'H';
  gpio(1) <= w_onewire;
  
  sram0 : sram
    generic map (index => 4, abits => 24, fname => sdramfile)
    port map (address(23 downto 0), data(31 downto 24), RamCE, writen, oen);

  sram1 : sram
    generic map (index => 5, abits => 24, fname => sdramfile)
    port map (address(23 downto 0), data(23 downto 16), RamCE, writen, oen);

    
  led(3) <= 'H';            -- ERROR pull-up
  error <= led(3);      

  iuerr : process
  begin
    wait for 5 us;
    if to_x01(error) = '1' then wait on error; end if;
    assert (to_X01(error) = '1')
      report "*** IU in error mode, simulation halted ***"
      severity failure;
  end process;

  data <= buskeep(data) after 5 ns;

  temp0: entity staging.ds18b20
    generic map (
      timing  => "MIN",
      devid   => x"00a0458d3ea2be28",
      nvrom   => x"3f0064",
      speedup => 10.0)
    port map (
      pwrin  => '1',
      tempin => -1.52,
      dio    => w_onewire);

  temp1: entity staging.ds18b20
    generic map (
      timing  => "MIN",
      devid   => x"002984456a32bf28",
      nvrom   => x"3f0064",
      speedup => 10.0)
    port map (
      pwrin  => '1',
      tempin => 115.3,
      dio    => w_onewire);
end;
