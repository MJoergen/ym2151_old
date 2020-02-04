library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

-- This file contains the ROM with the exp table.
-- Input is interpreted as an unsigned fractional number between 0 and 1.
-- Output is the exponential (with base 0.5), interpreted as an unsigned
-- The function calculated is y=0.5^x.

entity exp_rom is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(C_EXP_ADDR_WIDTH-1 downto 0);
      data_o : out std_logic_vector(C_EXP_DATA_WIDTH-1 downto 0)
   );
end exp_rom;

architecture synthesis of exp_rom is

   type mem_t is array (0 to 2**C_EXP_ADDR_WIDTH-1) of std_logic_vector(C_EXP_DATA_WIDTH-1 downto 0);

   impure function InitRom return mem_t is
      variable ROM_v : mem_t := (others => (others => '0'));
      variable exp_v : real;
   begin
      for i in 0 to 2**C_EXP_ADDR_WIDTH-1 loop
         exp_v   := exp(-real(i+1) / real(2**C_EXP_ADDR_WIDTH) * log(2.0));
         ROM_v(i):= to_stdlogicvector(integer(exp_v*real(2**C_EXP_DATA_WIDTH)), C_EXP_DATA_WIDTH);
      end loop;
      return ROM_v;
   end function;

   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end synthesis;

