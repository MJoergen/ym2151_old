-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
-- This calculates the delay between each update to the envelope.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity calc_delay is
   generic (
      G_UPDATE_HZ : integer             -- Update frequency
   );
   port (
      clk_i    : in  std_logic;
      device_i : in  device_t;
      state_i  : in  state_t;
      delay_o  : out std_logic_vector(C_DECAY_SIZE-1 downto 0)
   );
end entity calc_delay;

architecture synthesis of calc_delay is
   
   signal device_rate_s : std_logic_vector(4 downto 0);
   signal rate_s        : std_logic_vector(5 downto 0);

begin

   p_device_rate : process (device_i, state_i)
   begin
      device_rate_s <= (others => '0');
      case state_i.env_state is
         when ATTACK_ST  => device_rate_s <= device_i.attack_rate;
         when DECAY_ST   => device_rate_s <= device_i.decay_rate;
         when SUSTAIN_ST => device_rate_s <= device_i.sustain_rate;
         when RELEASE_ST => device_rate_s <= device_i.release_rate & "0";
      end case;
   end process p_device_rate;

   -- TBD: Consider device_i.key_scaling
   rate_s <= (device_rate_s & "0") + ("0000" & device_i.key_code(6 downto 5));

   i_rom_delay : entity work.rom_delay
      generic map (
         G_UPDATE_HZ => G_UPDATE_HZ
      )
      port map (
         clk_i   => clk_i,
         rate_i  => rate_s,
         delay_o => delay_o
      ); -- i_rom_delay

end architecture synthesis;

