library ieee;
use Std.TextIO.all;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package version is

  constant gitcommit : string := "diy-keyboard,80,20221120.16,07d6587~";
  constant fpga_commit : unsigned(31 downto 0) := x"07d6587e";
  constant fpga_datestamp : unsigned(15 downto 0) := to_unsigned(1056,16);

end version;
