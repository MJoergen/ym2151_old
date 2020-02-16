-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the frequency associated with the
-- current note.
--
-- This file takes as input a 7-bit key code consisting of
-- * Octave (3 bits)
-- * Semitone (4 bits)
-- as well as a 6-bit key fraction.
--
-- It generates the corresponding frequency as output, in the units of
-- fractional phase per clock cycle.
--
-- Latency is 1 clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

entity calc_phase_inc is
   generic (
      G_UPDATE_HZ : integer            -- Input clock frequency
   );
   port (
      clk_i       : in  std_logic;
      channel_i   : in  channel_t;
      device_i    : in  device_t;
      phase_inc_o : out std_logic_vector(C_PHASE_WIDTH-1 downto 0)
   );
end entity calc_phase_inc;

architecture synthesis of calc_phase_inc is

   signal phinc_addr_s : std_logic_vector(9 downto 0);
   signal phinc_data_s : std_logic_vector(C_PHASEINC_DATA_WIDTH-1 downto 0);

   signal octave_r     : std_logic_vector(2 downto 0);

begin

   ----------------------------------------------------
   -- Generate lookup address in ROM.
   ----------------------------------------------------

   -- Convert the key code from range 0..14 to range 0..11
   phinc_addr_s(9 downto 6) <= channel_i.key_code(3 downto 0) - ("00" & channel_i.key_code(3 downto 2));
   phinc_addr_s(5 downto 0) <= channel_i.key_fraction;

   inst_rom_phase_inc : entity work.rom_phase_inc
      generic map (
         G_UPDATE_HZ => G_UPDATE_HZ
      )
      port map (
         clk_i  => clk_i,
         addr_i => phinc_addr_s,
         data_o => phinc_data_s
      ); -- inst_rom_phase_inc


   ----------------------------------------------------
   -- Store octave, so it is ready together with the
   -- output from the Phase Increment ROM.
   ----------------------------------------------------

   p_octave : process (clk_i)
   begin
      if rising_edge(clk_i) then
         octave_r <= channel_i.key_code(6 downto 4);
      end if;
   end process p_octave;


   ----------------------------------------------------
   -- Shift frequency based on octave number
   ----------------------------------------------------

   p_phase_inc : process (phinc_data_s, octave_r)
   begin
      phase_inc_o <= (others => '0');
      phase_inc_o(C_PHASEINC_DATA_WIDTH-1+to_integer(octave_r) downto to_integer(octave_r)) <= phinc_data_s;
   end process p_phase_inc;

end architecture synthesis;

