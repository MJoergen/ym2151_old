library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

package ym2151_package is

   constant C_PDM_WIDTH           : integer := 12;
   constant C_SINE_DATA_WIDTH     : integer := C_PDM_WIDTH;
   constant C_SINE_ADDR_WIDTH     : integer := C_PDM_WIDTH+1;
   constant C_PHASEINC_ADDR_WIDTH : integer := 10;
   constant C_PHASEINC_DATA_WIDTH : integer := C_SINE_ADDR_WIDTH+3;
   constant C_PHASE_WIDTH         : integer := C_SINE_ADDR_WIDTH + 10;

   type t_phase_generator is record
      key_code           : std_logic_vector(6 downto 0);
   end record t_phase_generator;

   type t_envelope_generator is record
      total_level        : std_logic_vector(6 downto 0);
      attack_rate        : std_logic_vector(4 downto 0);
      first_decay_rate   : std_logic_vector(4 downto 0);
      first_decay_level  : std_logic_vector(3 downto 0);
      second_decay_rate  : std_logic_vector(3 downto 0);
      release_rate       : std_logic_vector(3 downto 0);
      key_onoff          : std_logic;
   end record t_envelope_generator;

   type t_device is record
      pg : t_phase_generator;
      eg : t_envelope_generator;
   end record t_device;
   constant C_DEVICE_DEFAULT : t_device := 
            (pg => (key_code           => (others => '0')),
             eg => (total_level        => (others => '0'),
                    attack_rate        => (others => '0'),
                    first_decay_rate   => (others => '0'),
                    first_decay_level  => (others => '0'),
                    second_decay_rate  => (others => '0'),
                    release_rate       => (others => '0'),
                    key_onoff          => '0'));
   type t_device_vector is array (natural range<>) of t_device;

   subtype t_envelope is std_logic_vector(9 downto 0);
   type t_envelope_vector is array (natural range<>) of t_envelope;

   subtype t_phase is std_logic_vector(19 downto 0);
   type t_phase_vector is array (natural range<>) of t_phase;

end package ym2151_package;

