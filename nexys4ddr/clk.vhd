library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity clk is
   port (
      sys_clk_i    : in  std_logic;   -- 100        MHz
      ym2151_clk_o : out std_logic;   --   3.579545 MHz
      pwm_clk_o    : out std_logic    -- 100        MHz
   );
end clk;

architecture synthesis of clk is
   -- Output clock buffering / unused connectors
   signal clkfbout_clk_wiz_0     : std_logic;
   signal clkfbout_buf_clk_wiz_0 : std_logic;
   signal clkfboutb_unused       : std_logic;
   signal ym2151_clk_wiz_0       : std_logic;
   signal pwm_clk_wiz_0          : std_logic;
   signal clkout0b_unused        : std_logic;
   signal clkout1b_unused        : std_logic;
   signal clkout2_unused         : std_logic;
   signal clkout2b_unused        : std_logic;
   signal clkout3_unused         : std_logic;
   signal clkout3b_unused        : std_logic;
   signal clkout4_unused         : std_logic;
   signal clkout5_unused         : std_logic;
   signal clkout6_unused         : std_logic;
   -- Dynamic programming unused signals
   signal do_unused              : std_logic_vector(15 downto 0);
   signal drdy_unused            : std_logic;
   -- Dynamic phase shift unused signals
   signal psdone_unused          : std_logic;
   signal locked_int             : std_logic;
   -- Unused status signals
   signal clkfbstopped_unused    : std_logic;
   signal clkinstopped_unused    : std_logic;

   signal ym2151_clk_s           : std_logic;
   signal ym2151_cnt_r           : std_logic_vector(4 downto 0) := (others => '0');

begin

   --------------------------------------
   -- Clocking PRIMITIVE
   --------------------------------------
   -- Instantiation of the MMCM PRIMITIVE
   --    * Unused inputs are tied off
   --    * Unused outputs are labeled unused
   i_mmcm_adv : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 55.125,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 9.625,     -- @ 114.545 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 11,        -- @ 100 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKIN1_PERIOD        => 10.0,
         REF_JITTER1          => 0.010
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfbout_clk_wiz_0,
         CLKFBOUTB           => clkfboutb_unused,
         CLKOUT0             => ym2151_clk_wiz_0,
         CLKOUT0B            => clkout0b_unused,
         CLKOUT1             => pwm_clk_wiz_0,
         CLKOUT1B            => clkout1b_unused,
         CLKOUT2             => clkout2_unused,
         CLKOUT2B            => clkout2b_unused,
         CLKOUT3             => clkout3_unused,
         CLKOUT3B            => clkout3b_unused,
         CLKOUT4             => clkout4_unused,
         CLKOUT5             => clkout5_unused,
         CLKOUT6             => clkout6_unused,
         -- Input clock control
         CLKFBIN             => clkfbout_buf_clk_wiz_0,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => do_unused,
         DRDY                => drdy_unused,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => psdone_unused,
         -- Other control and status signals
         LOCKED              => locked_int,
         CLKINSTOPPED        => clkinstopped_unused,
         CLKFBSTOPPED        => clkfbstopped_unused,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_mmcm_adv


   -------------------------------------
   -- Output buffering
   -------------------------------------

   clkf_buf : BUFG
      port map (
         I => clkfbout_clk_wiz_0,
         O => clkfbout_buf_clk_wiz_0
      );

   clkout0_buf : BUFG
      port map (
         I => ym2151_clk_wiz_0,
         O => ym2151_clk_s
      );

   clkout1_buf : BUFG
      port map (
         I => pwm_clk_wiz_0,
         O => pwm_clk_o
      );

   p_ym2151_clk : process (ym2151_clk_s)
   begin
      if rising_edge(ym2151_clk_s) then
         ym2151_cnt_r <= ym2151_cnt_r + 1;
      end if;
   end process p_ym2151_clk;

   clkout1a_buf : BUFG
      port map (
         I => ym2151_cnt_r(4),
         O => ym2151_clk_o
      );

end synthesis;

