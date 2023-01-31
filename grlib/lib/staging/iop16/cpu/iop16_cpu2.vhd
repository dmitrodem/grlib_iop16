-------------------------------------------------------------------------------
--! @file      iop16_cpu2.vhd
--! @brief     IOP16 CPU -- 2 proc
--! @details
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2022-12-27
--! @modified  2023-01-27
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
  type state_t is (ST_IDLE, ST_FETCH0, ST_FETCH1, ST_CHECK, ST_RUN0, ST_RUN1);

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
    checksum : std_logic_vector (7 downto 0);
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
    checksum => (others => '0'),
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

  function decode_bit (
    n : std_logic_vector (2 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector (7 downto 0);
  begin  -- function decode_bit
    case n is
      when "000" => result := "00000001";
      when "001" => result := "00000010";
      when "010" => result := "00000100";
      when "011" => result := "00001000";
      when "100" => result := "00010000";
      when "101" => result := "00100000";
      when "110" => result := "01000000";
      when "111" => result := "10000000";
      when others => null;
    end case;
    return result;
  end function decode_bit;

  function shift_left (
    v : std_logic_vector (7 downto 0);
    n : std_logic_vector (2 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector (7 downto 0);
  begin
    case n is
      when "000" => result := v (7 downto 0);
      when "001" => result := v (6 downto 0) & "0";
      when "010" => result := v (5 downto 0) & "00";
      when "011" => result := v (4 downto 0) & "000";
      when "100" => result := v (3 downto 0) & "0000";
      when "101" => result := v (2 downto 0) & "00000";
      when "110" => result := v (1 downto 0) & "000000";
      when "111" => result := v (0 downto 0) & "0000000";
      when others => null;
    end case;
    return result;
  end function shift_left;

  function shift_right (
    v : std_logic_vector (7 downto 0);
    n : std_logic_vector (2 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector (7 downto 0);
  begin
    case n is
      when "000" => result :=             v (7 downto 0);
      when "001" => result := "0"       & v (7 downto 1);
      when "010" => result := "00"      & v (7 downto 2);
      when "011" => result := "000"     & v (7 downto 3);
      when "100" => result := "0000"    & v (7 downto 4);
      when "101" => result := "00000"   & v (7 downto 5);
      when "110" => result := "000000"  & v (7 downto 6);
      when "111" => result := "0000000" & v (7 downto 7);
      when others => null;
    end case;
    return result;
  end function shift_right;

  function zflag (
    s : std_logic_vector (7 downto 0))
    return std_logic is
  begin  -- function zflag
    if s = x"00" then
      return '1';
    else
      return '0';
    end if;
  end function zflag;

begin  -- architecture behav

  comb : process (cpui, r, rst) is
    variable v           : registers;

    variable op : std_logic_vector (15 downto 0);
    variable opcode : std_logic_vector (3 downto 0);
    variable iRd : std_logic_vector (3 downto 0);
    variable Rd, Rs1, Rs2, Rio : std_logic_vector (7 downto 0);
    variable imm8 : std_logic_vector (7 downto 0);
    variable pc_address : std_logic_vector (11 downto 0);
    variable iomask : std_logic_vector (7 downto 0);
    variable iovalue : std_logic_vector (7 downto 0);
    variable ioaddr : std_logic_vector (7 downto 0);

    variable nshift : std_logic_vector (2 downto 0);
    variable npc  : std_logic_vector (11 downto 0);

    variable rom_addr : std_logic_vector (12 downto 0);
    variable rom_read : std_logic;

    variable write_reg : std_logic;

  begin  -- process comb

    v := r;

    v.perip_rd := '0';
    v.perip_wr := '0';

    case r.state is
      when ST_IDLE   => v.state := ST_FETCH0;
      when ST_FETCH0 => v.state := ST_FETCH1;
      when ST_FETCH1 => v.state := ST_CHECK;
      when ST_CHECK  => v.state := ST_RUN0;
      when ST_RUN0   => v.state := ST_FETCH0;
      when ST_RUN1   => v.state := ST_FETCH0;
    end case;

    -- Fetch instruction
    rom_read := '0';
    rom_addr := r.pc & "0";
    if   (r.state = ST_IDLE) then
      rom_read := '1';
    elsif (r.state = ST_FETCH0) then
      v.op(15 downto 8) := cpui.rom_data(7 downto 0);
      rom_addr := r.pc & "1";
      rom_read := '1';
    elsif (r.state = ST_FETCH1) then
      v.op(7 downto 0) := cpui.rom_data(7 downto 0);
      rom_addr := not ("0" & r.pc);
      rom_read := '1';
    elsif (r.state = ST_CHECK) then
      v.checksum := cpui.rom_data(7 downto 0);
    elsif (r.state = ST_RUN0) then
      rom_read := '1';
    end if;

    -- Parse opcode
    op         := r.op;
    opcode     := op(15 downto 12);
    iRd        := op(11 downto 8);
    Rd         := get_cpu_reg(r, iRd);
    Rs1        := get_cpu_reg(r, op(7 downto 4));
    Rs2        := get_cpu_reg(r, op(3 downto 0));
    Rio        := get_cpu_reg(r, op(11 downto 8));
    imm8       := op(7 downto 0);
    pc_address := op(11 downto 0);

    iomask  := x"FF";
    iovalue := x"00";
    ioaddr  := imm8;

    nshift := op(2 downto 0);
    npc := r.pc + 1;

    write_reg := '0';

    case opcode is
      when x"0" => null;
      when x"1" => null;
      when x"2" =>                      -- bset/bclr
        iomask := decode_bit(op(10 downto 8));
        if op(11) = '0' then
          iovalue := x"00";
        else
          iovalue := x"FF";
        end if;
        if r.state = ST_RUN0 then
          v.perip_wr := '1';
        end if;
      when x"3" =>                      -- sll/slr
        if op(3) = '0' then
          Rd := shift_left(Rs1, nshift);
        else
          Rd := shift_right(Rs1, nshift);
        end if;
        write_reg := '1';
      when x"4" =>                      -- lri
        Rd := imm8;
        write_reg := '1';
      when x"5" =>                      -- rts
        stack_pop(r, v, npc);
      when x"6" =>                      -- ior
        if r.state = ST_CHECK then
          v.perip_rd := '1';
        end if;
        Rd := cpui.perip_data;
        write_reg := '1';
      when x"7" =>                      -- iow
        if r.state = ST_RUN0 then
          v.perip_wr := '1';
        end if;
        iovalue := Rio;
      when x"8" =>                      -- xri
        Rd := Rs1 xor Rs2;
        v.zero := zflag(Rd);
        write_reg := '1';
      when x"9" =>                      -- ori
        Rd := Rs1 or Rs2;
        v.zero := zflag(Rd);
        write_reg := '1';
      when x"A" =>                      -- ari
        Rd := Rs1 and Rs2;
        v.zero := zflag(Rd);
        write_reg := '1';
      when x"B" =>                      -- adi
        Rd := Rs1 + Rs2;
        v.zero := zflag(Rd);
        write_reg := '1';
      when x"C" =>                      -- jsr
        stack_push(r, v, r.pc + 1);
        npc := pc_address;
      when x"D" =>                      -- jmp
        npc := pc_address;
      when x"E" =>                      -- bez
        if r.zero = '1' then
          npc := pc_address;
        end if;
      when x"F" =>                      -- bnz
        if r.zero /= '1' then
          npc := pc_address;
        end if;
      when others => null;
    end case;

    if r.state = ST_RUN0 then
      if write_reg = '1' then
        set_cpu_reg(v, iRd, Rd);
      end if;
      v.pc := npc;
      rom_addr := npc & "0";
    end if;

    if rst = '0' then
      v := RES_registers;
    end if;

    rin <= v;

    cpuo.perip_address <= ioaddr;
    cpuo.perip_data    <= iovalue;
    cpuo.perip_mask    <= iomask;
    cpuo.perip_wr      <= r.perip_wr;
    cpuo.perip_rd      <= r.perip_rd;

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
