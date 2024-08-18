library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lfsr_crc16ccitt is
end tb_lfsr_crc16ccitt;

architecture behavioral of tb_lfsr_crc16ccitt is

    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal enable : std_logic := '0';
    signal message : std_logic_vector(31 downto 0); -- messaggio a 16 bit con 16 zeri in coda
    signal long_message : std_logic_vector(47 downto 0); -- messaggio a 47 bit con 16 zeri in coda
    signal bit_msg : std_logic; -- singolo bit del messaggio
    signal crc : std_logic_vector(15 downto 0);

    component lfsr_crc16ccitt is
        port (
            clk, rst_lfsr, en_lfsr : in std_logic;
            msg : in std_logic;
            crc : out std_logic_vector(15 downto 0)
        );
    end component;

begin

    clk_process : process
    begin
        wait for 500 ns;
        clock <= not clock;
    end process clk_process;

    crc_process : process
    begin
        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        message <= "1010101010101010" & "0000000000000000"; --aaaa

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 31 loop
            bit_msg <= message(31 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        message <= "0011111100011011" & "0000000000000000"; --3f1b

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 31 loop
            bit_msg <= message(31 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        message <= "1011111100011010" & "0000000000000000"; --bf1a

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 31 loop
            bit_msg <= message(31 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        message <= "1011111100011011" & "0000000000000000"; --bf1b

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 31 loop
            bit_msg <= message(31 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        message <= "1010101010101010" & "0000000000000000"; --aaaa

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 31 loop
            bit_msg <= message(31 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

        --------------------------------------------------------------

        --------------------------------------------------------------
        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        long_message <= "0011111100011011" & "1011111100011011" & "0000000000000000"; --3bfbbf1b

        enable <= '1';
        wait for 100 ns;

        for i in 0 to 47 loop
            bit_msg <= long_message(47 - i);
            wait for 1000 ns;
        end loop;

        enable <= '0';
        wait for 5000 ns;

    end process;

    crc_calculator : lfsr_crc16ccitt
    port map(clk => clock, rst_lfsr => reset, en_lfsr => enable, msg => bit_msg, crc => crc);

end behavioral;