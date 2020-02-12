-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

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
      product_o  : out std_logic_vector(35 downto 0)
   );
end entity calc_product;

architecture synthesis of calc_product is

begin

   i_mult : mult_macro
      generic map (
         DEVICE  => "7SERIES",
         LATENCY => 1,
         WIDTH_A => 18,
         WIDTH_B => 18
      )
      port map (
         CLK => clk_i,
         RST => rst_i,
         CE  => '1',
         A   => envelope_i,
         B   => waveform_i,
         P   => product_o
      ); -- i_mult
      
end architecture synthesis;

