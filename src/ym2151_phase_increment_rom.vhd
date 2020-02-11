-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the ROM with the phase increments
-- (frequency) of each note.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

entity phase_increment_rom is
   generic (
      G_CLOCK_HZ : integer -- Frequency of input clock
   );
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(C_PHASEINC_ADDR_WIDTH-1 downto 0);
      data_o : out std_logic_vector(C_PHASEINC_DATA_WIDTH-1 downto 0)
   );
end entity phase_increment_rom;

architecture synthesis of phase_increment_rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 2**C_PHASEINC_ADDR_WIDTH-1) of
                 std_logic_vector(C_PHASEINC_DATA_WIDTH-1 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable ROM_v          : mem_t := (others => (others => '0'));
      variable freq_v         : real;
      variable phaseinc_v     : integer;

      -- There are 64 fractions per semitone, and 12 semitone per octave.
      constant C_FACTOR       : real := 2.0 ** (1.0/768.0);

      -- Frequency in Hz of the A4 tone.
      constant C_FREQ_A4_HZ   : real := 440.0;

      -- Index 0 corresponds to C#, which is 4 semitones above A4, but 5 octaves lower.
      constant C_FREQ_INDEX_0 : real := C_FREQ_A4_HZ * (C_FACTOR**(4.0*64.0)) / 32.0;

      constant C_SCALE        : real := 2.0 ** real(C_PHASE_WIDTH);

   begin
      for i in 0 to 767 loop
         freq_v     := C_FREQ_INDEX_0 * (C_FACTOR ** real(i));
         phaseinc_v := integer(freq_v/real(G_CLOCK_HZ) * C_SCALE);
         ROM_v(i)   := to_stdlogicvector(phaseinc_v, C_PHASEINC_DATA_WIDTH);
      end loop;
      return ROM_v;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end architecture synthesis;

