--**********************************************************************************
--* Multiplexer a due vie con ingressi e uscita su N bit
--* s=0: out_mux = IN_0
--* s=1: out_mux = IN_1
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_n_bits2to1 is
	generic (N : integer := 16);
	port (
		IN_0, IN_1 : in std_logic_vector(N - 1 downto 0); -- input a N bit
		s          : in std_logic;                        -- selettore a 1 bit
		uscita     : out std_logic_vector(N - 1 downto 0) -- output a N bit
	);
end mux_n_bits2to1;

architecture structure of mux_n_bits2to1 is
begin
	uscita <= IN_0 when s = '0' else
		IN_1;
end structure;