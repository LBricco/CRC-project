--**********************************************************************************
--* Multiplexer a due vie con ingressi e uscita su 1 bit
--* s=0: out_mux = IN_0
--* s=1: out_mux = IN_1
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_1_bit2to1 is
	port (
		IN_0, IN_1 : in std_logic; -- input a 1 bit
		s          : in std_logic; -- selettore a 1 bit
		uscita     : out std_logic -- output a 1 bit
	);
end mux_1_bit2to1;

architecture structure of mux_1_bit2to1 is
begin
	uscita <= IN_0 when s = '0' else
		IN_1;
end structure;