library ieee;
    use ieee.std_logic_1164.all;

library olo;

-- Sends back every byte received on the UART with the case of its letters swapped.
entity uart_echo is
    generic (
        CLK_FREQ  : real;
        BAUD_RATE : real
    );
    port (
        clk         : in    std_logic;
        rst         : in    std_logic;
        uart_rx     : in    std_logic;
        uart_tx     : out   std_logic;
        rx_received : out   std_logic
    );
end entity;

architecture rtl of uart_echo is

    signal rx_valid   : std_logic;
    signal rx_data    : std_logic_vector(7 downto 0);
    signal fifo_valid : std_logic;
    signal fifo_ready : std_logic;
    signal fifo_data  : std_logic_vector(7 downto 0);
    signal tx_valid   : std_logic;
    signal tx_ready   : std_logic;
    signal tx_data    : std_logic_vector(7 downto 0);

begin

    rx_received <= rx_valid;

    i_uart : entity olo.olo_intf_uart
        generic map (
            ClkFreq_g  => CLK_FREQ,
            BaudRate_g => BAUD_RATE
        )
        port map (
            Clk      => clk,
            Rst      => rst,
            Tx_Valid => tx_valid,
            Tx_Ready => tx_ready,
            Tx_Data  => tx_data,
            Rx_Valid => rx_valid,
            Rx_Data  => rx_data,
            Uart_Tx  => uart_tx,
            Uart_Rx  => uart_rx
        );

    -- The UART receiver has no ready, so bytes wait here while the transmitter is busy.
    i_fifo : entity olo.olo_base_fifo_sync
        generic map (
            Width_g => 8,
            Depth_g => 16
        )
        port map (
            Clk       => clk,
            Rst       => rst,
            In_Data   => rx_data,
            In_Valid  => rx_valid,
            Out_Data  => fifo_data,
            Out_Valid => fifo_valid,
            Out_Ready => fifo_ready
        );

    i_transform : entity work.byte_transform
        port map (
            clk       => clk,
            rst       => rst,
            in_valid  => fifo_valid,
            in_ready  => fifo_ready,
            in_data   => fifo_data,
            out_valid => tx_valid,
            out_ready => tx_ready,
            out_data  => tx_data
        );

end architecture;
