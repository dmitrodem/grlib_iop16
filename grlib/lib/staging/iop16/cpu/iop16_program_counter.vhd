library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity iop16_program_counter is
  port
    (
      -- Ins
      i_clock    : in  std_logic;         -- Clock (50 MHz)
      i_resetN   : in  std_logic;
      i_loadPC   : in  std_logic;         -- Load PC control
      i_incPC    : in  std_logic;         -- Increment PC control
      i_PCLdValr : in  std_logic_vector(11 downto 0);
      -- Outs
      o_ProgCtr  : out std_logic_vector(11 downto 0)
      );
end iop16_program_counter;

architecture beh of iop16_program_counter is

  signal w_progCtr : std_logic_vector(11 downto 0);

begin

  progCtr : process (i_clock)           -- Sensitivity list
  begin
    if rising_edge(i_clock) then        -- On clocks
      if i_resetN = '0' then
        w_progCtr <= x"000";
      elsif i_loadPC = '1' then         -- Load new PC
        w_progCtr <= i_PCLdValr;
      elsif i_incPC = '1' then          -- Increment counter
        w_progCtr <= w_progCtr+1;
      end if;
    end if;
  end process;

  o_ProgCtr <= w_progCtr;               -- Output pins

end beh;
