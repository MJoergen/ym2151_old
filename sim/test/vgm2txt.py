#!/usr/bin/env python3

# This program decodes a VGM file according to the specification in https://www.smspower.org/uploads/Music/vgmspec160.txt

import sys
import pathlib

if len(sys.argv) < 2:
    sys.exit(-1)

file_name = sys.argv[1]

state = 0
byte_offset = 0
wait = 0

for byte in pathlib.Path(file_name).read_bytes():
   if state == 0:
      print("%2.2x "% (byte), end = '')
      if (byte_offset % 0x10) == 0x0f:
         print()

      if byte_offset == 0x7F:
         state = 1

   elif state == 1:
      if byte == 0x54:
         state = 10  # YM2151
      elif byte == 0x61:
         state = 40  # Wait
      elif byte == 0x67:
         state = 20  # Data block
      elif byte >= 0x70 and byte <= 0x7F:
         wait += (byte & 0xf)+1
         state = 1
      elif byte == 0xC0:
         state = 30  # PCM block
      else:
         print("Unknown code: %2.2x"% (byte))
         sys.exit()

   elif state == 10:
      if wait > 1000:
         print("Wait %d cycles"% ((wait+100)/7000))
         wait = 0
      print("YM2151 %2.2x : "% (byte), end = '')
      state = 11

   elif state == 11:
      print("%2.2x"% (byte))
      state = 1

   elif state == 20:
      assert byte == 0x66
      state = 21

   elif state == 21:
      # Ignore datatype
      state = 22

   elif state == 22:
      # Size (bits 7-0)
      size = byte
      state = 23

   elif state == 23:
      # Size (bits 15-8)
      size += byte << 8
      state = 24

   elif state == 24:
      # Size (bits 23-16)
      size += byte << 16
      state = 25

   elif state == 25:
      # Size (bits 31-24)
      size += byte << 24
      addr = byte_offset
      #print("Block of size %8.8x bytes"% (size))
      state = 26

   elif state == 26:
      # Skip block data
      if byte_offset == addr + size:
         state = 1

   elif state == 30:
      addr = byte # address LSB
      state = 31

   elif state == 31:
      addr += byte << 8 # address MSB
      state = 32

   elif state == 32:
      #print("Writing %2.2x to %4.4x PCM"% (byte, addr))
      state = 1

   elif state == 40:
      wait += byte
      state = 41

   elif state == 41:
      wait += byte << 8
      #print("Wait %d cycles"% (wait))
      state = 1

   else:
      print("Unknown state: %d"% (state))
      sys.exit()

   byte_offset += 1

