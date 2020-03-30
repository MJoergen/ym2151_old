-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is the top level for the YM2151.
--
-- Devices:
--  0- 7 : Modulator 1
--  8-15 : Modulator 2
-- 16-23 : Carrier 1
-- 24-31 : Carrier 2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity ym2151 is
   generic (
      G_CLOCK_HZ : integer               -- Input clock frequency
   );
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      busy_o    : out std_logic;
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Waveform output
      valid_o   : out std_logic;
      data_o    : out std_logic_vector(C_PWM_WIDTH-1 downto 0)
   );
end entity ym2151;

architecture synthesis of ym2151 is

   -- This record contains temporary values calcuted in the pipeline,
   -- but which do not need to be stored later.
   type temp_t is record
      phase_inc : std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      waveform  : std_logic_vector(17 downto 0);
      rate      : std_logic_vector( 5 downto 0);
      delay     : std_logic_vector(C_DELAY_SIZE-1 downto 0);
      product   : std_logic_vector(C_PWM_WIDTH-1 downto 0);
   end record temp_t;

   -- This record contains the entire information available at every stage
   -- of the pipeline.
   type stage_t is record
      idx     : std_logic_vector(4 downto 0); -- Device index (0-31)
      channel : channel_t;                    -- Configuration
      device  : device_t;                     -- Configuration
      state   : state_t;                      -- State preserved from last iteration.
      temp    : temp_t;                       -- Temporary storage.
   end record stage_t;

   type stages_t is array (0 to 33) of stage_t; -- Stage 32 is the same device as stage 0.
   signal stages : stages_t;

   -- Debug
   constant DEBUG_MODE             : boolean := false;

   attribute mark_debug            : boolean;
   attribute mark_debug of rst_i   : signal is DEBUG_MODE;
   attribute mark_debug of busy_o  : signal is DEBUG_MODE;
   attribute mark_debug of valid_o : signal is DEBUG_MODE;
   attribute mark_debug of data_o  : signal is DEBUG_MODE;

begin

   ----------------------------------------------------
   -- Stage 0 : Read configuration for each device, one at a time.
   ----------------------------------------------------

   i_get_config : entity work.get_config
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         busy_o    => busy_o,
         addr_i    => addr_i,
         wr_en_i   => wr_en_i,
         wr_data_i => wr_data_i,
         idx_o     => stages(0).idx,      -- Device index (0-31)
         channel_o => stages(0).channel,  -- Configuration
         device_o  => stages(0).device    -- Configuration
      ); -- i_get_config

   -- Copy state from previous iteration of this device.
   stages(0).state <= stages(32).state;


   ----------------------------------------------------
   -- Stage 1 : Calculate temp.phase_inc and temp.delay
   ----------------------------------------------------

   i_calc_phase_inc : entity work.calc_phase_inc
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i       => clk_i,
         channel_i   => stages(0).channel,
         device_i    => stages(0).device,
         phase_inc_o => stages(1).temp.phase_inc
      ); -- i_phase_increment

   i_calc_delay : entity work.calc_delay
      generic map (
         G_UPDATE_HZ => G_CLOCK_HZ/32
      )
      port map (
         clk_i     => clk_i,
         channel_i => stages(0).channel,
         device_i  => stages(0).device,
         state_i   => stages(0).state,
         delay_o   => stages(1).temp.delay
      ); -- i_calc_delay

   -- Copy state from previous iteration of this device.
   stages(1).state <= stages(33).state;


   ----------------------------------------------------
   -- Stage 2 : Update state
   ----------------------------------------------------

   i_update_state : entity work.update_state
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         channel_i   => stages(1).channel,
         device_i    => stages(1).device,
         delay_i     => stages(1).temp.delay,
         phase_inc_i => stages(1).temp.phase_inc,
         cur_state_i => stages(1).state,
         new_state_o => stages(2).state
      ); -- i_update_state


   ----------------------------------------------------
   -- Stage 3 : Calculate waveform
   ----------------------------------------------------

   i_calc_waveform : entity work.calc_waveform
      port map (
         clk_i      => clk_i,
         state_i    => stages(2).state,
         waveform_o => stages(3).temp.waveform
      ); -- i_calc_waveform


   ----------------------------------------------------
   -- Stages 4-5 : Calculate product
   ----------------------------------------------------

   i_calc_product : entity work.calc_product
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         state_i    => stages(3).state,
         waveform_i => stages(3).temp.waveform,
         product_o  => stages(5).temp.product
      ); -- i_calc_product
      

   ----------------------------------------------------
   -- Generate pipeline
   ----------------------------------------------------

   gen_device : for i in 1 to 5 generate
      p_device : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).idx     <= stages(i-1).idx;
            stages(i).channel <= stages(i-1).channel;
            stages(i).device  <= stages(i-1).device;
         end if;
      end process p_device;
   end generate gen_device;

   gen_phase_inc : for i in 2 to 5 generate
      p_phase_inc : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).temp.phase_inc <= stages(i-1).temp.phase_inc;
            stages(i).temp.delay     <= stages(i-1).temp.delay;
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

   gen_state2 : for i in 3 to 5 generate
      p_state2 : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i).state <= stages(i-1).state;
         end if;
      end process p_state2;
   end generate gen_state2;

   gen_stages : for i in 6 to 33 generate
      p_stages : process (clk_i)
      begin
         if rising_edge(clk_i) then
            stages(i) <= stages(i-1);
         end if;
      end process p_stages;
   end generate gen_stages;


   ----------------------------------------------------
   -- Generate output
   ----------------------------------------------------

   i_calc_output : entity work.calc_output
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         idx_i     => stages(5).idx,
         product_i => stages(5).temp.product,
         valid_o   => valid_o,
         data_o    => data_o
      ); -- i_calc_output

end architecture synthesis;

