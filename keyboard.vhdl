--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.keyboard_cpld_version.all;

ENTITY keyboard IS
  PORT (
    SCAN_OUT			: IN std_logic_vector(9 downto 0);
    SCAN_IN		    	: OUT std_logic_vector(7 downto 0);

    -- And each key
    key_F5 : in std_logic := '1';
    key_9 : in std_logic := '1';
    key_I : in std_logic := '1';
    key_K : in std_logic := '1';
    key_LESSTHAN : in std_logic := '1';
    key_DEL : in std_logic := '1';
    key_HOME : in std_logic := '1';
    key_O : in std_logic := '1';
    key_F3 : in std_logic := '1';
    key_8 : in std_logic := '1';
    key_U : in std_logic := '1';
    key_J : in std_logic := '1';
    key_M : in std_logic := '1';
    key_RIGHT : in std_logic := '1';
    key_GBP : in std_logic := '1';
    key_EQUALS : in std_logic := '1';
    key_F1 : in std_logic := '1';
    key_7 : in std_logic := '1';
    key_Y : in std_logic := '1';
    key_H : in std_logic := '1';
    key_N : in std_logic := '1';
    key_DOWN : in std_logic := '1';
    key_MINUS : in std_logic := '1';
    key_SEMICOLON : in std_logic := '1';
    key_6 : in std_logic := '1';
    key_T : in std_logic := '1';
    key_G : in std_logic := '1';
    key_B : in std_logic := '1';
    key_LEFT : in std_logic := '1';
    key_PLUS : in std_logic := '1';
    key_COLON : in std_logic := '1';
    key_NOSCROLL : in std_logic := '1';
    key_5 : in std_logic := '1';
    key_R : in std_logic := '1';
    key_F : in std_logic := '1';
    key_V : in std_logic := '1';
    key_SPACE : in std_logic := '1';
    key_0 : in std_logic := '1';
    key_L : in std_logic := '1';
    key_CAPSLOCK : in std_logic := '1';
    key_4 : in std_logic := '1';
    key_E : in std_logic := '1';
    key_D : in std_logic := '1';
    key_C : in std_logic := '1';
    key_HELP : in std_logic := '1';
    key_RETURN : in std_logic := '1';
    key_ALT : in std_logic := '1';
    key_3 : in std_logic := '1';
    key_W : in std_logic := '1';
    key_S : in std_logic := '1';
    key_X : in std_logic := '1';
    key_CURSORUP : in std_logic := '1';
    key_F13 : in std_logic := '1';
    key_CARET : in std_logic := '1';
    key_ESC : in std_logic := '1';
    key_2 : in std_logic := '1';
    key_Q : in std_logic := '1';
    key_A : in std_logic := '1';
    key_Z : in std_logic := '1';
    key_RSHIFT : in std_logic := '1';
    key_F11 : in std_logic := '1';
    key_STAR : in std_logic := '1';
    key_1 : in std_logic := '1';
    key_SHIFTLOCK : in std_logic := '1';
    key_LSHIFT : in std_logic := '1';
    key_SLASH : in std_logic := '1';
    key_F9 : in std_logic := '1';
    key_AT : in std_logic := '1';
    key_STOP : in std_logic := '1';
    key_LARROW : in std_logic := '1';
    key_TAB : in std_logic := '1';
    key_CTRL : in std_logic := '1';
    key_MEGA : in std_logic := '1';
    key_GREATER : in std_logic := '1';
    key_F7 : in std_logic := '1';
    key_P : in std_logic := '1'
    
    );
end keyboard;

architecture smoke_and_mirrors of keyboard is

  type col_array is array(0 to 9) of std_logic_vector(7 downto 0);
  signal COL : col_array := (others => (others => '1'));
  
begin
  process (SCAN_OUT, key_f, key_o, key_RETURN, key_CURSORUP, key_DOWN) is
  begin

    COL(0)(0) <= key_F5;
    COL(0)(1) <= key_9;
    COL(0)(2) <= key_I;
    COL(0)(3) <= key_K;
    COL(0)(4) <= key_LESSTHAN;
    COL(0)(5) <= key_DEL;
    COL(0)(6) <= key_HOME;
    COL(0)(7) <= key_O;

    COL(1)(0) <= key_F3;
    COL(1)(1) <= key_8;
    COL(1)(2) <= key_U;
    COL(1)(3) <= key_J;
    COL(1)(4) <= key_M;
    COL(1)(5) <= key_RIGHT;
    COL(1)(6) <= key_GBP;
    COL(1)(7) <= key_EQUALS;

    COL(2)(0) <= key_F1;
    COL(2)(1) <= key_7;
    COL(2)(2) <= key_Y;
    COL(2)(3) <= key_H;
    COL(2)(4) <= key_N;
    COL(2)(5) <= key_DOWN;
    COL(2)(6) <= key_MINUS;
    COL(2)(7) <= key_SEMICOLON;

    -- NO COL(3)(0)
    COL(3)(1) <= key_6;
    COL(3)(2) <= key_T;
    COL(3)(3) <= key_G;
    COL(3)(4) <= key_B;
    COL(3)(5) <= key_LEFT;
    COL(3)(6) <= key_PLUS;
    COL(3)(7) <= key_COLON;

    COL(4)(0) <= key_NOSCROLL;
    COL(4)(1) <= key_5;
    COL(4)(2) <= key_R;
    COL(4)(3) <= key_F;
    COL(4)(4) <= key_V;
    COL(4)(5) <= key_SPACE;
    COL(4)(6) <= key_0;
    COL(4)(7) <= key_L;

    COL(5)(0) <= key_CAPSLOCK;
    COL(5)(1) <= key_4;
    COL(5)(2) <= key_E;
    COL(5)(3) <= key_D;
    COL(5)(4) <= key_C;
    -- NO COL(5)(5)
    COL(5)(6) <= key_HELP;
    COL(5)(7) <= key_RETURN;

    COL(6)(0) <= key_ALT;
    COL(6)(1) <= key_3;
    COL(6)(2) <= key_W;
    COL(6)(3) <= key_S;
    COL(6)(4) <= key_X;
    COL(6)(5) <= key_CURSORUP;
    COL(6)(6) <= key_F13;
    COL(6)(7) <= key_CARET;

    COL(7)(0) <= key_ESC;
    COL(7)(1) <= key_2;
    COL(7)(2) <= key_Q;
    COL(7)(3) <= key_A;
    COL(7)(4) <= key_Z;
    COL(7)(5) <= key_RSHIFT;
    COL(7)(6) <= key_F11;
    COL(7)(7) <= key_STAR;

    -- COL(8)(0) <= key_;
    COL(8)(1) <= key_1;
    -- COL(8)(2) <= key_;
    COL(8)(3) <= key_SHIFTLOCK;
    COL(8)(4) <= key_LSHIFT;
    COL(8)(5) <= key_SLASH;
    COL(8)(6) <= key_F9;
    COL(8)(7) <= key_AT;

    COL(9)(0) <= key_STOP;
    COL(9)(1) <= key_LARROW;
    COL(9)(2) <= key_TAB;
    COL(9)(3) <= key_CTRL;
    COL(9)(4) <= key_MEGA;
    COL(9)(5) <= key_GREATER;
    COL(9)(6) <= key_F7;
    COL(9)(7) <= key_P;
    
    for i in 0 to 7 loop
      SCAN_IN(i) <= '1'
                    and (COL(0)(i) or SCAN_OUT(0))
                    and (COL(1)(i) or SCAN_OUT(1))
                    and (COL(2)(i) or SCAN_OUT(2))
                    and (COL(3)(i) or SCAN_OUT(3))
                    and (COL(4)(i) or SCAN_OUT(4))
                    and (COL(5)(i) or SCAN_OUT(5))
                    and (COL(6)(i) or SCAN_OUT(6))
                    and (COL(7)(i) or SCAN_OUT(7))
                    and (COL(8)(i) or SCAN_OUT(8))
                    and (COL(9)(i) or SCAN_OUT(9));
    end loop;

  end process;
  
end smoke_and_mirrors;
