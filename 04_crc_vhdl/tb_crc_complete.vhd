library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_crc_complete is
end tb_crc_complete;

architecture behavioral of tb_crc_complete is

    -- definizione segnali interni
    signal clock   : std_logic := '0';              -- main clock
    signal s_clock : std_logic := '0';              -- system clock
    signal nSS_spi : std_logic := '1';              -- slave select
    signal reset   : std_logic := '0';              -- reset esterno
    signal s_mosi  : std_logic := '1';              -- MOSI seriale
    signal s_miso  : std_logic := 'Z';              -- MISO seriale
    signal MOSI_wr : std_logic_vector(31 downto 0); -- vettore dati per WR
    signal MOSI_rd : std_logic_vector(15 downto 0); -- vettore dati per RD
    signal MISO_rd : std_logic_vector(15 downto 0); -- vettore restituito su MISO

    -- definizione file di I/O
    file file_INPUT_SINGLE  : text;
    file file_INPUT_LONG    : text;
    file file_OUTPUT_SINGLE : text;
    file file_OUTPUT_LONG   : text;

    -- dichiarazione UUT
    component top_level is
        port (
            CK, SCK : in std_logic;
            nSS     : in std_logic;
            RST     : in std_logic;
            MOSI    : in std_logic;
            MISO    : out std_logic
        );
    end component;

begin

    -- istanza UUT
    TB_CRC_CALCULATOR : top_level
    port map(
        CK => clock, SCK => s_clock,
        RST => reset, nSS => nSS_spi,
        MOSI => s_mosi, MISO => s_miso
    );

    -- Process CK (clock FPGA, periodo 100 ns, f=10 MHz)
    CK_process : process
    begin
        wait for 50 ns;
        clock <= not clock;
    end process CK_process;

    -- Process di lettura e scrittura con I/O su file
    RD_WR_process : process
        variable v_ILINE  : line; -- riga file di input
        variable v_OLINE  : line; -- riga file di output
        variable v_CMD_WR : std_logic_vector(31 downto 0);
        variable v_CMD_RD : std_logic_vector(15 downto 0);
        variable cnt_bit  : integer := 15;

    begin

        wait for 100 ns;
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        --******************************************************************************
        --* Calcolo di CRC di singole parole di 16 bit
        --******************************************************************************

        -- Apro file di I/O in modalità di lettura/scrittura
        file_open(file_INPUT_SINGLE, "input_commands_single.txt", read_mode);
        file_open(file_OUTPUT_SINGLE, "output_results_single.txt", write_mode);

        -- Leggo da input_commands_single.txt
        while not endfile(file_INPUT_SINGLE) loop

            -- scrittura
            readline(file_INPUT_SINGLE, v_ILINE);
            read(v_ILINE, v_CMD_WR);
            MOSI_wr <= v_CMD_WR;
            nSS_spi <= '0';
            wait for 100 ns;

            for i in 0 to 31 loop
                s_mosi  <= MOSI_wr(31 - i);
                s_clock <= '1';
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            wait for 200 ns;
            nSS_spi <= '1';
            wait for 5 us;

            -- lettura
            MOSI_rd <= "00100001" & "00000001";
            nSS_spi <= '0';
            wait for 1 us;

            for i in 0 to 15 loop
                s_mosi  <= MOSI_rd(15 - i);
                s_clock <= '1';
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            for i in 0 to 18 loop
                s_clock <= '1';
                if (s_miso /= 'Z') then
                    MISO_rd(cnt_bit) <= s_miso;
                    cnt_bit := cnt_bit - 1;
                end if;
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            cnt_bit := 15;
            nSS_spi <= '1';
            wait for 2 us;

            -- Scrivo in output_results.txt
            write(v_OLINE, MISO_rd, right, 16);
            writeline(file_OUTPUT_SINGLE, v_OLINE);

            -- reset
            MOSI_wr <= "00100000" & "00000010" & "0000000000000001";
            nSS_spi <= '0';
            wait for 100 ns;

            for i in 0 to 31 loop
                s_mosi  <= MOSI_wr(31 - i);
                s_clock <= '1';
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            wait for 200 ns;
            nSS_spi <= '1';
            wait for 5 us;

        end loop;

        -- Chiudo i file di I/O
        file_close(file_INPUT_SINGLE);
        file_close(file_OUTPUT_SINGLE);

        --******************************************************************************
        --* Calcolo di CRC di messaggi lunghi
        --******************************************************************************

        -- Apro file di I/O in modalità di lettura/scrittura
        file_open(file_INPUT_LONG, "input_commands_long.txt", read_mode);
        file_open(file_OUTPUT_LONG, "output_results_long.txt", write_mode);

        -- Leggo da input_commands_long.txt
        while not endfile(file_INPUT_LONG) loop

            -- scrittura
            readline(file_INPUT_LONG, v_ILINE);
            read(v_ILINE, v_CMD_WR);
            MOSI_wr <= v_CMD_WR;
            nSS_spi <= '0';
            wait for 100 ns;

            for i in 0 to 31 loop
                s_mosi  <= MOSI_wr(31 - i);
                s_clock <= '1';
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            wait for 200 ns;
            nSS_spi <= '1';
            wait for 5 us;

            -- lettura
            MOSI_rd <= "00100001" & "00000001";
            nSS_spi <= '0';
            wait for 1 us;

            for i in 0 to 15 loop
                s_mosi  <= MOSI_rd(15 - i);
                s_clock <= '1';
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            for i in 0 to 18 loop
                s_clock <= '1';
                if (s_miso /= 'Z') then
                    MISO_rd(cnt_bit) <= s_miso;
                    cnt_bit := cnt_bit - 1;
                end if;
                wait for 500 ns;
                s_clock <= '0';
                wait for 500 ns;
            end loop;

            cnt_bit := 15;
            nSS_spi <= '1';
            wait for 2 us;

            -- Scrivo in output_results.txt
            write(v_OLINE, MISO_rd, right, 16);
            writeline(file_OUTPUT_LONG, v_OLINE);

        end loop;

        -- Chiudo i file di I/O
        file_close(file_INPUT_LONG);
        file_close(file_OUTPUT_LONG);

        wait;
    end process;

end architecture;