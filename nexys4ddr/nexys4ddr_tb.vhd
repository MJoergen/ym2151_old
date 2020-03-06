library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the top level module of the Nexys4DDR. The ports on this entity are mapped
-- directly to pins on the FPGA.

entity nexys4ddr_tb is
end nexys4ddr_tb;

architecture simulation of nexys4ddr_tb is

   signal sys_clk_s  : std_logic;
   signal sys_rstn_s : std_logic;

   signal aud_pwm_s  : std_logic;
   signal aud_sd_s   : std_logic;

begin

   -----------------------------
   -- Generate clock and reset
   -----------------------------

   -- Generate clock @ 100 MHz
   p_sys_clk : process
   begin
      sys_clk_s <= '1', '0' after 5 ns;
      wait for 10 ns;
   end process p_sys_clk;

   -- Generate reset
   p_sys_rstn : process
   begin
      sys_rstn_s <= '0', '1' after 5000 ns;
      wait;
   end process p_sys_rstn;


   ----------------------------------------------------------------
   -- Instantiate Nexys 4 DDR
   ----------------------------------------------------------------

   i_nexys4ddr : entity work.nexys4ddr
      generic map (
         G_INIT_FILE => "ctrl.txt"
      )
      port map (
         sys_clk_i  => sys_clk_s,
         sys_rstn_i => sys_rstn_s,
         aud_pwm_o  => aud_pwm_s,
         aud_sd_o   => aud_sd_s
      ); -- i_nexys4ddr

end architecture simulation;

