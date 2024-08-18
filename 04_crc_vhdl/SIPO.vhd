--**********************************************************************************
--* SIPO con parallelismo di uscita pari a N bit (generic)
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIPO is
	generic (N : integer);
	port (
		clk : in std_logic;
		rst : in std_logic;
		en  : in std_logic;
		d   : in std_logic;
		q   : out std_logic_vector(N - 1 downto 0)
	);
end SIPO;

architecture structure of SIPO is

	signal data : std_logic_vector(N - 1 downto 0);

begin

	process (clk, rst)
	begin
		if (rst = '1') then -- reset attivo alto
			data <= (others => '0');
		elsif (clk'event and clk = '1') then -- fronte di salita del clock
			if en = '1' then
				data <= data(N - 2 downto 0) & d;
			end if;
		end if;
	end process;

	q <= data;

end structure;