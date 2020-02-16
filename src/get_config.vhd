-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the CPU configuration
--
-- The register map is as follows (taken from http://www.cx5m.net/fmunit.htm)
-- 0x01        : Bit  1   : LFO reset
-- 0x08        : Key on.
--               Bit  6   : modulator 1
--               Bit  5   : carrier 1
--               Bit  4   : modulator 2
--               Bit  3   : carrier 2
--               Bits 2-0 : channel number
-- 0x0F        : Bit  7   : Noise enable
--               Bits 4-0 : Noise frequency
-- 0x11      ? : Timer A high
-- 0x12      ? : Timer A low
-- 0x13      ? : Timer B
-- 0x14        : Timer functions
-- 0x18        : Low oscillation frequency
-- 0x19        : Bit  7   : 0=Amplitude, 1=Phase
--               Bits 6-0 : Depth
-- 0x1B        : Control output and wave form select
--               Bit  7   : CT2
--               Bit  6   : CT1
--               Bits 1-0 : Wave form select (0=Saw, 1=Squared, 2=Triangle, 3=Noise)
-- 0x20        : Channel control
--               Bit  7   : RGT
--               Bit  6   : LFT
--               Bits 5-3 : FB
--               Bits 2-0 : CONNECT
-- 0x28 - 0x2F : Key code (bits 2-0 in address is channel number)
--             : Bits 7-4 : Octace
--             : Bits 3-0 : Note
-- 0x30 - 0x37 : Key fraction (bits 2-0 in address is channel number)
--             : Bits 7-2 : Key fraction
-- 0x38 - 0x3F : Modulation sensitivity (bits 2-0 in address is channel number)
--             : Bits 6-4 : PMS
--             : Bits 1-0 : AMS
-- 0x40 - 0x5F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 6-4 : Detune(1)
--             : Bits 3-0 : Phase multiply
-- 0x60 - 0x7F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 6-0 : Total level
-- 0x80 - 0x9F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-6 : Key Scale
--             : Bits 4-0 : Attack rate
-- 0xA0 - 0xBF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bit  7   : AM sensitivity enable
--             : Bits 4-0 : First decay rate
-- 0xC0 - 0xDF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-6 : Detune(2)
--             : Bits 3-0 : Second decay rate
-- 0xE0 - 0xFF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-4 : First decay level
--             : Bits 3-0 : Release rate
-- Device: 0:Modulator1, 1:Modulator2, 2:Carrier1, 3:Carrier2


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity get_config is
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Configuration output
      idx_o     : out std_logic_vector(4 downto 0);
      channel_o : out channel_t;
      device_o  : out device_t
   );
end entity get_config;

architecture synthesis of get_config is

   ----------------------------------------------------
   -- CPU interface
   ----------------------------------------------------

   signal wr_addr_r           : std_logic_vector(7 downto 0);
   signal wr_en_s             : std_logic;


   ----------------------------------------------------
   -- Reset logic
   ----------------------------------------------------

   signal rst_addr_r          : std_logic_vector(7 downto 0);
   signal rst_data_r          : std_logic_vector(7 downto 0);
   type RESET_STATE_t is (IDLE_ST, CLEAR_ST, KEYOFF_ST);
   signal rst_state_r         : RESET_STATE_t;
   signal wr_addr_s           : std_logic_vector(7 downto 0);
   signal wr_data_s           : std_logic_vector(7 downto 0);


   ----------------------------------------------------
   -- Channel configuration
   ----------------------------------------------------

   type byte_vector_t is array (0 to 7) of std_logic_vector(7 downto 0);
   signal key_onoff_r         : byte_vector_t := (others => (others => '0'));
   signal key_code_r          : byte_vector_t := (others => (others => '0'));
   signal key_fraction_r      : byte_vector_t := (others => (others => '0'));


   ----------------------------------------------------
   -- Device configuration
   ----------------------------------------------------

   signal rambe_a_addr_s      : std_logic_vector(4 downto 0);
   signal rambe_a_data_s      : std_logic_vector(8 downto 0);
   signal rambe_a_wren_s      : std_logic;
   signal rambe_a_be_s        : std_logic_vector(7 downto 0);


   ----------------------------------------------------
   -- Device counter
   ----------------------------------------------------

   signal device_cnt_r        : std_logic_vector(4 downto 0) := (others => '0');


   ----------------------------------------------------
   -- Read configuration from memories
   ----------------------------------------------------

   signal rambe_b_addr_s      : std_logic_vector(4 downto 0);
   signal rambe_b_data_s      : std_logic_vector(71 downto 0);
   signal key_onoff_read_r    : std_logic_vector(7 downto 0);
   signal key_code_read_r     : std_logic_vector(7 downto 0);
   signal key_fraction_read_r : std_logic_vector(7 downto 0);

   -- Debug
   constant C_DEBUG_MODE             : boolean := false; -- TRUE OR FALSE

   attribute mark_debug              : boolean;
   attribute mark_debug of wr_en_s   : signal is C_DEBUG_MODE;
   attribute mark_debug of wr_addr_s : signal is C_DEBUG_MODE;
   attribute mark_debug of wr_data_s : signal is C_DEBUG_MODE;

begin

   ----------------------------------------------------
   -- CPU interface
   ----------------------------------------------------

   p_wr_addr : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_i = '1'  and addr_i = 0 then
            wr_addr_r <= wr_data_i;
         end if;
         if rst_i = '1' then
            wr_addr_r <= (others => '0');
         end if;
      end if;
   end process p_wr_addr;


   ----------------------------------------------------
   -- Reset logic
   ----------------------------------------------------

   p_reset : process (clk_i)
   begin
      if rising_edge(clk_i) then
         case rst_state_r is
            when IDLE_ST =>
               null;

            when CLEAR_ST =>
               if rst_addr_r = X"FF" then
                  rst_addr_r  <= X"08";
                  rst_data_r  <= X"00";
                  rst_state_r <= KEYOFF_ST;
               else
                  rst_addr_r <= rst_addr_r + 1;
               end if;

            when KEYOFF_ST =>
               if rst_data_r = X"07" then
                  rst_state_r <= IDLE_ST;
               else
                  rst_data_r <= rst_data_r + 1;
               end if;

         end case;

         if rst_i = '1' then
            rst_addr_r  <= X"00";
            rst_data_r  <= X"00";
            rst_state_r <= CLEAR_ST;
         end if;
      end if;
   end process p_reset;

   wr_en_s   <= '1'        when rst_state_r /= IDLE_ST else
                wr_en_i    when addr_i = 1             else
                '0';

   wr_addr_s <= rst_addr_r when rst_state_r /= IDLE_ST else
                wr_addr_r;

   wr_data_s <= rst_data_r when rst_state_r /= IDLE_ST else
                wr_data_i;


   ----------------------------------------------------
   -- Channel configuration
   ----------------------------------------------------

   p_key_onoff : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_s = '1' and wr_addr_s = X"08" then
            key_onoff_r(to_integer(wr_data_s(2 downto 0))) <= "0000" & wr_data_s(6 downto 3);
         end if;
      end if;
   end process p_key_onoff;

   p_key_code : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_s = '1' and wr_addr_s(7 downto 3) = "00101" then
            key_code_r(to_integer(wr_addr_s(2 downto 0))) <= "0" & wr_data_s(6 downto 0);
         end if;
      end if;
   end process p_key_code;

   p_key_fraction : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_s = '1' and wr_addr_s(7 downto 3) = "00110" then
            key_fraction_r(to_integer(wr_addr_s(2 downto 0))) <= "00" & wr_data_s(7 downto 2);
         end if;
      end if;
   end process p_key_fraction;


   ----------------------------------------------------
   -- Device configuration
   ----------------------------------------------------

   rambe_a_addr_s <= wr_addr_s(4 downto 0);
   rambe_a_data_s <= "0" & wr_data_s;
   rambe_a_wren_s <= wr_en_s;

   process (wr_addr_s)
   begin
      rambe_a_be_s   <= (others => '0');
      rambe_a_be_s(to_integer(wr_addr_s(7 downto 5))) <= '1';
   end process;

   i_rambe : entity work.rambe
      generic map (
         G_ADDR_WIDTH => 5,
         G_DATA_BYTES => 8
      )
      port map (
         clk_i    => clk_i,
         a_addr_i => rambe_a_addr_s,
         a_data_i => rambe_a_data_s,
         a_wren_i => rambe_a_wren_s,
         a_be_i   => rambe_a_be_s,
         b_addr_i => rambe_b_addr_s,
         b_data_o => rambe_b_data_s
      ); -- i_rambe


   ----------------------------------------------------
   -- Device counter
   ----------------------------------------------------

   p_device_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         device_cnt_r <= device_cnt_r + 1;
      end if;
   end process p_device_cnt;


   ----------------------------------------------------
   -- Read configuration from memories
   ----------------------------------------------------

   rambe_b_addr_s <= device_cnt_r;

   p_register : process (clk_i)
   begin
      if rising_edge(clk_i) then
         idx_o               <= device_cnt_r;
         key_onoff_read_r    <= key_onoff_r(to_integer(device_cnt_r(2 downto 0)));
         key_code_read_r     <= key_code_r(to_integer(device_cnt_r(2 downto 0)));
         key_fraction_read_r <= key_fraction_r(to_integer(device_cnt_r(2 downto 0)));
      end if;
   end process p_register;


   ----------------------------------------------------
   -- Drive output signals
   ----------------------------------------------------

   device_o.total_level   <= rambe_b_data_s(9*3+6 downto 9*3+0);   -- 0x60 - 0x7F
   device_o.key_scaling   <= rambe_b_data_s(9*4+7 downto 9*4+6);   -- 0x80 - 0x9F
   device_o.attack_rate   <= rambe_b_data_s(9*4+4 downto 9*4+0);   -- 0x80 - 0x9F
   device_o.decay_rate    <= rambe_b_data_s(9*5+4 downto 9*5+0);   -- 0xA0 - 0xBF
   device_o.sustain_rate  <= rambe_b_data_s(9*6+4 downto 9*6+0);   -- 0xC0 - 0xDF
   device_o.decay_level   <= rambe_b_data_s(9*7+7 downto 9*7+4);   -- 0xE0 - 0xFF
   device_o.release_rate  <= rambe_b_data_s(9*7+3 downto 9*7+0);   -- 0xE0 - 0xFF
   device_o.key_onoff     <= key_onoff_read_r(to_integer(device_cnt_r(4 downto 3)));
   channel_o.key_code     <= key_code_read_r(6 downto 0);
   channel_o.key_fraction <= key_fraction_read_r(5 downto 0);

end architecture synthesis;

