library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the top level module of the Nexys4DDR. The ports on this entity are mapped
-- directly to pins on the FPGA.

entity nexys4ddr is
   port (
      sys_clk_i  : in    std_logic;    -- 100 MHz
      sys_rstn_i : in    std_logic;
      aud_pwm_o  : inout std_logic;
      aud_sd_o   : out   std_logic
   );
end nexys4ddr;

architecture synthesis of nexys4ddr is

   signal clk_s     : std_logic;
   signal rst_r     : std_logic_vector(35 downto 0) := (others => '1'); 
   signal rst_s     : std_logic; 

   signal addr_s    : std_logic_vector(0 downto 0);
   signal wr_en_s   : std_logic;
   signal wr_data_s : std_logic_vector(7 downto 0);

   signal val_s     : std_logic_vector(11 downto 0);

   signal pwm_clk_s : std_logic;
   signal pwm_val_s : std_logic_vector(11 downto 0);
   signal pwm_aud_s : std_logic;

begin

   ----------------------------------------------------------------
   -- Instantiate Clock generation
   ----------------------------------------------------------------

   i_clk : entity work.clk
      port map (
         sys_clk_i    => sys_clk_i,      -- 100 MHz
         ym2151_clk_o => clk_s,          --   3.579545 MHz
         pwm_clk_o    => pwm_clk_s       -- 100 MHz
      ); -- i_clk


   ----------------------------------------------------------------
   -- Generate reset signal.
   ----------------------------------------------------------------

   p_rst : process (clk_s)
   begin
      if rising_edge(clk_s) then
         rst_r <= rst_r(34 downto 0) & "0";  -- Shift left one bit
         if sys_rstn_i = '0' then
            rst_r <= (others => '1');
         end if;
      end if;
   end process p_rst;

   rst_s <= rst_r(35);


   ----------------------------------------------------------------
   -- Instantiate controller
   ----------------------------------------------------------------

   i_ctrl : entity work.ctrl
      port map (
         clk_i     => clk_s,
         rst_i     => rst_s,
         addr_o    => addr_s,
         wr_en_o   => wr_en_s,
         wr_data_o => wr_data_s
      ); -- i_ctrl


   ----------------------------------------------------------------
   -- Instantiate YM2151 module
   ----------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      generic map (
         G_CLOCK_HZ => 3579545
      )
      port map (
         clk_i     => clk_s,
         rst_i     => rst_s,
         addr_i    => addr_s,
         wr_en_i   => wr_en_s,
         wr_data_i => wr_data_s,
         val_o     => val_s
      ); -- i_ym2151


   --------------------------------------------------------
   -- Instantiate CDC module
   --------------------------------------------------------

   i_cdc : entity work.cdc
      generic map (
         G_SIZE => 12
      )
      port map (
         src_clk_i => clk_s,
         src_dat_i => val_s,
         dst_clk_i => pwm_clk_s,
         dst_dat_o => pwm_val_s
      ); -- i_cdc


   ----------------------------------------------------------------
   -- Instantiate PWN module
   ----------------------------------------------------------------

   i_pwm : entity work.pwm
      port map (
         clk_i => pwm_clk_s,
         val_i => pwm_val_s,
         pwm_o => pwm_aud_s
      ); -- i_pwm


   ----------------------------------------------------------------
   -- Drive output signals
   ----------------------------------------------------------------

   aud_sd_o <= '1';
   aud_pwm_o <= '0' when pwm_aud_s = '0' else 'Z';

end architecture synthesis;

