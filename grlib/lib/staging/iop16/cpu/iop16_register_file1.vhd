-- ---------------------------------------------------------------------------------
-- File: RegisterFile.vhd
-- Register file for IOP-16 CPU
--      8-bit registers
--      4, 8 or 16 registers
--      3 are constants
--              reg8 = 0x00
--              reg9 = 0x01
--              regF = 0xFF

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity iop16_register_file1 is
  generic (
    constant NUM_REGS : integer := 8    -- 4, 8. or 16
    );
  port (
    i_clock     : in  std_logic;        -- Clock (50 MHz)
    i_resetN    : in  std_logic;
    i_ldRegF    : in  std_logic;        -- Load signal
    i_regSel1   : in  std_logic_vector(3 downto 0);
    i_regSel2   : in  std_logic_vector(3 downto 0);
    i_regSel3   : in  std_logic_vector(3 downto 0);
    i_RegFData1 : in  std_logic_vector(7 downto 0);
    o_RegFData2 : out std_logic_vector(7 downto 0);
    o_RegFData3 : out std_logic_vector(7 downto 0)
    );
end entity iop16_register_file1;

architecture beh of iop16_register_file1 is

  signal reg0 : std_logic_vector(7 downto 0);
  signal reg1 : std_logic_vector(7 downto 0);
  signal reg2 : std_logic_vector(7 downto 0);
  signal reg3 : std_logic_vector(7 downto 0);
  signal reg4 : std_logic_vector(7 downto 0);
  signal reg5 : std_logic_vector(7 downto 0);
  signal reg6 : std_logic_vector(7 downto 0);
  signal reg7 : std_logic_vector(7 downto 0);
  signal regA : std_logic_vector(7 downto 0);
  signal regB : std_logic_vector(7 downto 0);
  signal regC : std_logic_vector(7 downto 0);
  signal regD : std_logic_vector(7 downto 0);
  signal regE : std_logic_vector(7 downto 0);

begin

  -- Register stores
  REGFILE4 : if (NUM_REGS = 4) generate
  begin
    RegisterFile : process (i_clock)    -- Sensitivity list
    begin
      if rising_edge(i_clock) then      -- On clocks
        if i_resetN = '0' then
          reg0 <= x"00";
          reg1 <= x"00";
          reg2 <= x"00";
          reg3 <= x"00";
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"0")) then
          reg0 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"1")) then
          reg1 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"2")) then
          reg2 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"3")) then
          reg3 <= i_RegFData1;
        end if;
      end if;
    end process;

    -- Register Read Multiplexer
    o_RegFData2 <= reg0  when i_regSel2 = x"0" else
                   reg1  when i_regSel2 = x"1" else
                   reg2  when i_regSel2 = x"2" else
                   reg3  when i_regSel2 = x"3" else
                   x"00" when i_regSel2 = x"8" else
                   x"01" when i_regSel2 = x"9" else
                   x"FF" when i_regSel2 = x"F" else
                   x"00";
    o_RegFData3 <= reg0  when i_regSel3 = x"0" else
                   reg1  when i_regSel3 = x"1" else
                   reg2  when i_regSel3 = x"2" else
                   reg3  when i_regSel3 = x"3" else
                   x"00" when i_regSel3 = x"8" else
                   x"01" when i_regSel3 = x"9" else
                   x"FF" when i_regSel3 = x"F" else
                   x"00";
    reg4 <= x"00";
    reg5 <= x"00";
    reg6 <= x"00";
    reg7 <= x"00";
    regA <= x"00";
    regB <= x"00";
    regC <= x"00";
    regD <= x"00";
    regE <= x"00";
  end generate REGFILE4;

  -- Register stores
  REGFILE8 : if (NUM_REGS = 8) generate
  begin
    RegisterFile : process (i_clock)    -- Sensitivity list
    begin
      if rising_edge(i_clock) then      -- On clocks
        if i_resetN = '0' then
          reg0 <= x"00";
          reg1 <= x"00";
          reg2 <= x"00";
          reg3 <= x"00";
          reg4 <= x"00";
          reg5 <= x"00";
          reg6 <= x"00";
          reg7 <= x"00";
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"0")) then
          reg0 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"1")) then
          reg1 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"2")) then
          reg2 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"3")) then
          reg3 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"4")) then
          reg4 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"5")) then
          reg5 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"6")) then
          reg6 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"7")) then
          reg7 <= i_RegFData1;
        end if;
      end if;
    end process;

    -- Register Read Multiplexer
    o_RegFData2 <= reg0  when i_regSel2 = x"0" else
                   reg1  when i_regSel2 = x"1" else
                   reg2  when i_regSel2 = x"2" else
                   reg3  when i_regSel2 = x"3" else
                   reg4  when i_regSel2 = x"4" else
                   reg5  when i_regSel2 = x"5" else
                   reg6  when i_regSel2 = x"6" else
                   reg7  when i_regSel2 = x"7" else
                   x"00" when i_regSel2 = x"8" else
                   x"01" when i_regSel2 = x"9" else
                   x"FF" when i_regSel2 = x"F" else
                   x"00";
    o_RegFData3 <= reg0  when i_regSel3 = x"0" else
                   reg1  when i_regSel3 = x"1" else
                   reg2  when i_regSel3 = x"2" else
                   reg3  when i_regSel3 = x"3" else
                   reg4  when i_regSel3 = x"4" else
                   reg5  when i_regSel3 = x"5" else
                   reg6  when i_regSel3 = x"6" else
                   reg7  when i_regSel3 = x"7" else
                   x"00" when i_regSel3 = x"8" else
                   x"01" when i_regSel3 = x"9" else
                   x"FF" when i_regSel3 = x"F" else
                   x"00";
    regA <= x"00";
    regB <= x"00";
    regC <= x"00";
    regD <= x"00";
    regE <= x"00";
  end generate REGFILE8;

  -- Register stores
  REGFILE16 : if (NUM_REGS = 16) generate
  begin
    RegisterFile : process (i_clock)    -- Sensitivity list
    begin
      if rising_edge(i_clock) then      -- On clocks
        if (i_resetN = '0') then
          reg0 <= x"00";
          reg1 <= x"00";
          reg2 <= x"00";
          reg3 <= x"00";
          reg4 <= x"00";
          reg5 <= x"00";
          reg6 <= x"00";
          reg7 <= x"00";
          regA <= x"00";
          regB <= x"00";
          regC <= x"00";
          regD <= x"00";
          regE <= x"00";
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"0")) then
          reg0 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"1")) then
          reg1 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"2")) then
          reg2 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"3")) then
          reg3 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"4")) then
          reg4 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"5")) then
          reg5 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"6")) then
          reg6 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"7")) then
          reg7 <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"A")) then
          regA <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"B")) then
          regB <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"C")) then
          regC <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"D")) then
          regD <= i_RegFData1;
        elsif ((i_ldRegF = '1') and (i_regSel1 = x"E")) then
          regE <= i_RegFData1;
        end if;
      end if;
    end process;

    -- Register Read Multiplexer
    o_RegFData2 <= reg0  when i_regSel2 = x"0" else
                   reg1  when i_regSel2 = x"1" else
                   reg2  when i_regSel2 = x"2" else
                   reg3  when i_regSel2 = x"3" else
                   reg4  when i_regSel2 = x"4" else
                   reg5  when i_regSel2 = x"5" else
                   reg6  when i_regSel2 = x"6" else
                   reg7  when i_regSel2 = x"7" else
                   x"00" when i_regSel2 = x"8" else
                   x"01" when i_regSel2 = x"9" else
                   regA  when i_regSel2 = x"A" else
                   regB  when i_regSel2 = x"B" else
                   regC  when i_regSel2 = x"C" else
                   regD  when i_regSel2 = x"D" else
                   regE  when i_regSel2 = x"E" else
                   x"FF" when i_regSel2 = x"F";
    o_RegFData3 <= reg0  when i_regSel3 = x"0" else
                   reg1  when i_regSel3 = x"1" else
                   reg2  when i_regSel3 = x"2" else
                   reg3  when i_regSel3 = x"3" else
                   reg4  when i_regSel3 = x"4" else
                   reg5  when i_regSel3 = x"5" else
                   reg6  when i_regSel3 = x"6" else
                   reg7  when i_regSel3 = x"7" else
                   x"00" when i_regSel3 = x"8" else
                   x"01" when i_regSel3 = x"9" else
                   regA  when i_regSel3 = x"A" else
                   regB  when i_regSel3 = x"B" else
                   regC  when i_regSel3 = x"C" else
                   regD  when i_regSel3 = x"D" else
                   regE  when i_regSel3 = x"E" else
                   x"FF" when i_regSel3 = x"F";

  end generate REGFILE16;

end beh;
