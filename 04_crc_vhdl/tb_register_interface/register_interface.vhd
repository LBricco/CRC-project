--**********************************************************************************
--* Register file con doppia interfaccia (SPI e CRC)
--* Il parallelismo dei dati è pari a N bit (generic)
--* ADDR = 0 Data In Register
--* ADDR = 1 CRC Out Register
--* ADDR = 2 Control Register
--* ADDR = 3 Status Register
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_interface is
	generic (N : integer := 16);
	port (
		--* porte per interfaccia SPI-memoria **************************************
		CK   : in std_logic;
		WR   : in std_logic;            --write mem (attivo alto)
		RD   : in std_logic;            --read mem (attivo alto)
		ADDR : in integer range 0 to 3; --indirizzo mem
		D    : in std_logic_vector(N - 1 downto 0);
		Q    : out std_logic_vector(N - 1 downto 0);
		--* porte per interfaccia CRC-memoria **************************************
		Q_DIN  : out std_logic_vector(N - 1 downto 0);
		EN_DIN : out std_logic; --start CRC
		----------------------------------------------------------------------------
		D_DOUT  : in std_logic_vector(N - 1 downto 0);
		EN_DOUT : in std_logic; --enable scrittura in CRC Out Register
		----------------------------------------------------------------------------
		D_CTRL  : in std_logic_vector(N - 1 downto 0);
		Q_CTRL  : out std_logic_vector(N - 1 downto 0);
		EN_CTRL : in std_logic; --enable scrittura in Control Register
		----------------------------------------------------------------------------
		D_STATUS  : in std_logic_vector(N - 1 downto 0);
		EN_STATUS : in std_logic --enable scrittura in Status Register
	);
end register_interface;

architecture structure of register_interface is

	type ram_array is array (0 to 3) of std_logic_vector (N - 1 downto 0);
	signal ram_spi, ram_crc : ram_array;
	signal ram              : ram_array;
	signal s_mem            : std_logic_vector (3 downto 0);

	component mux_n_bits2to1 is
		generic (N : integer := 16);
		port (
			A, B   : in std_logic_vector(N - 1 downto 0); -- input a N bit
			s      : in std_logic;                        -- selettore a 1 bit
			uscita : out std_logic_vector(N - 1 downto 0) -- output a N bit
		);
	end component;

begin

	crc_spi_interface : process (CK)
	begin
		EN_DIN <= '0'; 						-- valore di default
		if (CK'event and CK = '1') then 	-- fronte di salita del CK
			if (WR = '1') then          	-- SPI scrive in uno dei 4 registri
				ram_spi(ADDR) <= D;     	-- scrivo in ram_spi
				s_mem(ADDR)   <= '0';   	-- ram prende i dati da ram_spi
				EN_DIN        <= '1';   	-- start CRC

			elsif (RD = '1') then       	-- SPI legge uno dei 4 registri
				Q <= ram(ADDR);
				if (ADDR = 1) then      	-- se l'SPI legge il CRC Out Register, stoppo il CRC
					EN_DIN <= '0';
				end if;

			elsif (EN_DOUT = '1') then 		-- CRC scrive nel CRC Out Register
				ram_crc(1) <= D_DOUT;   	-- scrivo in ram_crc
				s_mem(1)   <= '1';      	-- ram prende i dati da ram_crc

			elsif (EN_CTRL = '1') then 		-- CRC scrive nel Control Register (durante il reset)
				ram_crc(2) <= D_CTRL;   	-- scrivo in ram_crc
				s_mem(2)   <= '1';      	-- ram prende i dati da ram_crc

			elsif (EN_STATUS = '1') then	-- CRC scrive nello Status Register
				ram_crc(3) <= D_STATUS; 	-- scrivo in ram_crc
				s_mem(3)   <= '1';      	-- ram prende i dati da ram_crc
			end if;
		end if;
	end process crc_spi_interface;

	Q_DIN  <= ram(0); -- CRC legge il Data In Register (sempre)
	Q_CTRL <= ram(2); -- CRC legge il Control Register (sempre)

	mux_add0 : mux_n_bits2to1
	generic map(N => 16)
	port map(
		A      => ram_spi(0),
		B      => ram_crc(0),
		s      => s_mem(0),
		uscita => ram(0)
	);

	mux_add1 : mux_n_bits2to1
	generic map(N => 16)
	port map(
		A      => ram_spi(1),
		B      => ram_crc(1),
		s      => s_mem(1),
		uscita => ram(1)
	);

	mux_add2 : mux_n_bits2to1
	generic map(N => 16)
	port map(
		A      => ram_spi(2),
		B      => ram_crc(2),
		s      => s_mem(2),
		uscita => ram(2)
	);

	mux_add3 : mux_n_bits2to1
	generic map(N => 16)
	port map(
		A      => ram_spi(3),
		B      => ram_crc(3),
		s      => s_mem(3),
		uscita => ram(3)
	);

end structure;