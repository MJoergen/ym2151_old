library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ctrl is
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      addr_o    : out std_logic_vector(0 downto 0);
      wr_en_o   : out std_logic;
      wr_data_o : out std_logic_vector(7 downto 0)
   );
end ctrl;

architecture synthesis of ctrl is

   signal rom_addr_r : std_logic_vector(11 downto 0);
   signal rom_addr_d : std_logic_vector(11 downto 0);
   signal rom_data_s : std_logic_vector(7 downto 0);

   signal cnt_r : std_logic_vector(15 downto 0);

   signal addr_r    : std_logic_vector(0 downto 0);
   signal wr_en_r   : std_logic;
   signal wr_data_r : std_logic_vector(7 downto 0);

   -- Debug
   constant DEBUG_MODE                   : boolean := true; -- TRUE OR FALSE

   attribute mark_debug                  : boolean;
   attribute mark_debug of rom_addr_r : signal is DEBUG_MODE;
   attribute mark_debug of rom_addr_d : signal is DEBUG_MODE;
   attribute mark_debug of rom_data_s : signal is DEBUG_MODE;
   attribute mark_debug of cnt_r      : signal is DEBUG_MODE;
   attribute mark_debug of addr_r     : signal is DEBUG_MODE;
   attribute mark_debug of wr_en_r    : signal is DEBUG_MODE;
   attribute mark_debug of wr_data_r  : signal is DEBUG_MODE;

begin

   ----------------------------------------------------------------
   -- Instantiate ROM
   ----------------------------------------------------------------

   i_rom_ctrl : entity work.rom_ctrl
      generic map (
         G_INIT_FILE => "nexys4ddr/ctrl.txt"
      )
      port map (
         clk_i  => clk_i,
         addr_i => rom_addr_r,
         data_o => rom_data_s
      ); -- i_rom_ctrl


   p_ctrl : process (clk_i)
   begin
      if rising_edge(clk_i) then
         rom_addr_d <= rom_addr_r;
         addr_r     <= "0";
         wr_en_r    <= '0';
         wr_data_r  <= (others => '0');

         if cnt_r = 0 then
            if rom_addr_d = 0 then
               cnt_r(15 downto 8) <= rom_data_s;
            else
               addr_r    <= "" & rom_addr_d(0);
               wr_en_r   <= '1';
               wr_data_r <= rom_data_s;
            end if;
            rom_addr_r <= rom_addr_r + 1;
         else
            cnt_r <= cnt_r - 1;
         end if;

         if rst_i = '1' then
            rom_addr_r <= (others => '0');
            cnt_r      <= (others => '0');
         end if;
      end if;
   end process p_ctrl;

   addr_o    <= addr_r;
   wr_en_o   <= wr_en_r;
   wr_data_o <= wr_data_r;

end synthesis;
