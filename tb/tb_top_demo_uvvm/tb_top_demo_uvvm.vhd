library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library uvvm_util;
    context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
    use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_uart;
    use bitvis_vip_uart.uart_bfm_pkg.all;
    use bitvis_vip_uart.vvc_methods_pkg.all;
    use bitvis_vip_uart.td_vvc_framework_common_methods_pkg.all;

-- The same test as tb_top_demo, written with UVVM: the UART VVC sends a
-- message to top_demo and expects it back with the case of every letter
-- swapped, then again with the swapping turned off by the button.
entity tb_top_demo_uvvm is
end entity;

architecture sim of tb_top_demo_uvvm is

    constant CLK_FREQ      : real := 100.0e6;
    constant BAUD_RATE     : real := 1.0e6;
    constant DEBOUNCE_TIME : time := 2 us;
    constant CLK_PERIOD    : time := 1 sec / CLK_FREQ;
    constant BIT_PERIOD    : time := 1 sec / BAUD_RATE;
    constant MESSAGE       : string := "Hello, ohsh!";
    constant SWAPPED       : string := "hELLO, OHSH!";

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal uart_rx : std_logic;
    signal uart_tx : std_logic;
    signal btn     : std_logic := '0';
    signal led     : std_logic;

    function to_byte (char : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(char), 8));
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

    i_uart_vvc : entity bitvis_vip_uart.uart_vvc
        generic map (
            GC_INSTANCE_IDX => 1
        )
        port map (
            uart_vvc_rx => uart_tx,
            uart_vvc_tx => uart_rx
        );

    i_dut : entity work.top_demo
        generic map (
            CLK_FREQ      => CLK_FREQ,
            BAUD_RATE     => BAUD_RATE,
            DEBOUNCE_TIME => DEBOUNCE_TIME
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            uart_rx => uart_rx,
            uart_tx => uart_tx,
            btn     => btn,
            led     => led
        );

    p_sequencer : process is

        procedure send_and_expect (sent : string; expected : string) is
        begin
            for i in sent'range loop
                uart_transmit(UART_VVCT, 1, TX, to_byte(sent(i)), "Send '" & sent(i) & "'");
                uart_expect(UART_VVCT, 1, RX, to_byte(expected(i)), "Expect '" & expected(i) & "'");
            end loop;
            await_completion(UART_VVCT, 1, RX, (sent'length + 2) * 12 * BIT_PERIOD);
        end procedure;

    begin
        await_uvvm_initialization(VOID);
        disable_log_msg(UART_VVCT, 1, ALL_CHANNELS, ALL_MESSAGES);
        shared_uart_vvc_config(TX, 1).bfm_config.bit_time := BIT_PERIOD;
        shared_uart_vvc_config(TX, 1).bfm_config.parity   := PARITY_NONE;
        shared_uart_vvc_config(RX, 1).bfm_config.bit_time := BIT_PERIOD;
        shared_uart_vvc_config(RX, 1).bfm_config.parity   := PARITY_NONE;

        wait for 20 * CLK_PERIOD;
        rst_n <= '1';
        wait for 20 * CLK_PERIOD;

        log(ID_LOG_HDR, "Letters come back with their case swapped");
        send_and_expect(MESSAGE, SWAPPED);

        log(ID_LOG_HDR, "A press of the button turns the swapping off");
        btn <= '1';
        wait for 2 * DEBOUNCE_TIME;
        btn <= '0';
        wait for 2 * DEBOUNCE_TIME;
        send_and_expect(MESSAGE, MESSAGE);

        await_uvvm_completion(1 us, print_alert_counters => REPORT_ALERT_COUNTERS_FINAL);
        log(ID_LOG_HDR, "tb_top_demo_uvvm: PASS");
        std.env.stop;
        wait;
    end process;

end architecture;
