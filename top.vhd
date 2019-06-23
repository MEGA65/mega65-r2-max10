library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY top IS
   PORT (
	   -- UART pins on the JB1 JTAG connector
		te_uart_tx : in std_logic;
		te_uart_rx : out std_logic;
		
		-- The UART pins on the Xilinx FPGA
		dbg_uart_tx : in std_logic;
		dbg_uart_rx : out std_logic
		);
end entity top;	
	
architecture simple of top is

component intclock is
                port (
                        oscena : in  std_logic := 'X'; -- oscena
                        clkout : out std_logic         -- clk
                );
        end component intclock;
		  
  signal clkout : std_logic := '0';

begin

        u0 : component intclock
                port map (
                        oscena => '1', -- oscena.oscena
                        clkout => clkout  -- clkout.clk
                );


		-- Make UART loopback
      te_uart_rx <= te_uart_tx;
		
		dbg_uart_rx <= '1';
		
end architecture simple;