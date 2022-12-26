library ieee;
use ieee.std_logic_1164.all;

entity iop16_rom is

  port (
    clock   : in  std_logic;
    rst     : in  std_logic;
    address : in  std_logic_vector (7 downto 0);
    q       : out std_logic_vector (15 downto 0));

end entity iop16_rom;

architecture behav of iop16_rom is

  signal qi : std_logic_vector(15 downto 0);
begin  -- architecture behav

  -- qi <=
  --   x"9800" when address = x"00" else   -- 000: ORI %r8, 0x00 ->        nop
  --   x"c006" when address = x"01" else   -- 001: JSR 0x006     ->        call proc1
  --   x"6100" when address = x"02" else   -- 002: IOR %r1, 0x00 -> 1:     %r1 = *0x00
  --   x"81ff" when address = x"03" else   -- 003: XRI %r1, 0xff ->        %r1 ^= 0xff
  --   x"7100" when address = x"04" else   -- 004: IOW %r1, 0x00 ->        *0x00 = %r1
  --   x"d002" when address = x"05" else   -- 005: JMP 0x002     ->        jmp 1b
  --   x"41ab" when address = x"06" else   -- 006: LRI %r1, 0xab -> proc1: %r1 = 0xab
  --   x"300f" when address = x"07" else   -- 007: RTS           ->        ret
  --   x"0000";
  qi <= x"410a" when address = x"00" else
        x"b1ff" when address = x"01" else
        x"f001" when address = x"02" else
        x"9800" when address = x"03" else
        x"c009" when address = x"04" else
        x"6100" when address = x"05" else
        x"81ff" when address = x"06" else
        x"7100" when address = x"07" else
        x"d005" when address = x"08" else
        x"41ab" when address = x"09" else
        x"3008" when address = x"0a" else
        x"0000";
  ff: process (clock) is
  begin  -- process ff
    if rising_edge(clock) then
      if rst = '0' then
        q <= (others => '0');
      else
        q <= qi;
      end if;
    end if;
  end process ff;

end architecture behav;
