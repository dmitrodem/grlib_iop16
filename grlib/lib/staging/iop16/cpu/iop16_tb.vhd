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
    subtype byte_t is std_logic_vector (7 downto 0);
    type firmware_t is array (natural range <>) of byte_t;
    constant firmware : firmware_t (0 to 41) := (
      x"40", x"10",                     -- 0
      x"41", x"01",                     -- 1
      x"42", x"02",                     -- 2
      x"43", x"03",                     -- 3
      x"44", x"04",                     -- 4
      x"45", x"05",                     -- 5
      x"46", x"06",                     -- 6
      x"47", x"07",                     -- 7
      x"48", x"08",                     -- 8
      x"49", x"09",                     -- 9
      x"4a", x"0a",                     -- a
      x"4b", x"0b",                     -- b
      x"4c", x"0c",                     -- c
      x"4d", x"0d",                     -- d
      x"4e", x"0e",                     -- e
      x"4f", x"0f",                     -- f
      x"b0", x"09",                     -- 10
      x"c0", x"13",                     -- 11
      x"c0", x"13",                     -- 12
      x"40", x"ab",                     -- 13
      x"50", x"00"
      );
  begin  -- process runtest
    rst <= '0';

    for i in firmware'range loop
      wait until falling_edge(clk);
      we <= '1';
      wa <= conv_std_logic_vector(i, 12);
      wd <= firmware(i);
      wait until rising_edge(clk);
    end loop;  -- i
    we <= '0'; wa <= x"000"; wd <= x"00";
    rst <= '1';
    wait;
  end process runtest;
end architecture behav;
