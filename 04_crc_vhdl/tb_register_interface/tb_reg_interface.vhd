library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_reg_interface is
end tb_reg_interface;

architecture behavioral of tb_reg_interface is

    signal clock : std_logic := '0';
    signal wr_spi, rd_spi : std_logic := '0';
    signal address_int : integer range 0 to 3;
    signal din_spi, dout_spi : std_logic_vector(15 downto 0); 
    signal din_crc, dout_crc, ctrl_crc, status_crc : std_logic_vector(15 downto 0);
    signal enable_din, enable_dout, enable_ctrl, enable_status : std_logic := '0';

    component register_interface is
        generic (N : integer := 16);
        port (
            --* porte per interfaccia SPI-memoria **************************************
            CK : in std_logic;
            WR : in std_logic; --write mem (attivo alto)
            RD : in std_logic; --read mem (attivo alto)
            ADDR : in integer range 0 to 3; --indirizzo mem
            D : in std_logic_vector(N - 1 downto 0);
            Q : out std_logic_vector(N - 1 downto 0);
            --* porte per interfaccia CRC-memoria **************************************
            Q_DIN : out std_logic_vector(N - 1 downto 0);
            EN_DIN : out std_logic; --start CRC
            ----------------------------------------------------------------------------
            D_DOUT : in std_logic_vector(N - 1 downto 0);
            EN_DOUT : in std_logic; --enable scrittura in CRC Out Register
            ----------------------------------------------------------------------------
            D_CTRL : in std_logic_vector(N - 1 downto 0);
            Q_CTRL : out std_logic_vector(N - 1 downto 0);
            EN_CTRL : in std_logic; --enable scrittura in Control Register
            ----------------------------------------------------------------------------
            D_STATUS : in std_logic_vector(N - 1 downto 0);
            EN_STATUS : in std_logic --enable scrittura in Status Register
        );
    end component;

begin

    clk_process : process
    begin
        wait for 500 ns;
        clock <= not clock;
    end process clk_process;

    rd_wr_process : process
    begin
        --------------------------------------------------------------------------------
        enable_ctrl <= '1'; -- reset control register
        wait for 600 ns;
        enable_ctrl <= '0';

        wr_spi <= '1'; -- spi scrive nel data in register
        address_int <= 0;
        din_spi <= "1010101010101010"; --aaaa
        wait for 1000 ns;
        wr_spi <= '0';

        enable_dout <= '1'; -- crc scrive nel CRC Out Register
        dout_crc <= "1011101110111011"; --bbbb
        wait for 1000 ns;
        enable_dout <= '0';

        rd_spi <= '1'; -- spi legge dal CRC Out Register
        address_int <= 1;
        wait for 1000 ns;
        rd_spi <= '0';

        wr_spi <= '1'; -- spi scrive nel control register
        address_int <= 2;
        din_spi <= "1100110011001100"; --cccc
        wait for 1000 ns;
        wr_spi <= '0';
        --------------------------------------------------------------------------------
    end process rd_wr_process;

    reg_file : register_interface
    generic map(N => 16)
    port map(
        CK => clock,
        WR => wr_spi,
        RD => rd_spi,
        ADDR => address_int,
        D => din_spi,
        Q => dout_spi,
        ---------------------------------------------------
        Q_DIN => din_crc,
        EN_DIN => enable_din,
        ---------------------------------------------------
        D_DOUT => dout_crc,
        EN_DOUT => enable_dout,
        ---------------------------------------------------
        D_CTRL => (others => '0'),
        Q_CTRL => ctrl_crc,
        EN_CTRL => enable_ctrl,
        ---------------------------------------------------
        D_STATUS => status_crc,
        EN_STATUS => enable_status
    );

end behavioral;