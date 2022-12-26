library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity iop16_grey_code is
  port (
    i_clock    : in  std_logic;         -- Clock (50 MHz)
    i_resetN   : in  std_logic;
    o_GreyCode : out std_logic_vector(1 downto 0)
    );
end iop16_grey_code;

architecture beh of iop16_grey_code is

  signal r_greyCode : std_logic_vector(1 downto 0);

begin

  GreyCode : process (i_clock)          -- Sensitivity list
  begin
    if rising_edge(i_clock) then        -- On clocks
      if (i_resetN = '0') then
        r_greyCode <= "00";
      else
        case (r_greyCode) is
          when "00"   => r_greyCode <= "01";
          when "01"   => r_greyCode <= "11";
          when "11"   => r_greyCode <= "10";
          when "10"   => r_greyCode <= "00";
          when others => null;
        end case;
      end if;
    end if;
  end process;

  o_greyCode <= r_GreyCode;

end beh;
