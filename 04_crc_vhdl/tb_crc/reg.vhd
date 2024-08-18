--**********************************************************************************
--* Registro con parallelismo di ingresso e uscita pari a N bit (generic)
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
	generic (N : integer);
	port (
		d            : in std_logic_vector(N - 1 downto 0);
		clk, rst, en : in std_logic;
		q            : out std_logic_vector(N - 1 downto 0)
	);
end reg;

architecture structure of reg is
begin

	process (clk, rst)
	begin
		if (rst = '1') then --reset asincrono
			q <= (others => '0');
		elsif (clk'event and clk = '1') then --fronte di salita del clock
			if (en = '1') then
				q <= d (N - 1 downto 0);
			end if;
		end if;
	end process;

end structure;