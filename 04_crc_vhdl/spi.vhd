library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
	port (
		CK, SCK : in std_logic;                      -- main clock e clock di sistema
		nSS     : in std_logic;                      -- slave select (attivo basso)
		RST     : in std_logic;                      -- reset (attivo alto)
		MOSI    : in std_logic;                      -- Master Out Slave In
		MISO    : out std_logic;                     -- Master In Slave Out
		RD, WR  : out std_logic;                     -- segnali di controllo per memoria
		A       : out std_logic_vector(7 downto 0);  -- indirizzo di memoria
		DIN     : out std_logic_vector(15 downto 0); -- ingresso memoria (uscita per spi)
		DOUT    : in std_logic_vector(15 downto 0)   -- uscita memoria (ingresso per spi)
	);
end spi;

architecture structure of spi is

	--**********************************************************************************
	--* Elenco degli stati
	--**********************************************************************************

	type state_type is (
		RESET, WAIT_nSS,
		-- trasmissione CMD su MOSI ----------------------------------------------------
		CMD_WAIT_HI, CMD_SCK_HI, CMD_SCK_LOx, CMD_SCK_LOy, CMD_SCK_LOz, CMD_CNT_UP, UP_CMD, UP_CMD_LOz, CMD_CNT_UP_TC,
		-- trasmissione ADD su MOSI ----------------------------------------------------
		ADD_SCK_HI, ADD_SCK_LOx, ADD_SCK_LOy, ADD_SCK_LOz, ADD_CNT_UP,
		-- trasmissione DIN su MOSI ----------------------------------------------------
		DIN_WAIT_HI, DIN_CNT_UP_TC, DIN_SCK_HI, DIN_SCK_LOx, DIN_SCK_LOy, DIN_SCK_LOz, DIN_CNT_UP,
		-- scrittura DIN in memoria ----------------------------------------------------
		UP_MEMx, UP_MEMy,
		-- trasmissione DOUT su MISO --------------------------------------------------
		DOUT_SCK_HIx, DOUT_SCK_HIy, DOUT_SHIFT, DOUT_MUX, DOUT_LSB, DOUT_MSB, DONE
	);
	signal PS, NS : state_type; -- present state (PS) e next state (NS)

	--**********************************************************************************
	--* Definizione segnali interni (N.B. I SEGNALI DI CONTROLLO SONO TUTTI ATTIVI ALTI)
	--**********************************************************************************

	signal SE_CMD, RST_CMD_SR, RST_CMD, CMD_EN : std_logic; -- comando
	signal SE_ADD, RST_ADD_SR, RST_ADD, ADD_EN : std_logic; -- indirizzo
	signal SE_DIN, RST_DIN_SR, RST_DIN, DIN_EN : std_logic; -- dato in scrittura
	signal SE_DOUT, LD_DOUT, RST_DOUT_SR       : std_logic; -- dato in lettura
	signal RST_CNT, CNT_EN, TC8, TC16, TC32    : std_logic; -- contatore
	signal SCK_LOx, SCK_HIx, EN_SCK_EDGE       : std_logic; -- rilevatori dei fronti di SCK
	signal S_MISO                              : std_logic; -- selettore mux di uscita

	signal CMD_SR_OUT : std_logic_vector(7 downto 0);
	signal CMD_OUT    : std_logic_vector(7 downto 0);
	signal R_EN, W_EN : std_logic;
	signal ADD_SR_OUT : std_logic_vector(7 downto 0);
	signal DIN_SR_OUT : std_logic_vector(15 downto 0);
	signal OUT_MUX    : std_logic;

	--**********************************************************************************
	--* Dichiarazione component
	--**********************************************************************************

	-- registro con ingressi e uscite su N bit
	component reg is
		generic (N : integer);
		port (
			d            : in std_logic_vector(N - 1 downto 0);
			clk, rst, en : in std_logic;
			q            : out std_logic_vector(N - 1 downto 0)
		);
	end component;

	-- shift register SIPO con uscite su N bit
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

	-- contatore a 5 bit con rilevatore di 7, 15, 31
	component counter is
		port (
			en, rst, clk    : in std_logic;
			tc8, tc16, tc32 : out std_logic
		);
	end component;

	-- rilevatore del comando di scrittura o lettura
	component command is
		port (
			cmd  : in std_logic_vector(7 downto 0);
			w_en : out std_logic;
			r_en : out std_logic
		);
	end component;

	-- rilevatore dei fronti di SCK
	component clock_edge is
		generic (N : integer := 4);
		port (
			sck          : in std_logic;
			clk, en, rst : in std_logic;
			sck_lox      : out std_logic;
			sck_hix      : out std_logic
		);
	end component;

	-- multiplexer a due vie che collega l'ingresso all'uscita oppure la mette in Z
	component mux_z is
		port (
			ingresso : in std_logic; -- input
			s        : in std_logic; -- selettore
			uscita   : out std_logic -- output 
		);
	end component;

	--**********************************************************************************
	--* Architecture
	--**********************************************************************************

begin

	--* STEP 1: ASM dei controlli ******************************************************
	controlASM : process (PS, nSS, SCK_LOx, SCK_HIx, TC8, TC16, TC32, W_EN, R_EN)
	begin

		--------------------------------------------------------------------------------
		-- Valori di default -----------------------------------------------------------
		SE_CMD     <= '0';
		RST_CMD_SR <= '0';
		RST_CMD    <= '0';
		CMD_EN     <= '0';
		--
		SE_ADD     <= '0';
		RST_ADD_SR <= '0';
		RST_ADD    <= '0';
		ADD_EN     <= '0';
		--
		SE_DIN     <= '0';
		RST_DIN_SR <= '0';
		RST_DIN    <= '0';
		DIN_EN     <= '0';
		--
		SE_DOUT     <= '0';
		LD_DOUT     <= '0';
		RST_DOUT_SR <= '0';
		S_MISO      <= '0';
		--
		WR <= '0';
		RD <= '0';
		--
		RST_CNT <= '0';
		CNT_EN  <= '0';
		--
		EN_SCK_EDGE <= '1';
		--------------------------------------------------------------------------------

		case PS is

			when RESET => -- resetto la macchina
				RST_CMD_SR  <= '1';
				RST_CMD     <= '1';
				RST_ADD_SR  <= '1';
				RST_ADD     <= '1';
				RST_DIN_SR  <= '1';
				RST_DIN     <= '1';
				RST_DOUT_SR <= '1';
				RST_CNT     <= '1';
				-------------------
				NS <= WAIT_nSS;

				---- ASM_CMD ---------------------------------------------------------------
				-- Il master invia gli 8 bit di CMD sul MOSI
			when WAIT_nSS => -- reset contatore (TC8, TC16, TC32 = 0), aspetto asserimento di nSS
				RST_CNT <= '1';
				-------------------
				if (nSS = '0') then
					NS <= CMD_WAIT_HI;
				else
					NS <= WAIT_nSS;
				end if;

			when CMD_WAIT_HI => -- valori di default, aspetto fronte di salita SCK
				if (SCK_HIx = '1') then
					NS <= CMD_SCK_HI;
				else
					NS <= CMD_WAIT_HI;
				end if;

			when CMD_SCK_HI => -- valori di default, aspetto fronte di discesa SCK per campionare il MOSI
				if (SCK_LOx = '1') then
					NS <= CMD_SCK_LOx;
				else
					NS <= CMD_SCK_HI;
				end if;

			when CMD_SCK_LOx => -- CMD_SR campiona MOSI = CMD(7-CNT) 
				SE_CMD <= '1';
				-------------------
				NS <= CMD_SCK_LOy;

			when CMD_SCK_LOy => -- stato di attesa, valori di default
				if (TC8 = '1') then
					NS <= UP_CMD;
				else
					NS <= CMD_SCK_LOz;
				end if;

			when CMD_SCK_LOz => -- valori di default, aspetto fronte di salita SCK per incrementare il contatore
				if (SCK_HIx = '1') then
					NS <= CMD_CNT_UP;
				else
					NS <= CMD_SCK_LOz;
				end if;

			when CMD_CNT_UP => -- incremento contatore con TC8=0
				CNT_EN <= '1';
				-------------------
				NS <= CMD_SCK_HI;

			when UP_CMD => -- memorizzo CMD in CMD_REG
				CMD_EN <= '1';
				-------------------
				NS <= UP_CMD_LOz;

			when UP_CMD_LOz => -- valori di default, aspetto fronte di salita SCK per incrementare il contatore 
				if (SCK_HIx = '1') then
					NS <= CMD_CNT_UP_TC;
				else
					NS <= UP_CMD_LOz;
				end if;

			when CMD_CNT_UP_TC => -- incremento contatore con TC8=1
				CNT_EN <= '1';
				-------------------
				NS <= ADD_SCK_HI;

				---- ASM_ADD ---------------------------------------------------------------
				-- Il master invia gli 8 bit di indirizzo sul MOSI
			when ADD_SCK_HI => -- valori di default, aspetto fronte di discesa SCK per campionare il MOSI
				if (SCK_LOx = '1') then
					NS <= ADD_SCK_LOx;
				else
					NS <= ADD_SCK_HI;
				end if;

			when ADD_SCK_LOx => -- ADD_SR campiona MOSI = ADD(15-CNT) 
				SE_ADD <= '1';
				-------------------
				NS <= ADD_SCK_LOy;

			when ADD_SCK_LOy => -- stato di attesa, valori di default
				if (TC16 = '1') then
					if (W_EN = '1') then -- scrittura
						NS <= DIN_WAIT_HI;
					elsif (R_EN = '1') then -- lettura
						NS <= DOUT_SCK_HIx;
					else
						NS <= RESET;
					end if;
				else
					NS <= ADD_SCK_LOz;
				end if;

			when ADD_SCK_LOz => -- valori di default, aspetto fronte di salita SCK per incrementare il contatore
				if (SCK_HIx = '1') then
					NS <= ADD_CNT_UP;
				else
					NS <= ADD_SCK_LOz;
				end if;

			when ADD_CNT_UP => -- incremento contatore con TC16=0
				CNT_EN <= '1';
				-------------------
				NS <= ADD_SCK_HI;

				---- ASM_DIN ---------------------------------------------------------------
				-- Il master invia i 16 bit di DIN sul MOSI
			when DIN_WAIT_HI => -- valori di default, aspetto fronte di salita SCK per incrementare il contatore
				if (SCK_HIx = '1') then
					NS <= DIN_CNT_UP_TC;
				else
					NS <= DIN_WAIT_HI;
				end if;

			when DIN_CNT_UP_TC => -- incremento il contatore con TC16=1
				CNT_EN <= '1';
				-------------------
				NS <= DIN_SCK_HI;

			when DIN_SCK_HI => -- valori di default, aspetto fronte di discesa SCK per campionare il MOSI
				if (SCK_LOx = '1') then
					NS <= DIN_SCK_LOx;
				else
					NS <= DIN_SCK_HI;
				end if;

			when DIN_SCK_LOx => -- DIN_SR campiona MOSI = DIN(31-CNT) 
				SE_DIN <= '1';
				-------------------
				NS <= DIN_SCK_LOy;

			when DIN_SCK_LOy => -- stato di attesa, valori di default
				if (TC32 = '0') then
					NS <= DIN_SCK_LOz;
				else
					NS <= UP_MEMx;
				end if;

			when DIN_SCK_LOz => -- valori di default, aspetto fronte di salita SCK per incrementare il contatore
				if (SCK_HIx = '1') then
					NS <= DIN_CNT_UP;
				else
					NS <= DIN_SCK_LOz;
				end if;

			when DIN_CNT_UP => -- incremento il contatore con TC32=0
				CNT_EN <= '1';
				-------------------
				NS <= DIN_SCK_HI;

			when UP_MEMx => -- memorizzo A in ADD_REG e DIN in DIN_REG
				DIN_EN <= '1';
				ADD_EN <= '1';
				-------------------
				NS <= UP_MEMy;

			when UP_MEMy => -- invio il segnale di scrittura
				WR <= '1';
				-------------------
				NS <= DONE;

				---- ASM_DOUT --------------------------------------------------------------
				-- Lo slave invia i 16 bit di DOUT sul MISO
			when DOUT_SCK_HIx => -- memorizzo A in ADD_REG
				ADD_EN <= '1';
				-------------------
				NS <= DOUT_SCK_HIy;

			when DOUT_SCK_HIy => -- invio il segnale di lettura, carico DOUT nel PISO, aspetto fronte di salita SCK per iniziare a mandare i dati sul MISO
				RD      <= '1';
				LD_DOUT <= '1';
				-------------------
				if (SCK_HIx = '1') then
					NS <= DOUT_MSB;
				else
					NS <= DOUT_SCK_HIy;
				end if;

			when DOUT_MSB => -- invio MSB di DOUT sull'ingresso 0 del mux, ma lascio ancora il MISO in Z
				SE_DOUT <= '1';  -- OUT_MUX = DOUT(15)
				CNT_EN  <= '1';  -- CNT++
				S_MISO  <= '0';  -- MISO in Z
				-------------------
				NS <= DOUT_MUX;

			when DOUT_SHIFT =>
				SE_DOUT <= '1'; -- OUT_MUX = DOUT(31-CNT)
				CNT_EN  <= '1'; -- CNT++
				S_MISO  <= '1'; -- dati su MISO
				-------------------
				NS <= DOUT_MUX;

			when DOUT_MUX => -- invio dati su MISO; aspetto fronte di salita di SCK per fare un nuovo shift o TC32 per terminare la transazione
				S_MISO <= '1';
				-------------------
				if (TC32 = '0' and SCK_HIx = '1') then
					NS <= DOUT_SHIFT;
				elsif (TC32 = '0' and SCK_HIx = '0') then
					NS <= DOUT_MUX;
				else
					NS <= DOUT_LSB;
				end if;

			when DOUT_LSB => -- aspetto fronte di salita di SCK o deasserimento nSS per andare in DONE
				S_MISO <= '1';
				-------------------
				if (nSS = '1' or SCK_HIx = '1') then
					NS <= DONE;
				else
					NS <= DOUT_LSB;
				end if;

			when DONE => -- stato di done (aspetto il deasserimento di nSS)
				if (nSS = '1') then
					NS <= WAIT_nSS;
				else
					NS <= DONE;
				end if;

			when others =>
				NS <= RESET;

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

	CMD_SR : SIPO
	generic map(N => 8)
	port map(clk => CK, en => SE_CMD, rst => RST_CMD_SR, d => MOSI, q => CMD_SR_OUT);

	CMD_REG : reg
	generic map(N => 8)
	port map(clk => CK, en => CMD_EN, rst => RST_CMD, d => CMD_SR_OUT, q => CMD_OUT);

	ADD_SR : SIPO
	generic map(N => 8)
	port map(clk => CK, en => SE_ADD, rst => RST_ADD_SR, d => MOSI, q => ADD_SR_OUT);

	ADD_REG : reg
	generic map(N => 8)
	port map(clk => CK, en => ADD_EN, rst => RST_ADD, d => ADD_SR_OUT, q => A);

	DIN_SR : SIPO
	generic map(N => 16)
	port map(clk => CK, en => SE_DIN, rst => RST_DIN_SR, d => MOSI, q => DIN_SR_OUT);

	DIN_REG : reg
	generic map(N => 16)
	port map(clk => CK, en => DIN_EN, rst => RST_DIN, d => DIN_SR_OUT, q => DIN);

	DOUT_SR : PISO
	generic map(N => 16)
	port map(clk => CK, en => LD_DOUT, se => SE_DOUT, rst => RST_DOUT_SR, d => DOUT, q => OUT_MUX);

	COUNT : counter
	port map(clk => CK, en => CNT_EN, rst => RST_CNT, tc8 => TC8, tc16 => TC16, tc32 => TC32);

	CMD_BLOCK : command
	port map(cmd => CMD_OUT, w_en => W_EN, r_en => R_EN);

	EDGE : clock_edge
	generic map(N => 4)
	port map(clk => CK, sck => SCK, rst => RST, en => EN_SCK_EDGE, sck_lox => SCK_LOx, sck_hix => SCK_HIx);

	EXIT_MUX : mux_z
	port map(ingresso => OUT_MUX, S => S_MISO, uscita => MISO);

end structure;