--**********************************************************************************
--* PISO con parallelismo di ingresso pari a N bit (generic)
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PISO is
	generic (N : integer := 16);
	port (
		clk : in std_logic;
		se  : in std_logic; -- shift enable
		rst : in std_logic;
		en  : in std_logic; -- load enable
		d   : in std_logic_vector(N - 1 downto 0);
		q   : out std_logic
	);
end PISO;

architecture structure of PISO is

	signal data : std_logic_vector(N - 1 downto 0);

begin
	process (CLK, RST)
	begin
		if (RST = '1') then                  				  -- reset attivo alto
			data <= (others => '0');         				  -- reset
			q    <= 'Z';                     				  -- uscita in alta impedenza
		elsif (clk'event and clk = '1') then 				  -- fronte di salita del clock
			if (EN = '1') then                                -- load
				data <= d;
			elsif (EN = '0' and SE = '1') then                -- shift
				q                    <= data(15);             -- mando fuori il MSB
				data(N - 1 downto 1) <= data(N - 2 downto 0); -- shifto di 1 bit verso sx
				data(0)              <= '0';                  -- appendo uno zero a dx (LSB)
			end if;
		end if;
	end process;

end structure;