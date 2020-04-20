-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the waveform from the current phase.
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
      state_i    : in  state_t;
      channel_i  : in  channel_t;
      waveform_o : out std_logic_vector(17 downto 0)
   );
end entity calc_waveform;

architecture synthesis of calc_waveform is

   type mem_t is array (0 to 2**C_SINE_ADDR_WIDTH-1) of
                 std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);
   
   impure function InitRom return mem_t is
      constant scale_x : real := real(2**C_SINE_ADDR_WIDTH);
      constant scale_y : real := real(2**(C_SINE_DATA_WIDTH-3)-1);
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
         ROM_v(i)(C_SINE_DATA_WIDTH-1) := not ROM_v(i)(C_SINE_DATA_WIDTH-3);
         ROM_v(i)(C_SINE_DATA_WIDTH-2) := not ROM_v(i)(C_SINE_DATA_WIDTH-3);
         ROM_v(i)(C_SINE_DATA_WIDTH-3) := not ROM_v(i)(C_SINE_DATA_WIDTH-3);
      end loop;
      return ROM_v;
   end function;

   signal phasemod_s : std_logic_vector(C_PHASE_WIDTH-1 downto 0);
   signal phase_s    : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   signal addr_s     : std_logic_vector(C_SINE_ADDR_WIDTH-1 downto 0);

   signal mem_r      : mem_t := InitRom;

   signal data_r     : std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);

   -- Debug
   constant DEBUG_MODE                : boolean := false;

   attribute mark_debug               : boolean;
   attribute mark_debug of state_i    : signal is DEBUG_MODE;
   attribute mark_debug of channel_i  : signal is DEBUG_MODE;
   attribute mark_debug of phasemod_s : signal is DEBUG_MODE;
   attribute mark_debug of phase_s    : signal is DEBUG_MODE;
   attribute mark_debug of addr_s     : signal is DEBUG_MODE;
   attribute mark_debug of data_r     : signal is DEBUG_MODE;

begin

   -- Truncate current phase.
   p_phasemod : process (state_i, channel_i)
   begin
      phasemod_s <= (others => state_i.output(C_PWM_WIDTH-1));
      case to_integer(channel_i.feedback) is
         when 0 => phasemod_s <= (others => '0');
         when 1 => phasemod_s(C_PHASE_WIDTH-3 downto C_PHASE_WIDTH-C_PWM_WIDTH-2) <= state_i.output;
         when 2 => phasemod_s(C_PHASE_WIDTH-2 downto C_PHASE_WIDTH-C_PWM_WIDTH-1) <= state_i.output;
         when 3 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH)   <= state_i.output;
         when 4 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+1) <= state_i.output(C_PWM_WIDTH-2 downto 0);
         when 5 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+2) <= state_i.output(C_PWM_WIDTH-3 downto 0);
         when 6 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+3) <= state_i.output(C_PWM_WIDTH-4 downto 0);
         when 7 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+4) <= state_i.output(C_PWM_WIDTH-5 downto 0);
      end case;
   end process p_phasemod;

   phase_s <= state_i.phase_cur + phasemod_s;

   addr_s <= phase_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_SINE_ADDR_WIDTH);

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

