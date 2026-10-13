library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package demo_pkg is

    subtype byte_t is std_logic_vector(7 downto 0);

    -- Swaps the case of ASCII letters and passes every other byte through.
    function swap_case (byte : byte_t) return byte_t;

end package;

package body demo_pkg is

    function swap_case (byte : byte_t) return byte_t is
        constant CODE : natural := to_integer(unsigned(byte));
    begin
        if (CODE >= character'pos('A') and CODE <= character'pos('Z')) or
           (CODE >= character'pos('a') and CODE <= character'pos('z')) then
            return byte xor x"20";
        end if;
        return byte;
    end function;

end package body;
