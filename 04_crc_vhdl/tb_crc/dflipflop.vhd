--**********************************************************************************
--* Flip-flop di tipo D con parallelismo unitario sia in ingresso sia in uscita
--**********************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dflipflop is
    port (
        clk, rst, en : in std_logic;
        d            : in std_logic;
        q            : out std_logic
    );
end dflipflop;

architecture structure of dflipflop is
begin

    process (clk, rst)
    begin
        -- reset attivo --> inizializzo Q a 0:
        if (rst = '1') then
            q <= '0';
        -- enable attivo sul fronte di salita del clock: 
        elsif (clk'event and clk = '1') then
            if (en = '1') then
                q <= d;
            end if;
        end if;
    end process;

end structure;