--**********************************************************************************
--* Linear Feedback Shift Register
--* Utilizzato per calcolare il CRC con lo standard CRC-16-CCITT XMODEM
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_crc16ccitt is
    port (
        clk, rst_lfsr, en_lfsr : in std_logic;
        msg : in std_logic;
        crc : buffer std_logic_vector(15 downto 0)
    );
end lfsr_crc16ccitt;

architecture structure of lfsr_crc16ccitt is

    signal xor0, xor5, xor12 : std_logic;
    signal q15, q4, q11 : std_logic;

    component dflipflop is
        port (
            clk, rst, en : in std_logic;
            d : in std_logic;
            q : out std_logic
        );
    end component;

begin

    xor0 <= msg xor crc(15);
    xor5 <= crc(4) xor crc(15);
    xor12 <= crc(11) xor crc(15);

    FF_0 : dflipflop
    port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => xor0, q => crc(0));

    FF_1_4 : for ii in 1 to 4 generate
        FF_ii : dflipflop
        port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => crc(ii - 1), q => crc(ii));
    end generate;

    FF_5 : dflipflop
    port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => xor5, q => crc(5));

    FF_6_11 : for ii in 6 to 11 generate
        FF_ii : dflipflop
        port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => crc(ii - 1), q => crc(ii));
    end generate;

    FF_12 : dflipflop
    port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => xor12, q => crc(12));

    FF_13_15 : for ii in 13 to 15 generate
        FF_ii : dflipflop
        port map(clk => clk, rst => rst_lfsr, en => en_lfsr, d => crc(ii - 1), q => crc(ii));
    end generate;

end structure;