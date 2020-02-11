-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module generates the waveform associated with the current
-- note.
--
-- Latency is 3 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity ym2151_waveform_generator is
   generic (
      G_CLOCK_HZ : integer             -- Input clock frequency
   );
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      key_code_i : in  std_logic_vector(6 downto 0);
      waveform_o : out std_logic_vector(17 downto 0)
   );
end entity ym2151_waveform_generator;

architecture synthesis of ym2151_waveform_generator is

   -- Frequency, in units of fractional phase per clock cycle.
   signal phase_inc_s : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Current fractional phase.
   signal phase_r     : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Current sine value.
   signal sine_s      : std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);

begin

   ----------------------------------------------------
   -- Phase Increment (frequency) lookup
   -- Latency 1 clock cycle.
   ----------------------------------------------------

   i_phase_increment : entity work.phase_increment
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i          => clk_i,
         key_code_i     => key_code_i,
         key_fraction_i => (others => '0'),
         phase_inc_o    => phase_inc_s
      ); -- i_phase_increment


   ----------------------------------------------------
   -- Phase
   -- Latency 1 clock cycle.
   ----------------------------------------------------

   p_phase : process (clk_i)
   begin
      if rising_edge(clk_i) then
         phase_r <= phase_r + phase_inc_s;
         if rst_i = '1' then
            phase_r <= (others => '0');
         end if;
      end if;
   end process p_phase;


   ----------------------------------------------------
   -- Instantiate sine table
   -- Latency 1 clock cycle.
   ----------------------------------------------------

   i_ym2151_sine_rom : entity work.ym2151_sine_rom
      port map (
         clk_i  => clk_i,
         addr_i => phase_r(phase_r'left downto phase_r'left - (C_SINE_ADDR_WIDTH-1)),
         data_o => sine_s
      ); -- i_ym2151_sine_rom


   ----------------------------------------------------
   -- Sign extend the lookup value, converting to an 18-bit signed number.
   ----------------------------------------------------

   p_waveform : process (sine_s)
   begin
      waveform_o <= (others => sine_s(C_SINE_DATA_WIDTH-1));
      waveform_o(C_SINE_DATA_WIDTH-1 downto 0) <= sine_s;
   end process p_waveform;

end architecture synthesis;

