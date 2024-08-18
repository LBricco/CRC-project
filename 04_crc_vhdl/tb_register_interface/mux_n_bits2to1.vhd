--**********************************************************************************
--* Multiplexer a due vie con ingressi e uscita su 1 bit
--* s=0: out_mux = A
--* s=1: out_mux = B
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_n_bits2to1 is
	generic (N : integer := 16);
	port (
		A, B : in std_logic_vector(N - 1 downto 0); -- input a N bit
		s : in std_logic; -- selettore a 1 bit
		uscita : out std_logic_vector(N - 1 downto 0) -- output a N bit
	);
end mux_n_bits2to1;

architecture structure of mux_n_bits2to1 is
begin
	uscita <= A when s = '0' else
		B;
end structure;