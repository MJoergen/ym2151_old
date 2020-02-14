-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains a number of global constants

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

package ym2151_package is

   type STATE_ADSR_t is (ATTACK_ST, DECAY_ST, SUSTAIN_ST, RELEASE_ST);

   -- This constant controls the attenuation of each step.  This value is used
   -- by the envelope generator.
   -- A value of 6 corresponds to 0.06839 dB (voltage) per step, i.e.
   -- -10*log10(1-2^(-6)).
   constant C_SHIFT_AMOUNT        : integer := 6;

   -- Number of update cycles between updating the envelope.
   constant C_DELAY_SIZE          : integer := 22;

   -- This constant is determined by the switching rate of the PDM signal (100 MHz)
   -- and the cutoff frequency of the low-pass filter on the board (15 kHz).
   -- The ratio between the two is 6666, and we therefore go for 12 bits (i.e. 4096).
   constant C_PDM_WIDTH           : integer := 12;

   -- The dimensions of the Sine ROM are determined by the output resolution.
   constant C_SINE_DATA_WIDTH     : integer := C_PDM_WIDTH;
   constant C_SINE_ADDR_WIDTH     : integer := C_PDM_WIDTH+1;

   -- This constant is determined by the desired granularity of the key
   -- (64*12 fractions within an octave)
   constant C_PHASEINC_ADDR_WIDTH : integer := 10;

   -- This constant is determined by the ratio of the update frequency (8.33/32 MHz)
   -- and the minimum frequency generated (C#0 at 17.3 Hz). This ratio
   -- is approx 15 thousand, i.e. 14 bits. Furthermore, each of the 768 fractions
   -- should have a distinct phase increment.
   constant C_PHASE_WIDTH         : integer := 14 + C_PHASEINC_ADDR_WIDTH;

   -- This constant is determined by the maximum phase increment in the ROM,
   -- which is 17.3*2/8.3E6*2^29 = 2230.
   constant C_PHASEINC_DATA_WIDTH : integer := 12; 

   type channel_t is record
      key_code     : std_logic_vector(6 downto 0);
      key_fraction : std_logic_vector(5 downto 0);
   end record channel_t;
   type channel_vector_t is array (natural range<>) of channel_t;

   -- Configuraion of each device
   type device_t is record
      total_level  : std_logic_vector(6 downto 0);
      key_scaling  : std_logic_vector(1 downto 0);
      attack_rate  : std_logic_vector(4 downto 0);
      decay_rate   : std_logic_vector(4 downto 0);
      decay_level  : std_logic_vector(3 downto 0);
      sustain_rate : std_logic_vector(4 downto 0);
      release_rate : std_logic_vector(3 downto 0);
      key_onoff    : std_logic;
   end record device_t;
   type device_vector_t is array (natural range<>) of device_t;

   type state_t is record
      phase_cur : std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      env_cur   : std_logic_vector(17 downto 0);
      env_state : STATE_ADSR_t;
      env_cnt   : std_logic_vector(C_DELAY_SIZE-1 downto 0);
   end record state_t;

end package ym2151_package;

