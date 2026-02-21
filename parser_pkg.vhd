library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package parser_pkg is
  subtype byte_t is std_logic_vector(7 downto 0);
  subtype u16_t  is std_logic_vector(15 downto 0);
  subtype u32_t  is std_logic_vector(31 downto 0);

  function get_byte(win : std_logic_vector; idx : natural) return byte_t;
  function get_u16_be(win : std_logic_vector; idx : natural) return u16_t;
  function get_u32_be(win : std_logic_vector; idx : natural) return u32_t;

  function popcount_keep(keep : std_logic_vector) return natural;

  function set_byte(
    win : std_logic_vector;
    idx : natural;
    b   : byte_t
  ) return std_logic_vector;

  function shift_left_bytes(
    win     : std_logic_vector;
    n_bytes : natural
  ) return std_logic_vector;
end package;

package body parser_pkg is

  function get_byte(win : std_logic_vector; idx : natural) return byte_t is
    constant WBYTES : natural := win'length / 8;
    variable res    : byte_t := (others => '0');
    variable lo, hi : integer;
  begin
    if idx >= WBYTES then
      return res;
    end if;

    hi := integer(win'length - 1 - idx*8);
    lo := hi - 7;

    if (hi > win'length - 1) or (lo < 0) then
      return res;
    end if;

    res := win(hi downto lo);
    return res;
  end function;

  function get_u16_be(win : std_logic_vector; idx : natural) return u16_t is
    variable b0, b1 : byte_t;
  begin
    b0 := get_byte(win, idx);
    b1 := get_byte(win, idx+1);
    return b0 & b1;
  end function;

  function get_u32_be(win : std_logic_vector; idx : natural) return u32_t is
    variable b0, b1, b2, b3 : byte_t;
  begin
    b0 := get_byte(win, idx);
    b1 := get_byte(win, idx+1);
    b2 := get_byte(win, idx+2);
    b3 := get_byte(win, idx+3);
    return b0 & b1 & b2 & b3;
  end function;

  function popcount_keep(keep : std_logic_vector) return natural is
    variable c : natural := 0;
  begin
    for i in keep'range loop
      if keep(i) = '1' then
        c := c + 1;
      end if;
    end loop;
    return c;
  end function;

  function set_byte(
    win : std_logic_vector;
    idx : natural;
    b   : byte_t
  ) return std_logic_vector is
    variable outv   : std_logic_vector(win'range) := win;
    constant WBYTES : natural := win'length / 8;
    variable lo, hi : integer;
  begin
    if idx >= WBYTES then
      return outv;
    end if;

    hi := integer(win'length - 1 - idx*8);
    lo := hi - 7;

    if (hi > win'length - 1) or (lo < 0) then
      return outv;
    end if;

    outv(hi downto lo) := b;
    return outv;
  end function;

  function shift_left_bytes(
    win     : std_logic_vector;
    n_bytes : natural
  ) return std_logic_vector is
    constant WBYTES : natural := win'length / 8;
    variable outv   : std_logic_vector(win'range) := (others => '0');
    variable src_i  : natural;
  begin
    if n_bytes = 0 then
      return win;
    end if;

    if n_bytes >= WBYTES then
      return (win'range => '0');
    end if;

    for i in 0 to WBYTES-1 loop
      src_i := i + n_bytes;
      if src_i < WBYTES then
        outv := set_byte(outv, i, get_byte(win, src_i));
      else
        outv := set_byte(outv, i, (others => '0'));
      end if;
    end loop;

    return outv;
  end function;

end package body;
