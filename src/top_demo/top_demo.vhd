library ieee;
    use ieee.std_logic_1164.all;

library olo;

entity top_demo is
    generic (
        CLK_FREQ  : real := 100.0e6;
        BAUD_RATE : real := 115.2e3
    );
    port (
        clk     : in    std_logic;
        rst_n   : in    std_logic;
        uart_rx : in    std_logic;
        uart_tx : out   std_logic;
        led     : out   std_logic
    );
end entity;

architecture rtl of top_demo is

    signal rst         : std_logic;
    signal rx_received : std_logic;
    signal led_r       : std_logic := '0';

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

    i_echo : entity work.uart_echo
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk         => clk,
            rst         => rst,
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
