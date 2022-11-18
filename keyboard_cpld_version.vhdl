library ieee;
use Std.TextIO.all;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package keyboard_cpld_version is

  constant git_version : unsigned(31 downto 0) := x"12345678";
  constant git_date : unsigned(13 downto 0) := to_unsigned(9876,14);

end keyboard_cpld_version;
