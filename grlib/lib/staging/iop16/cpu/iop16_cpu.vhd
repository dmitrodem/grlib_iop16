library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.stdlib.all;

-- Opcodes table is in here
library staging;
use staging.iop16_pkg.all;


-- ---------------------------------------------------------------------------------------------------------
-- CPU
entity iop16_cpu is
  generic (
    INST_ROM_SIZE_PASS : integer := 256;  -- Legal Values are 256, 512, 1024, 2048, 4096
    STACK_DEPTH_PASS   : integer := 1  -- Legal Values are 0, 1 (single), > 1 (2^N) (nested subroutines)
    );
  port
    (
      i_clock            : in  std_logic;  -- 50 MHz clock
      i_resetN           : in  std_logic := '1';
      -- Peripheral bus
      i_peripDataToCPU   : in  std_logic_vector(7 downto 0);
      o_peripAddr        : out std_logic_vector(7 downto 0);
      o_peripDataFromCPU : out std_logic_vector(7 downto 0);
      o_peripWr          : out std_logic;
      o_peripRd          : out std_logic
      );
end entity iop16_cpu;

architecture beh of iop16_cpu is

  -- Program Counter
  signal w_loadPC  : std_logic;
  signal w_incPC   : std_logic;
  signal w_ProgCtr : std_logic_vector(11 downto 0);
  signal pcPlus1   : std_logic_vector(11 downto 0);  -- Program Couner + 1

  -- Stack Return address
  signal w_rtnAddr : std_logic_vector(11 downto 0);
  signal w_LDAddr  : std_logic_vector(11 downto 0);
  signal w_ldPCSel : std_logic;

  -- Register File
  signal w_ldRegF       : std_logic;
  signal w_regFIn       : std_logic_vector(7 downto 0);
  signal w_regFOut      : std_logic_vector(7 downto 0);
  signal w_ldRegFileSel : std_logic;

  -- ROM
  signal w_romData : std_logic_vector(15 downto 0);

  -- Opcode decoder
  signal OP_ADI : std_logic;
  signal OP_CMP : std_logic;
  signal OP_LRI : std_logic;
  signal OP_SRI : std_logic;
  signal OP_XRI : std_logic;
  signal OP_IOR : std_logic;
  signal OP_IOW : std_logic;
  signal OP_ARI : std_logic;
  signal OP_ORI : std_logic;
  signal OP_BEZ : std_logic;
  signal OP_BNZ : std_logic;
  signal OP_JMP : std_logic;
  signal OP_JSR : std_logic;
  signal OP_RTS : std_logic;

  -- Stack
  signal w_wrStack : std_logic;
  signal w_rdStack : std_logic;

  -- State Machine
  signal w_GreyCode : std_logic_vector(1 downto 0);

  signal w_GreyCode00 : std_logic;
  signal w_GreyCode01 : std_logic;
  signal w_GreyCode11 : std_logic;
  signal w_GreyCode10 : std_logic;

  -- ALU
  signal w_ALUDataOut : std_logic_vector(7 downto 0);
  signal w_ALUZBit    : std_logic;

  -- Shifter
  signal w_ShiftDataOut : std_logic_vector(7 downto 0);

begin

  --pragma translate_off
  assert
    (INST_ROM_SIZE_PASS = 256) or
    (INST_ROM_SIZE_PASS = 512) or
    (INST_ROM_SIZE_PASS = 1024) or
    (INST_ROM_SIZE_PASS = 2048) or
    (INST_ROM_SIZE_PASS = 4096)
    report "Wrong INST_ROM_SIZE_PASS : " & tost(INST_ROM_SIZE_PASS)
    severity failure;
  --pragma translate_on

  -- -----------------------------------------------------------------------------------------------------------------
  -- Opcode decoder
  OP_SRI <= '1' when ((w_romData(15 downto 12) = OP3_OP) and (w_romData(4 downto 3) = "00")) else '0';  -- Shift/rotate instructions
  OP_RTS <= '1' when ((w_romData(15 downto 12) = OP3_OP) and (w_romData(4 downto 3) = "01")) else '0';  -- Return from subroutine

  -- LRI/CMP
  OP_LRI <= '1' when w_romData(15 downto 12) = LRI_OP else '0';  -- Load immediate to registet
  OP_CMP <= '1' when w_romData(15 downto 12) = CMP_OP else '0';  -- Compare immediate to registet

  -- IO
  OP_IOR <= '1' when w_romData(15 downto 12) = IOR_OP else '0';  -- I/O Read to register
  OP_IOW <= '1' when w_romData(15 downto 12) = IOW_OP else '0';  -- I/O Write from register

  -- ALU operations
  OP_XRI <= '1' when w_romData(15 downto 12) = XRI_OP else '0';  -- XOR immediate to registet
  OP_ORI <= '1' when w_romData(15 downto 12) = ORI_OP else '0';  -- AND immediate to registet
  OP_ARI <= '1' when w_romData(15 downto 12) = ARI_OP else '0';  -- AND immediate to registet
  OP_ADI <= '1' when w_romData(15 downto 12) = ADI_OP else '0';  -- Add immediate to registet

  -- Flow Change
  OP_JSR <= '1' when w_romData(15 downto 12) = JSR_OP else '0';  -- Jump to subroutine
  OP_JMP <= '1' when w_romData(15 downto 12) = JMP_OP else '0';  -- Jump to address
  OP_BEZ <= '1' when w_romData(15 downto 12) = BEZ_OP else '0';  -- Branch if equal to zero
  OP_BNZ <= '1' when w_romData(15 downto 12) = BNZ_OP else '0';  -- Branch if not equal to zero

  -- -----------------------------------------------------------------------------------------------------------------
  -- Program Counter
  -- Up to 12-bits
  -- FPGA compiler will optimize unused higher order bits depending on ROM size
  progCtr : entity staging.iop16_program_counter
    port map
    (
      -- Ins
      i_clock    => i_clock,            -- Clock (50 MHz)
      i_resetN   => i_resetN,
      i_loadPC   => w_loadPC,           -- Load PC control
      i_incPC    => w_incPC,            -- Increment PC control
      i_PCLdValr => w_LDAddr,           -- Load PC value
      -- Outs
      o_ProgCtr  => w_ProgCtr           -- Program Counter
      );
  w_LDAddr <= w_rtnAddr when (OP_RTS = '1') else  -- Return from Subroutine instruction
              w_romData(11 downto 0);
  -- Instruction that affects flow control
  w_ldPCSel <= OP_JMP or OP_RTS or OP_JSR or (OP_BEZ and w_ALUZBit) or (OP_BNZ and (not w_ALUZBit));
  w_loadPC  <= '1' when ((w_GreyCode10 and w_ldPCSel) = '1') else '0';
  w_incPC   <= '1' when ((w_GreyCode10 = '1'))               else '0';

  pcPlus1 <= (w_ProgCtr + 1);  -- Next address past PC is the return address
  -- -----------------------------------------------------------------------------------------------------------------
  -- LIFO - Return address stack
  -- JSR writes to stack, RTS reads from stack
  -- Allowed STACK_DEPTH_PASS values are: 0, 1, >1
  -- Single depth uses no memory
  GEN_STACK_SINGLE : if (STACK_DEPTH_PASS = 1) generate
  begin
    returnAddress : process (i_clock)
    begin
      if rising_edge(i_clock) then
        if i_resetN = '0' then
          w_rtnAddr <= x"000";
        elsif ((OP_JSR and w_GreyCode10) = '1') then
          w_rtnAddr <= w_ProgCtr + 1;
        end if;
      end if;
    end process;
  end generate GEN_STACK_SINGLE;

  -- Deeper depth (STACK_DEPTH_PASS > 1) uses FPGA memory
  GEN_STACK_DEEPER : if (STACK_DEPTH_PASS > 1) generate
  begin
    lifo : entity staging.iop16_lifo
      generic map (
        g_INDEX_WIDTH => STACK_DEPTH_PASS,  -- internal index bit width affecting the LIFO capacity
        g_DATA_WIDTH  => 12             -- bit width of stored data
        )
      port map (
        i_clk  => i_clock,              -- clock signal
        i_rst  => i_resetN,             -- reset signal
        --
        i_we   => w_wrStack,            -- write enable (push)
        i_data => pcPlus1,              -- written data
        i_re   => w_rdStack,            -- read enable (pop)
        o_data => w_rtnAddr             -- read data
        );
  end generate GEN_STACK_DEEPER;

  w_wrStack <= (OP_JSR and w_GreyCode10) when (STACK_DEPTH_PASS > 1) else '0';
  w_rdStack <= (OP_RTS and w_GreyCode11) when (STACK_DEPTH_PASS > 1) else '0';

  -- -----------------------------------------------------------------------------------------------------------------
  -- Register File
  -- Supports up to 16 of 8-bit registers
  RegFile : entity staging.iop16_register_file
    generic map (
      NUM_REGS => 4                     -- 4, 8. or 16
      )
    port map (
      i_clock    => i_clock,
      i_resetN   => i_resetN,
      i_ldRegF   => w_ldRegF,
      i_regSel   => w_romData(11 downto 8),
      i_RegFData => w_regFIn,
      o_RegFData => w_regFOut
      );
  -- Register File data in mux/select
  w_regFIn <= i_peripDataToCPU      when OP_IOR = '1' else  -- I/O Read
              w_ALUDataOut          when OP_ARI = '1' else  -- AND register immediate
              w_ALUDataOut          when OP_ADI = '1' else  -- ADD register immediate
              w_ALUDataOut          when OP_ORI = '1' else  -- OR register immediate
              w_ALUDataOut          when OP_xRI = '1' else  -- Exclusive-OR register immediate
              w_romData(7 downto 0) when OP_LRI = '1' else  -- Load register with immediate value
              w_ShiftDataOut        when OP_SRI = '1' else  -- Output of shiftewr
              x"00";                                        -- Otherwise 0x00
  -- Operations that load the Register File
  w_ldRegFileSel <= OP_LRI or OP_IOR or OP_ARI or OP_ORI or OP_ADI or OP_SRI or OP_xRI;
  w_ldRegF       <= '1' when ((w_GreyCode10 and w_ldRegFileSel) = '1') else '0';

  -- -----------------------------------------------------------------------------------------------------------------
  -- Shifter - Left/Right, Shift/Rotate
  -- Logical/Arithmetic
  -- Shift/rotate flag
  -- Count (cuurently only support shift of 0x1)
  Shifter : entity staging.iop16_shifter
    port map (
      -- Ins
      i_OP_SRI     => OP_SRI,                 -- Shift/Rotate Instruction
      i_ShiftL0A1  => w_romData(5),           -- 0=Logical, 1=Arithmetic
      i_Shift0Rot1 => w_romData(6),           -- Shift=0, Rotate=1
      i_ShiftL0R1  => w_romData(7),           -- 0=left, 1=right
      i_ShiftCount => w_romData(2 downto 0),  -- 0x1
      i_DataIn     => w_regFOut,              -- Data In
      -- Outs
      o_DataOut    => w_ShiftDataOut          -- Data Out
      );

  -- -----------------------------------------------------------------------------------------------------------------
  -- IO Processor ROM
  IopRom : entity staging.iop16_rom
    port map
    (
      address => w_ProgCtr(7 downto 0),
      clock   => i_clock,
      rst     => i_resetN,
      q       => w_romData
      );

  -- -----------------------------------------------------------------------------------------------------------------
  -- Grey code counter - The main state machine
  -- Counts 00 > 01 > 11 > 10
  GreyCodeCounter : entity staging.iop16_grey_code
    port map (
      i_clock    => i_clock,
      i_resetN   => i_resetN,
      o_GreyCode => w_GreyCode
      );

  w_GreyCode00 <= '1' when w_GreyCode = "00" else '0';
  w_GreyCode01 <= '1' when w_GreyCode = "01" else '0';
  w_GreyCode11 <= '1' when w_GreyCode = "11" else '0';
  w_GreyCode10 <= '1' when w_GreyCode = "10" else '0';


  -- -----------------------------------------------------------------------------------------------------------------
  -- ALU Unit
  ALU_Unit : entity staging.iop16_alu
    port map (
      i_clock     => i_clock,
      i_resetN    => i_resetN,
      i_ALU_A_In  => w_regFOut,              -- Register file out
      i_ALU_B_In  => w_romData(7 downto 0),  -- Immediate value
      i_OP_ADI    => OP_ADI,                 -- ADD opcode
      i_OP_CMP    => OP_CMP,                 -- COMPARE opcode
      i_OP_ARI    => OP_ARI,                 -- AND opcode
      i_OP_ORI    => OP_ORI,                 -- OR opcode
      i_OP_XRI    => OP_XRI,                 -- XOR opcode
      i_LatchZBit => w_GreyCode10,
      o_Z_Bit     => w_ALUZBit,              -- Z bit from ALU
      o_ALU_Out   => w_ALUDataOut            -- Register file input mux
      );

  -- -----------------------------------------------------------------------------------------------------------------
  -- Peripheral bus
  -- Routed to the level above the CPU
  o_peripAddr        <= w_romData(7 downto 0);
  o_peripDataFromCPU <= w_regFOut;
  o_peripWr          <= '1' when ((w_GreyCode10 and OP_IOW) = '1')   else '0';
  o_peripRd          <= '1' when ((w_GreyCode(1) = '1') and (OP_IOR = '1')) else '0';


  disas: process is
  begin
    wait until w_GreyCode10 = '1';
    iop16_insn(w_ProgCtr, w_romData, w_rtnAddr, w_regFIn, w_regFOut, w_ALUZBit);
  end process disas;

end beh;
