library ieee;
use ieee.std_logic_1164.all;

library techmap;
use techmap.gencomp.all;

library grlib;
use grlib.stdlib.all;

library staging;
use staging.iop16_pkg.all;

library modelsim_lib;
use modelsim_lib.util.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_iop16_cpu2 is
  generic (
    runner_cfg : string);
end entity tb_iop16_cpu2;

architecture behav of tb_iop16_cpu2 is

  constant T : time := 10 ns;

  signal clk  : std_logic := '1';
  signal rst  : std_logic := '0';
  signal cpui : iop16_cpu_in;
  signal cpuo : iop16_cpu_out;

  signal we : std_logic := '0';
  signal wa : std_logic_vector (11 downto 0);
  signal wd : std_logic_vector (7 downto 0);

  -- peripherial memory
  type perip_mem_t is array (0 to 255) of integer;
  signal perip_mem : perip_mem_t := (others => 0);

  -- SignalSpy signals
  signal r0 : std_logic_vector (7 downto 0);
  signal r1 : std_logic_vector (7 downto 0);
  signal r2 : std_logic_vector (7 downto 0);
  signal r3 : std_logic_vector (7 downto 0);
  signal r4 : std_logic_vector (7 downto 0);
  signal r5 : std_logic_vector (7 downto 0);
  signal r6 : std_logic_vector (7 downto 0);
  signal r7 : std_logic_vector (7 downto 0);
  signal rA : std_logic_vector (7 downto 0);
  signal rB : std_logic_vector (7 downto 0);
  signal rC : std_logic_vector (7 downto 0);
  signal rD : std_logic_vector (7 downto 0);
  signal rE : std_logic_vector (7 downto 0);
  signal pc : std_logic_vector (11 downto 0);

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
  -- cpui.perip_data <= x"00";

  perip_gen: process (clk) is
    variable v : std_logic_vector(7 downto 0);
  begin  -- process perip_gen
    v := x"00";
    if rising_edge(clk) then
      v := conv_std_logic_vector(perip_mem(conv_integer(cpuo.perip_address)), 8);

      if cpuo.perip_rd = '1' then
        cpui.perip_data <= v;
      end if;

      if cpuo.perip_wr = '1' then
        for i in 0 to 7 loop
          if cpuo.perip_mask(i) = '1' then
            v(i) := cpuo.perip_data(i);
          end if;
        end loop;  -- i
        perip_mem(conv_integer(cpuo.perip_address)) <= conv_integer(v);
      end if;

    end if;
  end process perip_gen;

  runtest: process is
    subtype byte_t is std_logic_vector (7 downto 0);
    type firmware_t is array (natural range <>) of byte_t;

    procedure load_firmware (
      firmware : firmware_t) is
    begin  -- procedure load_firmware
      for i in firmware'range loop
        wait until falling_edge(clk);
        we <= '1';
        wa <= conv_std_logic_vector(i, 12);
        wd <= firmware(i);
        wait until rising_edge(clk);
      end loop;  -- i
      we <= '0'; wa <= x"000"; wd <= x"00";
    end procedure load_firmware;

    constant test01_description : string := "LRI test";
    constant test01_firmware : firmware_t (0 to 17*2-1) := (
      x"40", x"10",                     -- 00 lri r0, 0x10
      x"41", x"01",                     -- 01 lri r1, 0x01
      x"42", x"02",                     -- 02 lri r2, 0x02
      x"43", x"03",                     -- 03 lri r3, 0x03
      x"44", x"04",                     -- 04 lri r4, 0x04
      x"45", x"05",                     -- 05 lri r5, 0x05
      x"46", x"06",                     -- 06 lri r6, 0x06
      x"47", x"07",                     -- 07 lri r7, 0x07
      x"48", x"08",                     -- 08 lri r8, 0x08
      x"49", x"09",                     -- 09 lri r9, 0x09
      x"4a", x"0a",                     -- 0a lri rA, 0x0a
      x"4b", x"0b",                     -- 0b lri rB, 0x0b
      x"4c", x"0c",                     -- 0c lri rC, 0x0c
      x"4d", x"0d",                     -- 0d lri rD, 0x0d
      x"4e", x"0e",                     -- 0e lri rE, 0x0e
      x"4f", x"0f",                     -- 0f lri rF, 0x0f
      x"00", x"00"                      -- 10 no-op
      );
    procedure test01_run is
    begin  -- procedure test01_run
      load_firmware(test01_firmware);
      rst <= '1';
      wait until pc = x"010";
      check(r0 = x"10");
      check(r1 = x"01");
      check(r2 = x"02");
      check(r3 = x"03");
      check(r4 = x"04");
      check(r5 = x"05");
      check(r6 = x"06");
      check(r7 = x"07");
      check(rA = x"0A");
      check(rB = x"0B");
      check(rC = x"0C");
      check(rD = x"0D");
      check(rE = x"0E");
      rst <= '0';
    end procedure test01_run;

    constant test02_description : string := "SLL/SLR test";
    constant test02_firmware : firmware_t (0 to 7*2-1) := (
      x"30", x"f0",                     -- 00 sll r0, rF, 0x0 -- a.k.a mov
      x"41", x"55",                     -- 01 lri r1, 0x55
      x"31", x"11",                     -- 02 sll r1, r1, 0x1
      x"32", x"14",                     -- 03 sll r2, r1, 0x4
      x"43", x"12",                     -- 04 lri r3, 0x12
      x"33", x"3a",                     -- 05 slr r3, r3, 0x2
      x"00", x"00"                      -- 06 no-op
    );
    procedure test02_run is
    begin  -- procedure test02_run
      load_firmware(test02_firmware);
      rst <= '1';
      wait until pc = x"006";
      check (r0 = x"FF");
      check (r1 = x"AA");
      check (r2 = x"A0");
      check (r3 = x"04");
      rst <= '0';
    end procedure test02_run;

    constant test03_description : string := "BSET/BCLR test";
    constant test03_firmware : firmware_t (0 to 12*2-1) := (
      x"28", x"00",                     -- 00 bset 0, 0x00
      x"28", x"01",                     -- 01 bset 0, 0x01
      x"2a", x"01",                     -- 02 bset 2, 0x01
      x"2c", x"01",                     -- 03 bset 4, 0x01
      x"2e", x"01",                     -- 04 bset 6, 0x01
      x"7f", x"02",                     -- 05 iow rF, 0x02
      x"21", x"02",                     -- 06 bclr 1, 0x02
      x"23", x"02",                     -- 07 bclr 3, 0x02
      x"25", x"02",                     -- 08 bclr 5, 0x02
      x"26", x"02",                     -- 09 bclr 6, 0x02
      x"48", x"00",                     -- 0a lri r8, 0x00
      x"00", x"00"                      -- 0b no-op
    );
    procedure test03_run is
    begin  -- procedure test03_run
      load_firmware(test03_firmware);
      rst <= '1';
      wait until pc = x"00b";
      check (perip_mem(0) = 16#01#);
      check (perip_mem(1) = 16#55#);
      check (perip_mem(2) = 16#95#);
      rst <= '0';
    end procedure test03_run;

  begin  -- process runtest
    rst <= '0';

    -- SignalSpy
    init_signal_spy("dut/r.reg.r0", "r0");
    init_signal_spy("dut/r.reg.r1", "r1");
    init_signal_spy("dut/r.reg.r2", "r2");
    init_signal_spy("dut/r.reg.r3", "r3");
    init_signal_spy("dut/r.reg.r4", "r4");
    init_signal_spy("dut/r.reg.r5", "r5");
    init_signal_spy("dut/r.reg.r6", "r6");
    init_signal_spy("dut/r.reg.r7", "r7");
    init_signal_spy("dut/r.reg.rA", "rA");
    init_signal_spy("dut/r.reg.rB", "rB");
    init_signal_spy("dut/r.reg.rC", "rC");
    init_signal_spy("dut/r.reg.rD", "rD");
    init_signal_spy("dut/r.reg.rE", "rE");
    init_signal_spy("dut/r.pc",     "pc");

    -- VUnit tests
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("LRI instruction") then
        test01_run;
      elsif run("SLL/SLR instruction") then
        test02_run;
      elsif run("BCLR/BSET instruction") then
        test03_run;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process runtest;
end architecture behav;
