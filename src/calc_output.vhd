-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- Devices:
--  0- 7 : Modulator 1
--  8-15 : Modulator 2
-- 16-23 : Carrier 1
-- 24-31 : Carrier 2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity calc_output is
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      idx_i     : in  std_logic_vector(4 downto 0);
      product_i : in  std_logic_vector(C_PWM_WIDTH-1 downto 0);
      val_o     : out std_logic_vector(C_PWM_WIDTH-1 downto 0)
   );
end entity calc_output;

architecture synthesis of calc_output is

   constant C_NEGATIVE_ONE : std_logic_vector(C_PWM_WIDTH-1 downto 0) :=
      (C_PWM_WIDTH-1 => '1', others => '0');

   signal sum_r : std_logic_vector(C_PWM_WIDTH-1 downto 0);

begin

   p_sum_outputs : process (clk_i)
      variable sum_v : std_logic_vector(C_PWM_WIDTH-1 downto 0);
   begin
      if rising_edge(clk_i) then
         if idx_i = 0 then
            sum_r <= product_i;
         end if;
         if idx_i > 0 then
            sum_v := sum_r + product_i;
            -- Check for overflow
            if sum_r(C_PWM_WIDTH-1) = product_i(C_PWM_WIDTH-1) and 
               sum_r(C_PWM_WIDTH-1) /= sum_v(C_PWM_WIDTH-1) then
               sum_v                := (others => not sum_r(C_PWM_WIDTH-1));
               sum_v(C_PWM_WIDTH-1) := sum_r(C_PWM_WIDTH-1);
            end if;
            sum_r <= sum_v;
         end if;
      end if;
   end process p_sum_outputs;

   p_store_device0 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if idx_i = 8 then
            val_o <= sum_r xor C_NEGATIVE_ONE;
         end if;
      end if;
   end process p_store_device0;

end architecture synthesis;

