#! /usr/bin/env python

# This converts a binary file into a text file written in hexadecimal with each
# byte on a single line.
# This is used to initialize memory.
#
# Usage: ./bin2hex.py <source> <dest>

import sys
import struct

infilename = sys.argv[1]
outfilename = sys.argv[2]

result = []

with open(infilename, "rb") as f:
    data = f.read(2)
    while data:
        num = struct.unpack(">H", data)[0]
        h = format(num, '04x')
        result.append(h)
        data = f.read(2)

fl = open(outfilename, "w")
for i in result:
    fl.write(i+"\n")
fl.close()

