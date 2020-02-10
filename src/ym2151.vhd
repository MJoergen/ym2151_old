library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;


-- This is the main YM2151 module
-- The single clock is the CPU clock.

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
end ym2151;

architecture synthesis of ym2151 is

   signal devices_s    : t_device_vector(0 to 31);

   signal device_cnt_r : integer range 0 to 31;
   signal envelopes_s  : t_envelope_vector(0 to 31);
   signal phases_s     : t_phase_vector(0 to 31);

   signal key_code_s   : std_logic_vector(6 downto 0);
   signal decay_rate_s : std_logic_vector( 4 downto 0);
   signal key_onoff_s  : std_logic;

   signal phase_inc_s  : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Current waveform value
   signal phase_r      : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Current waveform value
   signal sine_s       : std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);

   constant C_NEGATIVE_ONE : std_logic_vector(C_PDM_WIDTH-1 downto 0) :=
      (C_PDM_WIDTH-1 => '1', others => '0');

   -- Current waveform value
   signal val_s        : std_logic_vector(C_PDM_WIDTH-1 downto 0);

   signal input_a_s    : std_logic_vector(17 downto 0);
   signal input_b_s    : std_logic_vector(17 downto 0);
   signal product_s    : std_logic_vector(35 downto 0);

   signal envelope_s   : std_logic_vector(17 downto 0);
   
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
   -- Get configuration
   ----------------------------------------------------

   key_code_s   <= devices_s(0).pg.key_code;
   decay_rate_s <= devices_s(0).eg.first_decay_rate;
   key_onoff_s  <= devices_s(0).eg.key_onoff;



   ----------------------------------------------------
   -- Phase Increment (frequency) lookup
   ----------------------------------------------------

   i_phase_increment : entity work.phase_increment
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i          => clk_i,
         key_code_i     => key_code_s,
         key_fraction_i => (others => '0'),
         phase_inc_o    => phase_inc_s
      ); -- i_phase_increment


   ----------------------------------------------------
   -- Phase
   ----------------------------------------------------

   p_phase : process (clk_i)
   begin
      if rising_edge(clk_i) then
         phase_r <= phase_r + phase_inc_s;
         if rst_i = '1' then
            phase_r <= (others => '0');
         end if;
      end if;
   end process p_phase;


   ----------------------------------------------------
   -- Instantiate sine table
   ----------------------------------------------------

   i_ym2151_sine_rom : entity work.ym2151_sine_rom
      port map (
         clk_i  => clk_i,
         addr_i => phase_r(phase_r'left downto phase_r'left - (C_SINE_ADDR_WIDTH-1)),
         data_o => sine_s
      ); -- i_ym2151_sine_rom


   ----------------------------------------------------
   -- Instantiate envelope generator
   ----------------------------------------------------

   i_ym2151_envelope_generator : entity work.ym2151_envelope_generator
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         key_onoff_i  => key_onoff_s,
         decay_rate_i => decay_rate_s,
         key_code_i   => key_code_s,
         envelope_o   => envelope_s
      ); -- i_ym2151_envelope_generator


   --------------------------
   -- Instantiate multiplier
   --------------------------

   input_a_s <= envelope_s;

   p_input_b : process (sine_s)
   begin
      input_b_s <= (others => sine_s(C_SINE_DATA_WIDTH-1));
      input_b_s(C_SINE_DATA_WIDTH-1 downto 0) <= sine_s;
   end process p_input_b;

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
         P   => product_s,
         A   => input_a_s,
         B   => input_b_s
      ); -- i_mult
      

   -- The output from the multiplier is a signed 36-bit integer.
   assert (or(product_s(35 downto 17+C_PDM_WIDTH)) = '0') or
          (and(product_s(35 downto 17+C_PDM_WIDTH)) = '1') or
          rst_i /= '0';

   val_s <= product_s(17+C_PDM_WIDTH-1 downto 17) xor C_NEGATIVE_ONE;

   val_o <= val_s;

end architecture synthesis;

