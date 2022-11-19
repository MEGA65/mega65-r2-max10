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
  signal k_io1_en : std_logic;
  signal k_io2_en : std_logic;
  signal k_io3 : std_logic;

    -----------------------------------------------------------------
    -- Reset button
    -----------------------------------------------------------------
  signal reset_btn : std_logic;
  signal blue_wire : std_logic;

  signal SCAN_OUT    : std_logic_vector(9 downto 0);
  signal SCAN_IN    : std_logic_vector(7 downto 0);
  
    -- A selection of keys to model
  signal key_CAPSLOCK    : std_logic := '1';
  signal key_SHIFTLOCK    : std_logic := '1';
  signal key_f    : std_logic := '1'; -- Column 2, row 5
  signal key_o    : std_logic := '1'; -- Column 4, row 6,
  signal key_RETURN    : std_logic := '1'; -- Column 0, row 1
  signal key_CURSORUP    : std_logic := '1'; -- Colum 0, row 7 + Column 6, row 4 (RSHIFT)
  signal key_DOWN    : std_logic := '1'; -- Column 0, row 7

  signal mk1_KIO8    : std_logic;
  signal mk1_KIO9    : std_logic;
  signal mk1_KIO10    : std_logic;

  signal mk2_KIO8    : std_logic;
  signal mk2_KIO9    : std_logic;
  signal mk2_KIO10    : std_logic := '0';
  
  signal KIO8    : std_logic;
  signal KIO9    : std_logic;
  signal KIO10    : std_logic;
    
  signal KEY_RESTORE    : std_logic := '1';
  
  signal mk1_LED_R0    : std_logic;
  signal mk1_LED_G0    : std_logic;
  signal mk1_LED_B0    : std_logic;
  signal mk1_LED_R1    : std_logic;
  signal mk1_LED_G1    : std_logic;
  signal mk1_LED_B1    : std_logic;
  signal mk1_LED_R2    : std_logic;
  signal mk1_LED_G2    : std_logic;
  signal mk1_LED_B2    : std_logic;
  signal mk1_LED_R3    : std_logic;
  signal mk1_LED_G3    : std_logic;
  signal mk1_LED_B3    : std_logic;
  signal mk1_LED_SHIFT    : std_logic;
  signal mk1_LED_CAPS    : std_logic;

  signal mk2_LED_R0    : std_logic;
  signal mk2_LED_G0    : std_logic;
  signal mk2_LED_B0    : std_logic;
  signal mk2_LED_R1    : std_logic;
  signal mk2_LED_G1    : std_logic;
  signal mk2_LED_B1    : std_logic;
  signal mk2_LED_R2    : std_logic;
  signal mk2_LED_G2    : std_logic;
  signal mk2_LED_B2    : std_logic;
  signal mk2_LED_R3    : std_logic;
  signal mk2_LED_G3    : std_logic;
  signal mk2_LED_B3    : std_logic;
  signal mk2_LED_SHIFT    : std_logic;
  signal mk2_LED_CAPS    : std_logic;
  
  signal output_vector : std_logic_vector(127 downto 0);
  signal keyboard_data : std_logic_vector(127 downto 0);
  
    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
  signal vdac_psave_n : std_logic := '1';

  -- High if we are simulating a MK-I keyboard being connected,
  -- or low if simulating a MK-II keyboard being connected.
  signal mk1_connected : std_logic := '1';

  signal u1port0 : unsigned(7 downto 0) := (others => '1');
  signal u1port1 : unsigned(7 downto 0) := (others => '1');
  signal u1_reg : integer;
  signal u1_read : std_logic;
  signal u1_write : std_logic;
  signal u1_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u1_saw_write : unsigned(7 downto 0) := (others => '0');

  signal u2port0 : unsigned(7 downto 0) := (others => '1');
  signal u2port1 : unsigned(7 downto 0) := (others => '1');
  signal u2_reg : integer;
  signal u2_read : std_logic;
  signal u2_write : std_logic;
  signal u2_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u2_saw_write : unsigned(7 downto 0) := (others => '0');

  signal u3port0 : unsigned(7 downto 0) := (others => '1');
  signal u3port1 : unsigned(7 downto 0) := (others => '1');
  signal u3_reg : integer;
  signal u3_read : std_logic;
  signal u3_write : std_logic;
  signal u3_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u3_saw_write : unsigned(7 downto 0) := (others => '0');

  signal u4port0 : unsigned(7 downto 0) := (others => '1');
  signal u4port1 : unsigned(7 downto 0) := (others => '1');
  signal u4_reg : integer;
  signal u4_read : std_logic;
  signal u4_write : std_logic;
  signal u4_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u4_saw_write : unsigned(7 downto 0) := (others => '0');

  signal u5port0 : unsigned(7 downto 0) := (others => '1');
  signal u5port1 : unsigned(7 downto 0) := (others => '1');
  signal u5_reg : integer;
  signal u5_read : std_logic;
  signal u5_write : std_logic;
  signal u5_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u5_saw_write : unsigned(7 downto 0) := (others => '0');

  signal u6port0 : unsigned(7 downto 0) := (others => '1');
  signal u6port1 : unsigned(7 downto 0) := (others => '1');
  signal u6_reg : integer;
  signal u6_read : std_logic;
  signal u6_write : std_logic;
  signal u6_saw_read : unsigned(7 downto 0) := (others => '0');
  signal u6_saw_write : unsigned(7 downto 0) := (others => '0');

  signal reset : std_logic := '1';
  
begin

  u1: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100000"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u1port0,
              port1 => u1port1,
              accessed_reg => u1_reg,
              reg_write_strobe => u1_write,
              reg_read_strobe => u1_read
              );

  u2: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100011"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u2port0,
              port1 => u2port1,
              accessed_reg => u2_reg,
              reg_write_strobe => u2_write,
              reg_read_strobe => u2_read
              );

  u3: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100001"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u3port0,
              port1 => u3port1,
              accessed_reg => u3_reg,
              reg_write_strobe => u3_write,
              reg_read_strobe => u3_read
              );

  u4: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100100"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u4port0,
              port1 => u4port1,
              accessed_reg => u4_reg,
              reg_write_strobe => u4_write,
              reg_read_strobe => u4_read
              );

  u5: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100010"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u5port0,
              port1 => u5port1,
              accessed_reg => u5_reg,
              reg_write_strobe => u5_write,
              reg_read_strobe => u5_read
              );

  u6: entity work.pca9555
    generic map ( clock_frequency => 1e8,
                  address => "0100101"
                  )
    port map (clock => cpld_clk,
              reset => reset,
              scl => mk2_kio9,
              sda => mk2_kio8,
              port0 => u6port0,
              port1 => u6port1,
              accessed_reg => u6_reg,
              reg_write_strobe => u6_write,
              reg_read_strobe => u6_read
              );

  
  -- Simulation can select which keyboard type is connected
  process (mk1_connected,k_io1,k_io2,mk2_KIO8, mk2_KIO9, mk2_KIO10, mk1_KIO10,k_io1_en, k_io2_en) is
  begin
    if mk1_connected = '1' then
      report "MK-I connected: " & std_logic'image(k_io1)  & std_logic'image(k_io2);
      -- MK-I keyboard connected
      mk1_KIO8 <= k_io1;
      mk1_KIO9 <= k_io2;
      k_io3 <= mk1_KIO10;
      if mk1_KIO10 /= '1' then
        report "KIO10 = 0";
      end if;
      k_io1 <= 'Z';
      k_io2 <= 'Z';
    else
      report "MK-II connected";
      -- MK-II keyboard connected
      -- This is tricker, as we have to make two-way connection
      -- for SDA (KIO8) at least.
      -- XXX Not implemented
      if k_io1_en='1' then
        mk2_KIO8 <= k_io1;
      else
        k_io1 <= mk2_KIO8;
      end if;
      if k_io2_en='1' then
        mk2_KIO9 <= k_io2;
      else
        k_io2 <= mk2_KIO9;
      end if;
      k_io3 <= mk2_KIO10;
    end if;
  end process;
    
  
  mk1_keyboard0: entity work.keyboard
    port map (
      SCAN_OUT => SCAN_OUT,
      SCAN_IN => SCAN_IN,

      -- A selection of keys to model
      key_CAPSLOCK => key_CAPSLOCK,
      key_SHIFTLOCK => key_SHIFTLOCK,
      key_f => key_f ,
      key_o => key_o ,
      key_RETURN => key_RETURN ,
      key_CURSORUP => key_CURSORUP ,
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
    
      LED_R0           	=> mk1_LED_R0,
      LED_G0           	=> mk1_LED_G0,
      LED_B0           	=> mk1_LED_B0,
   
      LED_R1           	=> mk1_LED_R1,
      LED_G1           	=> mk1_LED_G1,
      LED_B1           	=> mk1_LED_B1,
    
      LED_R2           	=> mk1_LED_R2,
      LED_G2           	=> mk1_LED_G2,
      LED_B2           	=> mk1_LED_B2,
    
      LED_R3           	=> mk1_LED_R3,
      LED_G3           	=> mk1_LED_G3,
      LED_B3           	=> mk1_LED_B3,
    
      LED_SHIFT           => mk1_LED_SHIFT,
      LED_CAPS            => mk1_LED_CAPS
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
      k_io1_en => k_io1_en,
      k_io2_en => k_io2_en,

    -----------------------------------------------------------------
    -- Reset button
    -----------------------------------------------------------------
      reset_btn => reset_btn,
      blue_wire => blue_wire,

    -----------------------------------------------------------------
    -- VGA VDAC low-power switch
    -----------------------------------------------------------------
      vdac_psave_n => vdac_psave_n,

      mk2_LED_R0 => mk2_LED_R0,
      mk2_LED_G0 => mk2_LED_G0,
      mk2_LED_B0 => mk2_LED_B0,
   
      mk2_LED_R1 => mk2_LED_R1,
      mk2_LED_G1 => mk2_LED_G1,
      mk2_LED_B1 => mk2_LED_B1,
    
      mk2_LED_R2 => mk2_LED_R2,
      mk2_LED_G2 => mk2_LED_G2,
      mk2_LED_B2 => mk2_LED_B2,
    
      mk2_LED_R3 => mk2_LED_R3,
      mk2_LED_G3 => mk2_LED_G3,
      mk2_LED_B3 => mk2_LED_B3,
    
      mk2_LED_SHIFT => mk2_LED_SHIFT,
      mk2_LED_CAPS => mk2_LED_CAPS
    
      );

  process is
  begin
    while true loop
      cpld_clk <= '0'; wait for 5 ns;
      cpld_clk <= '1'; wait for 5 ns;
      cpld_clk <= '0'; wait for 5 ns;
      cpld_clk <= '1'; wait for 5 ns;
      cpld_clk <= '0'; wait for 5 ns;
      cpld_clk <= '1'; wait for 5 ns;
      reset <= '0';
    end loop;
  end process;  
  
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
              keyboard_data(127-i) <= kb_io3;
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
          & std_logic'image(mk1_LED_R0) & std_logic'image(mk1_LED_G0) & std_logic'image(mk1_LED_B0)
          & std_logic'image(mk1_LED_R1) & std_logic'image(mk1_LED_G1) & std_logic'image(mk1_LED_B1)
          & std_logic'image(mk1_LED_R2) & std_logic'image(mk1_LED_G2) & std_logic'image(mk1_LED_B2)
          & std_logic'image(mk1_LED_R3) & std_logic'image(mk1_LED_G3) & std_logic'image(mk1_LED_B3)
          ;
        if mk1_LED_R0/='1' or mk1_LED_G0/='1' or mk1_LED_B0/='1'
          or mk1_LED_R1/='0' or mk1_LED_G1/='0' or mk1_LED_B1/='0'                 
          or mk1_LED_R2/='1' or mk1_LED_G2/='1' or mk1_LED_B2/='1'                 
          or mk1_LED_R3/='0' or mk1_LED_G3/='0' or mk1_LED_B3/='0' then
          assert false report "LED 0,2 should have RGB=1, and LED1,3 should have RGB=0";
        end if;
        for i in 127 downto 50 loop
          if to_X01(keyboard_data(i)) /= '1' then
            assert false report "all keys should be released, but matrix position " & integer'image(i-50)
              & " was not high.";
          end if;
        end loop;
      elsif run("MK-I keyboard key press communicated to main FPGA") then
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

        -- UP key held down
        key_CURSORUP <= '0';
        
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
              keyboard_data(127-i) <= kb_io3;
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
          & std_logic'image(mk1_LED_R0) & std_logic'image(mk1_LED_G0) & std_logic'image(mk1_LED_B0)
          & std_logic'image(mk1_LED_R1) & std_logic'image(mk1_LED_G1) & std_logic'image(mk1_LED_B1)
          & std_logic'image(mk1_LED_R2) & std_logic'image(mk1_LED_G2) & std_logic'image(mk1_LED_B2)
          & std_logic'image(mk1_LED_R3) & std_logic'image(mk1_LED_G3) & std_logic'image(mk1_LED_B3)
          ;
        if mk1_LED_R0/='1' or mk1_LED_G0/='1' or mk1_LED_B0/='1'
          or mk1_LED_R1/='0' or mk1_LED_G1/='0' or mk1_LED_B1/='0'                 
          or mk1_LED_R2/='1' or mk1_LED_G2/='1' or mk1_LED_B2/='1'                 
          or mk1_LED_R3/='0' or mk1_LED_G3/='0' or mk1_LED_B3/='0' then
          assert false report "LED 0,2 should have RGB=1, and LED1,3 should have RGB=0";
        end if;
        for i in 2 to 79 loop
          if i /= 73 then
            if to_X01(keyboard_data(129 - i)) /= '1' then
              assert false report "other keys should be released, but matrix position " & integer'image(i)
                & " was not high.";
            end if;
          else
            if to_X01(keyboard_data(129 - i)) /= '0' then
              assert false report "selected key(s) should be down, but matrix position " & integer'image(i)
                & " was not low.";
            end if;
          end if;
        end loop;
      elsif run("MAX10 MK-II keyboard doesn't cause KIO10 to stay low") then
        output_vector(127 downto 96) <= (others => '0');
        -- Power LEDs
        output_vector(95 downto 72) <= x"FFFFFF";
        output_vector(71 downto 48) <= x"000000";
        -- Floppy LEDs
        output_vector(47 downto 24) <= x"ffffff";
        output_vector(23 downto 0) <= x"000000";

        -- Connect the MK-II keyboard instead
        mk1_connected <= '0';

        -- Pretend to be Xilinx FPGA driving the process
        -- FPGA drives signal at 40.5MHz / 64 / 2 half-clocks = 1.58 usec
        -- per clock phase
        -- I2C is slower, and so LED updates are slower, so we have to do more
        -- cycles before the LEDs will get updated.
        for s in 1 to 3 loop
          report "cycle";
          for i in 0 to 140 loop
            if i < 128 then
              -- Data bits
              kb_io1 <= '0'; kb_io2 <= output_vector(127-i); wait for 1580 ns;
              kb_io1 <= '1'; wait for 1580 ns;
              keyboard_data(127-i) <= kb_io3;
            else
              kb_io1 <= '1'; wait for 1580 ns; kb_io2 <= '1';
              kb_io1 <= '1'; wait for 1580 ns;              
            end if;
          end loop;
        end loop;
        report "Data from keyboard is " & to_hstring(keyboard_data);
        report "Data from keyboard is " & to_string(keyboard_data);
        report "Keyboard GIT commit is " & to_hstring(Reverse(keyboard_data(33 downto 2)));
        if Reverse(keyboard_data(33 downto 2)) /= x"4d4b4949" then
          assert false report "GIT commit should have been 4d4b4949";
        end if;
        report "Keyboard GIT date is " & integer'image(to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))))
          & " days after keyboard epoch";
        if to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))) /= 0 then
          assert false report "GIT date should have been 0";
        end if;
        report "LED status is: "
          & std_logic'image(mk2_LED_R0) & std_logic'image(mk2_LED_G0) & std_logic'image(mk2_LED_B0)
          & std_logic'image(mk2_LED_R1) & std_logic'image(mk2_LED_G1) & std_logic'image(mk2_LED_B1)
          & std_logic'image(mk2_LED_R2) & std_logic'image(mk2_LED_G2) & std_logic'image(mk2_LED_B2)
          & std_logic'image(mk2_LED_R3) & std_logic'image(mk2_LED_G3) & std_logic'image(mk2_LED_B3)
          ;
        if mk2_LED_R0/='1' or mk2_LED_G0/='1' or mk2_LED_B0/='1'
          or mk2_LED_R1/='0' or mk2_LED_G1/='0' or mk2_LED_B1/='0'                 
          or mk2_LED_R2/='1' or mk2_LED_G2/='1' or mk2_LED_B2/='1'                 
          or mk2_LED_R3/='0' or mk2_LED_G3/='0' or mk2_LED_B3/='0' then
          assert false report "LED 0,2 should have RGB=1, and LED1,3 should have RGB=0";
        end if;
        for i in 127 downto 50 loop
          if to_X01(keyboard_data(i)) /= '1' then
            assert false report "all keys should be released, but matrix position " & integer'image(i-50)
              & " was not high.";
          end if;
        end loop;
      elsif run("MK-II keyboard key press communicated to main FPGA") then
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

        mk1_connected <= '0';
        
        -- SPACE key held down
        u4port1(7) <= '0';
        
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
              keyboard_data(127-i) <= kb_io3;
            else
              kb_io1 <= '1'; wait for 1580 ns; kb_io2 <= '1';
              kb_io1 <= '1'; wait for 1580 ns;              
            end if;
          end loop;
        end loop;
        report "Data from keyboard is " & to_hstring(keyboard_data);
        report "Data from keyboard is " & to_string(keyboard_data);
        report "Keyboard GIT commit is " & to_hstring(Reverse(keyboard_data(33 downto 2)));
        if Reverse(keyboard_data(33 downto 2)) /= x"4d4b4949" then
          assert false report "GIT commit should have been 4d4b4949";
        end if;
        report "Keyboard GIT date is " & integer'image(to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))))
          & " days after keyboard epoch";
        if to_integer(unsigned(Reverse(keyboard_data(47 downto 34)))) /= 0 then
          assert false report "GIT date should have been 0";
        end if;
        report "LED status is: "
          & std_logic'image(mk2_LED_R0) & std_logic'image(mk2_LED_G0) & std_logic'image(mk2_LED_B0)
          & std_logic'image(mk2_LED_R1) & std_logic'image(mk2_LED_G1) & std_logic'image(mk2_LED_B1)
          & std_logic'image(mk2_LED_R2) & std_logic'image(mk2_LED_G2) & std_logic'image(mk2_LED_B2)
          & std_logic'image(mk2_LED_R3) & std_logic'image(mk2_LED_G3) & std_logic'image(mk2_LED_B3)
          ;
        if mk2_LED_R0/='1' or mk2_LED_G0/='1' or mk2_LED_B0/='1'
          or mk2_LED_R1/='0' or mk2_LED_G1/='0' or mk2_LED_B1/='0'                 
          or mk2_LED_R2/='1' or mk2_LED_G2/='1' or mk2_LED_B2/='1'                 
          or mk2_LED_R3/='0' or mk2_LED_G3/='0' or mk2_LED_B3/='0' then
          assert false report "LED 0,2 should have RGB=1, and LED1,3 should have RGB=0";
        end if;
        for i in 2 to 79 loop
          if i /= 73 then
            if to_X01(keyboard_data(129 - i)) /= '1' then
              assert false report "other keys should be released, but matrix position " & integer'image(i)
                & " was not high.";
            end if;
          else
            if to_X01(keyboard_data(129 - i)) /= '0' then
              assert false report "selected key(s) should be down, but matrix position " & integer'image(i)
                & " was not low.";
            end if;
          end if;
        end loop;
      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
