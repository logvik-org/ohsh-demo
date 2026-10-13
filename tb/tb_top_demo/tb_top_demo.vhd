library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library std;
    use std.env.all;

-- Sends a message to top_demo over its UART and checks that it comes back
-- with the case of every letter swapped.
entity tb_top_demo is
end entity;

architecture sim of tb_top_demo is

    constant CLK_FREQ    : real := 100.0e6;
    constant BAUD_RATE   : real := 1.0e6;
    constant CLK_PERIOD  : time := 1 sec / CLK_FREQ;
    constant BIT_PERIOD  : time := 1 sec / BAUD_RATE;
    constant MESSAGE     : string := "Hello, ohsh!";
    constant EXPECTED    : string := "hELLO, OHSH!";

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal uart_rx : std_logic := '1';
    signal uart_tx : std_logic;
    signal led     : std_logic;

    procedure send_byte (signal line : out std_logic; byte : character) is
        constant BITS : std_logic_vector(7 downto 0) :=
            std_logic_vector(to_unsigned(character'pos(byte), 8));
    begin
        line <= '0';
        wait for BIT_PERIOD;
        for i in 0 to 7 loop
            line <= BITS(i);
            wait for BIT_PERIOD;
        end loop;
        line <= '1';
        wait for BIT_PERIOD;
    end procedure;

    procedure receive_byte (signal line : in std_logic; byte : out character) is
        variable bits : std_logic_vector(7 downto 0);
    begin
        wait until line = '0';
        wait for BIT_PERIOD * 1.5;
        for i in 0 to 7 loop
            bits(i) := line;
            wait for BIT_PERIOD;
        end loop;
        assert line = '1' report "Missing stop bit" severity failure;
        byte := character'val(to_integer(unsigned(bits)));
    end procedure;

begin

    clk <= not clk after CLK_PERIOD / 2;

    i_dut : entity work.top_demo
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            uart_rx => uart_rx,
            uart_tx => uart_tx,
            led     => led
        );

    p_send : process is
    begin
        wait for 20 * CLK_PERIOD;
        rst_n <= '1';
        wait for 20 * CLK_PERIOD;
        for i in MESSAGE'range loop
            send_byte(uart_rx, MESSAGE(i));
        end loop;
        wait;
    end process;

    p_check : process is
        variable received : character;
    begin
        for i in EXPECTED'range loop
            receive_byte(uart_tx, received);
            assert received = EXPECTED(i)
                report "Byte " & integer'image(i) & ": expected '" & EXPECTED(i)
                    & "', received '" & received & "'"
                severity failure;
        end loop;
        report "tb_top_demo: PASS";
        finish;
    end process;

    p_timeout : process is
    begin
        wait for (MESSAGE'length + 4) * 12 * BIT_PERIOD;
        report "tb_top_demo: timed out" severity failure;
        wait;
    end process;

end architecture;
