library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity iop16_alu is
  port (
    --
    i_clock     : in    std_logic;      -- Clock (50 MHz)
    i_resetN    : in    std_logic;
    i_ALU_A_In  : in    std_logic_vector(7 downto 0);
    i_ALU_B_In  : in    std_logic_vector(7 downto 0);
    i_OP_ADI    : in    std_logic;
    i_OP_CMP    : in    std_logic;
    i_OP_ARI    : in    std_logic;
    i_OP_ORI    : in    std_logic;
    i_OP_XRI    : in    std_logic;
    i_LatchZBit : in    std_logic;
    --
    o_Z_Bit     : out std_logic;
    o_ALU_Out   : out std_logic_vector(7 downto 0)
    );
end iop16_alu;

architecture beh of iop16_alu is

  signal w_Zero : std_logic;

  signal w_latchZOps  : std_logic;
  signal w_ARI_Result : std_logic_vector(7 downto 0);
  signal w_ORI_Result : std_logic_vector(7 downto 0);
  signal w_XRI_Result : std_logic_vector(7 downto 0);
  signal w_ADI_Result : std_logic_vector(7 downto 0);

begin

  -- Opcodes which need to latch the Z bit
  w_latchZOps <= i_OP_ORI or i_OP_ARI or i_OP_XRI or i_OP_ADI or i_OP_CMP;

  w_ARI_Result <= i_ALU_A_In and i_ALU_B_In;
  w_ORI_Result <= i_ALU_A_In or  i_ALU_B_In;
  w_XRI_Result <= i_ALU_A_In xor i_ALU_B_In;
  w_ADI_Result <= i_ALU_A_In +   i_ALU_B_In;

  o_ALU_Out <= w_ARI_Result when (i_OP_ARI = '1') else
               w_ORI_Result when (i_OP_ORI = '1') else
               w_XRI_Result when (i_OP_XRI = '1') else
               w_ADI_Result when (i_OP_ADI = '1') else
               i_ALU_A_In   when (i_OP_CMP = '1') else  -- CMP does not change the value
               X"00";

  w_Zero <= '1' when ((w_ARI_Result = X"00") and (i_OP_ARI = '1')) else
            '1' when ((w_ORI_Result = X"00") and (i_OP_ORI = '1')) else
            '1' when ((w_XRI_Result = X"00") and (i_OP_XRI = '1')) else
            '1' when ((w_ADI_Result = X"00") and (i_OP_ADI = '1')) else
            '1' when ((w_XRI_Result = X"00") and (i_OP_CMP = '1')) else
            '0';

  latchZBit : process (i_clock)         -- Sensitivity list
  begin
    if rising_edge(i_clock) then        -- On clocks
      if (i_resetN = '0') then
        o_Z_Bit <= '0';
      elsif ((i_LatchZBit = '1') and (w_latchZOps = '1')) then
        o_Z_Bit <= w_Zero;
      end if;
    end if;
  end process;
end beh;
