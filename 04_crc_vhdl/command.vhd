--**********************************************************************************
--* Rilevatore del comando di scrittura o lettura
--* Scrittura = 00100000
--* Lettura = 00100001
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity command is
	port (
		cmd  : in std_logic_vector(7 downto 0);
		w_en : out std_logic;
		r_en : out std_logic
	);
end command;

architecture structure of command is

begin
	w_en <= (not(cmd(7)) and not(cmd(6)) and cmd(5) and not(cmd(4)) and not(cmd(3)) and not(cmd(2)) and not(cmd(1))) and not(cmd(0));
	r_en <= (not(cmd(7)) and not(cmd(6)) and cmd(5) and not(cmd(4)) and not(cmd(3)) and not(cmd(2)) and not(cmd(1))) and cmd(0);

end structure;