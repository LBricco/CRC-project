library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc is
    port (
        CK        : in std_logic;
        RST       : in std_logic;
        START     : in std_logic;
        DIN       : in std_logic_vector(15 downto 0);
        DOUT      : out std_logic_vector(15 downto 0);
        CTRL      : in std_logic;  -- reset calcolatore di CRC
        STATUS    : out std_logic; -- stato calcolatore di CRC (busy/free)
        CTRL_OUT  : out std_logic; -- dato da scrivere nel Control Register
        WR_DOUT   : out std_logic; -- enable scrittura in CRC Out Register
        WR_CTRL   : out std_logic; -- enable scrittura in Control Register
        WR_STATUS : out std_logic  -- enable scrittura in Status Register
    );
end crc;

architecture structure of crc is

    --**********************************************************************************
    --* Elenco degli stati
    --**********************************************************************************

    type state_type is (
        RESET, IDLE, IDLE_RESET, EXTERNAL_RESET, INTERNAL_RESET,
        LOAD_PRTL, SHIFT_PRTL, CALC_CRC_PRTL, CNT_UP_PRTL,
        LOAD_DIN, SHIFT_DIN, CALC_CRC_DIN, CNT_UP_DIN, LOAD_CRC_DIN,
        LOAD_FINALE, SHIFT_FINALE, CALC_CRC_FINALE, CNT_UP_FINALE, LOAD_CRC_FINALE,
        DONE
    );
    signal PS, NS : state_type; -- present state (PS) e next state (NS)

    --**********************************************************************************
    --* Definizione segnali interni (N.B. I SEGNALI DI CONTROLLO SONO TUTTI ATTIVI ALTI)
    --**********************************************************************************

    signal S_DIN             : std_logic_vector(1 downto 0);  -- selettore MUX_DIN (2 bit)
    signal S_DOUT            : std_logic;                     -- selettore MUX_DOUT (1 bit)
    signal S_STATUS          : std_logic;                     -- selettore MUX_STATUS (1 bit)
    signal LD_PISO, SE_PISO  : std_logic;                     -- controlli PISO_DIN
    signal RST_PISO          : std_logic;                     -- reset PISO_DIN
    signal EN_LFSR, RST_LFSR : std_logic;                     -- controlli LFSR
    signal EN_PRTL, RST_PRTL : std_logic;                     -- controlli REG_PARTIAL
    signal EN_FNL, RST_FNL   : std_logic;                     -- controlli REG_FINAL
    signal EN_CNT, RST_CNT   : std_logic;                     -- controlli contatore
    signal TC                : std_logic;                     -- terminal count
    signal DATA_IN_PISO      : std_logic_vector(15 downto 0); -- ingresso PISO_DIN
    signal DATA_IN_LFSR      : std_logic;                     -- ingresso LFSR
    signal CRC               : std_logic_vector(15 downto 0); -- uscita LFSR
    signal CRC_PRTL, CRC_FNL : std_logic_vector(15 downto 0); -- uscite REG_PARTIAL e REG_FINAL
    signal zeros             : std_logic_vector(15 downto 0); -- stringa di 16 zeri (per il reset)
    signal CNT               : integer;                       -- uscita contatore

    --**********************************************************************************
    --* Dichiarazione component
    --**********************************************************************************

    -- linear feedback shift register (LFSR)
    component lfsr_crc16ccitt is
        port (
            clk, rst, en : in std_logic;
            msg          : in std_logic;
            crc          : buffer std_logic_vector(15 downto 0)
        );
    end component;

    -- registro con ingressi e uscite su N bit
    component reg is
        generic (N : integer);
        port (
            d            : in std_logic_vector(N - 1 downto 0);
            clk, rst, en : in std_logic;
            q            : out std_logic_vector(N - 1 downto 0)
        );
    end component;

    -- registro parallel in serial out con ingressi su N bit
    component PISO is
        generic (N : integer := 16);
        port (
            clk : in std_logic;
            se  : in std_logic;
            rst : in std_logic;
            en  : in std_logic;
            d   : in std_logic_vector(N - 1 downto 0);
            q   : out std_logic
        );
    end component;

    component contatore is
        generic (N : integer := 16);
        port (
            clock   : in std_logic;
            rst, en : in std_logic;
            TC      : out std_logic;
            cnt     : buffer integer range 0 to N + 1
        );
    end component;

    component mux_1_bit2to1 is
        port (
            IN_0, IN_1 : in std_logic; -- input a 1 bit
            s          : in std_logic; -- selettore a 1 bit
            uscita     : out std_logic -- output a 1 bit
        );
    end component;

    -- multiplexer a due vie (N bit)
    component mux_n_bits2to1 is
        generic (N : integer := 16);
        port (
            IN_0, IN_1 : in std_logic_vector(N - 1 downto 0); -- input a N bit
            s          : in std_logic;                        -- selettore a 1 bit
            uscita     : out std_logic_vector(N - 1 downto 0) -- output a N bit
        );
    end component;

    -- multiplexer a 4 vie
    component mux_n_bits4to1 is
        generic (N : integer := 16);
        port (
            IN_0, IN_1, IN_2, IN_3 : in std_logic_vector(N - 1 downto 0); -- input a N bit
            s                      : in std_logic_vector(1 downto 0);     -- selettore a 2 bit
            uscita                 : out std_logic_vector(N - 1 downto 0) -- output a N bit
        );
    end component;

    --**********************************************************************************
    --* Architecture
    --**********************************************************************************

begin

    --* STEP 1: ASM dei controlli ******************************************************
    controlASM : process (PS, START, CTRL, TC)
    begin

        --------------------------------------------------------------------------------
        -- Valori di default -----------------------------------------------------------
        S_DIN    <= "01"; -- rilevazione dati da register file
        S_DOUT   <= '1';  -- caricamento risultato nel CRC Out Register
        S_STATUS <= '1';  -- CRC "free"
        --
        LD_PISO  <= '0';
        SE_PISO  <= '0';
        RST_PISO <= '0';
        --
        EN_LFSR  <= '0';
        RST_LFSR <= '0';
        --
        EN_PRTL  <= '0';
        RST_PRTL <= '0';
        --
        EN_FNL  <= '0';
        RST_FNL <= '0';
        --
        EN_CNT  <= '0';
        RST_CNT <= '0';
        --
        WR_DOUT   <= '0';
        WR_CTRL   <= '0';
        WR_STATUS <= '0';
        --------------------------------------------------------------------------------

        case PS is

            when RESET => -- resetto la macchina
                S_DOUT    <= '0';
                WR_DOUT   <= '1';
                WR_CTRL   <= '1';
                S_STATUS  <= '1';
                WR_STATUS <= '1';
                RST_LFSR  <= '1';
                RST_PRTL  <= '1';
                RST_FNL   <= '1';
                RST_CNT   <= '1';
                -------------------
                NS <= IDLE;

            when IDLE => -- valori di default
                if (START = '1') then
                    if (CTRL = '1') then
                        NS <= EXTERNAL_RESET;
                    else
                        NS <= INTERNAL_RESET;
                    end if;
                else -- START=0
                    if (CTRL = '1') then
                        NS <= EXTERNAL_RESET;
                    else
                        NS <= IDLE;
                    end if;
                end if;

            when EXTERNAL_RESET => -- reset innescato dall'esterno
                RST_LFSR <= '1';
                RST_PRTL <= '1';
                RST_FNL  <= '1';
                S_DOUT   <= '0'; -- giro il mux di uscita
                WR_DOUT  <= '1'; -- scrivo 16 zeri nel CRC Out Register 
                -------------------
                NS <= IDLE_RESET;

            when IDLE_RESET => -- attesa dello START dopo il reset esterno
                WR_CTRL <= '1';    -- reset Control Register
                -------------------
                if (START = '1') then
                    NS <= LOAD_PRTL;
                else
                    NS <= IDLE;
                end if;

            when INTERNAL_RESET => -- reset interno, preliminare a qualsiasi calcolo
                RST_LFSR <= '1';
                -------------------
                NS <= LOAD_PRTL;

            when LOAD_PRTL => -- carico il CRC parziale del ciclo precedente nel PISO (N.B. inutile al primo giro perché la macchina è stata appena resettata quindi carico tutti zeri, però lo faccio lo stesso perché l'SPI è molto lenta e non se ne accorge nemmeno)
                S_DIN   <= "00";  -- giro il mux di ingresso su REG_PARTIAL
                LD_PISO <= '1';   -- carico il PISO
                RST_CNT <= '1';   -- resetto il contatore
                -------------------
                NS <= SHIFT_PRTL;

            when SHIFT_PRTL => -- shifto di 1 posizione il parziale memorizzato nel PISO e mando il LSB al calcolatore di CRC
                S_DIN   <= "00";   -- giro il mux di ingresso su REG_PARTIAL
                SE_PISO <= '1';    -- shift PISO
                -------------------
                NS <= CALC_CRC_PRTL;

            when CALC_CRC_PRTL => -- calcolo il CRC appendendo in coda il bit inviato dal PISO
                S_DIN   <= "00";      -- giro il mux di ingresso su REG_PARTIAL
                EN_LFSR <= '1';       -- abilito il calcolatore di CRC
                -------------------
                if (TC = '1') then -- CNT=15
                    NS <= LOAD_DIN;
                else -- CNT<15
                    NS <= CNT_UP_PRTL;
                end if;

            when CNT_UP_PRTL => -- incremento di 1 il contatore
                S_DIN  <= "00";     -- giro il mux di ingresso su REG_PARTIAL
                EN_CNT <= '1';      -- cnt++
                -------------------
                NS <= SHIFT_PRTL;

            when LOAD_DIN =>  -- carico il contenuto del Data In Register nel PISO + dico all'SPI che il CRC è busy
                S_STATUS  <= '0'; -- giro il mux su "busy"
                WR_STATUS <= '1'; -- scrivo "busy" nello Status Register
                LD_PISO   <= '1'; -- carico il PISO
                RST_CNT   <= '1'; -- resetto il contatore
                -------------------
                NS <= SHIFT_DIN;

            when SHIFT_DIN => -- shifto di 1 posizione il dato memorizzato nel PISO e mando il LSB al calcolatore di CRC
                S_STATUS <= '0';  -- giro il mux su "busy"
                SE_PISO  <= '1';  -- shift PISO
                -------------------
                NS <= CALC_CRC_DIN;

            when CALC_CRC_DIN => -- calcolo il CRC appendendo in coda il bit inviato dal PISO
                S_STATUS <= '0';     -- giro il mux su "busy"
                EN_LFSR  <= '1';     -- abilito il calcolatore di CRC
                -------------------
                if (TC = '1') then -- CNT=15
                    NS <= LOAD_CRC_DIN;
                else -- CNT<15
                    NS <= CNT_UP_DIN;
                end if;

            when CNT_UP_DIN => -- incremento di 1 il contatore
                S_STATUS <= '0';   -- giro il mux su "busy"
                EN_CNT   <= '1';   -- cnt++
                -------------------
                NS <= SHIFT_DIN;

            when LOAD_CRC_DIN => -- carico il nuovo CRC parziale in REG_PARTIAL
                S_STATUS <= '0';     -- giro il mux su "busy"
                EN_PRTL  <= '1';     -- carico il risultato in REG_PARTIAL
                -------------------
                NS <= LOAD_FINALE;

            when LOAD_FINALE => -- carico i 16 zeri finali nel PISO
                S_STATUS <= '0';    -- giro il mux su "busy"
                S_DIN    <= "10";   -- giro il mux sui 16 zeri (append finale)
                LD_PISO  <= '1';    -- carico il PISO
                RST_CNT  <= '1';    -- resetto il contatore
                -------------------
                NS <= SHIFT_FINALE;

            when SHIFT_FINALE => -- shifto di 1 posizione il dato memorizzato nel PISO e mando il LSB al calcolatore di CRC
                S_DIN    <= "10";    -- giro il mux sui 16 zeri (append finale)
                S_STATUS <= '0';     -- giro il mux su "busy"
                SE_PISO  <= '1';     -- shift PISO
                -------------------
                NS <= CALC_CRC_FINALE;

            when CALC_CRC_FINALE => -- calcolo il CRC appendendo in coda il bit inviato dal PISO
                S_DIN    <= "10";       -- giro il mux sui 16 zeri (append finale)
                S_STATUS <= '0';        -- giro il mux su "busy"
                EN_LFSR  <= '1';        -- abilito il calcolatore di CRC
                -------------------
                if (TC = '1') then -- CNT=15
                    NS <= LOAD_CRC_FINALE;
                else -- CNT<15
                    NS <= CNT_UP_FINALE;
                end if;

            when CNT_UP_FINALE => -- incremento di 1 il contatore
                S_DIN    <= "10";     -- giro il mux sui 16 zeri (append finale)
                S_STATUS <= '0';      -- giro il mux su "busy"
                EN_CNT   <= '1';      -- cnt++
                -------------------
                NS <= SHIFT_FINALE;

            when LOAD_CRC_FINALE => -- carico il CRC definitivo nel registro REG_FINAL + "libero" il CRC
                S_DIN     <= "10";      -- giro il mux sui 16 zeri (append finale)
                S_STATUS  <= '1';       -- giro il mux su "free"
                WR_STATUS <= '1';       -- scrivo "free" nello Status Register
                EN_FNL    <= '1';       -- carico il risultato in REG_FINAL
                -------------------
                NS <= DONE;

            when DONE =>    -- scrivo il risultato in memoria
                WR_DOUT <= '1'; -- scrivo nel CRC Out Register
                -------------------
                if (START = '1') then
                    NS <= DONE;
                else
                    NS <= IDLE;
                end if;

            when others =>
                NS <= IDLE;

        end case;

    end process controlASM;

    --* STEP 2: transizioni di stato ***************************************************
    transitionsFSM : process (CK, RST)
    begin
        if (RST = '1') then -- reset asincrono attivo alto
            PS <= RESET;
        elsif (CK'event and CK = '1') then -- fronte di salita del CK
            PS <= NS;
        end if;
    end process transitionsFSM;

    --* STEP 3: datapath ***************************************************************
    zeros    <= (others => '0');
    CTRL_OUT <= '0';

    MUX_DIN : mux_n_bits4to1
    generic map(N => 16)
    port map(IN_0 => CRC_PRTL, IN_1 => DIN, IN_2 => zeros, IN_3 => zeros, s => S_DIN, uscita => DATA_IN_PISO);

    PISO_DIN : PISO
    generic map(N => 16)
    port map(clk => CK, se => SE_PISO, rst => RST_PISO, en => LD_PISO, d => DATA_IN_PISO, q => DATA_IN_LFSR);

    LFSR : lfsr_crc16ccitt
    port map(clk => CK, rst => RST_LFSR, en => EN_LFSR, msg => DATA_IN_LFSR, crc => CRC);

    REG_PARTIAL : reg
    generic map(N => 16)
    port map(d => CRC, clk => CK, rst => RST_PRTL, en => EN_PRTL, q => CRC_PRTL);

    REG_FINAL : reg
    generic map(N => 16)
    port map(d => CRC, clk => CK, rst => RST_FNL, en => EN_FNL, q => CRC_FNL);

    MUX_DOUT : mux_n_bits2to1
    generic map(N => 16)
    port map(IN_0 => zeros, IN_1 => CRC_FNL, s => S_DOUT, uscita => DOUT);

    MUX_STATUS : mux_1_bit2to1
    port map(IN_0 => '0', IN_1 => '1', s => S_STATUS, uscita => STATUS);

    COUNT_16 : contatore
    generic map(N => 15)
    port map(clock => CK, rst => RST_CNT, en => EN_CNT, TC => TC, cnt => CNT);

end structure;