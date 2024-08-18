--**********************************************************************************
--* Multiplexer a due vie con ingressi e uscita su 1 bit
--* s=0: l'uscita va in alta impedenza
--* s=1: trasmettiamo in uscita il valore presente in ingresso
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_z is
	port (
		ingresso : in std_logic; --input
		s        : in std_logic; --selettore
		uscita   : out std_logic --output 
	);
end mux_z;

architecture structure of mux_z is

begin
	uscita <= 'Z' when s = '0' --alta impedenza (s=0)
		else
		ingresso; --trasmissione dato (s=1)

end structure;