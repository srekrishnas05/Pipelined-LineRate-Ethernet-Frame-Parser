library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.parser_pkg.all;

entity stage5_l4 is
    generic (
        window_bytes : positive := 96
        );
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        s_win : in std_logic_vector(window_bytes*8-1 downto 0);
        s_ip_proto : in std_logic_vector(7 downto 0);
        s_l4_offset : in unsigned(15 downto 0);
        s_flags : in std_logic_vector(15 downto 0);
        s_valid : in std_logic;
        s_ready : out std_logic;
        s_sof : in std_logic;  
        s_eof : in std_logic;
        m_win : out std_logic_vector(window_bytes*8-1 downto 0);
        m_src_port : out std_logic_vector(15 downto 0);
        m_dst_port : out std_logic_vector(15 downto 0);
        m_payload_off : out unsigned(15 downto 0);
        m_flags : out std_logic_vector(15 downto 0);
        m_valid : out std_logic;
        m_ready : in std_logic;
        m_sof : out std_logic;
        m_eof : out std_logic
        );
end stage5_l4;

architecture Behavioral of stage5_l4 is
  signal v_r : std_logic := '0';
  signal win_r : std_logic_vector(window_bytes*8-1 downto 0) := (others => '0');
  signal srcp_r : std_logic_vector(15 downto 0) := (others => '0');
  signal dstp_r : std_logic_vector(15 downto 0) := (others => '0');
  signal pay_r : unsigned(15 downto 0) := (others => '0');
  signal flags_r: std_logic_vector(15 downto 0) := (others => '0');
  signal sof_r : std_logic := '0';
  signal eof_r : std_logic := '0';

  signal fire : std_logic;
begin
  s_ready <= m_ready;
  fire <= s_valid and m_ready;

  m_valid <= v_r;
  m_win <= win_r;
  m_src_port <= srcp_r;
  m_dst_port <= dstp_r;
  m_payload_off <= pay_r;
  m_flags <= flags_r;
  m_sof <= sof_r;
  m_eof <= eof_r;

  process(clk)
    variable l4off : natural;
    variable proto : std_logic_vector(7 downto 0);
    variable doff : unsigned(3 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        v_r <= '0';
        win_r <= (others => '0');
        srcp_r <= (others => '0');
        dstp_r <= (others => '0');
        pay_r <= (others => '0');
        flags_r <= (others => '0');
        sof_r <= '0';
        eof_r <= '0';
      else
        v_r <= fire;

        if fire = '1' then
          win_r <= s_win;
          sof_r <= s_sof;
          eof_r <= s_eof;

          flags_r <= s_flags;
          srcp_r <= (others => '0');
          dstp_r <= (others => '0');
          pay_r <= (others => '0');

          l4off := to_integer(s_l4_offset);
          proto := s_ip_proto;

          if (l4off + 4 < window_bytes) then
            srcp_r <= get_u16_be(s_win, l4off + 0);
            dstp_r <= get_u16_be(s_win, l4off + 2);

            if proto = x"11" then
              pay_r <= to_unsigned(l4off + 8, 16);

            elsif proto = x"06" then
              if (l4off + 13 < window_bytes) then
                doff := unsigned(get_byte(s_win, l4off + 12)(7 downto 4));
                pay_r <= to_unsigned(l4off, 16) + resize(doff, 16) * 4;
              else
                flags_r(3) <= '1';
                pay_r <= to_unsigned(l4off, 16);
              end if;

            else
              pay_r <= to_unsigned(l4off, 16);
            end if;

          else
            flags_r(3) <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
end Behavioral;

