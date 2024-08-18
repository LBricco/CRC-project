library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crc is
end tb_crc;

architecture behavioral of tb_crc is

    signal clock                                   : std_logic := '0';
    signal reset, start_crc                        : std_logic := '0';
    signal din_reg, dout_reg                       : std_logic_vector(15 downto 0);
    signal control                                 : std_logic := '0';
    signal status_crc                              : std_logic;
    signal reset_ctrl                              : std_logic;
    signal enable_dout, enable_ctrl, enable_status : std_logic := '0';

    component crc is
        port (
            CK, RST, START : in std_logic;
            DIN            : in std_logic_vector(15 downto 0);
            DOUT           : out std_logic_vector(15 downto 0);
            CTRL           : in std_logic;  -- reset CRC se CTRL=1
            STATUS         : out std_logic; -- CRC free (disponibile) se STATUS=1
            CTRL_OUT       : out std_logic; -- dato da scrivere nel Control Register
            WR_DOUT        : out std_logic; -- enable scrittura in CRC Out Register
            WR_CTRL        : out std_logic; -- enable scrittura in Control Register
            WR_STATUS      : out std_logic  -- enable scrittura in Status Register
        );
    end component;

begin

    clk_process : process
    begin
        wait for 500 ns;
        clock <= not clock;
    end process clk_process;

    crc_process : process
    begin
        --------------------------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';

        din_reg   <= "1010101010101010"; --AAAA
        start_crc <= '1';
        wait for 200 us; -- mi aspetto CRC = CRC(AAAA) = E615
        start_crc <= '0';
        wait for 20 us;

        din_reg   <= "0011111100011011"; --3F1B
        start_crc <= '1';
        wait for 200 us; -- mi aspetto CRC = CRC(AAAA3F1B) = 4E71
        start_crc <= '0';
        wait for 20 us;

        control <= '1'; -- reset esterno
        wait for 1000 ns;
        control <= '0';

        din_reg   <= "0101010101010101"; --5555
        start_crc <= '1';
        wait for 200 us; -- mi aspetto CRC = CRC(5555) = FB1A
        start_crc <= '0';
        wait for 20 us;
        --------------------------------------------------------------------------------
    end process crc_process;

    crc_calculator : crc
    port map(
        CK        => clock,
        RST       => reset,
        START     => start_crc,
        DIN       => din_reg,
        DOUT      => dout_reg,
        CTRL      => control,
        CTRL_OUT  => reset_ctrl,
        STATUS    => status_crc,
        WR_DOUT   => enable_dout,
        WR_CTRL   => enable_ctrl,
        WR_STATUS => enable_status
    );

end behavioral;