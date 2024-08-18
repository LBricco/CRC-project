library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crc_simple is
end tb_crc_simple;

architecture behavioral of tb_crc_simple is

    -- definizione segnali interni
    signal clock   : std_logic := '0';              -- main clock
    signal s_clock : std_logic := '0';              -- serial clock
    signal nSS_spi : std_logic := '1';              -- slave select
    signal reset   : std_logic := '0';              -- reset esterno
    signal s_mosi  : std_logic := '1';              -- MOSI seriale
    signal s_miso  : std_logic := 'Z';              -- MISO seriale
    signal MOSI_wr : std_logic_vector(31 downto 0); -- vettore dati per WR
    signal MOSI_rd : std_logic_vector(15 downto 0); -- vettore dati per RD
    signal MISO_rd : std_logic_vector(15 downto 0); -- vettore restituito su MISO

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

    -- Process di lettura e scrittura
    -- Effettuo alcune transazioni
    RD_WR_process : process
        variable cnt_bit : integer := 15;
    begin
        wait for 100 ns;
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- SCRITTURA NEL DATA IN REGISTER: w001206
        -- CMD 00100000 '20' (w)
        -- ADD 00000000 '00'
        -- DIN 0001001000000110 '1206'
        MOSI_wr <= "00100000" & "00000000" & "0001001000000110";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us;

        -- LETTURA DEL CRC OUT REGISTER: r01
        -- CMD 00100001 '21' (r)
        -- ADD 00000001 '01'
        MOSI_rd <= "00100001" & "00000001";
        nSS_spi <= '0';
        wait for 1 us;

        for i in 0 to 15 loop --invio dati su mosi
            s_mosi  <= MOSI_rd(15 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        --cnt_bit <= 15;
        for i in 0 to 18 loop -- aspetto il dato sul MISO: CRC(5555) = FB1A
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
        wait for 5 us;

        -- SCRITTURA NEL DATA IN REGISTER: w002203
        -- CMD 00100000 '20' (w)
        -- ADD 00000000 '00'
        -- DIN 0010001000000011 '2203'
        MOSI_wr <= "00100000" & "00000000" & "0010001000000011";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us;

        -- LETTURA DEL CRC OUT REGISTER: r01
        -- CMD 00100001 '21' (r)
        -- ADD 00000001 '01'
        MOSI_rd <= "00100001" & "00000001";
        nSS_spi <= '0';
        wait for 1 us;

        for i in 0 to 15 loop --invio dati su mosi
            s_mosi  <= MOSI_rd(15 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        for i in 0 to 18 loop -- aspetto il dato sul MISO: CRC(5555AAAA) = 9A55
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
        wait for 5 us;

        -- SCRITTURA NEL DATA IN REGISTER: w000306
        -- CMD 00100000 '20' (w)
        -- ADD 00000000 '00'
        -- DIN 0000001100000110 '0306'
        MOSI_wr <= "00100000" & "00000000" & "0000001100000110";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us;

        -- SCRITTURA NEL CONTROL REGISTER: w020001
        -- CMD 00100000 '20' (w)
        -- ADD 00000010 '02'
        -- DIN 0000000000000001 '0001'
        MOSI_wr <= "00100000" & "00000010" & "0000000000000001";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us; -- tempo affinche il dato venga mandato in memoria

        -- SCRITTURA NEL DATA IN REGISTER: w003f1b
        -- CMD 00100000 '20' (w)
        -- ADD 00000000 '00'
        -- DIN 0011111100011011 '3f1b'
        MOSI_wr <= "00100000" & "00000000" & "0011111100011011";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us;

        -- LETTURA DEL CRC OUT REGISTER: r01
        -- CMD 00100001 '21' (r)
        -- ADD 00000001 '01'
        MOSI_rd <= "00100001" & "00000001";
        nSS_spi <= '0';
        wait for 1 us;

        for i in 0 to 15 loop --invio dati su mosi
            s_mosi  <= MOSI_rd(15 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        for i in 0 to 18 loop -- aspetto il dato sul MISO: CRC(3F1B) = B6F1
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
        wait for 5 us;

        -- SCRITTURA NEL CONTROL REGISTER: w020001
        -- CMD 00100000 '20' (w)
        -- ADD 00000010 '02'
        -- DIN 0000000000000001 '0001'
        MOSI_wr <= "00100000" & "00000010" & "0000000000000001";
        nSS_spi <= '0';
        wait for 100 ns;

        for i in 0 to 31 loop --invio dati su mosi
            s_mosi  <= MOSI_wr(31 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        wait for 200 ns;
        nSS_spi <= '1';
        wait for 5 us; -- tempo affinche il dato venga mandato in memoria

        -- LETTURA DELLO STATUS REGISTER: r03
        -- CMD 00100001 '21' (r)
        -- ADD 00000011 '03'
        MOSI_rd <= "00100001" & "00000011";
        nSS_spi <= '0';
        wait for 1 us;

        for i in 0 to 15 loop --invio dati su mosi
            s_mosi  <= MOSI_rd(15 - i);
            s_clock <= '1';
            wait for 500 ns;
            s_clock <= '0';
            wait for 500 ns;
        end loop;

        for i in 0 to 18 loop -- aspetto il dato sul MISO
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
        wait for 5 us;

    end process RD_WR_process;

end architecture;