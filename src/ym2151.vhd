-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;

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

   signal devices_s    : t_device_vector(0 to 31);

   signal device_cnt_r : std_logic_vector(4 downto 0) := (others => '0');

   constant C_NEGATIVE_ONE : std_logic_vector(C_PDM_WIDTH-1 downto 0) :=
      (C_PDM_WIDTH-1 => '1', others => '0');

   type stage_t is record
      -- Valid in stage 0 and later
      device_cnt   : std_logic_vector(4 downto 0);
      key_code     : std_logic_vector(6 downto 0);
      key_fraction : std_logic_vector(5 downto 0);
      total_level  : std_logic_vector(6 downto 0);
      key_scaling  : std_logic_vector(1 downto 0);
      attack_rate  : std_logic_vector(4 downto 0);
      decay_rate   : std_logic_vector(4 downto 0);
      decay_level  : std_logic_vector(3 downto 0);
      sustain_rate : std_logic_vector(4 downto 0);
      release_rate : std_logic_vector(3 downto 0);
      key_onoff    : std_logic;

      -- Valid in stage 1 and later
      phase_inc    : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

      -- Updated in stage 2.
      cur_phase    : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

      -- Valid in stage 3 and later
      waveform     : std_logic_vector(17 downto 0);

      -- Valid in stage 4 and later
      rate         : std_logic_vector( 5 downto 0); -- One of 64 values

      -- Valid in stage 5 and later
      delay        : std_logic_vector(C_DECAY_SIZE-1 downto 0);

      -- Updated in stage 6.
      state        : STATE_ADSR_t;
      cnt          : std_logic_vector(C_DECAY_SIZE-1 downto 0);
      envelope     : std_logic_vector(17 downto 0);

      -- Valid in stage 7 and later
      product      : std_logic_vector(35 downto 0);
   end record stage_t;
   
   constant C_STAGE_DEFAULT : stage_t := (
      device_cnt   => (others => '0'),
      key_code     => (others => '0'),
      key_fraction => (others => '0'),
      total_level  => (others => '0'),
      key_scaling  => (others => '0'),
      attack_rate  => (others => '0'),
      decay_rate   => (others => '0'),
      decay_level  => (others => '0'),
      sustain_rate => (others => '0'),
      release_rate => (others => '0'),
      key_onoff    => '0',
      --
      phase_inc    => (others => '0'),
      --
      cur_phase    => (others => '0'),
      --
      waveform     => (others => '0'),
      --
      rate         => (others => '0'),
      --
      delay        => (others => '0'),
      --
      state        => RELEASE_ST,
      cnt          => (others => '0'),
      envelope     => (others => '0'),
      --
      product      => (others => '0')
   );

   type stages_t is array (0 to 32) of stage_t; -- Stage 32 is the same device as stage 0.
   signal stages : stages_t := (others => C_STAGE_DEFAULT);

begin

   ----------------------------------------------------
   -- Instantiate CPU configuration interface
   ----------------------------------------------------

   i_ym2151_config : entity work.ym2151_config
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         addr_i    => addr_i,
         wr_en_i   => wr_en_i,
         wr_data_i => wr_data_i,
         devices_o => devices_s
      ); -- i_config


   ----------------------------------------------------
   -- Loop through each of the 32 devices
   ----------------------------------------------------

   p_device_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         device_cnt_r <= device_cnt_r + 1;
      end if;
   end process p_device_cnt;


   ----------------------------------------------------
   -- Prepare stage 0 of pipeline
   ----------------------------------------------------

   stages(0).device_cnt   <= device_cnt_r;
   stages(0).key_code     <= devices_s(to_integer(device_cnt_r)).pg.key_code;
   stages(0).key_fraction <= devices_s(to_integer(device_cnt_r)).pg.key_fraction;
   stages(0).total_level  <= devices_s(to_integer(device_cnt_r)).eg.total_level;
   stages(0).key_scaling  <= devices_s(to_integer(device_cnt_r)).eg.key_scaling;
   stages(0).attack_rate  <= devices_s(to_integer(device_cnt_r)).eg.attack_rate;
   stages(0).decay_rate   <= devices_s(to_integer(device_cnt_r)).eg.decay_rate;
   stages(0).decay_level  <= devices_s(to_integer(device_cnt_r)).eg.decay_level;
   stages(0).sustain_rate <= devices_s(to_integer(device_cnt_r)).eg.sustain_rate;
   stages(0).release_rate <= devices_s(to_integer(device_cnt_r)).eg.release_rate;
   stages(0).key_onoff    <= devices_s(to_integer(device_cnt_r)).eg.key_onoff;

   -- Copy state from previous iteration of this device.
   stages(0).cur_phase  <= stages(32).cur_phase;
   stages(0).state      <= stages(32).state;
   stages(0).cnt        <= stages(32).cnt;
   stages(0).envelope   <= stages(32).envelope;


   ----------------------------------------------------
   -- Stage 1 : Calculate phase_inc
   ----------------------------------------------------

   i_calc_phase_inc : entity work.calc_phase_inc
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i          => clk_i,
         key_code_i     => stages(0).key_code,
         key_fraction_i => stages(0).key_fraction,
         phase_inc_o    => stages(1).phase_inc
      ); -- i_phase_increment


   ----------------------------------------------------
   -- Stage 2 : Update cur_phase
   ----------------------------------------------------

   i_calc_cur_phase : entity work.calc_cur_phase
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         cur_phase_i => stages(1).cur_phase,
         phase_inc_i => stages(1).phase_inc,
         cur_phase_o => stages(2).cur_phase
      ); -- i_calc_cur_phase


   ----------------------------------------------------
   -- Stage 3 : Calculate waveform
   ----------------------------------------------------

   i_calc_waveform : entity work.calc_waveform
      port map (
         clk_i      => clk_i,
         phase_i    => stages(2).cur_phase,
         waveform_o => stages(3).waveform
      ); -- i_ym2151_sine_rom


   ----------------------------------------------------
   -- Stage 4 : Calculate delay
   ----------------------------------------------------

   i_calc_delay : entity work.calc_delay
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i          => clk_i,
         state_i        => stages(3).state,
         key_code_i     => stages(3).key_code,
         key_scaling_i  => stages(3).key_scaling,
         attack_rate_i  => stages(3).attack_rate,
         decay_rate_i   => stages(3).decay_rate,
         sustain_rate_i => stages(3).sustain_rate,
         release_rate_i => stages(3).release_rate,
         delay_o        => stages(4).delay
      ); -- i_calc_delay


   ----------------------------------------------------
   -- Stage 6 : Update ADSR envelope
   ----------------------------------------------------

   i_calc_envelope : entity work.calc_envelope
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         state_i     => stages(5).state,
         cnt_i       => stages(5).cnt,
         envelope_i  => stages(5).envelope,
         key_onoff_i => stages(5).key_onoff,
         delay_i     => stages(5).delay,
         state_o     => stages(6).state,
         cnt_o       => stages(6).cnt,
         envelope_o  => stages(6).envelope
      ); -- i_calc_envelope


   ----------------------------------------------------
   -- Stage 7 : Calculate product
   ----------------------------------------------------

   i_calc_product : entity work.calc_product
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         envelope_i => stages(6).envelope,
         waveform_i => stages(6).waveform,
         product_o  => stages(7).product
      ); -- i_calc_product
      

   --------------------------
   -- Generate pipeline
   --------------------------

   gen_1 : for i in 1 to 7 generate
      p_1 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).device_cnt   <= stages(i-1).device_cnt;
            stages(i).key_code     <= stages(i-1).key_code;
            stages(i).key_fraction <= stages(i-1).key_fraction;
            stages(i).total_level  <= stages(i-1).total_level;
            stages(i).key_scaling  <= stages(i-1).key_scaling;
            stages(i).attack_rate  <= stages(i-1).attack_rate;
            stages(i).decay_rate   <= stages(i-1).decay_rate;
            stages(i).decay_level  <= stages(i-1).decay_level;
            stages(i).sustain_rate <= stages(i-1).sustain_rate;
            stages(i).release_rate <= stages(i-1).release_rate;
            stages(i).key_onoff    <= stages(i-1).key_onoff;
         end if;
      end process p_1;
   end generate gen_1;

   gen_1_2 : for i in 1 to 1 generate
      p_1_2 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).cur_phase    <= stages(i-1).cur_phase;
         end if;
      end process p_1_2;
   end generate gen_1_2;

   gen_1_6 : for i in 1 to 5 generate
      p_1_6 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).state        <= stages(i-1).state;
            stages(i).cnt          <= stages(i-1).cnt;
            stages(i).envelope     <= stages(i-1).envelope;
         end if;
      end process p_1_6;
   end generate gen_1_6;

   gen_2 : for i in 2 to 7 generate
      p_2 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).phase_inc    <= stages(i-1).phase_inc;
         end if;
      end process p_2;
   end generate gen_2;

   gen_3 : for i in 3 to 7 generate
      p_3 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).cur_phase    <= stages(i-1).cur_phase;
         end if;
      end process p_3;
   end generate gen_3;

   gen_4 : for i in 4 to 7 generate
      p_4 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).waveform     <= stages(i-1).waveform;
         end if;
      end process p_4;
   end generate gen_4;

   gen_5 : for i in 5 to 7 generate
      p_5 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).delay        <= stages(i-1).delay;
         end if;
      end process p_5;
   end generate gen_5;

   gen_7 : for i in 7 to 7 generate
      p_7 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).state        <= stages(i-1).state;
            stages(i).cnt          <= stages(i-1).cnt;
            stages(i).envelope     <= stages(i-1).envelope;
         end if;
      end process p_7;
   end generate gen_7;

   gen_8 : for i in 8 to 32 generate
      p_8 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i)              <= stages(i-1);
         end if;
      end process p_8;
   end generate gen_8;


   -- The output from the multiplier is a signed 36-bit integer.
   assert (or(stages(7).product(35 downto 17+C_PDM_WIDTH)) = '0') or
          (and(stages(7).product(35 downto 17+C_PDM_WIDTH)) = '1') or
          rst_i /= '0';

   p_store_device0 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if stages(7).device_cnt = 0 then
            val_o <= stages(7).product(17+C_PDM_WIDTH-1 downto 17) xor C_NEGATIVE_ONE;
         end if;
      end if;
   end process p_store_device0;

end architecture synthesis;

