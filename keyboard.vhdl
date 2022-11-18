--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library machxo2;
use machxo2.all;
use work.version.all;

ENTITY keyboard_cpld IS
  PORT (
    SCAN_OUT			: IN std_logic_vector(9 downto 0);
    SCAN_IN		    	: OUT std_logic_vector(7 downto 0);

    key_f : in std_logic; -- Column 2, row 5
    key_o : in std_logic; -- Column 4, row 6,
    key_RETURN : in std_logic; -- Column 0, row 1
    key_UP : in std_logic; -- Colum 0, row 7 + Column 6, row 4 (RSHIFT)
    key_DOWN : in std_logic; -- Column 0, row 7
    
    );
end keyboard_cpld;

architecture smoke_and_mirrors of keyboard_cpld is

  process (SCAN_OUT, key_f, key_o, key_RETURN) is
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
  
  
begin
  
end smoke_and_mirrors;
