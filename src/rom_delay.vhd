-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module calculates the decay rate from the rate constant.
-- It returns the number of clock cycles between each decay.  The decay is
-- implemented by a shift-and-subtract, where the shift is controlled by the
-- constant C_SHIFT_AMOUNT.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

-- The table below is taken from the documentation for the YM2151.
-- |   rate   | rate (ms/96dB) | delay
-- | -------- | -------------- | -----
-- |    63    |         6.73   | 79
-- |    62    |         6.73   | 79
-- |    61    |         6.73   | 79
-- |    60    |         6.73   | 79
-- |    59    |         7.49   | 94
-- |    56    |        13.45   |
-- |    52    |        26.91   |
-- |     8    |     55104.85   |
-- |     4    |    110209.71   | 1301087
-- |     3    |  infinity      | 2097151 (means infinity)
-- |     0    |  infinity      | 2097151 (means infinity)

entity rom_delay is
   generic (
      G_UPDATE_HZ : integer             -- Update frequency
   );
   port (
      clk_i   : in  std_logic;
      rate_i  : in  std_logic_vector( 5 downto 0); -- One of 64 values
      delay_o : out std_logic_vector(C_DECAY_SIZE-1 downto 0)  -- Number of clock cycles between each decay
   );
end entity rom_delay;

architecture synthesis of rom_delay is

   type mem_t is array (0 to 3) of std_logic_vector(C_DECAY_SIZE-1 downto 0);

   -- Calculate the decay constants at compile time.
   constant C_DECAY_TIME_4  : real := 110209.71/96.0;                            -- milliseconds per dB.
   constant C_DECAY_TIME_0  : real := 2.0*C_DECAY_TIME_4;                        -- milliseconds per dB.
   constant C_FACTOR        : real := 1.0-0.5**real(C_SHIFT_AMOUNT);
   constant C_ATTENUNATION  : real := log(C_FACTOR)/log(0.5) * 3.0;              -- Attenuation (dB) per iteration.
   constant C_CYCLES_MS     : real := real(G_UPDATE_HZ)/1000.0;                   -- Update cycles per millisecond.
   constant C_DELAY_VALUE_0 : real := C_DECAY_TIME_0*C_ATTENUNATION*C_CYCLES_MS;
   constant C_TWO_ROOT_025  : real := 2.0**0.25;

   constant C_RATES : mem_t := (to_stdlogicvector(integer(C_DELAY_VALUE_0),                       C_DECAY_SIZE),
                                to_stdlogicvector(integer(C_DELAY_VALUE_0/C_TWO_ROOT_025),        C_DECAY_SIZE),
                                to_stdlogicvector(integer(C_DELAY_VALUE_0/(C_TWO_ROOT_025**2.0)), C_DECAY_SIZE),
                                to_stdlogicvector(integer(C_DELAY_VALUE_0/(C_TWO_ROOT_025**3.0)), C_DECAY_SIZE));

   signal rate_s  : std_logic_vector(C_DECAY_SIZE-1 downto 0);
   signal shift_s : std_logic_vector(3 downto 0);

begin

   rate_s  <= C_RATES(to_integer(rate_i(1 downto 0)));
   shift_s <= rate_i(5 downto 2);

   process (clk_i)
   begin
      if rising_edge(clk_i) then
         delay_o <= (others => '0');
         delay_o(C_DECAY_SIZE-1 - to_integer(shift_s) downto 0) <= rate_s(C_DECAY_SIZE-1 downto to_integer(shift_s));
         if shift_s = 0 then
            delay_o <= (others => '1');
         end if;
      end if;
   end process;

end architecture synthesis;

