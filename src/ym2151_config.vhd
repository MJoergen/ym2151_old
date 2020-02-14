-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module contains the configuration of all the channels

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

-- This is the main YM2151 module
-- The single clock is the CPU clock.
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

entity ym2151_config is
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      -- CPU interface
      addr_i     : in  std_logic_vector(0 downto 0);
      wr_en_i    : in  std_logic;
      wr_data_i  : in  std_logic_vector(7 downto 0);
      -- Configuration output
      channels_o : out channel_vector_t(0 to 7);
      devices_o  : out device_vector_t(0 to 31)
   );
end entity ym2151_config;

architecture synthesis of ym2151_config is

   constant C_CHANNEL_DEFAULT : channel_t := (
      key_code     => (others => '0'),
      key_fraction => (others => '0')
   );

   constant C_DEVICE_DEFAULT : device_t := (
      total_level  => (others => '0'),
      key_scaling  => (others => '0'),
      attack_rate  => (others => '0'),
      decay_rate   => (others => '0'),
      decay_level  => (others => '0'),
      sustain_rate => (others => '0'),
      release_rate => (others => '0'),
      key_onoff    => '0'
   );

   -------------------------------------
   -- CPU interface
   -------------------------------------

   signal wr_addr_r : std_logic_vector(7 downto 0);
   signal wr_data_r : std_logic_vector(7 downto 0);
   signal wr_en_r   : std_logic;

   -- Debug
   constant DEBUG_MODE               : boolean := false; -- TRUE OR FALSE

   attribute mark_debug              : boolean;
   attribute mark_debug of wr_addr_r : signal is DEBUG_MODE;
   attribute mark_debug of wr_data_r : signal is DEBUG_MODE;
   attribute mark_debug of wr_en_r   : signal is DEBUG_MODE;

begin

   ----------------------
   -- CPU interface
   ----------------------

   p_regs : process (clk_i)
   begin
      if rising_edge(clk_i) then
         wr_en_r <= '0';
         if wr_en_i = '1' then
            case addr_i is
               when "0" => 
                  wr_addr_r <= wr_data_i;
               when "1" => 
                  wr_data_r <= wr_data_i;
                  wr_en_r   <= '1';
               when others => null;
            end case;
         end if;
      end if;
   end process p_regs;


   -----------------
   -- Configuration
   -----------------

   p_config : process (clk_i)
      variable channel_v : integer;
      variable device_v : integer;
   begin
      if rising_edge(clk_i) then
         device_v  := to_integer(wr_addr_r(4 downto 0));

         if wr_en_r = '1' then
            case wr_addr_r(7 downto 5) is
               when "000" => -- 0x00 - 0x1F
                  case wr_addr_r(4 downto 3) is
                     when "01" => -- Key ON/OFF
                        devices_o(   to_integer(wr_addr_r(2 downto 0))).key_onoff <= wr_data_r(3);
                        devices_o( 8+to_integer(wr_addr_r(2 downto 0))).key_onoff <= wr_data_r(4);
                        devices_o(16+to_integer(wr_addr_r(2 downto 0))).key_onoff <= wr_data_r(5);
                        devices_o(24+to_integer(wr_addr_r(2 downto 0))).key_onoff <= wr_data_r(6);

                     when others => null;
                  end case;

               when "001" => -- 0x20 - 0x3F
                  case wr_addr_r(4 downto 3) is
                     when "01" => -- Key code
                        channels_o(to_integer(wr_addr_r(2 downto 0))).key_code <= wr_data_r(6 downto 0);

                     when "10" => -- Key fraction
                        channels_o(to_integer(wr_addr_r(2 downto 0))).key_fraction <= wr_data_r(7 downto 2);

                     when others => null;
                  end case;

               when "011" => -- 0x60 - 0x7F
                  devices_o(device_v).total_level  <= wr_data_r(6 downto 0);

               when "100" => -- 0x80 - 0x9F
                  devices_o(device_v).key_scaling  <= wr_data_r(7 downto 6);
                  devices_o(device_v).attack_rate  <= wr_data_r(4 downto 0);

               when "101" => -- 0xA0 - 0xBF
                  devices_o(device_v).decay_rate   <= wr_data_r(4 downto 0);

               when "110" => -- 0xC0 - 0xDF
                  devices_o(device_v).sustain_rate <= wr_data_r(4 downto 0);

               when "111" => -- 0xE0 - 0xFF
                  devices_o(device_v).decay_level  <= wr_data_r(7 downto 4);
                  devices_o(device_v).release_rate <= wr_data_r(3 downto 0);

               when others => null;
            end case;
         end if;

         if rst_i = '1' then
            channels_o <= (others => C_CHANNEL_DEFAULT);
            devices_o  <= (others => C_DEVICE_DEFAULT);
         end if;
      end if;
   end process p_config;

end architecture synthesis;

