library ieee;
    use ieee.std_logic_1164.all;

library olo;
library colibri;

entity top_demo is
    generic (
        CLK_FREQ  : real := 100.0e6;
        BAUD_RATE     : real := 115.2e3;
        DEBOUNCE_TIME : time := 10 ms
    );
    port (
        clk     : in    std_logic;
        rst_n   : in    std_logic;
        uart_rx : in    std_logic;
        uart_tx : out   std_logic;
        btn     : in    std_logic;
        led     : out   std_logic
    );
end entity;

architecture rtl of top_demo is

    signal rst         : std_logic;
    signal rx_received : std_logic;
    signal led_r       : std_logic := '0';
    signal btn_sync    : std_logic_vector(0 downto 0);
    signal btn_stable  : std_logic_vector(0 downto 0);
    signal btn_pressed : std_logic;
    signal swap_enable : std_logic := '1';

begin

    led <= led_r;

    i_reset : entity olo.olo_base_reset_gen
        generic map (
            RstInPolarity_g => '0'
        )
        port map (
            Clk    => clk,
            RstIn  => rst_n,
            RstOut => rst
        );

    i_btn_sync : entity colibri.synchro
        generic map (
            g_DATA_LENGTH => 1
        )
        port map (
            clk_i   => clk,
            reset_i => rst,
            data_i  => (0 => btn),
            data_o  => btn_sync
        );

    i_btn_debounce : entity colibri.debouncer
        generic map (
            g_RESET_VAL     => "0",
            g_DEBOUNCE_TIME => DEBOUNCE_TIME,
            g_CLOCK_PERIOD  => 1 sec / CLK_FREQ
        )
        port map (
            clk_i   => clk,
            reset_i => rst,
            data_i  => btn_sync,
            data_o  => btn_stable
        );

    i_btn_edge : entity colibri.edge_detect
        port map (
            clk_i   => clk,
            data_i  => btn_stable(0),
            pulse_o => btn_pressed
        );

    -- Each press of the button turns the case swapping off or back on.
    p_swap_enable : process (clk) is
    begin
        if rising_edge(clk) then
            if btn_pressed = '1' then
                swap_enable <= not swap_enable;
            end if;
            if rst = '1' then
                swap_enable <= '1';
            end if;
        end if;
    end process;

    i_echo : entity work.uart_echo
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk         => clk,
            rst         => rst,
            swap_enable => swap_enable,
            uart_rx     => uart_rx,
            uart_tx     => uart_tx,
            rx_received => rx_received
        );

    p_led : process (clk) is
    begin
        if rising_edge(clk) then
            if rx_received = '1' then
                led_r <= not led_r;
            end if;
            if rst = '1' then
                led_r <= '0';
            end if;
        end if;
    end process;

end architecture;
