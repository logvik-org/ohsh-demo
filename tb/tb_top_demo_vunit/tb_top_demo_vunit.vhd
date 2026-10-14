library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library vunit_lib;
    context vunit_lib.vunit_context;

-- The same checks as tb_top_demo, written with VUnit as two test cases that
-- each start from reset.
entity tb_top_demo_vunit is
    generic (
        runner_cfg : string
    );
end entity;

architecture sim of tb_top_demo_vunit is

    constant CLK_FREQ      : real := 100.0e6;
    constant BAUD_RATE     : real := 1.0e6;
    constant DEBOUNCE_TIME : time := 2 us;
    constant CLK_PERIOD    : time := 1 sec / CLK_FREQ;
    constant BIT_PERIOD    : time := 1 sec / BAUD_RATE;
    constant MESSAGE       : string := "Hello, ohsh!";

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal uart_rx : std_logic := '1';
    signal uart_tx : std_logic;
    signal btn     : std_logic := '0';
    signal led     : std_logic;

    signal expected       : string(MESSAGE'range);
    signal received_count : natural := 0;

    function to_byte (char : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(char), 8));
    end function;

    function swap_case (text : string) return string is
        variable swapped : string(text'range) := text;
    begin
        for i in text'range loop
            if text(i) >= 'A' and text(i) <= 'Z' then
                swapped(i) := character'val(character'pos(text(i)) + 32);
            elsif text(i) >= 'a' and text(i) <= 'z' then
                swapped(i) := character'val(character'pos(text(i)) - 32);
            end if;
        end loop;
        return swapped;
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

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

    p_main : process is

        procedure send_message is
            variable bits : std_logic_vector(7 downto 0);
        begin
            for i in MESSAGE'range loop
                bits := to_byte(MESSAGE(i));
                uart_rx <= '0';
                wait for BIT_PERIOD;
                for bit_index in 0 to 7 loop
                    uart_rx <= bits(bit_index);
                    wait for BIT_PERIOD;
                end loop;
                uart_rx <= '1';
                wait for BIT_PERIOD;
            end loop;
        end procedure;

        procedure press_button is
        begin
            btn <= '1';
            wait for 2 * DEBOUNCE_TIME;
            btn <= '0';
            wait for 2 * DEBOUNCE_TIME;
        end procedure;

    begin
        test_runner_setup(runner, runner_cfg);
        wait for 20 * CLK_PERIOD;
        rst_n <= '1';
        wait for 20 * CLK_PERIOD;

        while test_suite loop
            if run("swaps_the_case_of_letters") then
                expected <= swap_case(MESSAGE);
                send_message;
            elsif run("button_turns_the_swapping_off") then
                expected <= MESSAGE;
                press_button;
                send_message;
            end if;
            wait until received_count = MESSAGE'length for 4 * 10 * BIT_PERIOD;
            check_equal(received_count, MESSAGE'length, "Bytes received");
        end loop;

        test_runner_cleanup(runner);
    end process;

    p_receive : process is
        variable bits : std_logic_vector(7 downto 0);
    begin
        wait until uart_tx = '0';
        wait for BIT_PERIOD * 1.5;
        for bit_index in 0 to 7 loop
            bits(bit_index) := uart_tx;
            wait for BIT_PERIOD;
        end loop;
        check_equal(uart_tx, '1', "Stop bit");
        check_equal(bits, to_byte(expected(received_count + 1)), "Byte " & integer'image(received_count + 1));
        received_count <= received_count + 1;
    end process;

    test_runner_watchdog(runner, 1 ms);

end architecture;
