library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        CK   : in std_logic;
        SCK  : in std_logic;
        nSS  : in std_logic;
        RST  : in std_logic;
        MOSI : in std_logic;
        MISO : out std_logic
    );
end entity;

architecture structure of top_level is

    --**********************************************************************************
    --* Definizione segnali interni
    --**********************************************************************************

    signal RD, WR     : std_logic;                     -- controlli reg file lato SPI
    signal A_SPI      : std_logic_vector(7 downto 0);  -- indirizzo reg file (vector)
    signal A_SPI_INT  : integer range 0 to 3;          -- indirizzo reg file (integer)
    signal D_SPI      : std_logic_vector(15 downto 0); -- ingresso reg file lato SPI 
    signal Q_SPI      : std_logic_vector(15 downto 0); -- uscita reg file lato SPI
    signal E0         : std_logic;                     -- start crc
    signal E1, E2, E3 : std_logic;                     -- controlli reg file lato CRC
    signal D1, D2, D3 : std_logic_vector(15 downto 0); -- ingressi reg file lato CRC
    signal Q0, Q2     : std_logic_vector(15 downto 0); -- uscite reg file lato CRC
    signal CTRL_CRC   : std_logic;                     -- segnale per Control Register
    signal STATUS_CRC : std_logic;                     -- stato CRC (busy/free)

    --**********************************************************************************
    --* Dichiarazione component
    --**********************************************************************************

    component spi is
        port (
            CK, SCK : in std_logic;
            nSS     : in std_logic;
            RST     : in std_logic;
            MOSI    : in std_logic;
            MISO    : out std_logic;
            RD, WR  : out std_logic;
            A       : out std_logic_vector(7 downto 0);
            DIN     : out std_logic_vector(15 downto 0);
            DOUT    : in std_logic_vector(15 downto 0)
        );
    end component;

    component register_interface is
        generic (N : integer := 16);
        port (
            --* porte per interfaccia SPI/memoria **************************************
            CK    : in std_logic;
            WR    : in std_logic;
            RD    : in std_logic;
            ADDR  : in integer range 0 to 3;
            START : out std_logic;
            D     : in std_logic_vector(N - 1 downto 0);
            Q     : out std_logic_vector(N - 1 downto 0);
            --* porte per interfaccia CRC/memoria **************************************
            Q_DIN : out std_logic_vector(N - 1 downto 0);
            ----------------------------------------------------------------------------
            D_DOUT  : in std_logic_vector(N - 1 downto 0);
            EN_DOUT : in std_logic;
            ----------------------------------------------------------------------------
            D_CTRL  : in std_logic_vector(N - 1 downto 0);
            EN_CTRL : in std_logic;
            Q_CTRL  : out std_logic_vector(N - 1 downto 0);
            ----------------------------------------------------------------------------
            D_STATUS  : in std_logic_vector(N - 1 downto 0);
            EN_STATUS : in std_logic
        );
    end component;

    component crc is
        port (
            CK        : in std_logic;
            RST       : in std_logic;
            START     : in std_logic;
            DIN       : in std_logic_vector(15 downto 0);
            DOUT      : out std_logic_vector(15 downto 0);
            CTRL      : in std_logic;
            CTRL_OUT  : out std_logic;
            STATUS    : out std_logic;
            WR_DOUT   : out std_logic;
            WR_CTRL   : out std_logic;
            WR_STATUS : out std_logic
        );
    end component;

begin

    A_SPI_INT <= to_integer(unsigned(A_SPI));

    D2 <= (0 => CTRL_CRC, others => '0');
    D3 <= (0 => STATUS_CRC, others => '0');

    SPI_INTERFACE : spi
    port map(
        CK   => CK,
        SCK  => SCK,
        nSS  => nSS,
        RST  => RST,
        A    => A_SPI,
        DIN  => D_SPI,
        DOUT => Q_SPI,
        RD   => RD,
        WR   => WR,
        MOSI => MOSI,
        MISO => MISO
    );

    REGISTER_FILE : register_interface
    generic map(N => 16)
    port map(
        CK   => CK,
        WR   => WR,
        RD   => RD,
        ADDR => A_SPI_INT,
        D    => D_SPI,
        Q    => Q_SPI,
        ---------------------------------------------------
        Q_DIN => Q0,
        START => E0,
        ---------------------------------------------------
        D_DOUT  => D1,
        EN_DOUT => E1,
        ---------------------------------------------------
        D_CTRL  => D2,
        EN_CTRL => E2,
        Q_CTRL  => Q2,
        ---------------------------------------------------
        D_STATUS  => D3,
        EN_STATUS => E3
    );

    CRC_CALCULATOR : crc
    port map(
        CK        => CK,
        RST       => RST,
        START     => E0,
        DIN       => Q0,
        DOUT      => D1,
        CTRL      => Q2(0),
        CTRL_OUT  => CTRL_CRC,
        STATUS    => STATUS_CRC,
        WR_DOUT   => E1,
        WR_CTRL   => E2,
        WR_STATUS => E3
    );

end structure;