library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity decodeur_8bits is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        comp_in  : in  STD_LOGIC;
        data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end decodeur_8bits;

architecture Behavioral of decodeur_8bits is
    signal compteur_interne : unsigned(7 downto 0) := (others => '0');
    signal prescaler        : unsigned(0 downto 0) := (others => '0');
    -- prescaler sur 1 bit = divise par 2  16MHz effectif
    -- en 10s : 16M  10 = 160 coups  dans les 255 
begin
    process(clk, reset)
    begin
        if reset = '1' then
            compteur_interne <= (others => '0');
            data_out         <= (others => '0');
            prescaler        <= (others => '0');
        elsif rising_edge(clk) then
            if comp_in = '1' then
                prescaler <= prescaler + 1;
                if prescaler = 0 then  -- compte 1 fois sur 2
                    compteur_interne <= compteur_interne + 1;
                end if;
            else
                data_out <= std_logic_vector(compteur_interne);
            end if;
        end if;
    end process;
end Behavioral;
