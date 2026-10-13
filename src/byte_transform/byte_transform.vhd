library ieee;
    use ieee.std_logic_1164.all;

library demo_common;
    use demo_common.demo_pkg.all;

-- Registered valid/ready stage that swaps the case of each byte while swap_enable is set.
entity byte_transform is
    port (
        clk       : in    std_logic;
        rst         : in    std_logic;
        swap_enable : in    std_logic;
        in_valid  : in    std_logic;
        in_ready  : out   std_logic;
        in_data   : in    byte_t;
        out_valid : out   std_logic;
        out_ready : in    std_logic;
        out_data  : out   byte_t
    );
end entity;

architecture rtl of byte_transform is

    signal out_valid_r : std_logic := '0';

begin

    in_ready  <= out_ready or not out_valid_r;
    out_valid <= out_valid_r;

    p_stage : process (clk) is
    begin
        if rising_edge(clk) then
            if out_ready = '1' or out_valid_r = '0' then
                out_valid_r <= in_valid;
                out_data    <= swap_case(in_data) when swap_enable = '1' else in_data;
            end if;
            if rst = '1' then
                out_valid_r <= '0';
            end if;
        end if;
    end process;

end architecture;
