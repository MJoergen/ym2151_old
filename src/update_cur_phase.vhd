-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity update_cur_phase is
   port (
      clk_i       : in  std_logic;
      rst_i       : in  std_logic;
      cur_phase_i : in  std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      phase_inc_i : in  std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      cur_phase_o : out std_logic_vector(C_PHASE_WIDTH-1 downto 0)
   );
end entity update_cur_phase;

architecture synthesis of update_cur_phase is

begin

   p_cur_phase : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cur_phase_o <= cur_phase_i + phase_inc_i;

         if rst_i = '1' then
            cur_phase_o <= (others => '0');
         end if;
      end if;
   end process p_cur_phase;

end architecture synthesis;

