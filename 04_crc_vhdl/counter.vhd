--**********************************************************************************
--* Contatore che solleva un flag quando arriva a 7 (TC8), 15 (TC16) e 31 (TC32)
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
	port (
		en, rst, clk    : in std_logic;
		tc8, tc16, tc32 : out std_logic
	);
end counter;

architecture structure of counter is

	signal Q : unsigned(4 downto 0);

begin
	process (clk, en, rst)
	begin
		if (rst = '1') then -- reset attivo alto
			Q <= (others => '0');
		elsif (clk'event and clk = '1') then -- fronte di salita del clock
			if (en = '1') then
				Q <= Q + 1;
			end if;
		end if;
	end process;

	tc8  <= Q(0) and Q(1) and Q(2) and not(Q(3)) and not(Q(4)); --7=00111
	tc16 <= Q(0) and Q(1) and Q(2) and Q(3) and not(Q(4));      --15=01111
	tc32 <= Q(0) and Q(1) and Q(2) and Q(3) and Q(4);           --31=11111

end structure;