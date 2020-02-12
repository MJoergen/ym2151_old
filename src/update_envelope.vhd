-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module generates the ADSR envelope.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity update_envelope is
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;

      state_i      : in  STATE_ADSR_t;
      cnt_i        : in  std_logic_vector(C_DECAY_SIZE-1 downto 0);
      envelope_i   : in  std_logic_vector(17 downto 0);

      key_onoff_i  : in  std_logic;
      delay_i      : in  std_logic_vector(C_DECAY_SIZE-1 downto 0);

      state_o      : out STATE_ADSR_t;
      cnt_o        : out std_logic_vector(C_DECAY_SIZE-1 downto 0);
      envelope_o   : out std_logic_vector(17 downto 0)
   );
end entity update_envelope;

architecture synthesis of update_envelope is

   constant C_DELAY_MAX : std_logic_vector(C_DECAY_SIZE-1 downto 0) := (others => '1');

   signal envelope_sub_s : std_logic_vector(17 downto 0);

begin

   ----------------------------------------------------
   -- The amount to subtract is obtained by shifting C_SHIFT_AMOUNT.
   ----------------------------------------------------

   envelope_sub_s(17-C_SHIFT_AMOUNT downto 0)  <= envelope_i(17 downto C_SHIFT_AMOUNT);
   envelope_sub_s(17 downto 18-C_SHIFT_AMOUNT) <= (others => '0');


   ----------------------------------------------------
   -- State machine controlling the ADSR envelope.
   ----------------------------------------------------

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         state_o    <= state_i;
         cnt_o      <= cnt_i;
         envelope_o <= envelope_i;

         case state_i is
            when ATTACK_ST =>
               -- In this state the envelope should increase linearly to maximum.
               state_o    <= DECAY_ST;
               cnt_o      <= delay_i;
               envelope_o <= (17 => '0', others => '1');

               if key_onoff_i = '0' then
                  state_o <= RELEASE_ST;
               end if;

            when DECAY_ST =>
               -- In this state the envelope should decrease exponentially, until
               -- it reaches the value decay_level.
               if cnt_i = 0 then
                  cnt_o  <= delay_i;
                  envelope_o <= envelope_i - envelope_sub_s;
               elsif cnt_i /= C_DELAY_MAX then
                  cnt_o <= cnt_i - 1;
               end if;

               if envelope_sub_s = 0 then
                  state_o <= SUSTAIN_ST;
               end if;

               if key_onoff_i = '0' then
                  state_o <= RELEASE_ST;
               end if;

            when SUSTAIN_ST =>
               -- In this state the envelope should decrease exponentially, until
               -- it reaches the minimum value, or until Key OFF event.
               if key_onoff_i = '0' then
                  state_o <= RELEASE_ST;
               end if;


            when RELEASE_ST =>
               -- In this state the envelope should decrease exponentially, until
               -- it reaches the minimum value, or until Key ON event.
               envelope_o <= (others => '0');

               if key_onoff_i = '1' then
                  state_o <= ATTACK_ST;
               end if;

         end case;

         if rst_i = '1' then
            state_o    <= RELEASE_ST;
            cnt_o      <= (others => '0');
            envelope_o <= (others => '0');
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

