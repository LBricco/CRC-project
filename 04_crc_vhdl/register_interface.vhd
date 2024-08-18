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
		--* porte per interfaccia SPI/memoria **************************************
		CK    : in std_logic;
		WR    : in std_logic;            -- write mem (attivo alto)
		RD    : in std_logic;            -- read mem (attivo alto)
		ADDR  : in integer range 0 to 3; -- indirizzo mem
		START : out std_logic;           -- start CRC
		D     : in std_logic_vector(N - 1 downto 0);
		Q     : out std_logic_vector(N - 1 downto 0);
		--* porte per interfaccia CRC/memoria **************************************
		Q_DIN : out std_logic_vector(N - 1 downto 0);
		----------------------------------------------------------------------------
		D_DOUT  : in std_logic_vector(N - 1 downto 0);
		EN_DOUT : in std_logic; -- enable scrittura in CRC Out Register
		----------------------------------------------------------------------------
		D_CTRL  : in std_logic_vector(N - 1 downto 0);
		EN_CTRL : in std_logic; -- enable scrittura in Control Register
		Q_CTRL  : out std_logic_vector(N - 1 downto 0);
		----------------------------------------------------------------------------
		D_STATUS  : in std_logic_vector(N - 1 downto 0);
		EN_STATUS : in std_logic -- enable scrittura in Status Register
	);
end register_interface;

architecture structure of register_interface is

	type ram_array is array (0 to 3) of std_logic_vector (N - 1 downto 0);
	signal ram : ram_array;

begin

	crc_spi_interface : process (CK)
	begin

		if (CK'event and CK = '1') then
			START <= '0';
			if (RD = '1') then
				Q <= ram(ADDR);
			end if;

			if (WR = '1') then -- SPI scrive
				ram(ADDR) <= D;    -- scrivo in ram
				if (ADDR = 0) then -- start CRC
					START <= '1';
				end if;
			else -- CRC scrive
				if (EN_DOUT = '1') then
					ram(1) <= D_DOUT; -- scrivo in ram
				end if;

				if (EN_CTRL = '1') then
					ram(2) <= D_CTRL; -- scrivo in ram
				end if;

				if (EN_STATUS = '1') then
					ram(3) <= D_STATUS; -- scrivo in ram_crc
				end if;

			end if;
		end if;
	end process crc_spi_interface;

	Q_DIN  <= ram(0); -- CRC legge il Data In Register (sempre)
	Q_CTRL <= ram(2); -- CRC legge il Control Register (sempre)

end structure;