-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
-- Project: YM2151 implementation
--
-- Description: This module write the generated output to a WAV file.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity output2wav is
   generic (
      G_FILE_NAME : string
   );
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      active_i  : in  std_logic;
      valid_i   : in  std_logic;
      data_i    : in  std_logic_vector(11 downto 0)
   );
end entity output2wav;

architecture simulation of output2wav is

begin

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

      -- Copy output to file
      file_open(output_file, G_FILE_NAME, WRITE_MODE);

      -- Write WAV header
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

      out_loop : while active_i loop
         wait until clk_i = '1';
         if valid_i = '1' then
            report "Writing";
            write_16_bits(output_file, (data_i xor X"800") & "0000");
            flush(output_file);
         end if;
      end loop out_loop;
      file_close(output_file);

      wait;
   end process p_output;

end simulation;

