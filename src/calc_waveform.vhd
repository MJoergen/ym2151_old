-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the ROM with the table of sine values.
-- Input is interpreted as an unsigned fractional number between 0 and 1.
-- Output is the sine, interpreted as a signed number (in two's complement)
-- beween -1 and 1.
-- 
-- The function calculated is y=sin(2*pi*x).
-- The RAM is initialized by calculating first (1+y), converting to integer,
-- and then subtracting 1 by inverting the MSB.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

entity calc_waveform is
   port (
      clk_i      : in  std_logic;
      phase_i    : in  std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      waveform_o : out std_logic_vector(17 downto 0)
   );
end entity calc_waveform;

architecture synthesis of calc_waveform is

   type mem_t is array (0 to 2**C_SINE_ADDR_WIDTH-1) of
                 std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);
   
   impure function InitRom return mem_t is
      constant scale_x : real := real(2**C_SINE_ADDR_WIDTH);
      constant scale_y : real := real(2**(C_SINE_DATA_WIDTH-1)-1);
      variable phase_v : real;
      variable sine_v  : real;
      variable ROM_v   : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 2**C_SINE_ADDR_WIDTH-1 loop
         phase_v  := real(i*2) * MATH_PI / scale_x;

         -- Translate up by 1.
         sine_v   := sin(phase_v)+1.0;

         -- Add 1 to make the range [1..FFF] instead of [0..FFE].
         ROM_v(i) := to_stdlogicvector(integer(sine_v*scale_y)+1, C_SINE_DATA_WIDTH);

         -- And translate back down by 1 again.
         ROM_v(i)(C_SINE_DATA_WIDTH-1) := not ROM_v(i)(C_SINE_DATA_WIDTH-1);
      end loop;
      return ROM_v;
   end function;

   signal mem_r : mem_t := InitRom;

   signal addr_s : std_logic_vector(C_SINE_ADDR_WIDTH-1 downto 0);
   signal data_r : std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);

begin

   addr_s <= phase_i(phase_i'left downto phase_i'left - (C_SINE_ADDR_WIDTH-1));

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_r <= mem_r(to_integer(addr_s));
      end if;
   end process p_read;


   -- Sign extend
   p_waveform : process (data_r)
   begin
      waveform_o <= (others => data_r(C_SINE_DATA_WIDTH-1));
      waveform_o(C_SINE_DATA_WIDTH-1 downto 0) <= data_r;
   end process p_waveform;

end architecture synthesis;

