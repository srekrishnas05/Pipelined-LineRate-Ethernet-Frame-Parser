library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.parser_pkg.all;

entity stage1_aligner is
  generic (
    BPC          : positive := 1;
    WINDOW_BYTES : positive := 96
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;

    s_data : in  std_logic_vector(BPC*8-1 downto 0);
    s_keep : in  std_logic_vector(BPC-1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    s_sof : in  std_logic;
    s_eof : in  std_logic;

    m_win : out std_logic_vector(WINDOW_BYTES*8-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic;
    m_in_frame : out std_logic;
    m_byte_count : out unsigned(15 downto 0);

    m_have14 : out std_logic;
    m_have18 : out std_logic;
    m_have22 : out std_logic;
    m_have60 : out std_logic;

    m_sof : out std_logic;
    m_eof : out std_logic
  );
end entity;

architecture Behavioral of stage1_aligner is
  subtype byte_t is std_logic_vector(7 downto 0);
  constant WINW : natural := WINDOW_BYTES*8;

  signal win_r : std_logic_vector(WINW-1 downto 0) := (others => '0');
  signal in_frame_r : std_logic := '0';
  signal byte_cnt_r : unsigned(15 downto 0) := (others => '0');

  signal fire : std_logic;

  function beat_byte(d : std_logic_vector; i : natural) return byte_t is
    variable lo, hi : integer;
    variable res : byte_t := (others => '0');
  begin
    lo := integer(i*8);
    hi := lo + 7;
    if (hi > d'high) or (lo < d'low) then
      return res;
    end if;
    res := d(hi downto lo);
    return res;
  end function;

begin
  s_ready <= m_ready;
  fire <= s_valid and m_ready;

  m_win <= win_r;
  m_in_frame <= in_frame_r;
  m_byte_count <= byte_cnt_r;

  m_have14 <= '1' when byte_cnt_r >= to_unsigned(14, byte_cnt_r'length) else '0';
  m_have18 <= '1' when byte_cnt_r >= to_unsigned(18, byte_cnt_r'length) else '0';
  m_have22 <= '1' when byte_cnt_r >= to_unsigned(22, byte_cnt_r'length) else '0';
  m_have60 <= '1' when byte_cnt_r >= to_unsigned(60, byte_cnt_r'length) else '0';

  m_valid <= fire;
  m_sof <= s_sof and fire;
  m_eof <= s_eof and fire;

  process(clk)
    variable w : std_logic_vector(WINW-1 downto 0);
    variable bc : unsigned(15 downto 0);
    variable idx : natural;
    variable b : byte_t;
    variable wrote : natural;
  begin
    if rising_edge(clk) then
      if rst='1' then
        win_r <= (others => '0');
        in_frame_r <= '0';
        byte_cnt_r <= (others => '0');
      else
        if fire='1' then
          w  := win_r;
          bc := byte_cnt_r;

          if s_sof='1' then
            w  := (others => '0');
            bc := (others => '0');
            in_frame_r <= '1';
          end if;

          wrote := 0;
          for i in 0 to BPC-1 loop
            if s_keep(i)='1' then
              idx := to_integer(bc) + wrote;
              if idx < WINDOW_BYTES then
                b := beat_byte(s_data, i);
                w := set_byte(w, idx, b);
              end if;
              wrote := wrote + 1;
            end if;
          end loop;

          win_r <= w;
          byte_cnt_r <= bc + to_unsigned(wrote, bc'length);

          if s_eof='1' then
            in_frame_r <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;

