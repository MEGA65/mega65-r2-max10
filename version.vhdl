library ieee;
use Std.TextIO.all;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package version is

  constant gitcommit : string := "master,41,20221116.21,743d8ab~";
  constant fpga_commit : unsigned(31 downto 0) := x"743d8ab9";
  constant fpga_datestamp : unsigned(15 downto 0) := to_unsigned(1052,16);

end version;
