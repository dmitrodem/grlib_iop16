-------------------------------------------------------------------------------
--! @file      iop16_cpu2.vhd
--! @brief     IOP16 CPU -- 2 proc
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-27
--! @modified  2023-01-09
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
  type state_t is (ST_IDLE, ST_FETCH0, ST_FETCH1, ST_IO, ST_SPARE);

  type cpu_registers_t is record
    r0 : std_logic_vector (7 downto 0);
    r1 : std_logic_vector (7 downto 0);
    r2 : std_logic_vector (7 downto 0);
    r3 : std_logic_vector (7 downto 0);
    r4 : std_logic_vector (7 downto 0);
    r5 : std_logic_vector (7 downto 0);
    r6 : std_logic_vector (7 downto 0);
    r7 : std_logic_vector (7 downto 0);
    rA : std_logic_vector (7 downto 0);
    rB : std_logic_vector (7 downto 0);
    rC : std_logic_vector (7 downto 0);
    rD : std_logic_vector (7 downto 0);
    rE : std_logic_vector (7 downto 0);
  end record cpu_registers_t;

  constant RES_cpu_registers : cpu_registers_t := (
    r0 => x"00", r1 => x"00", r2 => x"00", r3 => x"00",
    r4 => x"00", r5 => x"00", r6 => x"00", r7 => x"00",
    rA => x"00", rB => x"00",
    rC => x"00", rD => x"00", rE => x"00");

  type stack_array_t is array (natural range <>) of std_logic_vector (11 downto 0);
  type stack_ptr_t is (STK0, STK1, STK2, STK3, STK4);

  type stack_registers_t is record
    stack : stack_array_t (0 to 3);
    ptr   : stack_ptr_t;
  end record stack_registers_t;

  constant RES_stack_registers : stack_registers_t := (
    stack => (others => x"000"), ptr => STK0);

  type registers is record
    state    : state_t;
    pc       : std_logic_vector (11 downto 0);
    rom_addr : std_logic_vector (12 downto 0);
    rom_read : std_logic;
    op       : std_logic_vector (15 downto 0);
    reg      : cpu_registers_t;
    stack    : stack_registers_t;
    zero     : std_logic;
    perip_rd : std_logic;
    perip_wr : std_logic;
  end record registers;

  constant RES_registers : registers := (
    state    => ST_IDLE,
    pc       => (others => '0'),
    rom_addr => (others => '0'),
    rom_read => '0',
    op       => (others => '0'),
    reg      => RES_cpu_registers,
    stack    => RES_stack_registers,
    zero     => '0',
    perip_rd => '0',
    perip_wr => '0');

  signal r, rin : registers;

  function get_cpu_reg (
    r     : registers;
    index : std_logic_vector (3 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector (7 downto 0);
  begin  -- function get_cpu_reg
    case index is
      when x"0"   => result := r.reg.r0;
      when x"1"   => result := r.reg.r1;
      when x"2"   => result := r.reg.r2;
      when x"3"   => result := r.reg.r3;
      when x"4"   => result := r.reg.r4;
      when x"5"   => result := r.reg.r5;
      when x"6"   => result := r.reg.r6;
      when x"7"   => result := r.reg.r7;
      when x"8"   => result := x"00";
      when x"9"   => result := x"01";
      when x"a"   => result := r.reg.rA;
      when x"b"   => result := r.reg.rB;
      when x"c"   => result := r.reg.rC;
      when x"d"   => result := r.reg.rD;
      when x"e"   => result := r.reg.rE;
      when x"f"   => result := x"ff";
      when others => null;
    end case;
    return result;
  end function get_cpu_reg;

  procedure set_cpu_reg (
    variable v : out registers;
    index      :     std_logic_vector (3 downto 0);
    value      :     std_logic_vector (7 downto 0)) is
  begin  -- procedure set_cpu_reg
    case index is
      when x"0"   => v.reg.r0 := value;
      when x"1"   => v.reg.r1 := value;
      when x"2"   => v.reg.r2 := value;
      when x"3"   => v.reg.r3 := value;
      when x"4"   => v.reg.r4 := value;
      when x"5"   => v.reg.r5 := value;
      when x"6"   => v.reg.r6 := value;
      when x"7"   => v.reg.r7 := value;
      when x"8"   => null;
      when x"9"   => null;
      when x"a"   => v.reg.rA := value;
      when x"b"   => v.reg.rB := value;
      when x"c"   => v.reg.rC := value;
      when x"d"   => v.reg.rD := value;
      when x"e"   => v.reg.rE := value;
      when x"f"   => null;
      when others => null;
    end case;
  end procedure set_cpu_reg;

  procedure stack_push (
    signal r   : in  registers;
    variable v : out registers;
    value      : in  std_logic_vector (11 downto 0)) is
  begin  -- procedure stack_push
    case r.stack.ptr is
      when STK0 => v.stack.stack(0) := value;
                   v.stack.ptr := STK1;
      when STK1 => v.stack.stack(1) := value;
                   v.stack.ptr := STK2;
      when STK2 => v.stack.stack(2) := value;
                   v.stack.ptr := STK3;
      when STK3 => v.stack.stack(3) := value;
                   v.stack.ptr := STK4;
      when STK4 => null;
    end case;
  end procedure stack_push;

  procedure stack_pop (
    signal r   : in  registers;
    variable v : out registers;
    value      : out std_logic_vector (11 downto 0)) is
  begin  -- procedure stack_pop
    case r.stack.ptr is
      when STK0 => null;
      when STK1 => value := r.stack.stack(0);
                   v.stack.ptr := STK0;
      when STK2 => value := r.stack.stack(1);
                   v.stack.ptr := STK1;
      when STK3 => value := r.stack.stack(2);
                   v.stack.ptr := STK2;
      when STK4 => value := r.stack.stack(3);
                   v.stack.ptr := STK3;
    end case;
  end procedure stack_pop;


begin  -- architecture behav

  comb : process (cpui, r, rst) is
    variable v           : registers;
    variable opcode      : std_logic_vector (15 downto 0);
    variable regnum      : std_logic_vector (3 downto 0);
    variable sreg        : std_logic_vector (7 downto 0);
    variable treg        : std_logic_vector (7 downto 0);
    variable shift_right : boolean;
    variable shift_roll  : boolean;
    variable shift_arith : boolean;
    variable npc         : std_logic_vector (11 downto 0);
    variable immed       : std_logic_vector (7 downto 0);
    variable perip_addr  : std_logic_vector (7 downto 0);
    variable perip_data  : std_logic_vector (7 downto 0);
    variable pc_addr     : std_logic_vector (11 downto 0);

    variable rom_addr : std_logic_vector (12 downto 0);
    variable rom_read : std_logic;

  begin  -- process comb

    v := r;

    case r.state is
      when ST_IDLE   => v.state := ST_FETCH0;
      when ST_FETCH0 => v.state := ST_FETCH1;
      when ST_FETCH1 => v.state := ST_IO;
      when ST_IO     => v.state := ST_SPARE;
      when ST_SPARE  => v.state := ST_FETCH0;
    end case;

    rom_read := '0';
    if   (r.state = ST_IDLE) then
      rom_read := '1';
    elsif (r.state = ST_FETCH0) then
      v.op(15 downto 8) := cpui.rom_data(7 downto 0);
      rom_addr := r.pc & "1";
      rom_read := '1';
    elsif (r.state = ST_FETCH1) then
      v.op(7 downto 0) := cpui.rom_data(7 downto 0);
    elsif (r.state = ST_IO) then
      null;
    elsif (r.state = ST_SPARE) then
      rom_addr := r.pc & "0";
      rom_read := '1';
    end if;


    if r.state = ST_FETCH0 then
      opcode := r.op;
    else
      opcode := v.op;
    end if;
    regnum     := opcode(11 downto 8);
    sreg       := get_cpu_reg(r, regnum);
    treg       := sreg;
    npc        := r.pc + 1;
    immed      := opcode(7 downto 0);
    perip_addr := opcode(7 downto 0);
    perip_data := x"00";
    pc_addr    := opcode(11 downto 0);

    shift_right := (opcode(7) = '1');
    shift_roll  := (opcode(6) = '1');
    shift_arith := (opcode(5) = '1');

    if r.state = ST_FETCH1 then
      case opcode (15 downto 12) is
        when OP0_OP => null;
        when OP1_OP => null;
        when OP2_OP => null;
        when OP3_OP =>
          if opcode(4 downto 3) = "00" then  -- SHIFT Op
            if not shift_roll then
              if not shift_arith then        -- Logic shift
                if not shift_right then
                  treg := sreg (6 downto 0) & '0';
                else
                  treg := '0' & sreg (7 downto 1);
                end if;
              else                           -- Arithmetic shift
                if not shift_right then
                  treg := sreg (6 downto 0) & '0';
                else
                  treg := sreg(7) & sreg (7 downto 1);
                end if;
              end if;
            else                             -- Roll
              if not shift_right then
                treg := sreg (6 downto 0) & sreg(7);
              else
                treg := sreg(0) & sreg (7 downto 1);
              end if;
            end if;
          elsif opcode (4 downto 3) = "01" then
            stack_pop(r, v, npc);
          end if;
        when LRI_OP =>
          treg := immed;
        when CMP_OP =>
          if sreg = immed then v.zero := '1'; else v.zero := '0'; end if;
        when IOR_OP =>
          v.perip_rd := '1';
          treg       := cpui.perip_data;
        when IOW_OP =>
          v.perip_wr := '1';
          perip_data := sreg;
        when XRI_OP =>
          treg                        := sreg xor immed;
          if treg = x"00" then v.zero := '1'; else v.zero := '0'; end if;
        when ORI_OP =>
          treg                        := sreg or immed;
          if treg = x"00" then v.zero := '1'; else v.zero := '0'; end if;
        when ARI_OP =>
          treg                        := sreg and immed;
          if treg = x"00" then v.zero := '1'; else v.zero := '0'; end if;
        when ADI_OP =>
          treg                        := sreg + immed;
          if treg = x"00" then v.zero := '1'; else v.zero := '0'; end if;
        when JSR_OP =>
          stack_push(r, v, r.pc + 1);
          npc := pc_addr;
        when JMP_OP =>
          npc := pc_addr;
        when BEZ_OP =>
          if r.zero = '1' then npc := pc_addr; end if;
        when BNZ_OP =>
          if r.zero /= '1' then npc := pc_addr; end if;
        when others => null;
      end case;
    end if;

    if r.state = ST_IO then
      v.pc := r.pc + 1;
    end if;

    if rst = '0' then
      v := RES_registers;
    end if;

    rin <= v;

    cpuo.rom_read    <= rom_read;
    cpuo.rom_address <= rom_addr (11 downto 0);

  end process comb;


  seq : process (clk) is
  begin  -- process seq
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process seq;

end architecture behav;
