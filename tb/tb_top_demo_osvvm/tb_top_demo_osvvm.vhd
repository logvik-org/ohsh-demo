library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library osvvm;
    context osvvm.OsvvmContext;
    use osvvm.ScoreboardPkg_slv.all;

-- The same test as tb_top_demo, written with OSVVM: every byte expected back
-- from top_demo goes into a scoreboard, which the receiving process checks
-- against, and AlertLogPkg counts the errors.
entity tb_top_demo_osvvm is
end entity;

architecture sim of tb_top_demo_osvvm is

    constant CLK_FREQ      : real := 100.0e6;
    constant BAUD_RATE     : real := 1.0e6;
    constant DEBOUNCE_TIME : time := 2 us;
    constant CLK_PERIOD    : time := 1 sec / CLK_FREQ;
    constant BIT_PERIOD    : time := 1 sec / BAUD_RATE;
    constant MESSAGE       : string := "Hello, ohsh!";
    constant SWAPPED       : string := "hELLO, OHSH!";

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal uart_rx : std_logic := '1';
    signal uart_tx : std_logic;
    signal btn     : std_logic := '0';
    signal led     : std_logic;

    signal expected_bytes : ScoreboardIDType;
    signal is_done        : boolean := false;

    function to_byte (char : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(char), 8));
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

    p_send : process is

        procedure send_message (sent : string; expected : string) is
            variable bits : std_logic_vector(7 downto 0);
        begin
            for i in sent'range loop
                Push(expected_bytes, to_byte(expected(i)));
                bits := to_byte(sent(i));
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

    begin
        SetTestName("tb_top_demo_osvvm");
        expected_bytes <= NewID("expected_bytes");
        wait for 20 * CLK_PERIOD;
        rst_n <= '1';
        wait for 20 * CLK_PERIOD;

        Log("Letters come back with their case swapped");
        send_message(MESSAGE, SWAPPED);
        wait for 3 * 10 * BIT_PERIOD;

        Log("A press of the button turns the swapping off");
        btn <= '1';
        wait for 2 * DEBOUNCE_TIME;
        btn <= '0';
        wait for 2 * DEBOUNCE_TIME;
        send_message(MESSAGE, MESSAGE);

        wait until is_done for (MESSAGE'length + 4) * 12 * BIT_PERIOD;
        AlertIfNot(is_done, "Not every byte came back");
        ReportAlerts;
        std.env.stop(GetAlertCount);
        wait;
    end process;

    p_receive : process is
        variable bits : std_logic_vector(7 downto 0);
    begin
        for i in 1 to 2 * MESSAGE'length loop
            wait until uart_tx = '0';
            wait for BIT_PERIOD * 1.5;
            for bit_index in 0 to 7 loop
                bits(bit_index) := uart_tx;
                wait for BIT_PERIOD;
            end loop;
            AffirmIfEqual(uart_tx, '1', "Stop bit");
            Check(expected_bytes, bits);
        end loop;
        is_done <= true;
        wait;
    end process;

end architecture;
