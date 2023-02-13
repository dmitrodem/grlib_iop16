library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.stdlib.all;
use grlib.amba.all;

-- pragma translate_off
library  std;
use      std.standard.all;
use      std.textio.all;
-- pragma translate_on

package iop16_pkg is

  constant OP0_OP : std_logic_vector(3 downto 0) := "0000";
  constant OP1_OP : std_logic_vector(3 downto 0) := "0001";
  constant OP2_OP : std_logic_vector(3 downto 0) := "0010";
  constant OP3_OP : std_logic_vector(3 downto 0) := "0011";
  constant LRI_OP : std_logic_vector(3 downto 0) := "0100";
  constant CMP_OP : std_logic_vector(3 downto 0) := "0101";
  constant IOR_OP : std_logic_vector(3 downto 0) := "0110";
  constant IOW_OP : std_logic_vector(3 downto 0) := "0111";
  constant XRI_OP : std_logic_vector(3 downto 0) := "1000";
  constant ORI_OP : std_logic_vector(3 downto 0) := "1001";
  constant ARI_OP : std_logic_vector(3 downto 0) := "1010";
  constant ADI_OP : std_logic_vector(3 downto 0) := "1011";
  constant JSR_OP : std_logic_vector(3 downto 0) := "1100";
  constant JMP_OP : std_logic_vector(3 downto 0) := "1101";
  constant BEZ_OP : std_logic_vector(3 downto 0) := "1110";
  constant BNZ_OP : std_logic_vector(3 downto 0) := "1111";

  type iop16_cpu_in is record
    perip_data : std_logic_vector (7 downto 0);
    rom_data : std_logic_vector (15 downto 0);
    irq : std_logic_vector (3 downto 0);
    disas : std_logic;
  end record iop16_cpu_in;

  type iop16_cpu_out is record
    perip_address : std_logic_vector (7 downto 0);
    perip_data    : std_logic_vector (7 downto 0);
    perip_mask    : std_logic_vector (7 downto 0);
    perip_wr      : std_logic;
    perip_rd      : std_logic;
    rom_address   : std_logic_vector (11 downto 0);
    rom_read      : std_logic;
    grey_code     : std_logic_vector (1 downto 0);
    -- debug
    errcnt        : std_logic_vector (3 downto 0);
    error         : std_logic;
    halt          : std_logic;
    -- interrupt handling
    irq_ack       : std_logic;
  end record iop16_cpu_out;

  type iop16_gpio_in is record
    data : std_logic_vector (7 downto 0);
  end record iop16_gpio_in;

  type iop16_gpio_out is record
    data : std_logic_vector (7 downto 0);
    oen  : std_logic_vector (7 downto 0);
  end record iop16_gpio_out;

  procedure iop16_insn (
    w_ProgCtr : std_logic_vector (11 downto 0);
    w_romData : std_logic_vector (15 downto 0);
    w_rtnAddr : std_logic_vector;
    w_regFIn  : std_logic_vector;
    w_regFOut : std_logic_vector;
    w_ALUZBit : std_logic);

  type edacdectype is record
    data : std_logic_vector(31 downto 0);
    err  : std_ulogic;
    merr : std_ulogic;
  end record;

  --calculates 7 BCH(32,7) checkbits from the 32-bit dataword d
  function edacencode( d  : in std_logic_vector(31 downto 0) )
    return std_logic_vector;

  --calculates the syndrome from inputs checkbits (cb) and checkbits
  --calculated from input data d.
  function edacsyngen( d  : in std_logic_vector(31 downto 0);
                       cb : in std_logic_vector(6 downto 0) )
    return std_logic_vector;

  --corrects any single errors in data word d with syndrome syn.
  --single error and multiple error indication signals are also set.
  --single error is also set if one of the checkbits is wrong.
  function edacdecode( d   : in std_logic_vector(31 downto 0);
                       syn : in std_logic_vector(6 downto 0) )
    return edacdectype;

end package iop16_pkg;

package body iop16_pkg is

  procedure iop16_insn (
    w_ProgCtr : std_logic_vector (11 downto 0);
    w_romData : std_logic_vector (15 downto 0);
    w_rtnAddr : std_logic_vector;
    w_regFIn  : std_logic_vector;
    w_regFOut : std_logic_vector;
    w_ALUZBit : std_logic) is
    -- pragma translate_off
    variable l : line;
    variable reg : line;
    variable imm : line;
    variable adr : line;
  -- pragma translate_on
  begin
    -- pragma translate_off
    write(reg, string'("r") & integer'image(conv_integer(w_romData(11 downto 8))));
    write(imm, tost(w_romData(7 downto 0)));
    write(adr, tost(w_romData(11 downto 0)));
    write(l, now, right, 15);
    write(l, " : " & tost(w_ProgCtr) & " ");
    case w_romData(15 downto 12) is
      when "0000" =>
        write(l, string'("RS0"));
      when "0001" =>
        write(l, string'("RS1"));
      when "0010" =>
        write(l, string'("RS2"));
      when "0011" =>
        if    w_romData(7 downto 3) = "00000" then
          write(l, string'("SLL ") & reg.all);
        elsif w_romData(7 downto 3) = "10000" then
          write(l, string'("SLR ") & reg.all);
        elsif w_romData(7 downto 3) = "00100" then
          write(l, string'("SAL ") & reg.all);
        elsif w_romData(7 downto 3) = "10100" then
          write(l, string'("SAR ") & reg.all);
        elsif w_romData(7 downto 6) = "01" and w_romData(4 downto 3) = "00" then
          write(l, string'("RRL ") & reg.all);
        elsif w_romData(7 downto 6) = "11" and w_romData(4 downto 3) = "00" then
          write(l, string'("RRR ") & reg.all);
        elsif w_romData(4 downto 3) = "01" then
          write(l, string'("RTS [") & tost(w_rtnAddr) & string'("]"));
        elsif w_romData(4 downto 3) = "10" then
          write(l, string'("RS3"));
        end if;
      when "0100" =>
        write(l, string'("LRI ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "0101" =>
        write(l, string'("CMP ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "0110" =>
        write(l, string'("IOR ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "0111" =>
        write(l, string'("IOW ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFOut) & "]");
      when "1000" =>
        write(l, string'("XRI ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "1001" =>
        write(l, string'("ORI ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "1010" =>
        write(l, string'("ARI ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "1011" =>
        write(l, string'("ADI ") & reg.all & string'(", ") & imm.all & " [" & tost(w_regFIn) & "]");
      when "1100" =>
        write(l, string'("JSR ") & adr.all);
      when "1101" =>
        write(l, string'("JMP ") & adr.all);
      when "1110" =>
        write(l, string'("BEZ ") & adr.all & " [" & tost(w_ALUZBit) & "]");
      when "1111" =>
        write(l, string'("BNZ ") & adr.all & " [" & tost(w_ALUZBit) & "]");
      when others => null;
    end case;
    write(l, string'(" "));
    writeline(output, l);
    deallocate(reg);
    deallocate(imm);
    deallocate(adr);
  -- pragma translate_on
  end procedure;


  function edacencode( d : in std_logic_vector(31 downto 0) )
    return std_logic_vector is
    variable cb : std_logic_vector(6 downto 0);
  begin
    cb(0) := d(0) xor d(4) xor d(6) xor d(7) xor d(8) xor d(9) xor
             d(11) xor d(14) xor d(17) xor d(18) xor d(19) xor d(21)
             xor d(26) xor d(28) xor d(29) xor d(31);
    cb(1) := d(0) xor d(1) xor d(2) xor d(4) xor d(6) xor d(8) xor
             d(10) xor d(12) xor d(16) xor d(17) xor d(18) xor d(20)
             xor d(22) xor d(24) xor d(26) xor d(28);
    cb(2) := not ( d(0) xor d(3) xor d(4) xor d(7) xor d(9) xor d(10) xor
                   d(13) xor d(15) xor d(16) xor d(19) xor d(20) xor d(23)
                   xor d(25) xor d(26) xor d(29) xor d(31) );
    cb(3) := not ( d(0) xor d(1) xor d(5) xor d(6) xor d(7) xor d(11) xor
                   d(12) xor d(13) xor d(16) xor d(17) xor d(21) xor d(22)
                   xor d(23) xor d(27) xor d(28) xor d(29) );
    cb(4) := d(2) xor d(3) xor d(4) xor d(5) xor d(6) xor d(7) xor
             d(14) xor d(15) xor d(18) xor d(19) xor d(20) xor d(21)
             xor d(22) xor d(23) xor d(30) xor d(31);
    cb(5) := d(8) xor d(9) xor d(10) xor d(11) xor d(12) xor d(13) xor
             d(14) xor d(15) xor d(24) xor d(25) xor d(26) xor d(27)
             xor d(28) xor d(29) xor d(30) xor d(31);
    cb(6) := d(0) xor d(1) xor d(2) xor d(3) xor d(4) xor d(5) xor
             d(6) xor d(7) xor d(24) xor d(25) xor d(26) xor d(27)
             xor d(28) xor d(29) xor d(30) xor d(31);
    return cb;
  end function;

  function edacsyngen( d  : in std_logic_vector(31 downto 0);
                       cb : in std_logic_vector(6 downto 0) )
    return std_logic_vector is
    variable syn : std_logic_vector(6 downto 0);
    variable intcb : std_logic_vector(6 downto 0);
  begin
    intcb := edacencode(d);
    syn := cb xor intcb;
    return syn;
  end function;

  function edacdecode( d   : in std_logic_vector(31 downto 0);
                       syn : in std_logic_vector(6 downto 0) )
    return edacdectype is
    variable co : edacdectype;
  begin
    co.data := d; co.err := '1'; co.merr := '0';
    case syn is
      when "0000000" => co.err := '0';
      when "1001111" => co.data(0) := not co.data(0);
      when "1001010" => co.data(1) := not co.data(1);
      when "1010010" => co.data(2) := not co.data(2);
      when "1010100" => co.data(3) := not co.data(3);
      when "1010111" => co.data(4) := not co.data(4);
      when "1011000" => co.data(5) := not co.data(5);
      when "1011011" => co.data(6) := not co.data(6);
      when "1011101" => co.data(7) := not co.data(7);
      when "0100011" => co.data(8) := not co.data(8);
      when "0100101" => co.data(9) := not co.data(9);
      when "0100110" => co.data(10) := not co.data(10);
      when "0101001" => co.data(11) := not co.data(11);
      when "0101010" => co.data(12) := not co.data(12);
      when "0101100" => co.data(13) := not co.data(13);
      when "0110001" => co.data(14) := not co.data(14);
      when "0110100" => co.data(15) := not co.data(15);
      when "0001110" => co.data(16) := not co.data(16);
      when "0001011" => co.data(17) := not co.data(17);
      when "0010011" => co.data(18) := not co.data(18);
      when "0010101" => co.data(19) := not co.data(19);
      when "0010110" => co.data(20) := not co.data(20);
      when "0011001" => co.data(21) := not co.data(21);
      when "0011010" => co.data(22) := not co.data(22);
      when "0011100" => co.data(23) := not co.data(23);
      when "1100010" => co.data(24) := not co.data(24);
      when "1100100" => co.data(25) := not co.data(25);
      when "1100111" => co.data(26) := not co.data(26);
      when "1101000" => co.data(27) := not co.data(27);
      when "1101011" => co.data(28) := not co.data(28);
      when "1101101" => co.data(29) := not co.data(29);
      when "1110000" => co.data(30) := not co.data(30);
      when "1110101" => co.data(31) := not co.data(31);
      when "0000001" => null;
      when "0000010" => null;
      when "0000100" => null;
      when "0001000" => null;
      when "0010000" => null;
      when "0100000" => null;
      when "1000000" => null;
      when others => co.merr := '1'; co.err := '0';
    end case;
    return co;
  end function;


end package body iop16_pkg;
