-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module generates the ADSR envelope.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity ym2151_envelope_generator is
   generic (
      G_CLOCK_HZ : integer
   );
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      key_onoff_i  : in  std_logic;
      decay_rate_i : in  std_logic_vector(4 downto 0);
      key_code_i   : in  std_logic_vector(6 downto 0);
      envelope_o   : out std_logic_vector(17 downto 0)
   );
end entity ym2151_envelope_generator;

architecture synthesis of ym2151_envelope_generator is

   signal rate_s  : std_logic_vector( 5 downto 0);
   signal delay_s : std_logic_vector(21 downto 0);

   type t_state is (ATTACK_ST, DECAY1_ST, DECAY2_ST, RELEASE_ST);
   signal state_r        : t_state;
   signal envelope_r     : std_logic_vector(16 downto 0);
   signal envelope_sub_s : std_logic_vector(16 downto 0);
   signal clk_cnt_r      : std_logic_vector(21 downto 0);

begin

   envelope_sub_s(16-C_SHIFT_AMOUNT downto 0)  <= envelope_r(16 downto C_SHIFT_AMOUNT);
   envelope_sub_s(16 downto 17-C_SHIFT_AMOUNT) <= (others => '0');

   ----------------------------
   -- Calculate decay constant
   ----------------------------

   rate_s <= (decay_rate_i & "0") + ("0000" & key_code_i(6 downto 5));

   i_ym2151_decay : entity work.ym2151_decay
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         rate_i  => rate_s,
         delay_o => delay_s
      ); -- i_ym2151_decay


   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then

         case state_r is
            when ATTACK_ST =>
               envelope_r <= (others => '1');
               clk_cnt_r  <= delay_s;
               state_r    <= DECAY1_ST;
               if key_onoff_i = '0' then
                  state_r <= RELEASE_ST;
               end if;

            when DECAY1_ST =>
               if clk_cnt_r = 0 then
                  clk_cnt_r  <= delay_s;
                  envelope_r <= envelope_r - envelope_sub_s;
               else
                  clk_cnt_r <= clk_cnt_r - 1;
               end if;

               if envelope_sub_s = 0 then
                  state_r <= DECAY2_ST;
               end if;

               if key_onoff_i = '0' then
                  state_r <= RELEASE_ST;
               end if;

            when DECAY2_ST =>
               if key_onoff_i = '0' then
                  state_r <= RELEASE_ST;
               end if;

            when RELEASE_ST =>
               envelope_r <= (others => '0');
               if key_onoff_i = '1' then
                  state_r <= ATTACK_ST;
               end if;

         end case;

         if rst_i = '1' then
            state_r <= RELEASE_ST;
         end if;
      end if;
   end process p_fsm;


   -- Connect output
   envelope_o <= "0" & envelope_r;  -- Prepend zero to make sure number is always positive.

end architecture synthesis;

