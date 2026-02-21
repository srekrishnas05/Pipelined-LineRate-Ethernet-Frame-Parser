library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity stage0_skid is
    generic (
        BPC : positive := 1
    );
    port (
        clk : in std_logic; 
        rst : in std_logic;
        
        s_data : in std_logic_vector(BPC*8-1 downto 0);
        s_keep : in std_logic_vector(BPC-1 downto 0);
        s_valid : in std_Logic;
        s_ready : out std_logic;
        s_sof : in std_logic;
        s_eof : in std_logic;
        
        m_data : out std_logic_vector(bpc*8-1 downto 0);
        m_keep : out std_logic_vector(bpc-1 downto 0);
        m_valid : out std_logic;
        m_ready : in std_logic;
        m_sof : out std_logic;
        m_eof : out std_logic
        );
end stage0_skid;

architecture passthrough of stage0_skid is
begin

  s_ready <= m_ready;

  m_data <= s_data;
  m_keep <= s_keep;
  m_valid <= s_valid;
  m_sof <= s_sof;
  m_eof <= s_eof;

end architecture;

