-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description:
-- This is a wrapper module that instantiates a simple dual-port RAM with byte-enable.
-- Each byte is 9 bits wide.
-- Can only write to one byte at a time.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity rambe is
   generic (
      G_ADDR_WIDTH : integer;
      G_DATA_BYTES : integer
   );
   port (
      clk_i    : in  std_logic;
      a_addr_i : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);
      a_data_i : in  std_logic_vector(8 downto 0);
      a_wren_i : in  std_logic;
      a_be_i   : in  std_logic_vector(G_DATA_BYTES-1 downto 0);
      b_addr_i : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);
      b_data_o : out std_logic_vector(9*G_DATA_BYTES-1 downto 0)
   );
end entity rambe;

architecture synthesis of rambe is

   type mem_t is array (0 to 2**G_ADDR_WIDTH-1) of std_logic_vector(9*G_DATA_BYTES-1 downto 0);

   signal mem_r : mem_t;

begin

   p_write : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if a_wren_i = '1' then
            for i in 0 to G_DATA_BYTES-1 loop
               if a_be_i(i) = '1' then
                  mem_r(to_integer(a_addr_i))(9*i+8 downto 9*i) <= a_data_i;
               end if;
            end loop;
         end if;
      end if;
   end process p_write;

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         b_data_o <= mem_r(to_integer(b_addr_i));
      end if;
   end process p_read;

end architecture synthesis;

