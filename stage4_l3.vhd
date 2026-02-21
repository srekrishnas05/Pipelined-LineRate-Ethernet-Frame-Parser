library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.parser_pkg.all;

entity stage4_l3 is
    generic (
        window_bytes : positive := 96
        );
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        s_win : in std_logic_vector(window_bytes*8-1 downto 0);
        s_ethertype : in std_logic_vector(15 downto 0);
        s_l3_offset : in unsigned(15 downto 0);
        s_valid : in std_logic;
        s_ready : out std_logic;
        s_sof : in std_logic;
        s_eof : in std_logic;
        m_win : out std_logic_vector(window_bytes*8-1 downto 0);
        m_ip_ver : out std_logic_vector(3 downto 0);
        m_ip_proto : out std_logic_vector(7 downto 0);
        m_src_ip4 : out std_logic_vector(31 downto 0);
        m_dst_ip4 : out std_logic_vector(31 downto 0);
        m_l4_offset : out unsigned(15 downto 0);
        m_flags : out std_logic_vector(15 downto 0);
        m_valid : out std_logic;
        m_ready : in std_logic;
        m_sof : out std_logic;
        m_eof : out std_logic
        );
end stage4_l3;

architecture Behavioral of stage4_l3 is
  signal v_r : std_logic := '0';
  signal win_r : std_logic_vector(window_bytes*8-1 downto 0) := (others => '0');
  signal ip_ver_r : std_logic_vector(3 downto 0) := (others => '0');
  signal ip_proto_r : std_logic_vector(7 downto 0) := (others => '0');
  signal src_ip4_r : std_logic_vector(31 downto 0) := (others => '0');
  signal dst_ip4_r : std_logic_vector(31 downto 0) := (others => '0');
  signal l4off_r : unsigned(15 downto 0) := (others => '0');
  signal flags_r : std_logic_vector(15 downto 0) := (others => '0');
  signal sof_r : std_logic := '0';
  signal eof_r : std_logic := '0';

  signal fire : std_logic;
begin
  s_ready <= m_ready;
  fire <= s_valid and m_ready;

  m_valid <= v_r;
  m_win <= win_r;
  m_ip_ver <= ip_ver_r;
  m_ip_proto <= ip_proto_r;
  m_src_ip4 <= src_ip4_r;
  m_dst_ip4 <= dst_ip4_r;
  m_l4_offset <= l4off_r;
  m_flags <= flags_r;
  m_sof <= sof_r;
  m_eof <= eof_r;

  process(clk)
    variable ip0 : std_logic_vector(7 downto 0);
    variable ihl : unsigned(3 downto 0);
    variable l3off : natural;
    variable l4off : unsigned(15 downto 0);
    variable frag : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        v_r <= '0';
        win_r <= (others => '0');
        ip_ver_r <= (others => '0');
        ip_proto_r <= (others => '0');
        src_ip4_r <= (others => '0');
        dst_ip4_r <= (others => '0');
        l4off_r <= (others => '0');
        flags_r <= (others => '0');
        sof_r <= '0';
        eof_r <= '0';
      else
        v_r <= fire;

        if fire = '1' then
          win_r <= s_win;
          sof_r <= s_sof;
          eof_r <= s_eof;

          flags_r <= (others => '0');
          ip_ver_r <= (others => '0');
          ip_proto_r <= (others => '0');
          src_ip4_r <= (others => '0');
          dst_ip4_r <= (others => '0');
          l4off_r <= (others => '0');

          l3off := to_integer(s_l3_offset);

          if s_ethertype = x"0800" then
            ip0 := get_byte(s_win, l3off + 0);
            ip_ver_r <= ip0(7 downto 4);
            ihl := unsigned(ip0(3 downto 0));

            ip_proto_r <= get_byte(s_win, l3off + 9);
            src_ip4_r <= get_u32_be(s_win, l3off + 12);
            dst_ip4_r <= get_u32_be(s_win, l3off + 16);

            l4off := to_unsigned(l3off, 16) + resize(ihl, 16) * 4;
            l4off_r <= l4off;

            if ihl > 5 then
              flags_r(0) <= '1'; 
            end if;

            frag := get_u16_be(s_win, l3off + 6);
            if frag(12 downto 0) /= "0000000000000" then
              flags_r(1) <= '1';
            end if;

          elsif s_ethertype = x"86DD" then
            ip0 := get_byte(s_win, l3off + 0);
            ip_ver_r <= ip0(7 downto 4);
            ip_proto_r <= get_byte(s_win, l3off + 6);
            l4off_r <= to_unsigned(l3off + 40, 16);
            flags_r(2) <= '1'; 
          end if;
        end if;
      end if;
    end if;
  end process;
end Behavioral;

