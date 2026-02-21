library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_eth_parser is
  generic (
    BPC          : positive := 1;
    WINDOW_BYTES : positive := 96
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    in_data : in  std_logic_vector(BPC*8-1 downto 0);
    in_keep : in  std_logic_vector(BPC-1 downto 0);
    in_valid : in  std_logic;
    in_ready : out std_logic;
    in_sof : in  std_logic;
    in_eof : in  std_logic;
    meta_valid : out std_logic;
    meta_ready : in  std_logic;
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
end entity;

architecture rtl of top_eth_parser is

  signal d0 : std_logic_vector(BPC*8-1 downto 0);
  signal k0 : std_logic_vector(BPC-1 downto 0);
  signal v0 : std_logic;
  signal r0 : std_logic;
  signal sof0, eof0 : std_logic;

  signal win1 : std_logic_vector(WINDOW_BYTES*8-1 downto 0);
  signal v1, r1 : std_logic;
  signal in_frame1 : std_logic;
  signal bc1 : unsigned(15 downto 0);
  signal have14_1, have18_1, have22_1, have60_1 : std_logic;
  signal sof1, eof1 : std_logic;


  signal win2 : std_logic_vector(WINDOW_BYTES*8-1 downto 0);
  signal v2, r2 : std_logic;
  signal dst2, src2 : std_logic_vector(47 downto 0);
  signal tpid2 : std_logic_vector(15 downto 0);
  signal have14_2 : std_logic;
  signal sof2, eof2 : std_logic;

  signal win3 : std_logic_vector(WINDOW_BYTES*8-1 downto 0);
  signal v3, r3 : std_logic;
  signal vlan_cnt3 : unsigned(1 downto 0);
  signal etype3 : std_logic_vector(15 downto 0);
  signal l3off3 : unsigned(15 downto 0);
  signal sof3, eof3 : std_logic;

  signal win4 : std_logic_vector(WINDOW_BYTES*8-1 downto 0);
  signal v4, r4 : std_logic;
  signal ipver4 : std_logic_vector(3 downto 0);
  signal ipproto4 : std_logic_vector(7 downto 0);
  signal srcip4_4, dstip4_4 : std_logic_vector(31 downto 0);
  signal l4off4 : unsigned(15 downto 0);
  signal flags4 : std_logic_vector(15 downto 0);
  signal sof4, eof4 : std_logic;

  signal win5 : std_logic_vector(WINDOW_BYTES*8-1 downto 0);
  signal v5, r5 : std_logic;
  signal srcp5, dstp5 : std_logic_vector(15 downto 0);
  signal pay5 : unsigned(15 downto 0);
  signal flags5 : std_logic_vector(15 downto 0);
  signal sof5, eof5 : std_logic;

begin
  u0: entity work.stage0_skid
    generic map (BPC => BPC)
    port map (
      clk => clk, rst => rst,
      s_data => in_data, s_keep => in_keep, s_valid => in_valid, s_ready => in_ready,
      s_sof => in_sof, s_eof => in_eof,
      m_data => d0, m_keep => k0, m_valid => v0, m_ready => r0,
      m_sof => sof0, m_eof => eof0
    );

  u1: entity work.stage1_aligner
    generic map (BPC => BPC, WINDOW_BYTES => WINDOW_BYTES)
    port map (
      clk => clk, rst => rst,
      s_data => d0, s_keep => k0, s_valid => v0, s_ready => r0, s_sof => sof0, s_eof => eof0,
      m_win => win1, m_valid => v1, m_ready => r1,
      m_in_frame => in_frame1, m_byte_count => bc1,
      m_have14 => have14_1, m_have18 => have18_1, m_have22 => have22_1, m_have60 => have60_1,
      m_sof => sof1, m_eof => eof1
    );

  u2: entity work.stage2_l2
    generic map (WINDOW_BYTES => WINDOW_BYTES)
    port map (
      clk => clk, rst => rst,
      s_win => win1, s_have14 => have14_1,
      s_valid => v1, s_ready => r1,
      s_sof => sof1, s_eof => eof1,
      m_win => win2, m_have14 => have14_2,
      m_dst_mac => dst2, m_src_mac => src2, m_tpid_or_type => tpid2,
      m_valid => v2, m_ready => r2,
      m_sof => sof2, m_eof => eof2
    );

  u3: entity work.stage3_vlan
    generic map (WINDOW_BYTES => WINDOW_BYTES)
    port map (
      clk => clk, rst => rst,
      s_win => win2, s_have18 => have18_1, s_have22 => have22_1, s_tpid_or_type => tpid2,
      s_valid => v2, s_ready => r2,
      s_sof => sof2, s_eof => eof2,
      m_win => win3,
      m_vlan_cnt => vlan_cnt3, m_ethertype => etype3, m_l3_offset => l3off3,
      m_valid => v3, m_ready => r3,
      m_sof => sof3, m_eof => eof3
    );

  u4: entity work.stage4_l3
    generic map (WINDOW_BYTES => WINDOW_BYTES)
    port map (
      clk => clk, rst => rst,
      s_win => win3, s_ethertype => etype3, s_l3_offset => l3off3,
      s_valid => v3, s_ready => r3,
      s_sof => sof3, s_eof => eof3,
      m_win => win4,
      m_ip_ver => ipver4, m_ip_proto => ipproto4,
      m_src_ip4 => srcip4_4, m_dst_ip4 => dstip4_4,
      m_l4_offset => l4off4, m_flags => flags4,
      m_valid => v4, m_ready => r4,
      m_sof => sof4, m_eof => eof4
    );

  u5: entity work.stage5_l4
    generic map (WINDOW_BYTES => WINDOW_BYTES)
    port map (
      clk => clk, rst => rst,
      s_win => win4, s_ip_proto => ipproto4, s_l4_offset => l4off4, s_flags => flags4,
      s_valid => v4, s_ready => r4,
      s_sof => sof4, s_eof => eof4,
      m_win => win5,
      m_src_port => srcp5, m_dst_port => dstp5,
      m_payload_off => pay5, m_flags => flags5,
      m_valid => v5, m_ready => r5,
      m_sof => sof5, m_eof => eof5
    );

  u6: entity work.stage6_meta_out
    port map (
      clk => clk, rst => rst,
      s_valid => v5, s_ready => r5,
      s_sof => sof5, s_eof => eof5,
      s_have14 => have14_2,
      s_ip_ver => ipver4,
      s_dst_mac => dst2,
      s_src_mac => src2,
      s_vlan_cnt => std_logic_vector(vlan_cnt3),
      s_ethertype => etype3,
      s_ip_proto => ipproto4,
      s_src_ip4 => srcip4_4,
      s_dst_ip4 => dstip4_4,
      s_src_port => srcp5,
      s_dst_port => dstp5,
      s_payload_off => std_logic_vector(pay5),
      s_flags => flags5,
      meta_valid => meta_valid,
      meta_ready => meta_ready,
      meta_dst_mac => meta_dst_mac,
      meta_src_mac => meta_src_mac,
      meta_vlan_cnt => meta_vlan_cnt,
      meta_ethertype => meta_ethertype,
      meta_ip_ver => meta_ip_ver,
      meta_ip_proto => meta_ip_proto,
      meta_src_ip4 => meta_src_ip4,
      meta_dst_ip4 => meta_dst_ip4,
      meta_src_port => meta_src_port,
      meta_dst_port => meta_dst_port,
      meta_payload_off => meta_payload_off,
      meta_flags => meta_flags
    );

end architecture;
