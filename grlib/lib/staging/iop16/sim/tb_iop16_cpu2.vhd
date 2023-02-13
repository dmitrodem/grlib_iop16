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
context vunit_lib.vc_context;

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

  signal irq : std_logic_vector (3 downto 0);

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
  cpui.irq <= irq;

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
      firmware : firmware_t;
      inject_single : integer;
      inject_double : integer) is
      variable d1, d2, chk : std_logic_vector (7 downto 0);
      variable nerrors : integer;
    begin  -- procedure load_firmware
      nerrors := 0;
      for i in 0 to firmware'length/2-1 loop
        wait until falling_edge(clk);
        we <= '1';
        wa <= conv_std_logic_vector(2*i, 12);
        d1 := firmware(2*i);
        if nerrors < inject_single then
          d1(0) := not d1(0);
        end if;
        wd <= d1;
        wait until rising_edge(clk);

        wait until falling_edge(clk);
        we <= '1';
        wa <= conv_std_logic_vector(2*i+1, 12);
        d2 := firmware(2*i+1);
        wd <= d2;
        wait until rising_edge(clk);

        wait until falling_edge(clk);
        we <= '1';
        wa <= not conv_std_logic_vector(i, 12);
        chk := "0" & edacencode(x"0000" & firmware(2*i) & firmware(2*i+1));
        wd <= chk;
        wait until rising_edge(clk);

        nerrors := nerrors + 1;
      end loop;  -- i
      we <= '0'; wa <= x"000"; wd <= x"00";
    end procedure load_firmware;

    procedure load_firmware (
      firmware : firmware_t;
      inject_single : integer) is
    begin
      load_firmware(firmware, inject_single, 0);
    end procedure load_firmware;

    procedure load_firmware (
      firmware : firmware_t) is
    begin
      load_firmware(firmware, 0, 0);
    end procedure load_firmware;


    constant test01_description : string := "LRI test";
    constant test01_firmware : firmware_t (0 to 16*2-1) := (
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
      x"4f", x"0f",                     -- 0e lri rF, 0x0f
      x"00", x"00"                      -- 0f no-op
      );
    procedure test01_run is
    begin  -- procedure test01_run
      load_firmware(test01_firmware, 3);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
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
      check(cpuo.errcnt = x"3");
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
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check (r0 = x"FF");
      check (r1 = x"AA");
      check (r2 = x"A0");
      check (r3 = x"04");
      rst <= '0';
    end procedure test02_run;

    constant test03_description : string := "BSET/BCLR test";
    constant test03_firmware : firmware_t (0 to 12*2-1) := (
      x"28", x"80",                     -- 00 bset 0, r8, 0x0
      x"28", x"81",                     -- 01 bset 0, r8, 0x1
      x"2a", x"81",                     -- 02 bset 2, r8, 0x1
      x"2c", x"81",                     -- 03 bset 4, r8, 0x1
      x"2e", x"81",                     -- 04 bset 6, r8, 0x1
      x"7f", x"82",                     -- 05 iow rF, r8, 0x2
      x"21", x"82",                     -- 06 bclr 1, r8, 0x2
      x"23", x"82",                     -- 07 bclr 3, r8, 0x2
      x"25", x"82",                     -- 08 bclr 5, r8, 0x2
      x"26", x"82",                     -- 09 bclr 6, r8, 0x2
      x"48", x"00",                     -- 0a lri r8, 0x00
      x"00", x"00"                      -- 0b no-op
    );
    procedure test03_run is
    begin  -- procedure test03_run
      load_firmware(test03_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check (perip_mem(0) = 16#01#);
      check (perip_mem(1) = 16#55#);
      check (perip_mem(2) = 16#95#);
      rst <= '0';
    end procedure test03_run;

    constant test04_description : string := "IOR/IOW test";
    constant test04_firmware : firmware_t (0 to 9*2-1) := (
      x"40", x"ab",                     -- 00 lri r0, 0xab
      x"44", x"c0",                     -- 01 lri r4, 0xc0
      x"70", x"4d",                     -- 02 iow r0, r4, 0xd
      x"44", x"10",                     -- 03 lri r4, 0x10
      x"7f", x"42",                     -- 04 iow rF, r4, 0x2
      x"61", x"42",                     -- 05 ior r1, r4, 0x2
      x"44", x"c1",                     -- 06 lri r4, 0xc1
      x"62", x"4c",                     -- 07 ior r2, r4, 0xc
      x"00", x"00"                      -- 08 no-op
    );
    procedure test04_run is
    begin  -- procedure test04_run
      load_firmware(test04_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check (perip_mem(16#cd#) = 16#ab#);
      check (perip_mem(16#12#) = 16#ff#);
      check (r1 = x"ff");
      check (r2 = x"ab");
      rst <= '0';
    end procedure test04_run;

    constant test05_description : string := "ALU test";
    constant test05_firmware : firmware_t (0 to 14*2-1) := (
      x"4e", x"02",                     -- 00 lri rE, 0x02 (set carry flag)
      x"40", x"ab",                     -- 00 lri r0, 0xab
      x"41", x"86",                     -- 01 lri r1, 0x86
      x"42", x"49",                     -- 02 lri r2, 0x49
      x"43", x"c4",                     -- 03 lri r3, 0xc4
      x"44", x"9c",                     -- 04 lri r4, 0x9c
      x"45", x"d4",                     -- 05 lri r5, 0xd4
      x"46", x"d2",                     -- 06 lri r6, 0xd2
      x"47", x"0a",                     -- 07 lri r7, 0x0a
      x"8a", x"01",                     -- 08 xri rA, r0, r1
      x"9b", x"23",                     -- 09 ori rB, r2, r3
      x"ac", x"45",                     -- 0a ari rC, r4, r5
      x"bd", x"67",                     -- 0b adi rD, r6, r7
      x"00", x"00"                      -- 0c no-op
      );
    procedure test05_run is
      variable v : std_logic_vector (7 downto 0);
    begin  -- procedure test05_run
      load_firmware(test05_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      v := r0 xor r1; check (rA = v);
      v := r2 or r3; check (rB = v);
      v := r4 and r5; check (rC = v);
      v := r6 + r7 + '1'; check (rD = v);
      check_equal(rE(1), '0');
      rst <= '0';
    end procedure test05_run;

    constant test06_description : string := "JMP test";
    constant test06_firmware : firmware_t (0 to 17*2-1) := (
      x"d0", x"10",                     -- 00 jmp 0x010
      x"00", x"00",                     -- 01 halt
      x"00", x"00",                     -- 02 halt
      x"00", x"00",                     -- 03 halt
      x"00", x"00",                     -- 04 halt
      x"00", x"00",                     -- 05 halt
      x"00", x"00",                     -- 06 halt
      x"00", x"00",                     -- 07 halt
      x"00", x"00",                     -- 08 halt
      x"00", x"00",                     -- 09 halt
      x"00", x"00",                     -- 0a halt
      x"00", x"00",                     -- 0b halt
      x"00", x"00",                     -- 0c halt
      x"00", x"00",                     -- 0d halt
      x"00", x"00",                     -- 0e halt
      x"00", x"00",                     -- 0f halt
      x"00", x"00"                      -- 10 halt
      );
    procedure test06_run is
    begin  -- procedure test05_run
      load_firmware(test06_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check_equal(pc, std_logic_vector'(x"010"));
      rst <= '0';
    end procedure test06_run;

    constant test07_description : string := "CALL/RET test";
    constant test07_firmware : firmware_t (0 to 19*2-1) := (
      x"40", x"ab",                     -- 00 lri r0, 0xab
      x"c0", x"10",                     -- 01 call 0x010
      x"00", x"00",                     -- 02 halt
      x"00", x"00",                     -- 03 halt
      x"00", x"00",                     -- 04 halt
      x"00", x"00",                     -- 05 halt
      x"00", x"00",                     -- 06 halt
      x"00", x"00",                     -- 07 halt
      x"00", x"00",                     -- 08 halt
      x"00", x"00",                     -- 09 halt
      x"00", x"00",                     -- 0a halt
      x"00", x"00",                     -- 0b halt
      x"00", x"00",                     -- 0c halt
      x"00", x"00",                     -- 0d halt
      x"00", x"00",                     -- 0e halt
      x"00", x"00",                     -- 0f halt
      x"40", x"cd",                     -- 00 lri r0, 0xcd
      x"50", x"00",                     -- 11 ret
      x"00", x"00"                      -- 12 halt
      );
    procedure test07_run is
    begin  -- procedure test07_run
      load_firmware(test07_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check_equal(pc, std_logic_vector'(x"002"));
      check_equal(r0, std_logic_vector'(x"cd"));
      rst <= '0';
    end procedure test07_run;

    constant test08_description : string := "BEZ/BNZ test";
    constant test08_firmware : firmware_t (0 to 18*2-1) := (
      x"40", x"ab",                     -- 00 lri r0, 0xab
      x"41", x"cd",                     -- 01 lri r1, 0xcd
      x"88", x"01",                     -- 02 cmp r0, r1
      x"f0", x"10",                     -- 03 bnz 0x010
      x"88", x"11",                     -- 04 cmp r1, r1
      x"e0", x"08",                     -- 05 bez 0x008
      x"00", x"00",                     -- 06 halt
      x"00", x"00",                     -- 07 halt
      x"d0", x"07",                     -- 08 jmp 0x007
      x"00", x"00",                     -- 09 halt
      x"00", x"00",                     -- 0a halt
      x"00", x"00",                     -- 0b halt
      x"00", x"00",                     -- 0c halt
      x"00", x"00",                     -- 0d halt
      x"00", x"00",                     -- 0e halt
      x"00", x"00",                     -- 0f halt
      x"d0", x"04",                     -- 10 jmp 0x004
      x"00", x"00"                      -- 11 halt
      );
    procedure test08_run is
    begin  -- procedure test08_run
      load_firmware(test08_firmware);
      rst <= '1';
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check_equal(pc, std_logic_vector'(x"007"));
      rst <= '0';
    end procedure test08_run;

    constant test09_description : string := "IRQ test";
    constant test09_firmware : firmware_t (0 to 10*2-1) := (
      x"d0", x"04",                     -- 00 jmp 0x004
      x"d0", x"08",                     -- 01 jmp 0x008
      x"d0", x"10",                     -- 02 jmp 0x010
      x"d0", x"14",                     -- 03 jmp 0x014
      x"40", x"ab",                     -- 04 lri r0, 0xab
      x"38", x"80",                     -- 05 nop
      x"38", x"80",                     -- 06 nop
      x"d0", x"07",                     -- 07 jmp 0x007
      x"41", x"cd",                     -- 08 lri r1, 0xcd
      x"00", x"00"                      -- 09 halt
      );
    procedure test09_run is
    begin  -- procedure test09_run
      load_firmware(test09_firmware);
      rst <= '1';
      wait until pc = x"007";
      wait until falling_edge(clk);
      irq <= x"1";
      wait until cpuo.irq_ack = '1';
      irq <= x"0";
      wait for 10 * T;
      if cpuo.halt /= '1' then
        wait until cpuo.halt = '1';
      end if;
      check_equal(pc, std_logic_vector'(x"009"));
      check_equal(r0, std_logic_vector'(x"ab"));
      check_equal(r1, std_logic_vector'(x"cd"));
      rst <= '0';
    end procedure test09_run;

  begin  -- process runtest
    rst <= '0';
    irq <= x"0";

    -- VUnit tests
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("LRI instruction") then
        test01_run;
      elsif run("SLL/SLR instructions") then
        test02_run;
      elsif run("BCLR/BSET instructions") then
        test03_run;
      elsif run("IOW/IOR instructions") then
        test04_run;
      elsif run("ALU instructions") then
        test05_run;
      elsif run("JMP instruction") then
        test06_run;
      elsif run("CALL/RET instructions") then
        test07_run;
      elsif run("BEZ/BNZ instructions") then
        test08_run;
      elsif run("IRQ test") then
        test09_run;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process runtest;

  signal_spy: block is
  begin  -- block signal_spy
    r0 <= << signal ^.dut.debug.r0 : std_logic_vector >>;
    r1 <= << signal ^.dut.debug.r1 : std_logic_vector >>;
    r2 <= << signal ^.dut.debug.r2 : std_logic_vector >>;
    r3 <= << signal ^.dut.debug.r3 : std_logic_vector >>;
    r4 <= << signal ^.dut.debug.r4 : std_logic_vector >>;
    r5 <= << signal ^.dut.debug.r5 : std_logic_vector >>;
    r6 <= << signal ^.dut.debug.r6 : std_logic_vector >>;
    r7 <= << signal ^.dut.debug.r7 : std_logic_vector >>;
    rA <= << signal ^.dut.debug.rA : std_logic_vector >>;
    rB <= << signal ^.dut.debug.rB : std_logic_vector >>;
    rC <= << signal ^.dut.debug.rC : std_logic_vector >>;
    rD <= << signal ^.dut.debug.rD : std_logic_vector >>;
    rE <= << signal ^.dut.debug.rE : std_logic_vector >>;
    pc <= << signal ^.dut.debug.pc : std_logic_vector >>;
  end block signal_spy;


end architecture behav;
