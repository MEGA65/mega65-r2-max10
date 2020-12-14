library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.version.all;

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
    -- MAX10 own debug UART interface
    -----------------------------------------------------------------
    -- (overloads external uSD card interface, so we have to tri-state
    --  it).
    m_tx : out std_logic := 'Z';
    m_rx : in std_logic;
    
    -----------------------------------------------------------------
    -- Motherboard dip-switches
    -----------------------------------------------------------------
    cpld_cfg0 : in std_logic;
    cpld_cfg1 : in std_logic;
    cpld_cfg2 : in std_logic;
    cpld_cfg3 : in std_logic;

    -----------------------------------------------------------------
    -- J21 GPIO interface
    -----------------------------------------------------------------
    J21 : inout std_logic_vector(11 downto 0) := (others => '0');
    
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

    
    -----------------------------------------------------------------
    -- Xilinx FPGA communications channel
    -----------------------------------------------------------------
    fpga_done : in std_logic;    -- acts as clock
    xilinx_sync : in std_logic;
    xilinx_tx : in std_logic;
    xilinx_rx : out std_logic := '1';
    
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
  signal counter2 : integer := 0;
  signal led_bright : integer := 0;
  signal led_bright_dir : std_logic := '0';

  signal xilinx_counter : integer range 0 to 63 := 0;
  signal xilinx_vector_in : std_logic_vector(63 downto 0) := (others => '0');
  signal xilinx_vector_out : std_logic_vector(63 downto 0) := (others => '0');

  signal last_xilinx_sync : std_logic := '0';
  signal sync_toggle : std_logic := '0';
  signal last_sync_toggle : std_logic := '0';
  signal sync_counter : integer range 0 to 7 := 0;

  signal toggle : std_logic := '0';
  
begin

  u0 : component intclock
    port map (
      oscena => '1', -- oscena.oscena
      clkout => clkout  -- clkout.clk
      );
    
  -- Make UART loopback
  dbg_uart_rx <= te_uart_tx;
  te_uart_rx <= dbg_uart_tx;

--  LED_G <= kb_io1;
  
  -- Connect Xilinx FPGA to JTAG interface
  fpga_tck <= te_tck;
  fpga_tdi <= te_tdi;
  fpga_tms <= te_tms;

  process (xilinx_sync,clkout) is
  begin
    led_r <= xilinx_sync;

    if rising_edge(clkout) then
      if xilinx_sync = last_xilinx_sync then
        if sync_counter < 4 then
          sync_counter <= sync_counter + 1;
        else
          sync_toggle <= not sync_toggle;
        end if;
      else
        sync_counter <= 0;
      end if;
      last_xilinx_sync <= xilinx_sync;
      
    end if;
    
    if rising_edge(xilinx_sync) then
          
      if sync_toggle /= last_sync_toggle then

        last_sync_toggle <= sync_toggle;
        -- Sync: reset output vector, and apply input vector
        xilinx_counter <= 0;
        xilinx_rx <= j21(0);
        xilinx_vector_out(10 downto 0) <= j21(11 downto 1);
        xilinx_vector_out(11) <= cpld_cfg0;
        xilinx_vector_out(12) <= cpld_cfg1;
        xilinx_vector_out(13) <= cpld_cfg2;
        xilinx_vector_out(14) <= cpld_cfg3;
        xilinx_vector_out(15) <= blue_wire; -- Reset button
        xilinx_vector_out(47 downto 16) <= std_logic_vector(fpga_commit);
        xilinx_vector_out(62 downto 48) <= std_logic_vector(fpga_datestamp(14 downto 0));
        for bit in 0 to 11 loop
          if xilinx_vector_in(12+bit)='1' then
            -- DDR = out
            j21(bit) <= xilinx_vector_in(bit);
          else
            j21(bit) <= 'Z';
          end if;
        end loop;
      else
        xilinx_counter <= xilinx_counter + 1;

        xilinx_rx <= xilinx_vector_out(63);
        led_g <= xilinx_vector_out(63);
        xilinx_vector_out(63 downto 1) <= xilinx_vector_out(62 downto 0);        
      end if;
      xilinx_vector_in(63) <= xilinx_tx;
      xilinx_vector_in(62 downto 0) <= xilinx_vector_in(63 downto 1);
      
    end if;
  end process;
  
  
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

      -- Communications with the Xilinx FPGA is a bit "fun", because the internal
      -- oscillator of the MAX10 can drift anywhere between 55MHz and 116MHz based
      -- on temperature, voltage, phase of moon etc.
      -- Also, we have only two wires between the two FPGAs for general communications.
      -- FPGA_TX and FPGA_RX.  This means we don't have enough lines for TX and
      -- RX and an explicit clock.
      -- (Actually, we have JTAG and the MEGA65's serial monitor interface
      -- passing through us as well, but those lines are more or less spoken for.)
      -- What other options do we have?  We currently dedicate a line for the
      -- reset button, which we could re-use.
      -- We also have FPGA_DONE from the Xilinx FPGA, which the Xilinx FPGA can
      -- control, and which we don't use for anything else.
      -- Four lines is much nicer, as we can have CLK, SYNC, TX and RX, and thus
      -- maximise our transfer rate, by not having to waste any cycles with sync
      -- stuff.  It also lets us have the Xilinx FPGA provide the clock, so that
      -- we don't have to worry about the MAX10 clock drifting.
      -- The FPGA_DONE line can only be written to, so we can use that as the clock.
      -- The RESET line, normally to the Xilinx, we can read, and if low, then
      -- we treat it as a sync signal.  The Xilinx FPGA can modulate this at
      -- its end.  Then the TX and RX lines can have their natural meanings.
      
      if counter /= 256 then
        counter <= counter + 1;
      else
        counter <= 0;
        if led_bright /= 0 then
--          LED_R <= '0';
        end if;
      end if;
      if counter = led_bright then
--        LED_R <= '1';
      end if;
      if counter2 /= 800000 then
        counter2 <= counter2 + 1;
      else
        counter2 <= 0;
        if led_bright = 63 then
          led_bright <= 62;
          led_bright_dir <= '1';
        elsif led_bright = 0 then
          led_bright <= 1;
          led_bright_dir <= '0';
        elsif led_bright_dir = '1' then
          led_bright <= led_bright - 1;
        else
          led_bright <= led_bright + 1;
        end if;
      end if;
      
    end if;
  end process;
   		
end architecture simple;
