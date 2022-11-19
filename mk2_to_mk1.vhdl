library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use Std.TextIO.all;
use work.debugtools.all;

entity mk2_to_mk1 is
  port (
    clock100 : in std_logic;

    mk2_xil_io1 : in std_logic;
    mk2_xil_io2 : in std_logic;
    mk2_xil_io3 : out std_logic := '1';
    
    mk2_io1_in : in std_logic;
    mk2_io1 : out std_logic;
    mk2_io1_en : out std_logic;

    mk2_io2_in : in std_logic;
    mk2_io2 : out std_logic;
    mk2_io2_en : out std_logic
    
    );

end entity mk2_to_mk1;

architecture behavioural of mk2_to_mk1 is

  signal output_vector : std_logic_vector(127 downto 0);
  signal disco_vector : std_logic_vector(95 downto 0);

  signal i2c_counter : integer range 0 to 125 := 0;
  signal i2c_tick : std_logic := '0';
  signal i2c_state : integer := 0;
  signal addr : unsigned(2 downto 0) := to_unsigned(0,3);

  signal i2c_bit : std_logic := '0';
  signal i2c_bit_valid : std_logic := '0';
  signal i2c_bit_num : integer range 0 to 15 := 0;

  signal current_keys : std_logic_vector(79 downto 0) := (others => '1');
  signal export_keys : std_logic_vector(79 downto 0) := (others => '1');

  -- These signals are used to cause the first write to U1 to instead set the
  -- data direection register instead of writing to the port
  signal u1_active : std_logic := '0';
  signal u1_reg6 : std_logic := '1';
  
  signal led0_r : std_logic := '0';
  signal led0_g : std_logic := '0';
  signal led0_b : std_logic := '0';
  signal led1_r : std_logic := '0';
  signal led1_g : std_logic := '0';
  signal led1_b : std_logic := '0';
  signal led2_r : std_logic := '0';
  signal led2_g : std_logic := '0';
  signal led2_b : std_logic := '0';
  signal led3_r : std_logic := '0';
  signal led3_g : std_logic := '0';
  signal led3_b : std_logic := '0';
  signal led_capslock : std_logic := '0';
  signal led_shiftlock : std_logic := '0';
  signal led_tick : std_logic := '0';
  signal led_counter : integer range 0 to 15 := 0;
  -- shiftlock active low
  signal shiftlock_toggle : std_logic := '1';
  signal kbd_gpio1 : std_logic;
  signal kbd_gpio2 : std_logic;
  signal shiftlock : std_logic := '0';

  signal sda_assert : std_logic := '0';

  signal returnkey : std_logic;
  signal upkey : std_logic;
  signal leftkey : std_logic;
  signal restore : std_logic;
  
begin  -- behavioural

  process (clock100)
    variable keyram_write_enable : std_logic_vector(7 downto 0);
    variable keyram_offset : integer range 0 to 15 := 0;
    variable keyram_offset_tmp : std_logic_vector(2 downto 0);
    
  begin
    if rising_edge(clock100) then

      i2c_bit_valid <= '0';

      -- Generate ~400KHz I2C clock
      -- We use 2 or 3 ticks per clock, so 100MHz/(400KHz*2) = 125
      if i2c_counter < 125 then
        i2c_counter <= i2c_counter + 1;
        i2c_tick <= '0';
      else
        i2c_counter <= 0;
        i2c_tick <= '1';
      end if;
      
      -- This keyboard uses I2C to talk to 6 I2C IO expanders
      -- Each key on the keyboard is connected to a separate line,
      -- so we just need to read the input ports of them, and build
      -- the matrix data from that, and then export it.
      -- For the LEDs, we just have to write to the correct I2C registers
      -- to set those to output, and to write the appropriate values.
      
      -- The main trade-offs of the MK-II keyboard is no "ambulance
      -- lights" mode, and that the scanning will be at ~1KHz, rather than
      -- the ~100KHz of the MK-I. But 1ms latency should be ok. It will likely
      -- reduce the amount of PWM we can do on the LEDs for different brightness
      -- levels.
      
      -- We use a state machine for the simple I2C reads
      -- mk2_io1 = SDA, mk2_io2 = SCL

      if sda_assert='1' then
        sda_assert <= '0';
        mk2_io1 <= '0'; mk2_io1_en <= '1';
      end if;
      
      if led_tick='1' then
        if led_counter < 15 then
          led_counter <= led_counter + 1;
        else
          led_counter <= 0;
        end if;
        led0_r <= '0'; led0_g <= '0'; led0_b <= '0';
        led1_r <= '0'; led1_g <= '0'; led1_b <= '0';
        led2_r <= '0'; led2_g <= '0'; led2_b <= '0';
        led3_r <= '0'; led3_g <= '0'; led3_b <= '0';
        if to_integer(unsigned(output_vector(7 downto 4))) > led_counter then led0_r <= '1'; end if;
        if to_integer(unsigned(output_vector(15 downto 12))) > led_counter then led0_g <= '1'; end if;
        if to_integer(unsigned(output_vector(23 downto 20))) > led_counter then led0_b <= '1'; end if;
        if to_integer(unsigned(output_vector(31 downto 24))) > led_counter then led1_r <= '1'; end if;
        if to_integer(unsigned(output_vector(39 downto 36))) > led_counter then led1_g <= '1'; end if;
        if to_integer(unsigned(output_vector(47 downto 44))) > led_counter then led1_b <= '1'; end if;
        if to_integer(unsigned(output_vector(55 downto 52))) > led_counter then led2_r <= '1'; end if;
        if to_integer(unsigned(output_vector(63 downto 60))) > led_counter then led2_g <= '1'; end if;
        if to_integer(unsigned(output_vector(71 downto 68))) > led_counter then led2_b <= '1'; end if;
        if to_integer(unsigned(output_vector(79 downto 76))) > led_counter then led3_r <= '1'; end if;
        if to_integer(unsigned(output_vector(87 downto 84))) > led_counter then led3_g <= '1'; end if;
        if to_integer(unsigned(output_vector(95 downto 92))) > led_counter then led3_b <= '1'; end if;

        led_shiftlock <= not shiftlock_toggle;
      end if;

      -- Stash the bits into the key matrix
      -- MK-II keyboard PCB schematics have the key assignments there.
      if i2c_bit_valid='1' then
        report "Storing matrix bit " & integer'image(i2c_bit_num) & " = " & std_logic'image(i2c_bit)
          & ", addr= " & to_string(std_logic_vector(addr)) & ", i2c_state = " & integer'image(i2c_state);
        case addr is
          when "011" => -- U2
            case i2c_bit_num is
              when 0 => current_keys(67) <= i2c_bit; -- HELP
              when 1 => current_keys(70) <= i2c_bit;-- F13
              when 2 => current_keys(69) <= i2c_bit;-- F11
              when 3 => current_keys(68) <= i2c_bit;-- F9
              when 4 => current_keys(0) <= i2c_bit; -- DEL
                        -- XXX copied from MK-I keyboard behaviour. Why
                        -- does DEL map to two positions in the vector?
                        current_keys(76) <= i2c_bit;
              when 5 => current_keys(51) <= i2c_bit;-- HOME
              when 6 => current_keys(48) <= i2c_bit;-- GBP
              when 7 => current_keys(43) <= i2c_bit;-- MINUS
              when 8 => current_keys(41) <= i2c_bit;-- P
              when 9 => current_keys(38) <= i2c_bit;-- O
              when 10 => current_keys(33) <= i2c_bit;-- I
              when 11 => current_keys(30) <= i2c_bit;-- U
              when 12 => current_keys(40) <= i2c_bit;-- PLUS
              when 13 => current_keys(35) <= i2c_bit;-- ZERO
              when 14 => current_keys(6) <= i2c_bit;-- F5
              when 15 => current_keys(3) <= i2c_bit;-- F7
              when others => null;
            end case;

          when "001" => -- U3
            case i2c_bit_num is
              when 0 => shiftlock <= i2c_bit;-- SHIFTLOCK
                        if i2c_bit='0' and shiftlock='1' then
                          shiftlock_toggle <= not shiftlock_toggle;
                        end if;
              when 1 => current_keys(10) <= i2c_bit;-- A
              when 2 => current_keys(13) <= i2c_bit;-- S
              when 3 => current_keys(18) <= i2c_bit;-- D
              when 4 => current_keys(65) <= i2c_bit;-- TAB
              when 5 => current_keys(62) <= i2c_bit;-- Q
              when 6 => current_keys(9) <= i2c_bit;-- W
              when 7 => current_keys(14) <= i2c_bit;-- E
              when 8 => kbd_gpio1 <= i2c_bit;-- GPIO1
              when 9 => kbd_gpio2 <= i2c_bit;-- GPIO2
              when 10 => current_keys(58) <= i2c_bit;-- CTRL
              when 11 => current_keys(61) <= i2c_bit;-- MEGA
              when 12 => current_keys(15) <= i2c_bit and shiftlock_toggle;-- LSHIFT
              when 13 => current_keys(12) <= i2c_bit;-- Z
              when 14 => current_keys(23) <= i2c_bit;-- X
              when 15 => current_keys(20) <= i2c_bit;-- C
              when others => null;
            end case;

          when "100" => -- U4
            case i2c_bit_num is
              when 0 => current_keys(47) <= i2c_bit;-- <
              when 1 => current_keys(44) <= i2c_bit;-- >
              when 2 => current_keys(31) <= i2c_bit;-- V
              when 3 => current_keys(28) <= i2c_bit;-- B
              when 4 => current_keys(39) <= i2c_bit;-- N
              when 5 => current_keys(37) <= i2c_bit;-- K
              when 6 => current_keys(36) <= i2c_bit;-- M
              when 7 => current_keys(42) <= i2c_bit;-- L
              when 8 => current_keys(34) <= i2c_bit;-- J
              when 9 => current_keys(25) <= i2c_bit;-- Y
              when 10 => current_keys(29) <= i2c_bit;-- H
              when 11 => current_keys(22) <= i2c_bit;-- T
              when 12 => current_keys(26) <= i2c_bit;-- G
              when 13 => current_keys(17) <= i2c_bit;-- R
              when 14 => current_keys(21) <= i2c_bit;-- F
              when 15 => current_keys(60) <= i2c_bit;-- SPACE
                         report "SPACE is " & std_logic'image(i2c_bit);
              when others => null;
            end case;

          when "010" => -- U5
            case i2c_bit_num is
              when 0 => current_keys(52) <= i2c_bit;-- RSHIFT
              when 1 => current_keys(55) <= i2c_bit;-- ?
              when 2 => -- duplicate of >
              when 3 => -- duplucate of <
              when 4 => current_keys(74) <= i2c_bit;-- LEFT
                        -- XXX need to be delayed until we have
                        -- exported RSHIFT
                        leftkey <= not i2c_bit;
              when 5 => current_keys(73) <= i2c_bit;-- UP
                        -- XXX need to be delayed until we have
                        -- exported RSHIFT
                        upkey <= not i2c_bit;
              when 6 => current_keys(7) <= i2c_bit;-- DOWN
              when 7 => current_keys(2) <= i2c_bit;-- RIGHT
              when 8 => current_keys(45) <= i2c_bit;-- :
              when 9 => current_keys(50) <= i2c_bit;-- ;
              when 10 => current_keys(53) <= i2c_bit;-- =
              when 11 => current_keys(1) <= i2c_bit;-- RETURN
                         returnkey <= i2c_bit;
                         -- Copied from MK-I keyboard behaviour
                         current_keys(77) <= i2c_bit;
              when 12 => current_keys(46) <= i2c_bit;-- @
              when 13 => current_keys(49) <= i2c_bit;-- * 
              when 14 => current_keys(54) <= i2c_bit;-- ^
              when 15 => current_keys(75) <= i2c_bit;-- RESTORE
                         restore <= i2c_bit;
              when others => null;
            end case;

          when "101" => -- U6
            case i2c_bit_num is
              when 0 => current_keys(11) <= i2c_bit;-- 4
              when 1 => current_keys(16) <= i2c_bit;-- 5
              when 2 => current_keys(19) <= i2c_bit;-- 6
              when 3 => current_keys(24) <= i2c_bit;-- 7
              when 4 => current_keys(27) <= i2c_bit;-- 8
              when 5 => current_keys(32) <= i2c_bit;-- 9
              when 6 => current_keys(5) <= i2c_bit;-- F3
              when 7 => current_keys(4) <= i2c_bit;-- F1
              when 8 => current_keys(64) <= i2c_bit;-- NOSCROLL
              when 9 => current_keys(72) <= i2c_bit;-- CAPSLOCK
                        -- XXX need to cancel/toggle CAPSLOCK when held for
                        -- fast-key behaviour
                        led_capslock <= i2c_bit;
              when 10 => current_keys(66) <= i2c_bit;-- ALT
              when 11 => current_keys(71) <= i2c_bit;-- ESC
              when 12 => current_keys(63) <= i2c_bit;-- RUNSTOP
              when 13 => current_keys(56) <= i2c_bit;-- 1
              when 14 => current_keys(59) <= i2c_bit;-- 2
              when 15 => current_keys(8) <= i2c_bit;-- 3
              when others => null;
            end case;
            
          when others => null;
        end case;
      end if;
      
      led_tick <= '0';
      if i2c_state = 0 then
        if to_integer(addr) < 5 then
--            addr <= addr + 1;
          -- XXX DEBUG - just keep on the same expander
          addr <= "101";
          report "Reading I2C IO expander " & integer'image(to_integer(addr)+ 1);
          i2c_state <= 100;
        else
          addr <= "000";
          led_tick <= '1';
          report "Writing to I2C IO expander " & integer'image(0);
          -- We have read all IO expanders, so update exported key states
          export_keys <= current_keys;
          current_keys <= (others => '1');
          -- Update LEDs
          i2c_state <= 500;
        end if;
      end if;
      
      if i2c_tick='1' and i2c_state /= 0 then
        i2c_state <= i2c_state + 1;

        case i2c_state is
          when 0 => null;

          -- State 500 = write to output ports of IO expander
          -- Start condition
          when 500 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 501 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          -- Send address 0100xxx
          when 502 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 503 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 504 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 505 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 506 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 507 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 508 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 509 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 510 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 511 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 512 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 513 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 514 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 515 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 516 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 517 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 518 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 519 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 520 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 521 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 522 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1'; -- XXX delete superflous
                                                                                                    -- state
          when 523 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';       -- select write
          when 524 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          -- ACK bit
          when 525 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 526 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 527 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';

          -- Write to set address to read from
          -- Send $02 to indicate read will be of register 2
          when 528 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 529 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 530 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';                          
          when 531 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 532 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 533 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 534 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 535 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 536 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 537 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 538 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 539 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 540 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 541 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 542 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 543 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 544 => mk2_io1 <= '0'; mk2_io1_en <= not u1_reg6; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 545 => mk2_io1 <= '0'; mk2_io1_en <= not u1_reg6; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 546 => mk2_io1 <= '0'; mk2_io1_en <= not u1_reg6; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 547 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 548 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 549 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 550 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 551 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 552 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- Send ACK bit during write
          when 553 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 554 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 555 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Write output port values in 2 bytes
          when 556 => mk2_io1 <= '0'; mk2_io1_en <= not (led_shiftlock and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 557 => mk2_io1 <= '0'; mk2_io1_en <= not (led_shiftlock and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';                          
          when 558 => mk2_io1 <= '0'; mk2_io1_en <= not (led_shiftlock and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';                          
          when 559 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 560 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_b and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 561 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 562 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 563 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_g and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 564 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 565 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 566 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_r and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 567 => mk2_io1 <= '0'; mk2_io1_en <= not (led1_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 568 => mk2_io1 <= '0'; mk2_io1_en <= not (led_capslock and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 569 => mk2_io1 <= '0'; mk2_io1_en <= not (led_capslock and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 570 => mk2_io1 <= '0'; mk2_io1_en <= not (led_capslock and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 571 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 572 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_b and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 573 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 574 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 575 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_g and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 576 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 577 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 578 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_r and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 579 => mk2_io1 <= '0'; mk2_io1_en <= not (led0_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- Send ACK bit during write
          when 580 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 581 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 582 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';


          when 583 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 584 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';                          
          when 585 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';                          
          when 586 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 587 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_b and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 588 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 589 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 590 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_g and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 591 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 592 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 593 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_r and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 594 => mk2_io1 <= '0'; mk2_io1_en <= not (led3_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 595 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 596 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 597 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 598 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 599 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_b and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 600 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_b and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 601 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 602 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_g and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 603 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_g and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 604 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 605 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_r and u1_active); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 606 => mk2_io1 <= '0'; mk2_io1_en <= not (led2_r and u1_active); mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- Send ACK bit during write
          when 607 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 608 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 609 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Send STOP at end of read
          when 610 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1'; -- don't ack last byte read
          when 611 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 612 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
                      i2c_state <= 0;
                      if u1_reg6='1' then
                        u1_reg6 <= '0';
                        u1_active <= '1';
                      end if;
                      
          -- State 100 = read inputs from an IO expander
          -- Start condition
          when 100 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 101 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          -- Send address 0100xxx
          when 102 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 103 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 104 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 105 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 106 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 107 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 108 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 109 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 110 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 111 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 112 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 113 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Write to set address to read from
          when 114=> mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 115 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 116 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 117 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 118 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 119 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 120 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 121 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 122 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 123 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 124 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';  -- XXX delete this
                                                                                                     -- superflous state
          when 125 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';       -- select write
          when 126 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 127 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- ACK bit
          when 128 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 129 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 130 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 131 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Send $00 to indicate read will be of register 0
          when 132 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 133 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';                          
          when 134 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 135 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 136 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 137 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 138 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 139 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 140 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 141 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 142 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 143 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 144 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 145 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 146 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 147 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 148 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 149 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 150 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 151 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 152 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 153 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 154 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 155 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- Send ACK bit during write
          when 156 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 157 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 158 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Send repeated start
          when 159 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 160 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 161 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
                      
          -- Send address 0100xxx
          when 162 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 163 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 164 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 165 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 166 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 167 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 168 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 169 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 170 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 171 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 172 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 173 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          -- 
          when 175 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 176 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 177 => mk2_io1 <= '0'; mk2_io1_en <= not addr(2); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 178 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 179 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 180 => mk2_io1 <= '0'; mk2_io1_en <= not addr(1); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 181 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 182 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 183 => mk2_io1 <= '0'; mk2_io1_en <= not addr(0); mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 184 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';      -- select read
          when 185 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          -- ACK bit
          when 186 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 187 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 188 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 189 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
                      
          -- Read 2 bytes of data
          when 190 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 191 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 7; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 192 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 193 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 6; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 194 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 195 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 5; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 196 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 197 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 4; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 198 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 199 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 3; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 200 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 201 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 2; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 202 => mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 203 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 1; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 204 => mk2_io2 <= '1'; mk2_io2_en <= '1'; mk2_io1 <= '1'; mk2_io1_en <= '0';
          when 205 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 0; mk2_io2 <= '0'; mk2_io2_en <= '1';   -- ack byte read
                      -- Now we need to release SDA immediately, rather than
                      -- waiting 1 bit time, but only after we have pulled
                      -- SCL low.
                      sda_assert <= '1';
          when 206 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
                      
          when 207 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 208 => mk2_io2 <= '1'; mk2_io2_en <= '1'; mk2_io1 <= '1'; mk2_io1_en <= '0';
          when 209 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 15; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 210 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 211 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 14; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 212 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 213 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 13; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 214 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 215 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 12; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 216 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 217 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 11; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 218 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 219 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 10; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 220 => mk2_io2 <= '1'; mk2_io2_en <= '1'; 
          when 221 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 9; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 222 => mk2_io2 <= '1'; mk2_io2_en <= '1'; mk2_io1 <= '1'; mk2_io1_en <= '0'; -- don't ack last byte read
          when 223 => i2c_bit <= mk2_io1; i2c_bit_valid <= '1'; i2c_bit_num <= 8; mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1'; 
          when 224 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
                      
          -- Send STOP at end of read
          when 225 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '0'; mk2_io2_en <= '1'; -- don't ack last byte read
          when 226 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '0'; mk2_io2_en <= '1';
          when 227 => mk2_io1 <= '0'; mk2_io1_en <= '1'; mk2_io2 <= '1'; mk2_io2_en <= '1';
          when 228 => mk2_io1 <= '1'; mk2_io1_en <= '0'; mk2_io2 <= '1'; mk2_io2_en <= '1';
                      i2c_state <= 0;
          when others => null;
        end case;
      end if;
    end if;
  end process;
  
end behavioural;