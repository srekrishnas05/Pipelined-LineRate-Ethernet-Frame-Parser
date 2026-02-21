library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_eth_parser is
end entity;

architecture sim of tb_top_eth_parser is
  constant BPC          : positive := 1;   -- change to 2 / 8 to test 2G/10G style
  constant WINDOW_BYTES : positive := 96;

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  signal in_data  : std_logic_vector(BPC*8-1 downto 0) := (others => '0');
  signal in_keep  : std_logic_vector(BPC-1 downto 0)   := (others => '0');
  signal in_valid : std_logic := '0';
  signal in_ready : std_logic;
  signal in_sof   : std_logic := '0';
  signal in_eof   : std_logic := '0';

  signal meta_valid : std_logic;
  signal meta_ready : std_logic := '1';

  signal meta_dst_mac    : std_logic_vector(47 downto 0);
  signal meta_src_mac    : std_logic_vector(47 downto 0);
  signal meta_vlan_cnt   : std_logic_vector(1 downto 0);
  signal meta_ethertype  : std_logic_vector(15 downto 0);
  signal meta_ip_ver     : std_logic_vector(3 downto 0);
  signal meta_ip_proto   : std_logic_vector(7 downto 0);
  signal meta_src_ip4    : std_logic_vector(31 downto 0);
  signal meta_dst_ip4    : std_logic_vector(31 downto 0);
  signal meta_src_port   : std_logic_vector(15 downto 0);
  signal meta_dst_port   : std_logic_vector(15 downto 0);
  signal meta_payload_off: std_logic_vector(15 downto 0);
  signal meta_flags      : std_logic_vector(15 downto 0);

  type byte_arr is array(natural range <>) of std_logic_vector(7 downto 0);

  constant pkt : byte_arr := (
    -- dst mac 00:11:22:33:44:55
    x"00", x"11", x"22", x"33", x"44", x"55",
    -- src mac 66:77:88:99:AA:BB
    x"66", x"77", x"88", x"99", x"AA", x"BB",
    -- ethertype IPv4 0x0800
    x"08", x"00",

    -- IPv4 header (20 bytes)
    x"45", x"00", x"00", x"20",  -- ver/ihl=4/5, total_len=32
    x"00", x"01", x"00", x"00",  -- id, flags/frag
    x"40", x"11", x"00", x"00",  -- ttl, proto=17 UDP, checksum=0
    x"C0", x"A8", x"01", x"0A",  -- src 192.168.1.10
    x"C0", x"A8", x"01", x"14",  -- dst 192.168.1.20

    -- UDP header (8)
    x"12", x"34", x"56", x"78",  -- src=0x1234, dst=0x5678
    x"00", x"0C", x"00", x"00",  -- len=12, checksum=0

    -- payload (4)
    x"DE", x"AD", x"BE", x"EF"
  );

begin
  clk <= not clk after 5 ns;

  dut: entity work.top_eth_parser
    generic map (
      BPC => BPC,
      WINDOW_BYTES => WINDOW_BYTES
    )
    port map (
      clk => clk,
      rst => rst,
      in_data => in_data,
      in_keep => in_keep,
      in_valid => in_valid,
      in_ready => in_ready,
      in_sof => in_sof,
      in_eof => in_eof,
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

  stim: process
    variable i         : integer := 0;
    variable beat_bytes: integer;
  begin
    rst <= '1';
    in_valid <= '0';
    in_sof <= '0';
    in_eof <= '0';
    in_keep <= (others => '0');
    in_data <= (others => '0');
    wait for 50 ns;
    wait until rising_edge(clk);
    rst <= '0';

    i := 0;
    while i < pkt'length loop
      wait until rising_edge(clk);

      if in_ready = '1' then
        in_valid <= '1';
        in_data  <= (others => '0');
        in_keep  <= (others => '0');
        in_sof   <= '0';
        in_eof   <= '0';

        if i = 0 then
          in_sof <= '1';
        end if;

        beat_bytes := 0;
        for b in 0 to BPC-1 loop
          if (i + b) < pkt'length then
            in_data(b*8+7 downto b*8) <= pkt(i+b);
            in_keep(b) <= '1';
            beat_bytes := beat_bytes + 1;
          end if;
        end loop;

        if (i + beat_bytes) >= pkt'length then
          in_eof <= '1';
        end if;

        i := i + beat_bytes;
      else
        in_valid <= '0';
        in_sof <= '0';
        in_eof <= '0';
        in_keep <= (others => '0');
        in_data <= (others => '0');
      end if;
    end loop;

    wait until rising_edge(clk);
    in_valid <= '0';
    in_sof <= '0';
    in_eof <= '0';
    in_keep <= (others => '0');
    in_data <= (others => '0');

    wait until meta_valid = '1';
    wait until rising_edge(clk); -- stabilize in same cycle view

    assert meta_dst_mac = x"001122334455" report "DST MAC mismatch" severity failure;
    assert meta_src_mac = x"66778899AABB" report "SRC MAC mismatch" severity failure;
    assert meta_ethertype = x"0800" report "Ethertype mismatch" severity failure;
    assert meta_vlan_cnt = "00" report "VLAN count mismatch" severity failure;

    assert meta_ip_ver = "0100" report "IP version mismatch (expect 4)" severity failure;
    assert meta_ip_proto = x"11" report "IP proto mismatch (expect UDP=0x11)" severity failure;

    assert meta_src_ip4 = x"C0A8010A" report "SRC IP mismatch" severity failure;
    assert meta_dst_ip4 = x"C0A80114" report "DST IP mismatch" severity failure;

    assert meta_src_port = x"1234" report "SRC port mismatch" severity failure;
    assert meta_dst_port = x"5678" report "DST port mismatch" severity failure;

    assert meta_payload_off = x"002A" report "Payload offset mismatch" severity failure;

    report "PASS: tb_top_eth_parser" severity note;

    wait for 50 ns;
    assert false report "Done" severity failure;
  end process;

end architecture;
