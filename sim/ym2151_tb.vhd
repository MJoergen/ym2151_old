-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module is a test bench for the YM2151 module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity ym2151_tb is
end entity ym2151_tb;

architecture simulation of ym2151_tb is

   constant C_CLOCK_HZ        : integer := 3579545;
   constant C_CLOCK_PERIOD    : time := (10.0**9)/real(C_CLOCK_HZ) * 1.0 ns;

   -- Connected to DUT
   signal clk_s               : std_logic;
   signal rst_s               : std_logic;
   signal addr_s              : std_logic_vector(0 downto 0);
   signal wr_en_s             : std_logic;
   signal wr_data_s           : std_logic_vector(7 downto 0);
   signal valid_s             : std_logic;
   signal data_s              : std_logic_vector(11 downto 0);

   -- Control the execution of the test.
   signal test_running_s      : std_logic := '1';
   signal write_output_file_s : std_logic := '0';

   constant C_INPUT_FILENAME  : string := "test/Ievan_Polkka.bin";
   constant C_OUTPUT_FILENAME : string := "music.wav";

begin

   ----------------------------------------------------------------
   -- Generate clock and reset
   ----------------------------------------------------------------

   -- Generate cpu clock
   proc_clk : process
   begin
      clk_s <= '1', '0' after C_CLOCK_PERIOD/2;
      wait for C_CLOCK_PERIOD;

      -- Stop clock when test is finished
      if test_running_s = '0' then
         wait;
      end if;
   end process proc_clk;

   -- Generate cpu reset
   proc_rst : process
   begin
      rst_s <= '1', '0' after 40*C_CLOCK_PERIOD;
      wait;
   end process proc_rst;


   ----------------------------------------------------------------
   -- Instantiate DUT
   ----------------------------------------------------------------

   i_ym2151 : entity work.ym2151
      generic map (
         G_CLOCK_HZ => C_CLOCK_HZ
      )
      port map (
         clk_i     => clk_s,
         rst_i     => rst_s,
         addr_i    => addr_s,
         wr_en_i   => wr_en_s,
         wr_data_i => wr_data_s,
         valid_o   => valid_s,
         data_o    => data_s
      ); -- i_ym2151
   

   ----------------------------------------------------------------
   -- Store output in file
   ----------------------------------------------------------------

   p_output : process

      type CHAR_FILE_TYPE is file of character;
      file output_file : CHAR_FILE_TYPE;

      -- Helper function:
      -- Write a 2-byte value to the file.
      procedure write_16_bits
      (
         file data_file : CHAR_FILE_TYPE;
         data : std_logic_vector(15 downto 0)
      ) is
      begin
         write(data_file, character'val(to_integer(data(7 downto 0))));
         write(data_file, character'val(to_integer(data(15 downto 8))));
      end procedure write_16_bits;

   begin

      -- Copy output from YM2151 to file
      file_open(output_file, C_OUTPUT_FILENAME, WRITE_MODE);

      -- Write WAVE header
      write_16_bits(output_file, X"4952");
      write_16_bits(output_file, X"4646");
      write_16_bits(output_file, X"0024");
      write_16_bits(output_file, X"7FFF");
      write_16_bits(output_file, X"4157");
      write_16_bits(output_file, X"4556");

      write_16_bits(output_file, X"6d66");
      write_16_bits(output_file, X"2074");
      write_16_bits(output_file, X"0010");
      write_16_bits(output_file, X"0000");
      write_16_bits(output_file, X"0001");
      write_16_bits(output_file, X"0001");
      write_16_bits(output_file, X"B4F4");
      write_16_bits(output_file, X"0001");
      write_16_bits(output_file, X"69E8");
      write_16_bits(output_file, X"0003");
      write_16_bits(output_file, X"0002");
      write_16_bits(output_file, X"0010");

      write_16_bits(output_file, X"6164");
      write_16_bits(output_file, X"6174");
      write_16_bits(output_file, X"0000");
      write_16_bits(output_file, X"7FFF");

      out_loop : while test_running_s = '1' loop
         wait until clk_s = '1';
         if valid_s = '1' and write_output_file_s = '1' then
            report "Writing";
            write_16_bits(output_file, (data_s xor X"800") & "0000");
         end if;
      end loop out_loop;
      file_close(output_file);

      wait;
   end process p_output;


   ----------------------------------------------------------------
   -- Main test program
   ----------------------------------------------------------------

   p_test : process

      type CHAR_FILE_TYPE is file of character;
      file input_file : CHAR_FILE_TYPE;

      -- Helper function:
      -- Read a single byte from the file.
      impure function read_8_bits
      (
         file data_file : CHAR_FILE_TYPE
      ) return std_logic_vector is
         variable char_read_v : character; -- char read from file
         variable byte_v      : std_logic_vector(7 downto 0);
      begin
         read(data_file, char_read_v);
         byte_v := to_std_logic_vector(character'pos(char_read_v), 8);
         return byte_v;
      end function read_8_bits;

      -- Helper function:
      -- Write a command to the YM2151.
      procedure write(addr : std_logic_vector; value : std_logic_vector) is
      begin
         addr_s    <= "0";
         wr_data_s <= addr;
         wr_en_s   <= '1';
         wait until clk_s = '1';
         wr_en_s   <= '0';
         wait until clk_s = '1';

         addr_s    <= "1";
         wr_data_s <= value;
         wr_en_s   <= '1';
         wait until clk_s = '1';
         wr_en_s   <= '0';
         wait until clk_s = '1';
      end procedure write;

      variable addr_v : std_logic_vector(7 downto 0);
      variable data_v : std_logic_vector(7 downto 0);

   begin

      addr_s    <= (others => '0');
      wr_en_s   <= '0';
      wr_data_s <= (others => '0');

      -- Wait for reset
      wait until rst_s = '0';
      wait for 300 * C_CLOCK_PERIOD; -- Wait 300 clock cycles to allow reset sequence to complete.
      write_output_file_s <= '1';
      wait until clk_s = '1';

      -- Copy commands from file to YM2151
      file_open(input_file, C_INPUT_FILENAME, READ_MODE);
      cpu_loop : while not endfile(input_file) loop

         addr_v := read_8_bits(input_file);
         data_v := read_8_bits(input_file);

         if addr_v = X"00" then
            if data_v = X"00" then
               exit;
            end if;
            report "Waiting for " & to_string(to_integer(data_v)*100) & " us";
            wait for to_integer(data_v) * 100 us;
         else
            write(addr_v, data_v);
         end if;
      end loop cpu_loop;

      -- End test
      report "Test completed";
      test_running_s <= '0';
      wait;

   end process p_test;

end simulation;

