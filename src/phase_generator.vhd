library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity phase_generator is
   generic (
      G_CLOCK_HZ : integer
   );
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      device_cnt_i : in  integer range 0 to 31;
      devices_i    : in  t_device_vector(0 to 31);
      phases_o     : out t_phase_vector(0 to 31)
   );
end phase_generator;

architecture synthesis of phase_generator is

   signal device_s : t_device;
   signal phases_r : t_phase_vector(0 to 31);

   signal key_code_s        : std_logic_vector(9 downto 0);
   signal phase_increment_s : std_logic_vector(11 downto 0);

begin

   -- Demultiplex input
   device_s <= devices_i(device_cnt_i);


   -----------------------------------
   -- Instantiate Phase Increment ROM
   -----------------------------------

   key_code_s <= "000" & device_s.pg.key_code;

   i_phase_increment_rom : entity work.phase_increment_rom
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i     => clk_i,
         addr_i    => key_code_s,
         rd_data_o => phase_increment_s
      ); -- i_phase_increment_rom


   p_phase : process (clk_i)
   begin
      if rising_edge(clk_i) then

         if rst_i = '1' then
            phases_r <= (others => (others => '0'));
         end if;
      end if;
   end process p_phase;

end architecture synthesis;

