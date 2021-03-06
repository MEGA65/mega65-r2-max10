-- intclock.vhd

-- Generated using ACDS version 18.1 625

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity intclock is
	port (
		clkout : out std_logic;        -- clkout.clk
		oscena : in  std_logic := '0'  -- oscena.oscena
	);
end entity intclock;

architecture rtl of intclock is
	component altera_int_osc is
		generic (
			DEVICE_FAMILY   : string := "";
			DEVICE_ID       : string := "UNKNOWN";
			CLOCK_FREQUENCY : string := "UNKNOWN"
		);
		port (
			oscena : in  std_logic := 'X'; -- oscena
			clkout : out std_logic         -- clk
		);
	end component altera_int_osc;

begin

	int_osc_0 : component altera_int_osc
		generic map (
			DEVICE_FAMILY   => "MAX 10",
			DEVICE_ID       => "08",
			CLOCK_FREQUENCY => "55"
		)
		port map (
			oscena => oscena, -- oscena.oscena
			clkout => clkout  -- clkout.clk
		);

end architecture rtl; -- of intclock
