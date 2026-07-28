library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity logic_control is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        start      : in  STD_LOGIC;
        comp_in    : in  STD_LOGIC;
        pd_input   : in  STD_LOGIC;
        din        : in  STD_LOGIC_VECTOR(7 downto 0);
        data_out   : out STD_LOGIC_VECTOR(11 downto 0);  -- 12 bits pour mV (0  3300mV)
        rst_cnt    : out STD_LOGIC;
        en_rampe_n : out STD_LOGIC;
        en_rampe_p : out STD_LOGIC;
        en_pd      : out STD_LOGIC
    );
end logic_control;

architecture Behavioral of logic_control is
    type state_type is (S0_RESET, S1_CONVERT, S2_SAMPLE, S3_PD);
    signal state_reg, state_next : state_type;
    signal counter_reg : unsigned(7 downto 0);
    signal comp_sync   : std_logic_vector(1 downto 0);
    signal data_reg    : std_logic_vector(7 downto 0);
    signal tension_mv  : unsigned(11 downto 0);
begin

    -- Synchronisation comp_in
    process(clk, reset)
    begin
        if reset = '1' then
            comp_sync <= "11";
        elsif rising_edge(clk) then
            comp_sync <= comp_sync(0) & comp_in;
        end if;
    end process;

    -- Registre d'tat
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= S0_RESET;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    -- Compteur interne
    process(clk, reset)
    begin
        if reset = '1' then
            counter_reg <= (others => '0');
        elsif rising_edge(clk) then
            if state_reg = S0_RESET then
                counter_reg <= (others => '0');
            elsif state_reg = S1_CONVERT then
                counter_reg <= counter_reg + 1;
            end if;
        end if;
    end process;

    -- Stockage et conversion en mV
    -- Vin_mV = (din * 3300) / 160
    -- On approxime : 3300/160 = 20.625  21
    process(clk, reset)
    begin
        if reset = '1' then
            data_reg   <= (others => '0');
            tension_mv <= (others => '0');
        elsif rising_edge(clk) then
            if state_reg = S2_SAMPLE then
                data_reg   <= din;
                tension_mv <= resize(unsigned(din) * 21, 12);
            end if;
        end if;
    end process;

    data_out <= std_logic_vector(tension_mv);

    -- FSM combinatoire
    process(state_reg, start, comp_sync, counter_reg, pd_input)
    begin
        state_next <= state_reg;
        rst_cnt    <= '0';
        en_rampe_n <= '1';
        en_rampe_p <= '0';
        en_pd      <= '0';

        case state_reg is
            when S0_RESET =>
                rst_cnt    <= '1';
                en_rampe_n <= '1';
                en_rampe_p <= '0';
                en_pd      <= '0';
                if pd_input = '1' then
                    state_next <= S3_PD;
                elsif start = '1' then
                    state_next <= S1_CONVERT;
                end if;

            when S1_CONVERT =>
                rst_cnt    <= '0';
                en_rampe_n <= '0';
                en_rampe_p <= '1';
                en_pd      <= '0';
                if pd_input = '1' then
                    state_next <= S3_PD;
                elsif comp_sync(1) = '0' or counter_reg = 255 then
                    state_next <= S2_SAMPLE;
                end if;

            when S2_SAMPLE =>
                rst_cnt    <= '0';
                en_rampe_n <= '1';
                en_rampe_p <= '0';
                en_pd      <= '0';
                if pd_input = '1' then
                    state_next <= S3_PD;
                else
                    state_next <= S0_RESET;
                end if;

            when S3_PD =>
                rst_cnt    <= '1';
                en_rampe_n <= '1';
                en_rampe_p <= '0';
                en_pd      <= '1';
                if pd_input = '0' then
                    state_next <= S0_RESET;
                end if;
        end case;
    end process;

end Behavioral;
