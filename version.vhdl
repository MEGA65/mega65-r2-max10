library ieee;
use Std.TextIO.all;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package version is

  constant gitcommit : string := "diy-keyboard,68,20221120.09,ffc08b8~";
  constant fpga_commit : unsigned(31 downto 0) := x"ffc08b8d";
  constant fpga_datestamp : unsigned(15 downto 0) := to_unsigned(1056,16);

end version;
