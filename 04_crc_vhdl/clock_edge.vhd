--**********************************************************************************
--* Rilevatore dei fronti di SCK con sovracampionamento
--* Fronte di discesa = 1100
--* Fronte di salite = 0011
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_edge is
	generic (N : integer := 4);
	port (
		sck          : in std_logic;
		clk, en, rst : in std_logic;
		sck_lox      : out std_logic;
		sck_hix      : out std_logic
	);
end clock_edge;

architecture structure of clock_edge is

	component SIPO is
		generic (N : integer);
		port (
			clk : in std_logic;
			rst : in std_logic;
			en  : in std_logic;
			d   : in std_logic;
			q   : out std_logic_vector(N - 1 downto 0)
		);
	end component;

	signal edge : std_logic_vector(3 downto 0);

begin
	REG_SCK : SIPO
	generic map(N => N)
	port map(clk => clk, rst => rst, en => en, d => sck, q => edge);

	SCK_LOx <= (edge(3) and edge(2)) and (not(edge(1)) and not(edge(0)));
	SCK_HIx <= (not(edge(3)) and not(edge(2))) and (edge(1) and edge(0));

end structure;