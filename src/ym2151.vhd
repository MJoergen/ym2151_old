-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity ym2151 is
   generic (
      G_CLOCK_HZ : integer := 8333333    -- Input clock frequency
   );
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Waveform output
      val_o     : out std_logic_vector(C_PDM_WIDTH-1 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   constant C_NEGATIVE_ONE : std_logic_vector(C_PDM_WIDTH-1 downto 0) :=
      (C_PDM_WIDTH-1 => '1', others => '0');


   type stage_t is record
      config         : config_t;
      temp           : temp_t;
      state_phase    : std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      state_envelope : state_envelope_t;
   end record stage_t;
   
   constant C_STAGE_DEFAULT : stage_t := (
      config          => C_CONFIG_DEFAULT,
      temp            => C_TEMP_DEFAULT,
      state_phase     => (others => '0'),
      state_envelope  => C_STATE_ENVELOPE_DEFAULT
   ); -- C_STAGE_DEFAULT


   type stages_t is array (0 to 32) of stage_t; -- Stage 32 is the same device as stage 0.
   signal stages : stages_t := (others => C_STAGE_DEFAULT);

begin

   ----------------------------------------------------
   -- Stage 0 : Read configuration for each device, one at a time.
   ----------------------------------------------------

   i_get_config : entity work.get_config
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         addr_i    => addr_i,
         wr_en_i   => wr_en_i,
         wr_data_i => wr_data_i,
         config_o  => stages(0).config
      ); -- i_get_config


   ----------------------------------------------------
   -- Copy state from previous iteration of this device.
   ----------------------------------------------------

   stages(0).state_phase    <= stages(32).state_phase;
   stages(0).state_envelope <= stages(32).state_envelope;


   ----------------------------------------------------
   -- Stage 1 : Calculate phase_inc
   ----------------------------------------------------

   i_calc_phase_inc : entity work.calc_phase_inc
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i          => clk_i,
         key_code_i     => stages(0).config.key_code,
         key_fraction_i => stages(0).config.key_fraction,
         phase_inc_o    => stages(1).temp.phase_inc
      ); -- i_phase_increment


   ----------------------------------------------------
   -- Stage 1 : Calculate delay
   ----------------------------------------------------

   i_calc_delay : entity work.calc_delay
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i          => clk_i,
         state_i        => stages(0).state_envelope.state,
         key_code_i     => stages(0).config.key_code,
         key_scaling_i  => stages(0).config.key_scaling,
         attack_rate_i  => stages(0).config.attack_rate,
         decay_rate_i   => stages(0).config.decay_rate,
         sustain_rate_i => stages(0).config.sustain_rate,
         release_rate_i => stages(0).config.release_rate,
         delay_o        => stages(1).temp.delay
      ); -- i_calc_delay


   ----------------------------------------------------
   -- Stage 2 : Update cur_phase
   ----------------------------------------------------

   i_update_cur_phase : entity work.update_cur_phase
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         phase_inc_i => stages(1).temp.phase_inc,
         cur_phase_i => stages(1).state_phase,
         cur_phase_o => stages(2).state_phase
      ); -- i_update_cur_phase


   ----------------------------------------------------
   -- Stage 2 : Update envelope
   ----------------------------------------------------

   i_update_envelope : entity work.update_envelope
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         key_onoff_i => stages(1).config.key_onoff,
         delay_i     => stages(1).temp.delay,
         state_i     => stages(1).state_envelope.state,
         cnt_i       => stages(1).state_envelope.cnt,
         envelope_i  => stages(1).state_envelope.envelope,
         state_o     => stages(2).state_envelope.state,
         cnt_o       => stages(2).state_envelope.cnt,
         envelope_o  => stages(2).state_envelope.envelope
      ); -- i_update_envelope


   ----------------------------------------------------
   -- Stage 3 : Calculate waveform
   ----------------------------------------------------

   i_calc_waveform : entity work.calc_waveform
      port map (
         clk_i      => clk_i,
         phase_i    => stages(2).state_phase,
         waveform_o => stages(3).temp.waveform
      ); -- i_ym2151_sine_rom


   ----------------------------------------------------
   -- Stage 4-5 : Calculate product
   ----------------------------------------------------

   i_calc_product : entity work.calc_product
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         envelope_i => stages(3).state_envelope.envelope,
         waveform_i => stages(3).temp.waveform,
         product_o  => stages(5).temp.product
      ); -- i_calc_product
      

   --------------------------
   -- Generate pipeline
   --------------------------

   gen_config : for i in 1 to 5 generate
      p_config : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).config <= stages(i-1).config;
         end if;
      end process p_config;
   end generate gen_config;

   gen_phase_inc : for i in 2 to 5 generate
      p_phase_inc : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).temp.phase_inc <= stages(i-1).temp.phase_inc;
         end if;
      end process p_phase_inc;
   end generate gen_phase_inc;

   gen_waveform : for i in 4 to 5 generate
      p_waveform : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).temp.waveform <= stages(i-1).temp.waveform;
         end if;
      end process p_waveform;
   end generate gen_waveform;

   gen_delay : for i in 2 to 5 generate
      p_delay : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).temp.delay <= stages(i-1).temp.delay;
         end if;
      end process p_delay;
   end generate gen_delay;

   gen_state1 : for i in 1 to 1 generate
      p_state1 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).state_phase    <= stages(i-1).state_phase;
            stages(i).state_envelope <= stages(i-1).state_envelope;
         end if;
      end process p_state1;
   end generate gen_state1;

   gen_state2 : for i in 3 to 5 generate
      p_state2 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).state_phase    <= stages(i-1).state_phase;
            stages(i).state_envelope <= stages(i-1).state_envelope;
         end if;
      end process p_state2;
   end generate gen_state2;

   gen_stages : for i in 6 to 32 generate
      p_stages : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i) <= stages(i-1);
         end if;
      end process p_stages;
   end generate gen_stages;


   p_store_device0 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if stages(5).config.device_cnt = 0 then
            val_o <= stages(5).temp.product xor C_NEGATIVE_ONE;
         end if;
      end if;
   end process p_store_device0;

end architecture synthesis;

