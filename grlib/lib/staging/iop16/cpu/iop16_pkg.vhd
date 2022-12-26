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
  end record iop16_cpu_in;

  type iop16_cpu_out is record
    perip_address : std_logic_vector (7 downto 0);
    perip_data    : std_logic_vector (7 downto 0);
    perip_wr      : std_logic;
    perip_rd      : std_logic;
    rom_address   : std_logic_vector (11 downto 0);
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

end package iop16_pkg;

package body iop16_pkg is

  procedure iop16_insn (
    w_ProgCtr : std_logic_vector (11 downto 0);
    w_romData : std_logic_vector (15 downto 0);
    w_rtnAddr : std_logic_vector;
    w_regFIn  : std_logic_vector;
    w_regFOut : std_logic_vector;
    w_ALUZBit : std_logic) is
    variable l : line;
    variable reg : line;
    variable imm : line;
    variable adr : line;
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

end package body iop16_pkg;
