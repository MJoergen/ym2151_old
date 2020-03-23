library ieee;
use ieee.std_logic_1164.all;

-- This block is a simple synchronizer, used for Clock Domain Crossing.
--
-- Note: There is no parallel synchronization, so the individual bits in the
-- input may not be synchronized at the same time. If you require the input
-- vector to be synchronized in parallel, i.e. simultaneously, you should use a
-- FIFO.

entity cdc is
   generic (
      G_SIZE : integer
   );
   port (
      src_clk_i : in  std_logic;
      src_dat_i : in  std_logic_vector(G_SIZE-1 downto 0);
      dst_clk_i : in  std_logic;
      dst_dat_o : out std_logic_vector(G_SIZE-1 downto 0)
   );
end cdc;

architecture structural of cdc is

   signal src_dat_r : std_logic_vector(G_SIZE-1 downto 0);
   signal dst_dat_r : std_logic_vector(G_SIZE-1 downto 0);
   signal dst_dat_d : std_logic_vector(G_SIZE-1 downto 0);

   attribute ASYNC_REG              : string;
   attribute ASYNC_REG of dst_dat_r : signal is "TRUE";
   attribute ASYNC_REG of dst_dat_d : signal is "TRUE";   

begin

   gen_cdc : if true generate             -- This generate statement makes it easy to wildcard in the XDC file all the CDC's.
      p_sync_src : process (src_clk_i)
      begin
         if rising_edge(src_clk_i) then
            src_dat_r <= src_dat_i;
         end if;
      end process p_sync_src;

      p_sync_dst : process (dst_clk_i)
      begin
         if rising_edge(dst_clk_i) then
            dst_dat_r <= src_dat_r;
            dst_dat_d <= dst_dat_r;
         end if;
      end process p_sync_dst;

      dst_dat_o <= dst_dat_d;
   end generate gen_cdc;

end architecture structural;

