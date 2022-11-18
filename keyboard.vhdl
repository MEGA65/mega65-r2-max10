--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.keyboard_cpld_version.all;

ENTITY keyboard IS
  PORT (
    SCAN_OUT			: IN std_logic_vector(9 downto 0);
    SCAN_IN		    	: OUT std_logic_vector(7 downto 0);

    -- A selection of keys to model
    key_f : in std_logic; -- Column 2, row 5
    key_o : in std_logic; -- Column 4, row 6,
    key_RETURN : in std_logic; -- Column 0, row 1
    key_UP : in std_logic; -- Colum 0, row 7 + Column 6, row 4 (RSHIFT)
    key_DOWN : in std_logic -- Column 0, row 7
    
    );
end keyboard;

architecture smoke_and_mirrors of keyboard is

begin
  process (SCAN_OUT, key_f, key_o, key_RETURN, key_UP, key_DOWN) is
  begin
    SCAN_IN(7) <= '1' and (key_UP or SCAN_OUT(0)) and (key_DOWN or SCAN_OUT(0));
    SCAN_IN(6) <= '1' and (key_o or SCAN_OUT(4));
    SCAN_IN(5) <= '1' and (key_f or SCAN_OUT(2));
    SCAN_IN(4) <= '1' and (key_UP or SCAN_OUT(6));
    SCAN_IN(3) <= '1';
    SCAN_IN(2) <= '1';
    SCAN_IN(1) <= '1' and (key_RETURN or SCAN_OUT(0));
    SCAN_IN(0) <= '1';
  end process;
  
end smoke_and_mirrors;
