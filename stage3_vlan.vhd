library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.parser_pkg.all;

entity stage3_vlan is
    generic (
        window_bytes : positive := 96
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        s_win : in std_logic_vector(window_bytes*8-1 downto 0);
        s_have18 : in std_logic;
        s_have22 : in std_logic;
        s_tpid_or_type : in std_logic_vector(15 downto 0);
        s_valid : in std_logic;
        s_ready : out std_logic;
        s_sof : in std_logic;
        s_eof : in std_logic;
        m_win : out std_logic_vector(window_bytes*8-1 downto 0);
        m_vlan_cnt : out unsigned(1 downto 0);
        m_ethertype : out std_logic_vector(15 downto 0);
        m_l3_offset : out unsigned(15 downto 0);
        m_valid : out std_logic;
        m_ready : in std_logic;
        m_sof : out std_logic;
        m_eof : out std_logic
        );
end stage3_vlan;

architecture Behavioral of stage3_vlan is
  signal v_r : std_logic := '0';
  signal win_r : std_logic_vector(window_bytes*8-1 downto 0) := (others => '0');
  signal vlan_cnt_r : unsigned(1 downto 0) := (others => '0');
  signal ethertype_r : std_logic_vector(15 downto 0) := (others => '0');
  signal l3off_r : unsigned(15 downto 0) := (others => '0');
  signal sof_r : std_logic := '0';
  signal eof_r : std_logic := '0';

  signal fire : std_logic;

  function is_vlan_tpid(x : std_logic_vector(15 downto 0)) return boolean is
  begin
    return (x = x"8100") or (x = x"88A8") or (x = x"9100");
  end function;
begin
  s_ready <= m_ready;
  fire    <= s_valid and m_ready;

  m_valid <= v_r;
  m_win <= win_r;
  m_vlan_cnt <= vlan_cnt_r;
  m_ethertype <= ethertype_r;
  m_l3_offset <= l3off_r;
  m_sof <= sof_r and v_r;
  m_eof <= eof_r and v_r;

  process(clk)
    variable t0 : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        v_r <= '0';
        win_r <= (others => '0');
        vlan_cnt_r <= (others => '0');
        ethertype_r <= (others => '0');
        l3off_r <= (others => '0');
        sof_r <= '0';
        eof_r <= '0';
      else
        v_r <= fire;

        if fire = '1' then
          win_r <= s_win;
          sof_r <= s_sof;
          eof_r <= s_eof;

          vlan_cnt_r  <= (others => '0');
          ethertype_r <= s_tpid_or_type;
          l3off_r     <= to_unsigned(14, l3off_r'length);

          if is_vlan_tpid(s_tpid_or_type) then
            if s_have18 = '1' then
              t0 := get_u16_be(s_win, 16);

              vlan_cnt_r  <= to_unsigned(1, vlan_cnt_r'length);
              ethertype_r <= t0;
              l3off_r     <= to_unsigned(18, l3off_r'length);

              if is_vlan_tpid(t0) then
                vlan_cnt_r <= to_unsigned(2, vlan_cnt_r'length);
                if s_have22 = '1' then
                  ethertype_r <= get_u16_be(s_win, 20);
                  l3off_r     <= to_unsigned(22, l3off_r'length);
                else
                  ethertype_r <= t0;
                  l3off_r     <= to_unsigned(22, l3off_r'length);
                end if;
              end if;
            else
              vlan_cnt_r  <= to_unsigned(1, vlan_cnt_r'length);
              ethertype_r <= s_tpid_or_type;
              l3off_r     <= to_unsigned(18, l3off_r'length);
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end Behavioral;

