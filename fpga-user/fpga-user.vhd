library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity user is
	port (
		-- Main clock inputs
		mainClk : in std_logic;
		slowClk : in std_logic;
		-- Main reset input
		reset : in std_logic;
		-- MCU interface (UART, I2C)
		mcuUartTx : in std_logic;
		mcuUartRx : out std_logic;
		mcuI2cScl : in std_logic;
		mcuI2cSda : inout std_logic;
		-- Logic state analyzer/stimulator
		lsasBus : inout std_logic_vector(31 downto 0);
		-- Dip switches
		switches : in std_logic_vector(7 downto 0);
		-- LEDs
		leds : out std_logic_vector(3 downto 0)
	);
end user;

architecture behavioural of user is

	signal clk     : std_logic;
	signal pllLock : std_logic;

	signal lsasBusIn  : std_logic_vector(31 downto 0);
	signal lsasBusOut : std_logic_vector(31 downto 0);
	signal lsasBusEn  : std_logic_vector(31 downto 0) := (others => '0');

	signal mcuI2cDIn  : std_logic;
	signal mcuI2CDOut : std_logic;
	signal mcuI2cEn   : std_logic := '0';

	component myAltPll
		port (
			areset : in std_logic := '0';
			inclk0 : in std_logic := '0';
			c0     : out std_logic;
			locked : out std_logic
		);
	end component;

	component top_level is
		port (
			CK   : in std_logic;
			SCK  : in std_logic;
			nSS  : in std_logic;
			RST  : in std_logic;
			MOSI : in std_logic;
			MISO : out std_logic
		);
	end component;

begin

	--**********************************************************************************
	--* Main clock PLL
	--**********************************************************************************

	myAltPll_inst : myAltPll port map(
		areset => reset,
		inclk0 => mainClk,
		c0     => clk,
		locked => pllLock
	);

	--**********************************************************************************
	--* LEDs
	--**********************************************************************************

	leds(2 downto 0) <= switches(2 downto 0);
	lsasbusEn (14)   <= '1';

	--**********************************************************************************
	--* 		lsasBus	: inout std_logic_vector( 31 downto 0 )
	--**********************************************************************************

	lsasBusIn <= lsasBus;

	lsasBus_tristate :
	process (lsasBusEn, lsasBusOut) is
	begin
		for index in 0 to 31 loop
			if lsasBusEn(index) = '1' then
				lsasBus(index) <= lsasBusOut (index);
			else
				lsasBus(index) <= 'Z';
			end if;
		end loop;
	end process;

	leds(3) <= '1';

	crc : top_level
	port map(
		CK   => mainClk,
		SCK  => lsasbus(13),
		nSS  => lsasbus(12),
		RST  => switches(0),
		MOSI => lsasbus(15),
		MISO => lsasbusOut(14)
	);

end behavioural;