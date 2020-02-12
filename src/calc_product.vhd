-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;

entity calc_product is
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      envelope_i : in  std_logic_vector(17 downto 0);
      waveform_i : in  std_logic_vector(17 downto 0);
      product_o  : out std_logic_vector(C_PDM_WIDTH-1 downto 0)
   );
end entity calc_product;

architecture synthesis of calc_product is

   signal product_s : std_logic_vector(35 downto 0);

begin

   i_mult : mult_macro
      generic map (
         DEVICE  => "7SERIES",
         LATENCY => 2,
         WIDTH_A => 18,
         WIDTH_B => 18
      )
      port map (
         CLK => clk_i,
         RST => rst_i,
         CE  => '1',
         A   => envelope_i,
         B   => waveform_i,
         P   => product_s
      ); -- i_mult
      
   -- The output from the multiplier is a signed 36-bit integer.
   assert (or(product_s(35 downto 17+C_PDM_WIDTH)) = '0') or
          (and(product_s(35 downto 17+C_PDM_WIDTH)) = '1') or
          rst_i /= '0';

   product_o <= product_s(17+C_PDM_WIDTH-1 downto 17);

end architecture synthesis;

