-------------------------------------------------------------------------------
--! @file      iop16_cpu2.vhd
--! @brief     IOP16 CPU -- 2 proc
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-27
--! @modified  2022-12-27
--! @version   0.1
--! @copyright Copyright (c) MIPT 2022
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.stdlib.all;

library staging;
use staging.iop16_pkg.all;

entity iop16_cpu2 is
  port
    (
      clk  : in  std_logic;
      rst  : in  std_logic;
      cpui : in  iop16_cpu_in;
      cpuo : out iop16_cpu_out);
end entity iop16_cpu2;

architecture behav of iop16_cpu2 is
  type registers is record
    pc : std_logic_vector (11 downto 0);
  end record registers;

  constant RES_registers : registers := (
    pc => (others => '0'));

  signal r, rin : registers;

begin  -- architecture behav

  comb: process (r, rst) is
    variable v : registers;
    variable opcode : std_logic_vector;
  begin  -- process comb
    v := r;

    if rst = '0' then
      v := RES_registers;
    end if;

    rin <= v;
  end process comb;

  seq: process is
  begin  -- process seq
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process seq;

end architecture behav;
