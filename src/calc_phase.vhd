-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the current phase.
-- Latency is 0 clock cycles (i.e. combinatorial).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity calc_phase is
   port (
      clk_i       : in  std_logic;
      device_i    : in  device_t;
      state_i     : in  state_t;
      state_d1_i  : in  state_t;
      state_d2_i  : in  state_t;
      prevstate_i : in  state_t;
      channel_i   : in  channel_t;
      phase_o     : out std_logic_vector(C_PHASE_WIDTH-1 downto 0)
   );
end entity calc_phase;

architecture synthesis of calc_phase is

   signal sum_s      : std_logic_vector(C_PWM_WIDTH downto 0);

   signal phasemod_s : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Debug
   constant DEBUG_MODE                 : boolean := false;

   attribute mark_debug                : boolean;
   attribute mark_debug of state_i     : signal is DEBUG_MODE;
   attribute mark_debug of prevstate_i : signal is DEBUG_MODE;
   attribute mark_debug of channel_i   : signal is DEBUG_MODE;
   attribute mark_debug of phasemod_s  : signal is DEBUG_MODE;
   attribute mark_debug of phase_o     : signal is DEBUG_MODE;

begin

   -- Calculate sum of the two previous values, while sign extending them.
   sum_s <= (state_i.output(C_PWM_WIDTH-1 downto C_PWM_WIDTH-1) & state_i.output)
          + (prevstate_i.output(C_PWM_WIDTH-1 downto C_PWM_WIDTH-1) & prevstate_i.output);

   -- Truncate current phase.
   p_phasemod : process (sum_s, channel_i)
   begin
      phasemod_s <= (others => sum_s(C_PWM_WIDTH));
      case to_integer(channel_i.feedback) is
         when 0 => phasemod_s <= (others => '0');
         when 1 => phasemod_s(C_PHASE_WIDTH-3 downto C_PHASE_WIDTH-C_PWM_WIDTH-3) <= sum_s;
         when 2 => phasemod_s(C_PHASE_WIDTH-2 downto C_PHASE_WIDTH-C_PWM_WIDTH-2) <= sum_s;
         when 3 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH-1) <= sum_s;
         when 4 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH)   <= sum_s(C_PWM_WIDTH-1 downto 0);
         when 5 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+1) <= sum_s(C_PWM_WIDTH-2 downto 0);
         when 6 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+2) <= sum_s(C_PWM_WIDTH-3 downto 0);
         when 7 => phasemod_s(C_PHASE_WIDTH-1 downto C_PHASE_WIDTH-C_PWM_WIDTH+3) <= sum_s(C_PWM_WIDTH-4 downto 0);
         when others => null;
      end case;
   end process p_phasemod;

   phase_o <= state_i.phase_cur + phasemod_s;

end architecture synthesis;

