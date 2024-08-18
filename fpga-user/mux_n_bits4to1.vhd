--**********************************************************************************
--* Multiplexer a quattro vie con ingressi e uscita a N bit
--* s=00: out_mux = IN_0 (0)
--* s=01: out_mux = IN_1 (1)
--* s=10: out_mux = IN_2 (2)
--* s=11: out_mux = IN_3 (3)
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_n_bits4to1 is
	generic (N : integer := 16);
	port (
		IN_0, IN_1, IN_2, IN_3 : in std_logic_vector(N - 1 downto 0); -- input a N bit
		s                      : in std_logic_vector(1 downto 0);     -- selettore a 2 bit
		uscita                 : out std_logic_vector(N - 1 downto 0) -- output a N bit
	);
end mux_n_bits4to1;

architecture structure of mux_n_bits4to1 is
begin
	uscita <=
		IN_0 when s = "00" else --0
		IN_1 when s = "01" else --1
		IN_2 when s = "10" else --2
		IN_3;                   --3
end structure;