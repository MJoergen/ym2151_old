# The YM2151 module

This directory contains the VHDL source code for the YM2151 module.

This file contains a user guide on how to use the YM2151 module.  This is based
on the [original documentation](doc/yamaha_ym2151_synthesis.pdf), as well as
the [MAME emulation](https://github.com/mamedev/mame/).

At [this document](Register_Interface.md) is the complete register interface.

I've written a separate document with the [notes on the design](Design_Notes.md).

## Directory structure

* src : Contains source files for the YM2151 module
* doc : Contains documentation
* nexys4ddr : Contains board specific files to build the Example Design for the Nexys 4 DDR board from Digilent.
* sim : Contains testbench and other files used during simulation.


## User guide

The YM2151 has eight parallel sound channels and each sound channel consists 
of the following
* A key note selector. This selects the base frequency (pitch) to be played.
* A waveform generator. This selects the timbre of the note.
* An envelope generator. This selects the amplitude modulation of the note.

Outside this, the YM2151 has a dedicated noise generator as well as a vibraro
generator.

## The key note selector.

