-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity get_config is
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Configuration output
      config_o  : out config_t
   );
end entity get_config;

architecture synthesis of get_config is

   signal devices_s    : t_device_vector(0 to 31);
   signal device_cnt_r : std_logic_vector(4 downto 0) := (others => '0');

begin

   ----------------------------------------------------
   -- Instantiate CPU configuration interface
   ----------------------------------------------------

   i_ym2151_config : entity work.ym2151_config
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         addr_i    => addr_i,
         wr_en_i   => wr_en_i,
         wr_data_i => wr_data_i,
         devices_o => devices_s
      ); -- i_config


   ----------------------------------------------------
   -- Loop through each of the 32 devices
   ----------------------------------------------------

   p_device_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         device_cnt_r <= device_cnt_r + 1;
      end if;
   end process p_device_cnt;


   config_o.device_cnt   <= device_cnt_r;
   config_o.key_code     <= devices_s(to_integer(device_cnt_r)).pg.key_code;
   config_o.key_fraction <= devices_s(to_integer(device_cnt_r)).pg.key_fraction;
   config_o.total_level  <= devices_s(to_integer(device_cnt_r)).eg.total_level;
   config_o.key_scaling  <= devices_s(to_integer(device_cnt_r)).eg.key_scaling;
   config_o.attack_rate  <= devices_s(to_integer(device_cnt_r)).eg.attack_rate;
   config_o.decay_rate   <= devices_s(to_integer(device_cnt_r)).eg.decay_rate;
   config_o.decay_level  <= devices_s(to_integer(device_cnt_r)).eg.decay_level;
   config_o.sustain_rate <= devices_s(to_integer(device_cnt_r)).eg.sustain_rate;
   config_o.release_rate <= devices_s(to_integer(device_cnt_r)).eg.release_rate;
   config_o.key_onoff    <= devices_s(to_integer(device_cnt_r)).eg.key_onoff;

end architecture synthesis;

