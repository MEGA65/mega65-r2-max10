library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY top IS
  PORT (

    LED_G : out std_logic;
    LED_R : out std_logic;
    
    -----------------------------------------------------------------
    -- M65 Serial monitor interface
    -----------------------------------------------------------------    
    -- UART pins on the JB1 JTAG connector
    te_uart_tx : in std_logic;
    te_uart_rx : out std_logic;
    -- The UART pins on the Xilinx FPGA
    dbg_uart_tx : in std_logic;
    dbg_uart_rx : out std_logic;

    -----------------------------------------------------------------
    -- Motherboard dip-switches
    -----------------------------------------------------------------
    cpld_cfg0 : in std_logic;
    cpld_cfg1 : in std_logic;
    cpld_cfg2 : in std_logic;
    cpld_cfg3 : in std_logic;
    
    -----------------------------------------------------------------
    -- Xilinx FPGA JTAG interface
    -----------------------------------------------------------------
    -- FPGA pins
    fpga_tck : out std_logic;
    fpga_tdo : in std_logic;
    fpga_tdi : out std_logic;
    fpga_tms : out std_logic;
    -- TE0790 pins
    te_tck : in std_logic;
    te_tdo : out std_logic;
    te_tdi : in std_logic;
    te_tms : in std_logic;
        
    -----------------------------------------------------------------
    -- Xilinx FPGA configuration control
    -----------------------------------------------------------------
    fpga_prog_b : out std_logic := 'Z';
    fpga_init : out std_logic := 'Z';
    fpga_done : in std_logic;

    -----------------------------------------------------------------
    -- 5V Power rail control
    -----------------------------------------------------------------
    en_5v_joy_n : out std_logic := '0';

    -----------------------------------------------------------------
    -- Keyboard connector
    -----------------------------------------------------------------
    -- pins connecting to xilinx fpga
    kb_tdo : out std_logic;
    kb_tdi : in std_logic;
    kb_tck : in std_logic;
    kb_tms : in std_logic;
    kb_jtagen : in std_logic;
    kb_io1 : in std_logic;
    kb_io2 : in std_logic;
    kb_io3 : out std_logic;
    -- pins connecting to actual keyboard
    k_tdo : in std_logic;
    k_tdi : out std_logic;
    k_tck : out std_logic;
    k_tms : out std_logic;
    k_jtagen : out std_logic;
    k_io1 : out std_logic;
    k_io2 : out std_logic;
    k_io3 : in std_logic;

    -----------------------------------------------------------------
    -- Reset button
    -----------------------------------------------------------------
    reset_btn : in std_logic;
    blue_wire : in std_logic;
    fpga_reset_n : out std_logic;

    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
    vdac_psave_n : out std_logic := '1'
    
    );
end entity top;	
	
architecture simple of top is

  component intclock is
    port (
      oscena : in  std_logic := '1'; -- oscena
      clkout : out std_logic         -- clk
      );
  end component intclock;

  signal clkout : std_logic := '0';
  signal led : std_logic := '0';
  
  signal counter : integer := 0;
  
begin

  u0 : component intclock
    port map (
      oscena => '1', -- oscena.oscena
      clkout => clkout  -- clkout.clk
      );
  

  -- Make UART loopback
  dbg_uart_rx <= te_uart_tx;
  te_uart_rx <= dbg_uart_tx;

  LED_G <= kb_io1;
  
  -- Connect Xilinx FPGA to JTAG interface
  fpga_tck <= te_tck;
  fpga_tdi <= te_tdi;
  fpga_tms <= te_tms;
  
  process (cpld_cfg0,fpga_tdo,k_tdo) is
  begin
    if cpld_cfg0='0' then
      te_tdo <= fpga_tdo;
      -- And connect keyboard to Xilinx FPGA, and turn off JTAG mode for it
      k_jtagen <= '0';
      kb_tdo <= k_tdo;
      k_tdi <= kb_tdi;
      k_tck <= kb_tck;
      k_tms <= kb_tms;
      -- Connect keyboard GPIO interface
      k_io1 <= kb_io1;
      k_io2 <= kb_io2;
      kb_io3 <= k_io3;      
    else
      -- Otherwise connect keyboard to JTAG
      te_tdo <= k_tdo;
      k_jtagen <= '1';
      k_tdi <= te_tdi;
      k_tms <= te_tms;
      k_tck <= te_tck;

    end if;
  end process;  

  
  process(clkout) is
  begin
    if rising_edge(clkout) then
      if counter /= 10000000 then
        counter <= counter + 1;
      else
        counter <= 0;
        led <= not led;
        LED_R <= not led;
      end if;      
    end if;
  end process;
  
  
  -- M65 reset button
  fpga_reset_n <= not blue_wire;
		
end architecture simple;
