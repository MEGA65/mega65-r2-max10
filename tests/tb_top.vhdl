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
    -- Motherboard dip-switches: All off by default
    -----------------------------------------------------------------
  signal cpld_cfg0 : std_logic := '0';
  signal cpld_cfg1 : std_logic := '0';
  signal cpld_cfg2 : std_logic := '0';
  signal cpld_cfg3 : std_logic := '0';

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

  signal SCAN_OUT    : std_logic_vector(9 downto 0);
  signal SCAN_IN    : std_logic_vector(7 downto 0);
  
    -- A selection of keys to model
  signal key_f    : std_logic := '1'; -- Column 2, row 5
  signal key_o    : std_logic := '1'; -- Column 4, row 6,
  signal key_RETURN    : std_logic := '1'; -- Column 0, row 1
  signal key_UP    : std_logic := '1'; -- Colum 0, row 7 + Column 6, row 4 (RSHIFT)
  signal key_DOWN    : std_logic := '1'; -- Column 0, row 7

  signal mk1_KIO8    : std_logic;
  signal mk1_KIO9    : std_logic;
  signal mk1_KIO10    : std_logic;

  signal mk2_KIO8    : std_logic;
  signal mk2_KIO9    : std_logic;
  signal mk2_KIO10    : std_logic;
  
  signal KIO8    : std_logic;
  signal KIO9    : std_logic;
  signal KIO10    : std_logic;
    
  signal KEY_RESTORE    : std_logic := '1';
  
  signal LED_R0    : std_logic;
  signal LED_G0    : std_logic;
  signal LED_B0    : std_logic;
  
  signal LED_R1    : std_logic;
  signal LED_G1    : std_logic;
  signal LED_B1    : std_logic;
  
  signal LED_R2    : std_logic;
  signal LED_G2    : std_logic;
  signal LED_B2    : std_logic;
  
  signal LED_R3    : std_logic;
  signal LED_G3    : std_logic;
  signal LED_B3    : std_logic;
  
  signal LED_SHIFT    : std_logic;
  signal LED_CAPS    : std_logic;

  signal output_vector : std_logic_vector(127 downto 0);
  signal keyboard_data : std_logic_vector(127 downto 0);
  
    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
  signal vdac_psave_n : std_logic := '1';

  -- High if we are simulating a MK-I keyboard being connected,
  -- or low if simulating a MK-II keyboard being connected.
  signal mk1_connected : std_logic := '1';
  
begin

  -- Simulation can select which keyboard type is connected
  process (mk1_connected,k_io1,k_io2,mk1_KIO10) is
  begin
    if mk1_connected = '1' then
      -- MK-I keyboard connected
      mk1_KIO8 <= k_io1;
      mk1_KIO9 <= k_io2;
      k_io3 <= mk1_KIO10;
    else
      -- MK-II keyboard connected
      -- This is tricker, as we have to make two-way connection
      -- for SDA (KIO8) at least.
      -- XXX Not implemented
      k_io3 <= '0';
    end if;
  end process;
    
  
  mk1_keyboard0: entity work.keyboard
    port map (
      SCAN_OUT => SCAN_OUT,
      SCAN_IN => SCAN_IN,

      -- A selection of keys to model
      key_f => key_f ,
      key_o => key_o ,
      key_RETURN => key_RETURN ,
      key_UP => key_UP ,
      key_DOWN => key_DOWN 
      
      );

  cpld0: if true generate
    mk1_cpld0: entity work.keyboard_cpld
    port map (
      KIO8 => mk1_KIO8 ,
      KIO9 => mk1_KIO9 ,
      KIO10 => mk1_KIO10 ,
    
      SCAN_OUT	=> SCAN_OUT,
      SCAN_IN	=> SCAN_IN,
    
    
      KEY_RESTORE => KEY_RESTORE,
    
      LED_R0           	=> LED_R0,
      LED_G0           	=> LED_G0,
      LED_B0           	=> LED_B0,
   
      LED_R1           	=> LED_R1,
      LED_G1           	=> LED_G1,
      LED_B1           	=> LED_B1,
    
      LED_R2           	=> LED_R2,
      LED_G2           	=> LED_G2,
      LED_B2           	=> LED_B2,
    
      LED_R3           	=> LED_R3,
      LED_G3           	=> LED_G3,
      LED_B3           	=> LED_B3,
    
      LED_SHIFT           => LED_SHIFT,
      LED_CAPS            => LED_CAPS
      );
  end generate;
  
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
    function Reverse (x : std_logic_vector) return std_logic_vector is
      alias alx : std_logic_vector (x'length - 1 downto 0) is x;
      variable y : std_logic_vector (alx'range);
    begin
      for i in alx'range loop
        y(i) := alx (alx'left - i);
      end loop;
      return y;
    end;     
  begin
    test_runner_setup(runner, runner_cfg);
        
    while test_suite loop

      if run("MAX10 relays MK-I keyboard traffic to main FPGA") then
        -- Either way, we expect valid MK-I keyboard traffic from the MAX10:
        -- for MK-I keyboards it is transparently relayed. For MK-II keyboards
        -- the MAX10 does the protocol conversion.
        --
        -- The protocol for MK-I keyboard is:
        -- KIO8 = clock/sync from FPGA to keyboard
        -- KIO9 = output from FPGA to keyboard
        -- KIO10 = input from keyboard to FPGA
        -- The protocol sends a 128 bit string in this way.
        -- 24 bits of RGB for each of the four LEDs = 96 bits.
        -- The remaining bits are reserved
        -- Data is sent MSB first
        -- For testing, we will set it to have 2 LEDs on, and 2 off, so that we
        -- can check the reflected LED settings
        -- Total sequence is 140 counts long, with 128 data ticks and a sync pulse
        -- that lasts the rest of the duration
        output_vector(127 downto 96) <= (others => '0');
        -- Power LEDs
        output_vector(95 downto 72) <= x"FFFFFF";
        output_vector(71 downto 48) <= x"000000";
        -- Floppy LEDs
        output_vector(47 downto 24) <= x"ffffff";
        output_vector(23 downto 0) <= x"000000";

        -- Pretend to be Xilinx FPGA driving the process
        -- FPGA drives signal at 40.5MHz / 64 / 2 half-clocks = 1.58 usec
        -- per clock phase
        for s in 1 to 2 loop
          report "cycle";
          for i in 0 to 140 loop
            if i < 128 then
              -- Data bits
              kb_io1 <= '0'; kb_io2 <= output_vector(127-i); wait for 1580 ns;
              kb_io1 <= '1'; wait for 1580 ns;
              keyboard_data(127-i) <= k_io3;
            else
              kb_io1 <= '1'; wait for 1580 ns; kb_io2 <= '1';
              kb_io1 <= '1'; wait for 1580 ns;              
            end if;
          end loop;
        end loop;
        report "Data from keyboard is " & to_hstring(keyboard_data);
        report "Data from keyboard is " & to_string(keyboard_data);
        report "Keyboard GIT commit is " & to_hstring(Reverse(keyboard_data(33 downto 2)));
        if Reverse(keyboard_data(33 downto 2)) /= x"12345678" then
          assert false report "GIT commit should have been 12345678";
        end if;
        report "Keyboard GIT date is " & integer'image(to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))))
          & " days after keyboard epoch";
        if to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))) /= 9876 then
          assert false report "GIT date should have been 9876";
        end if;
        report "LED status is: "
          & std_logic'image(LED_R0) & std_logic'image(LED_G0) & std_logic'image(LED_B0)
          & std_logic'image(LED_R1) & std_logic'image(LED_G1) & std_logic'image(LED_B1)
          & std_logic'image(LED_R2) & std_logic'image(LED_G2) & std_logic'image(LED_B2)
          & std_logic'image(LED_R3) & std_logic'image(LED_G3) & std_logic'image(LED_B3)
          ;
        if LED_R0/='1' or LED_G0/='1' or LED_B0/='1'
          or LED_R1/='0' or LED_G1/='0' or LED_B1/='0'                 
          or LED_R2/='1' or LED_G2/='1' or LED_B2/='1'                 
          or LED_R3/='0' or LED_G3/='0' or LED_B3/='0' then
          assert false report "LED 0,2 should have RGB=1, and LED1,3 should have RGB=0";
        end if;
        for i in 127 downto 48 loop
          if to_X01(keyboard_data(i)) /= '1' then
            assert false report "all keys should be released, but matrix position " & integer'image(i-48)
              & " was not high.";
          end if;
        end loop;
      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
