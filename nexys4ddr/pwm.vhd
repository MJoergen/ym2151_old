library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the Pulse Width Modulation module.
-- It takes as input a 12-bit signal representing an unsigned value between
-- 0x0.000 and 0x0.FFF. This value is interpreted as the required width of
-- each pulse.

entity pwm is
   port (
      clk_i : in  std_logic;
      val_i : in  std_logic_vector(11 downto 0);
      pwm_o : out std_logic
   );
end pwm;

architecture synthesis of pwm is

   signal cnt_r : std_logic_vector(11 downto 0) := (others => '0');

begin

   p_cnt : process (clk_i)
      variable cnt_v : std_logic_vector(11 downto 0);
   begin
      if rising_edge(clk_i) then
         cnt_v := cnt_r + 1;

         -- Only count from 0x000 to 0xFFE.
         if and(cnt_v) = '1' then
            cnt_v := (others => '0');
         end if;

         cnt_r <= cnt_v;
      end if;
   end process p_cnt;

   p_pwm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if val_i > cnt_r then
            pwm_o <= '1';
         else
            pwm_o <= '0';
         end if;
      end if;
   end process p_pwm;

end architecture synthesis;

