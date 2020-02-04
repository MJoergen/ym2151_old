library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

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

   signal key_code_s   : std_logic_vector(9 downto 0);

   signal phase_inc_s  : std_logic_vector(C_PHASEINC_DATA_WIDTH-1 downto 0);

   -- Current waveform value
   signal phase_r      : std_logic_vector(C_PHASE_WIDTH-1 downto 0);

   -- Current waveform value
   signal sine_s       : std_logic_vector(C_SINE_DATA_WIDTH-1 downto 0);

   constant C_NEGATIVE_ONE : std_logic_vector(C_PDM_WIDTH-1 downto 0) :=
      (C_PDM_WIDTH-1 => '1', others => '0');

   -- Debug
   constant DEBUG_MODE                 : boolean := true; -- TRUE OR FALSE

   attribute mark_debug                : boolean;
   attribute mark_debug of key_code_s  : signal is DEBUG_MODE;
   attribute mark_debug of phase_inc_s : signal is DEBUG_MODE;
   attribute mark_debug of phase_r     : signal is DEBUG_MODE;
   attribute mark_debug of sine_s      : signal is DEBUG_MODE;

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
   -- Phase Increment ROM
   ----------------------------------------------------

   key_code_s <= "000" & devices_s(0).pg.key_code;

   i_phase_increment_rom : entity work.phase_increment_rom
      generic map (
         G_CLOCK_HZ => G_CLOCK_HZ
      )
      port map (
         clk_i  => clk_i,
         addr_i => key_code_s,
         data_o => phase_inc_s
      ); -- i_phase_increment_rom


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
      ); -- i_sine_rom

   val_o <= sine_s xor C_NEGATIVE_ONE;

end architecture synthesis;

