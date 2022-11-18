library vunit_lib;
context vunit_lib.vunit_context;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity tb_top is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_top is

  signal LED_G : std_logic;
  signal LED_R : std_logic;

  signal cpld_clk : std_logic;
    
    -----------------------------------------------------------------
    -- M65 Serial monitor interface
    -----------------------------------------------------------------    
    -- UART pins on the JB1 JTAG connector
  signal te_uart_tx : std_logic;
  signal te_uart_rx : std_logic;

    -- The UART pins on the Xilinx FPGA
  signal dbg_uart_tx : std_logic;
  signal dbg_uart_rx : std_logic;

    -----------------------------------------------------------------
    -- MAX10 own debug UART interface
    -----------------------------------------------------------------
    -- (overloads external uSD card interface, so we have to tri-state
    --  it).
  signal m_tx : std_logic := 'Z';
  signal m_rx : std_logic;
    
    -----------------------------------------------------------------
    -- Motherboard dip-switches
    -----------------------------------------------------------------
  signal cpld_cfg0 : std_logic;
  signal cpld_cfg1 : std_logic;
  signal cpld_cfg2 : std_logic;
  signal cpld_cfg3 : std_logic;

    -----------------------------------------------------------------
    -- J21 GPIO interface
    -----------------------------------------------------------------
  signal J21 : std_logic_vector(11 downto 0) := (others => '0');
    
    -----------------------------------------------------------------
   -- Xilinx FPGA JTAG interface
    -----------------------------------------------------------------
    -- FPGA pins
  signal fpga_tck : std_logic;
  signal fpga_tdo : std_logic;
  signal fpga_tdi : std_logic;
  signal fpga_tms : std_logic;
    -- TE0790 pins
  signal te_tck : std_logic;
  signal te_tdo : std_logic;
  signal te_tdi : std_logic;
  signal te_tms : std_logic;
        
    -----------------------------------------------------------------
    -- Xilinx FPGA configuration control
    -----------------------------------------------------------------
  signal fpga_prog_b : std_logic := 'Z';
  signal fpga_init : std_logic := 'Z';
  signal fpga_done : std_logic;   
    
    -----------------------------------------------------------------
    -- Xilinx FPGA communications channel
    -----------------------------------------------------------------
  signal xilinx_sync : std_logic;
  signal xilinx_tx : std_logic;
  signal xilinx_rx : std_logic := '1';
    
    -----------------------------------------------------------------
    -- 5V Power rail control
    -----------------------------------------------------------------
  signal en_5v_joy_n : std_logic := '0';

    -----------------------------------------------------------------
    -- Keyboard connector
    -----------------------------------------------------------------
    -- pins connecting to xilinx fpga
  signal kb_tdo : std_logic;
  signal kb_tdi : std_logic;
  signal kb_tck : std_logic;
  signal kb_tms : std_logic;
  signal kb_jtagen : std_logic;
  signal kb_io1 : std_logic;
  signal kb_io2 : std_logic;
  signal kb_io3 : std_logic;
    -- pins connecting to actual keyboard
  signal k_tdo : std_logic;
  signal k_tdi : std_logic;
  signal k_tck : std_logic;
  signal k_tms : std_logic;
  signal k_jtagen : std_logic;
  signal k_io1 : std_logic;
  signal k_io2 : std_logic;
  signal k_io3 : std_logic;

    -----------------------------------------------------------------
    -- Reset button
    -----------------------------------------------------------------
  signal reset_btn : std_logic;
  signal blue_wire : std_logic;

    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
  signal vdac_psave_n : std_logic := '1';
  
begin

  top0: entity work.top
    port map (

      LED_G => LED_G,
      LED_R => LED_R,

      cpld_clk => cpld_clk,
    
    -----------------------------------------------------------------
    -- M65 Serial monitor interface
    -----------------------------------------------------------------    
    -- UART pins on the JB1 JTAG connector
      te_uart_tx => te_uart_tx,
      te_uart_rx => te_uart_rx,

    -- The UART pins on the Xilinx FPGA
      dbg_uart_tx => dbg_uart_tx,
      dbg_uart_rx => dbg_uart_rx,

    -----------------------------------------------------------------
    -- MAX10 own debug UART interface
    -----------------------------------------------------------------
    -- (overloads external uSD card interface, so we have to tri-state
    --  it).
      m_tx => m_tx,
      m_rx => m_rx,
    
    -----------------------------------------------------------------
    -- Motherboard dip-switches
    -----------------------------------------------------------------
      cpld_cfg0 => cpld_cfg0,
      cpld_cfg1 => cpld_cfg1,
      cpld_cfg2 => cpld_cfg2,
      cpld_cfg3 => cpld_cfg3,

    -----------------------------------------------------------------
    -- J21 GPIO interface
    -----------------------------------------------------------------
      J21 => J21,
    
    -----------------------------------------------------------------
   -- Xilinx FPGA JTAG interface
    -----------------------------------------------------------------
    -- FPGA pins
      fpga_tck => fpga_tck,
      fpga_tdo => fpga_tdo,
      fpga_tdi => fpga_tdi,
      fpga_tms => fpga_tms,
    -- TE0790 pins
      te_tck => te_tck,
      te_tdo => te_tdo,
      te_tdi => te_tdi,
      te_tms => te_tms,
        
    -----------------------------------------------------------------
    -- Xilinx FPGA configuration control
    -----------------------------------------------------------------
      fpga_prog_b => fpga_prog_b,
      fpga_init => fpga_init,
      fpga_done => fpga_done,
    
    -----------------------------------------------------------------
    -- Xilinx FPGA communications channel
    -----------------------------------------------------------------
      xilinx_sync => xilinx_sync,
      xilinx_tx => xilinx_tx,
      xilinx_rx => xilinx_rx,
    
    -----------------------------------------------------------------
    -- 5V Power rail control
    -----------------------------------------------------------------
      en_5v_joy_n => en_5v_joy_n,

    -----------------------------------------------------------------
    -- Keyboard connector
    -----------------------------------------------------------------
    -- pins connecting to xilinx fpga
      kb_tdo => kb_tdo,
      kb_tdi => kb_tdi,
      kb_tck => kb_tck,
      kb_tms => kb_tms,
      kb_jtagen => kb_jtagen,
      kb_io1 => kb_io1,
      kb_io2 => kb_io2,
      kb_io3 => kb_io3,
    -- pins connecting to actual keyboard
      k_tdo => k_tdo,
      k_tdi => k_tdi,
      k_tck => k_tck,
      k_tms => k_tms,
      k_jtagen => k_jtagen,
      k_io1 => k_io1,
      k_io2 => k_io2,
      k_io3 => k_io3,

    -----------------------------------------------------------------
    -- Reset button
    -----------------------------------------------------------------
      reset_btn => reset_btn,
      blue_wire => blue_wire,

    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
      vdac_psave_n => vdac_psave_n
    
      );
   
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
        
    while test_suite loop

      if run("MAX10 relays MK-I keyboard traffic to main FPGA") then
        assert false report "not implemented";
      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
