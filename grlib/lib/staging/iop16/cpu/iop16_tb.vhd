library ieee;
use ieee.std_logic_1164.all;

library techmap;
use techmap.gencomp.all;

library grlib;
use grlib.stdlib.all;

library staging;
use staging.iop16_pkg.all;

entity iop16_tb is

end entity iop16_tb;

architecture behav of iop16_tb is

  constant T : time := 10 ns;

  signal clk  : std_logic := '1';
  signal rst  : std_logic := '0';
  signal cpui : iop16_cpu_in;
  signal cpuo : iop16_cpu_out;

  signal we : std_logic := '0';
  signal wa : std_logic_vector (11 downto 0);
  signal wd : std_logic_vector (7 downto 0);
begin  -- architecture behav

  clk <= not clk after T/2;

  dut: entity staging.iop16_cpu2
    port map (
      clk  => clk,
      rst  => rst,
      cpui => cpui,
      cpuo => cpuo);

  rom: entity techmap.syncram_2p
    generic map (
      tech       => inferred,
      abits      => 12,
      dbits      => 8)
    port map (
      rclk     => clk,
      renable  => cpuo.rom_read,
      raddress => cpuo.rom_address,
      dataout  => cpui.rom_data (7 downto 0),
      wclk     => clk,
      write    => we,
      waddress => wa,
      datain   => wd,
      testin   => (others => '0'));

  cpui.rom_data(15 downto 8) <= x"00";
  cpui.perip_data <= x"00";

  runtest: process is
  begin  -- process runtest
    rst <= '0';
    wait until falling_edge(clk);
    we <= '1';  wa <= x"000"; wd <= x"40";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"001"; wd <= x"80";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"002"; wd <= x"70";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"003"; wd <= x"20";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"004"; wd <= x"78";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"005"; wd <= x"11";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"006"; wd <= x"79";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    we <= '1';  wa <= x"007"; wd <= x"12";
    wait until rising_edge(clk);
    we <= '0'; wa <= x"000"; wd <= x"00";
    rst <= '1';
    wait;
  end process runtest;
end architecture behav;
