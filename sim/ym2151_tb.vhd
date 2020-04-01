-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ym2151_tb is
end entity ym2151_tb;

architecture simulation of ym2151_tb is

   constant C_CLOCK_HZ        : integer := 3579545;
   constant C_CLOCK_PERIOD    : time := (10.0**9)/real(C_CLOCK_HZ) * 1.0 ns;

   -- Connected to DUT
   signal clk_s               : std_logic;
   signal rst_s               : std_logic;
   signal cfg_valid_s         : std_logic;
   signal cfg_ready_s         : std_logic;
   signal cfg_addr_s          : std_logic_vector(7 downto 0);
   signal cfg_data_s          : std_logic_vector(7 downto 0);
   signal aud_valid_s         : std_logic;
   signal aud_data_s          : std_logic_vector(11 downto 0);
   signal playing_s           : std_logic;
   signal test_running_s      : std_logic := '1';

   constant C_INPUT_FILENAME  : string := "rom.txt";
   constant C_OUTPUT_FILENAME : string := "music.wav";

begin

   ----------------------------------------------------------------
   -- Generate clock and reset
   ----------------------------------------------------------------

   -- Generate cpu clock
   p_clk : process
   begin
      clk_s <= '1', '0' after C_CLOCK_PERIOD/2;
      wait for C_CLOCK_PERIOD;

      -- Stop clock when test is finished
      if test_running_s = '0' then
         wait;
      end if;
   end process p_clk;

   -- Generate cpu reset
   p_rst : process
   begin
      rst_s <= '1', '0' after 40*C_CLOCK_PERIOD;
      wait;
   end process p_rst;

   p_test_running : process
   begin
      wait until playing_s = '1';
      wait until playing_s = '0';
      test_running_s <= '0';
      wait;
   end process p_test_running;


   ----------------------------------------------------------------
   -- Instantiate controller
   ----------------------------------------------------------------

   i_ctrl : entity work.ctrl
      generic map (
         G_INIT_FILE => C_INPUT_FILENAME
      )
      port map (
         clk_i       => clk_s,
         rst_i       => rst_s,
         playing_o   => playing_s,
         cfg_valid_o => cfg_valid_s,
         cfg_ready_i => cfg_ready_s,
         cfg_addr_o  => cfg_addr_s,
         cfg_data_o  => cfg_data_s
      ); -- i_ctrl


   ----------------------------------------------------------------
   -- Instantiate DUT
   ----------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      generic map (
         G_CLOCK_HZ => C_CLOCK_HZ
      )
      port map (
         clk_i       => clk_s,
         rst_i       => rst_s,
         cfg_valid_i => cfg_valid_s,
         cfg_ready_o => cfg_ready_s,
         cfg_addr_i  => cfg_addr_s,
         cfg_data_i  => cfg_data_s,
         aud_valid_o => aud_valid_s,
         aud_data_o  => aud_data_s
      ); -- i_ym2151
   

   ----------------------------------------------------------------
   -- Copy output from YM2151 to file
   ----------------------------------------------------------------

   i_output2wav : entity work.output2wav
      generic map (
         G_FILE_NAME => C_OUTPUT_FILENAME
      )
      port map (
         clk_i    => clk_s,
         rst_i    => rst_s,
         active_i => test_running_s,
         valid_i  => aud_valid_s,
         data_i   => aud_data_s
      ); -- i_output2wav

end simulation;

