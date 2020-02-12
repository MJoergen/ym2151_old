-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity calc_delay is
   generic (
      G_UPDATE_HZ : integer             -- Update frequency
   );
   port (
      clk_i          : in  std_logic;
      state_i        : in  STATE_ADSR_t;
      key_code_i     : in  std_logic_vector(6 downto 0);
      key_scaling_i  : in  std_logic_vector(1 downto 0);
      attack_rate_i  : in  std_logic_vector(4 downto 0);
      decay_rate_i   : in  std_logic_vector(4 downto 0);
      sustain_rate_i : in  std_logic_vector(4 downto 0);
      release_rate_i : in  std_logic_vector(3 downto 0);
      delay_o        : out std_logic_vector(C_DECAY_SIZE-1 downto 0)
   );
end entity calc_delay;

architecture synthesis of calc_delay is
   
   signal rate_s  : std_logic_vector(5 downto 0);
   signal delay_s : std_logic_vector(C_DECAY_SIZE-1 downto 0);

begin

   -- TBD: Consider state_i and key_scaling_i
   rate_s <= (decay_rate_i & "0") + ("0000" & key_code_i(6 downto 5));

   i_ym2151_decay : entity work.ym2151_decay
      generic map (
         G_UPDATE_HZ => G_UPDATE_HZ
      )
      port map (
         rate_i  => rate_s,
         delay_o => delay_s
      ); -- i_ym2151_decay

   p_register : process (clk_i)
   begin
      if rising_edge(clk_i) then
         delay_o <= delay_s;
      end if;
   end process p_register;

end architecture synthesis;

