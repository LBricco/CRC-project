--**********************************************************************************
--* Contatore 0 to N con count enable e terminal count
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contatore is
	generic (N : integer := 16);
	port (
		clock   : in std_logic;
		rst, en : in std_logic;
		TC      : out std_logic;
		cnt     : buffer integer range 0 to N + 1
	);
end contatore;

architecture structure of contatore is
begin

	count_process : process (clock, rst)
	begin
		if (rst = '1') then -- rst asincrono
			cnt <= 0;
			TC  <= '0';
		elsif (clock'event and clock = '1') then -- fronte di salita del clock
			if (en = '1') then
				TC  <= '0';
				cnt <= cnt + 1;
				if cnt = N then -- fine ciclo conta, riporto cnt a zero
					cnt <= 0;
				elsif cnt = N - 1 then -- alzo flag di terminal count
					TC <= '1';
				end if;
			end if;
		end if;
	end process count_process;

end structure;