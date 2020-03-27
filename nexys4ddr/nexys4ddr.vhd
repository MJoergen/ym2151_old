library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the top level module of the Nexys4DDR. The ports on this entity are mapped
-- directly to pins on the FPGA.

entity nexys4ddr is
   generic (
      G_INIT_FILE : string := "rom.txt"
   );
   port (
      sys_clk_i  : in    std_logic;    -- 100 MHz
      sys_rstn_i : in    std_logic;
      aud_pwm_o  : inout std_logic;
      aud_sd_o   : out   std_logic
   );
end nexys4ddr;

architecture synthesis of nexys4ddr is

   signal ym2151_clk_s     : std_logic;
   signal ym2151_rst_s     : std_logic; 
   signal ym2151_addr_s    : std_logic_vector(0 downto 0);
   signal ym2151_wr_en_s   : std_logic;
   signal ym2151_wr_data_s : std_logic_vector(7 downto 0);
   signal ym2151_valid_s   : std_logic;
   signal ym2151_data_s    : std_logic_vector(11 downto 0);

   signal pwm_clk_s        : std_logic;
   signal pwm_data_s       : std_logic_vector(11 downto 0);
   signal pwm_aud_s        : std_logic;

begin

   ----------------------------------------------------------------
   -- Instantiate Clock and Reset generation
   ----------------------------------------------------------------

   i_clk_rst : entity work.clk_rst
      port map (
         sys_clk_i    => sys_clk_i,      -- 100 MHz
         sys_rstn_i   => sys_rstn_i,
         ym2151_clk_o => ym2151_clk_s,   --   3.579545 MHz
         ym2151_rst_o => ym2151_rst_s,
         pwm_clk_o    => pwm_clk_s       -- 100 MHz
      ); -- i_clk_rst


   ----------------------------------------------------------------
   -- Instantiate controller
   ----------------------------------------------------------------

   i_ctrl : entity work.ctrl
      generic map (
         G_INIT_FILE => G_INIT_FILE
      )
      port map (
         clk_i     => ym2151_clk_s,
         rst_i     => ym2151_rst_s,
         addr_o    => ym2151_addr_s,
         wr_en_o   => ym2151_wr_en_s,
         wr_data_o => ym2151_wr_data_s
      ); -- i_ctrl


   ----------------------------------------------------------------
   -- Instantiate YM2151 module
   ----------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      generic map (
         G_CLOCK_HZ => 3579545
      )
      port map (
         clk_i     => ym2151_clk_s,
         rst_i     => ym2151_rst_s,
         addr_i    => ym2151_addr_s,
         wr_en_i   => ym2151_wr_en_s,
         wr_data_i => ym2151_wr_data_s,
         valid_o   => ym2151_valid_s,
         data_o    => ym2151_data_s
      ); -- i_ym2151


   --------------------------------------------------------
   -- Instantiate CDC module
   --------------------------------------------------------

   i_cdc : entity work.cdc
      generic map (
         G_SIZE => 12
      )
      port map (
         src_clk_i => ym2151_clk_s,
         src_dat_i => ym2151_data_s,
         dst_clk_i => pwm_clk_s,
         dst_dat_o => pwm_data_s
      ); -- i_cdc


   ----------------------------------------------------------------
   -- Instantiate PWN module
   ----------------------------------------------------------------

   i_pwm : entity work.pwm
      port map (
         clk_i => pwm_clk_s,
         val_i => pwm_data_s,
         pwm_o => pwm_aud_s
      ); -- i_pwm


   ----------------------------------------------------------------
   -- Drive output signals
   ----------------------------------------------------------------

   aud_sd_o <= '1';
   aud_pwm_o <= '0' when pwm_aud_s = '0' else 'Z';

end architecture synthesis;

