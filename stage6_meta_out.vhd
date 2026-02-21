library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity stage6_meta_out is
    port (
        clk : in std_logic;
        rst : in std_logic;
        s_valid : in std_logic;
        s_ready : out std_logic;
        s_sof : in std_logic;
        s_eof : in std_logic;
        s_have14 : in std_logic;
        s_ip_ver : in std_logic_vector(3 downto 0);
        s_dst_mac : in std_logic_vector(47 downto 0);
        s_src_mac : in std_logic_vector(47 downto 0);
        s_vlan_cnt : in std_logic_vector(1 downto 0);
        s_ethertype : in std_logic_vector(15 downto 0);
        s_ip_proto : in std_logic_vector(7 downto 0);
        s_src_ip4 : in std_logic_vector(31 downto 0);
        s_dst_ip4 : in std_logic_vector(31 downto 0);
        s_src_port : in std_logic_vector(15 downto 0);
        s_dst_port : in std_logic_vector(15 downto 0);
        s_payload_off : in std_logic_vector(15 downto 0);
        s_flags : in std_logic_vector(15 downto 0);
        meta_valid : out std_logic;
        meta_ready : in std_logic;
        meta_dst_mac : out std_logic_vector(47 downto 0);
        meta_src_mac : out std_logic_vector(47 downto 0);
        meta_vlan_cnt : out std_logic_vector(1 downto 0);
        meta_ethertype : out std_logic_vector(15 downto 0);
        meta_ip_ver : out std_logic_vector(3 downto 0);
        meta_ip_proto : out std_logic_vector(7 downto 0);
        meta_src_ip4 : out std_logic_vector(31 downto 0);
        meta_dst_ip4 : out std_logic_vector(31 downto 0);
        meta_src_port : out std_logic_vector(15 downto 0);
        meta_dst_port : out std_logic_vector(15 downto 0);
        meta_payload_off : out std_logic_vector(15 downto 0); 
        meta_flags : out std_logic_vector(15 downto 0)
        );
end stage6_meta_out;

architecture Behavioral of stage6_meta_out is
  signal v_r : std_logic := '0';
  signal fire : std_logic;

  signal dst_mac_r : std_logic_vector(47 downto 0) := (others=>'0');
  signal src_mac_r : std_logic_vector(47 downto 0) := (others=>'0');
  signal vlan_r : std_logic_vector(1 downto 0)  := (others=>'0');
  signal etype_r : std_logic_vector(15 downto 0) := (others=>'0');
  signal ip_ver_r : std_logic_vector(3 downto 0)  := (others=>'0');
  signal ip_proto_r : std_logic_vector(7 downto 0)  := (others=>'0');
  signal src_ip_r : std_logic_vector(31 downto 0) := (others=>'0');
  signal dst_ip_r : std_logic_vector(31 downto 0) := (others=>'0');
  signal src_port_r : std_logic_vector(15 downto 0) := (others=>'0');
  signal dst_port_r : std_logic_vector(15 downto 0) := (others=>'0');
  signal payload_r : std_logic_vector(15 downto 0) := (others=>'0');
  signal flags_r : std_logic_vector(15 downto 0) := (others=>'0');
begin

  s_ready <= meta_ready;
  fire    <= s_valid and meta_ready;

  meta_valid <= v_r;
  meta_dst_mac <= dst_mac_r;
  meta_src_mac <= src_mac_r;
  meta_vlan_cnt <= vlan_r;
  meta_ethertype <= etype_r;
  meta_ip_ver <= ip_ver_r;
  meta_ip_proto <= ip_proto_r;
  meta_src_ip4 <= src_ip_r;
  meta_dst_ip4 <= dst_ip_r;
  meta_src_port <= src_port_r;
  meta_dst_port <= dst_port_r;
  meta_payload_off <= payload_r;
  meta_flags <= flags_r;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        v_r <= '0';
        dst_mac_r <= (others=>'0');
        src_mac_r <= (others=>'0');
        vlan_r <= (others=>'0');
        etype_r <= (others=>'0');
        ip_ver_r <= (others=>'0');
        ip_proto_r <= (others=>'0');
        src_ip_r <= (others=>'0');
        dst_ip_r <= (others=>'0');
        src_port_r <= (others=>'0');
        dst_port_r <= (others=>'0');
        payload_r <= (others=>'0');
        flags_r <= (others=>'0');
      else
        v_r <= '0';

        if fire='1' then
          dst_mac_r <= s_dst_mac;
          src_mac_r <= s_src_mac;
          vlan_r <= s_vlan_cnt;
          etype_r <= s_ethertype;
          ip_ver_r <= s_ip_ver;
          ip_proto_r <= s_ip_proto;
          src_ip_r <= s_src_ip4;
          dst_ip_r <= s_dst_ip4;
          src_port_r <= s_src_port;
          dst_port_r <= s_dst_port;
          payload_r <= s_payload_off;
          flags_r <= s_flags;

          if s_eof='1' then
            v_r <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;

