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
      device_cnt : std_logic_vector(4 downto 0);
      key_code   : std_logic_vector(6 downto 0);
      decay_rate : std_logic_vector(4 downto 0);
      key_onoff  : std_logic;

      -- Valid in stage 1 and later
      phase_inc  : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

      -- Updated in stage 2.
      cur_phase  : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

      -- Valid in stage 3 and later
      waveform   : std_logic_vector(17 downto 0);

      -- Valid in stage 4 and later
      rate       : std_logic_vector( 5 downto 0); -- One of 64 values

      -- Valid in stage 5 and later
      delay      : std_logic_vector(C_DECAY_SIZE-1 downto 0);

      -- Updated in stage 6.
      state      : STATE_ADSR_t;
      cnt        : std_logic_vector(C_DECAY_SIZE-1 downto 0);
      envelope   : std_logic_vector(17 downto 0);

      -- Valid in stage 7 and later
      product    : std_logic_vector(35 downto 0);
   end record stage_t;
   
   constant C_STAGE_DEFAULT : stage_t := (
      device_cnt => (others => '0'),
      key_code   => (others => '0'),
      decay_rate => (others => '0'),
      key_onoff  => '0',
      --
      phase_inc  => (others => '0'),
      --
      cur_phase  => (others => '0'),
      --
      waveform   => (others => '0'),
      --
      rate       => (others => '0'),
      --
      delay      => (others => '0'),
      --
      state      => RELEASE_ST,
      cnt        => (others => '0'),
      envelope   => (others => '0'),
      --
      product    => (others => '0')
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

   stages(0).device_cnt <= device_cnt_r;
   stages(0).key_code   <= devices_s(to_integer(device_cnt_r)).pg.key_code;
   stages(0).decay_rate <= devices_s(to_integer(device_cnt_r)).eg.first_decay_rate;
   stages(0).key_onoff  <= devices_s(to_integer(device_cnt_r)).eg.key_onoff;

   -- Copy values from previous iteration of this device.
   stages(0).cur_phase  <= stages(32).cur_phase;
   stages(0).state      <= stages(32).state;
   stages(0).cnt        <= stages(32).cnt;
   stages(0).envelope   <= stages(32).envelope;


   ----------------------------------------------------
   -- Stage 1 : Phase Increment (frequency) lookup
   ----------------------------------------------------

   i_ym2151_phase_increment : entity work.ym2151_phase_increment
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i          => clk_i,
         key_code_i     => stages(0).key_code,
         key_fraction_i => (others => '0'),     -- TBD
         phase_inc_o    => stages(1).phase_inc
      ); -- i_phase_increment

   p_stage1 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(1).device_cnt <= stages(0).device_cnt;
         stages(1).key_code   <= stages(0).key_code;
         stages(1).decay_rate <= stages(0).decay_rate;
         stages(1).key_onoff  <= stages(0).key_onoff;
         stages(1).cur_phase  <= stages(0).cur_phase;
         stages(1).state      <= stages(0).state;
         stages(1).cnt        <= stages(0).cnt;
         stages(1).envelope   <= stages(0).envelope;
      end if;
   end process p_stage1;


   ----------------------------------------------------
   -- Stage 2 : Update cur_phase
   ----------------------------------------------------

   p_stage2 : process (clk_i)
   begin
      if rising_edge(clk_i) then

         stages(2).device_cnt <= stages(1).device_cnt;
         stages(2).key_code   <= stages(1).key_code;
         stages(2).decay_rate <= stages(1).decay_rate;
         stages(2).key_onoff  <= stages(1).key_onoff;
         stages(2).phase_inc  <= stages(1).phase_inc;
         stages(2).state      <= stages(1).state;
         stages(2).cnt        <= stages(1).cnt;
         stages(2).envelope   <= stages(1).envelope;

         stages(2).cur_phase  <= stages(1).cur_phase + stages(1).phase_inc;

         if rst_i = '1' then
            stages(2).cur_phase <= (others => '0');
         end if;
      end if;
   end process p_stage2;


   ----------------------------------------------------
   -- Stage 3 : Calculate sine of phase
   ----------------------------------------------------

   i_ym2151_sine_rom : entity work.ym2151_sine_rom
      port map (
         clk_i      => clk_i,
         phase_i    => stages(2).cur_phase,
         waveform_o => stages(3).waveform
      ); -- i_ym2151_sine_rom

   p_stage3 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(3).device_cnt <= stages(2).device_cnt;
         stages(3).key_code   <= stages(2).key_code;
         stages(3).decay_rate <= stages(2).decay_rate;
         stages(3).key_onoff  <= stages(2).key_onoff;
         stages(3).phase_inc  <= stages(2).phase_inc;
         stages(3).cur_phase  <= stages(2).cur_phase;
         stages(3).state      <= stages(2).state;
         stages(3).cnt        <= stages(2).cnt;
         stages(3).envelope   <= stages(2).envelope;
      end if;
   end process p_stage3;


   ----------------------------------------------------
   -- Stage 4 : Calculate rate constant.
   -- TBD: Add support for key scaling.
   ----------------------------------------------------

   p_stage4 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(4).device_cnt <= stages(3).device_cnt;
         stages(4).key_code   <= stages(3).key_code;
         stages(4).decay_rate <= stages(3).decay_rate;
         stages(4).key_onoff  <= stages(3).key_onoff;
         stages(4).phase_inc  <= stages(3).phase_inc;
         stages(4).cur_phase  <= stages(3).cur_phase;
         stages(4).waveform   <= stages(3).waveform;
         stages(4).rate       <= (stages(3).decay_rate & "0") + ("0000" & stages(3).key_code(6 downto 5));
         stages(4).state      <= stages(3).state;
         stages(4).cnt        <= stages(3).cnt;
         stages(4).envelope   <= stages(3).envelope;
      end if;
   end process p_stage4;


   ----------------------------------------------------
   -- Stage 5 : Calculate time between each decay.
   ----------------------------------------------------

   i_ym2151_decay : entity work.ym2151_decay
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         rate_i  => stages(4).rate,
         delay_o => stages(4).delay
      ); -- i_ym2151_decay

   p_stage5 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(5).device_cnt <= stages(4).device_cnt;
         stages(5).key_code   <= stages(4).key_code;
         stages(5).decay_rate <= stages(4).decay_rate;
         stages(5).key_onoff  <= stages(4).key_onoff;
         stages(5).phase_inc  <= stages(4).phase_inc;
         stages(5).cur_phase  <= stages(4).cur_phase;
         stages(5).waveform   <= stages(4).waveform;
         stages(5).rate       <= stages(4).rate;
         stages(5).delay      <= stages(4).delay;
         stages(5).state      <= stages(4).state;
         stages(5).cnt        <= stages(4).cnt;
         stages(5).envelope   <= stages(4).envelope;
      end if;
   end process p_stage5;


   ----------------------------------------------------
   -- Stage 6 : Update ADSR envelope
   ----------------------------------------------------

   i_ym2151_envelope_generator : entity work.ym2151_envelope_generator
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
      ); -- i_ym2151_envelope_generator

   p_stage6 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(6).device_cnt <= stages(5).device_cnt;
         stages(6).key_code   <= stages(5).key_code;
         stages(6).decay_rate <= stages(5).decay_rate;
         stages(6).key_onoff  <= stages(5).key_onoff;
         stages(6).phase_inc  <= stages(5).phase_inc;
         stages(6).cur_phase  <= stages(5).cur_phase;
         stages(6).waveform   <= stages(5).waveform;
         stages(6).rate       <= stages(5).rate;
         stages(6).delay      <= stages(5).delay;
      end if;
   end process p_stage6;


   --------------------------
   -- Stage 7 : Instantiate multiplier
   --------------------------

   i_mult : mult_macro
      generic map (
         DEVICE  => "7SERIES",
         LATENCY => 1,
         WIDTH_A => 18,
         WIDTH_B => 18
      )
      port map (
         CLK => clk_i,
         RST => rst_i,
         CE  => '1',
         A   => stages(6).envelope,
         B   => stages(6).waveform,
         P   => stages(7).product
      ); -- i_mult
      
   p_stage7 : process (clk_i)
   begin
      if rising_edge(clk_i) then
         stages(7).device_cnt <= stages(6).device_cnt;
         stages(7).key_code   <= stages(6).key_code;
         stages(7).decay_rate <= stages(6).decay_rate;
         stages(7).key_onoff  <= stages(6).key_onoff;
         stages(7).phase_inc  <= stages(6).phase_inc;
         stages(7).cur_phase  <= stages(6).cur_phase;
         stages(7).waveform   <= stages(6).waveform;
         stages(7).rate       <= stages(6).rate;
         stages(7).delay      <= stages(6).delay;
         stages(7).state      <= stages(6).state;
         stages(7).cnt        <= stages(6).cnt;
         stages(7).envelope   <= stages(6).envelope;
      end if;
   end process p_stage7;

   gen_stages : for i in 8 to 32 generate
      p_stages : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i) <= stages(i-1);
         end if;
      end process p_stages;
   end generate gen_stages;


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

