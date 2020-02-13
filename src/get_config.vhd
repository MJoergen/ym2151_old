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
      idx_o     : out std_logic_vector(4 downto 0);
      device_o  : out device_t
   );
end entity get_config;

architecture synthesis of get_config is

   signal devices_s    : device_vector_t(0 to 31);
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

   idx_o    <= device_cnt_r;
   device_o <= devices_s(to_integer(device_cnt_r));

end architecture synthesis;

