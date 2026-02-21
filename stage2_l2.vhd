library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.parser_pkg.all;

entity stage2_l2 is
    generic (
        window_bytes : positive := 96
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        s_win : in std_logic_vector(window_bytes*8-1 downto 0);
        s_have14 : in std_logic;
        s_valid : in std_logic;
        s_ready : out std_logic;
        s_sof : in std_logic;
        s_eof : in std_logic;
        m_win : out std_logic_vector(window_bytes*8-1 downto 0);
        m_have14 : out std_logic;
        m_dst_mac : out std_logic_vector(47 downto 0);
        m_src_mac : out std_logic_vector(47 downto 0);
        m_tpid_or_type : out std_logic_vector(15 downto 0);
        m_valid : out std_logic;
        m_ready : in std_logic;
        m_sof : out std_logic;
        m_eof : out std_logic
        );    
end stage2_l2;
    
architecture Behavioral of stage2_l2 is
  signal v_r      : std_logic := '0';
  signal win_r    : std_logic_vector(window_bytes*8-1 downto 0) := (others => '0');
  signal have14_r : std_logic := '0';
  signal dst_r    : std_logic_vector(47 downto 0) := (others => '0');
  signal src_r    : std_logic_vector(47 downto 0) := (others => '0');
  signal tpid_r   : std_logic_vector(15 downto 0) := (others => '0');
  signal sof_r    : std_logic := '0';
  signal eof_r    : std_logic := '0';

  signal fire     : std_logic;
begin
  s_ready <= m_ready;

  fire <= s_valid and m_ready;

  m_valid <= v_r;
  m_win <= win_r;
  m_have14 <= have14_r;
  m_dst_mac <= dst_r;
  m_src_mac <= src_r;
  m_tpid_or_type <= tpid_r;
  m_sof <= sof_r;
  m_eof <= eof_r;

  process(clk)
    variable mac : std_logic_vector(47 downto 0);
    variable b   : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        v_r <= '0';
        win_r <= (others => '0');
        have14_r <= '0';
        dst_r<= (others => '0');
        src_r <= (others => '0');
        tpid_r <= (others => '0');
        sof_r <= '0';
        eof_r <= '0';
      else
        v_r <= fire;

        if fire = '1' then
          win_r <= s_win;
          have14_r <= s_have14;
          sof_r <= s_sof;
          eof_r <= s_eof;

          dst_r <= (others => '0');
          src_r <= (others => '0');
          tpid_r <= (others => '0');

          if (s_have14 = '1') then
            mac := (others => '0');
            for i in 0 to 5 loop
              b := get_byte(s_win, i);
              mac(47 - i*8 downto 40 - i*8) := b;
            end loop;
            dst_r <= mac;

            mac := (others => '0');
            for i in 0 to 5 loop
              b := get_byte(s_win, 6+i);
              mac(47 - i*8 downto 40 - i*8) := b;
            end loop;
            src_r <= mac;

            tpid_r <= get_u16_be(s_win, 12);
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;

