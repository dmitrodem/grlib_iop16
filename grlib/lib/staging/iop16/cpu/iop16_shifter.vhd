-- File: Shifter.vhd
-- Supports:
--		Shift Logical left/right
--		Shift Arithmetic left/right
--		Rotate left/right
--
-- Info: https://open4tech.com/logical-vs-arithmetic-shift/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity iop16_shifter is
  port (
    -- Ins
    i_OP_SRI : IN std_logic;  -- Shift/Rotate Instruction
    i_ShiftL0A1 : IN std_logic;  -- 0=Logical, 1=Arithmetic
    i_Shift0Rot1 : IN std_logic;  -- Shift=0, Rotate=1
    i_ShiftL0R1 : IN std_logic;  -- 0=left, 1=right
    i_ShiftCount : IN std_logic_vector(2 downto 0);  -- 0x1
    i_DataIn : IN std_logic_vector(7 downto 0);  -- Data In
    -- Outs
    o_DataOut : out std_logic_vector(7 downto 0)  -- Data Out
    );
end iop16_shifter;

architecture beh of iop16_shifter is

begin

  o_DataOut <= i_DataIn(6 downto 0) & '0' when ( -- Shift left Logical
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '0') and
                 (i_Shift0Rot1 = '0') and
                 (i_ShiftCount = "001") and
                 (i_ShiftL0A1 = '0')
    ) else
               '0' & i_DataIn(7 downto 1) when ( -- Shift right Logical
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '1') and
                 (i_Shift0Rot1 = '0') and
                 (i_ShiftCount = "001") and
                 (i_ShiftL0A1 = '0')
    ) else
               i_DataIn(6 downto 0) & '0' when ( -- Shift left Arithmetic
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '0') and
                 (i_Shift0Rot1 = '0') and
                 (i_ShiftCount = "001") and
                 (i_ShiftL0A1='1')
    ) else
               i_DataIn(7) & i_DataIn(7 downto 1) when ( -- Shift right Arithmetic
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '1') and
                 (i_Shift0Rot1 = '0') and
                 (i_ShiftCount = "001") and
                 (i_ShiftL0A1='1')
    ) else
               i_DataIn(6 downto 0) & i_DataIn(7) when ( -- rotate left
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '0') and
                 (i_Shift0Rot1 = '1') and
                 (i_ShiftCount = "001")
    ) else
               i_DataIn(0) & i_DataIn(7 downto 1) when ( -- rotate right
                 (i_OP_SRI = '1') and
                 (i_ShiftL0R1 = '1') and
                 (i_Shift0Rot1 = '1') and
                 (i_ShiftCount = "001")
    ) else
               i_DataIn;

end beh;
