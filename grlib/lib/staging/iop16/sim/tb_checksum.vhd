library ieee;
use ieee.std_logic_1164.all;

library staging;
use staging.iop16_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.TextUtilPkg.all;
entity tb_checksum is
  generic (
    runner_cfg : string);
end entity tb_checksum;

architecture behav of tb_checksum is

begin  -- architecture behav

  runtest: process is
    variable RV : RandomPType;
    variable d, d1 : std_logic_vector (31 downto 0);
    variable cb : std_logic_vector (6 downto 0);
    variable syn : std_logic_vector (6 downto 0);
    variable co : edacdectype;
    constant zero7 : std_logic_vector (6 downto 0) := (others => '0');
    variable idx : natural range 0 to 31;
    variable idx2 : integer_vector (0 to 1);
  begin  -- process runtest
    test_runner_setup(runner, runner_cfg);
    RV.InitSeed(RV'instance_name);
    while test_suite loop
      if run("BCH(32,7) code test") then
        for i in 0 to 1023 loop
          d := RV.RandSlv(Size => 32);
          cb := edacencode(d);
          syn := edacsyngen(d, cb);
          co := edacdecode(d, syn);
          check_equal(d, co.data);
          check_equal(syn, zero7);
          check_equal(co.err, '0');
          check_equal(co.merr, '0');
        end loop;  -- i
      elsif run("BCH(32,7) single error") then
        for i in 0 to 1023 loop
          d := RV.RandSlv(Size => 32);
          cb := edacencode(d);
          d1 := d;
          idx := RV.RandInt(0, 31);
          d1(idx) := not d1(idx);
          syn := edacsyngen(d1, cb);
          co := edacdecode(d1, syn);
          check_equal(d, co.data);
          check(syn /= zero7);
          check_equal(co.err, '1');
          check_equal(co.merr, '0');
        end loop;  -- i
      elsif run("BCH(32,7) double error") then
        for i in 0 to 1023 loop
          d := RV.RandSlv(Size => 32);
          cb := edacencode(d);
          d1 := d;
          idx2 := RV.RandIntV(0, 31, Unique => 2, Size => 2);
          d1(idx2(0)) := not d1(idx2(0));
          d1(idx2(1)) := not d1(idx2(1));
          syn := edacsyngen(d1, cb);
          co := edacdecode(d1, syn);
          check_equal(co.err, '0');
          check_equal(co.merr, '1');
        end loop;  -- i
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process runtest;

end architecture behav;
