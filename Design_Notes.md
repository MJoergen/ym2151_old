# Design considerations

I initially started this project just writing a lot of code, but I gradually
realized that was the wrong approach. I need to first think of data
representation and signal widths and resolution.

## Audio signal generation

So let's start with the Nexys 4 DDR board. The audio output is a single bit
from the FPGA, which is passed through a 4th-order low pass filter at 15 kHz.
So to synthesize an audio signal, Pulse Density Modulation can be used. In this
approach the output bit rapidly switches on and off, and the low pass filter
will then smooth out this digital signal, essentially removing all the high
frequency components.

The switching rate of the PDM signal should be as high as possible, and for
convenience I have chosen to use the FPGA input clock of 100 MHz.

## Pulse Density Modulation

The PDM module will take as input a density, represented as a fraction between
0 and 1 that is encoded as an unsigned integer.  The PDM module works in
combination with the low-pass filter to give an approximate Digital-To-Analog
effect. In other words, the density value is roughly translated into a
proportional analog voltage on the audio output.

Note that there is a tradeoff between resolution in the time domain (i.e.
frequency response) and resolution in the voltage domain (i.e. signal-to-noise
ratio). With a PDM sampling rate of 100 MHz and an audio cutoff frequency of 15
kHz, the signal-to-noise ratio on the output of the PDM is 100000/15 ~= 6600.
I've therefore decided to use a density resolution of 12 bits, which gives a
signal-to-noise ratio of 4192.  With 6 dB for each bit, this corresponds to 72
dB. This is the constant C\_PDM\_WIDTH.

So we have the following correspondence:

| input | output |
| ----- | ------ |
| 0x000 | 0      |
| 0x800 | 0.5 (approx)   |
| 0xFFF | 1.0    |

The important part is that all-zeros or all-ones on the input correspond to a
"flat line" on the output, i.e. steady zero or steady one, respectively.

## Clock Domain Crossing
The entire YM2151 will be running at the CPU clock frequency because this
makes it easier to handle the CPU writes to the YM2151 registers. However,
the input to the PDM module must be synchronous to the onboard clock. So
there must be a CDC between the YM2151 module and the PDM module.

## Two's complement
Since the sin function generates values in the interval -1 to 1, we will be
dealing with signed values. These signed values will be scaled to signed
integers and represented using two's complement. So there must be a conversion
from signed value (from the sin function) to an unsigned value (to the PDM
module).  Fortunately, this is easily done by inverting the MSB of the
corresponding integer.

So we have the following correspondence:

| 2's comp | pdm |
| -------- | ------ |
| 0x800    | 0x000 |
| 0xFFF    | 0x7FF |
| 0x000    | 0x800 |
| 0x7FF    | 0xFFF |

## Multiplication

The two main components of the YM2151 are the Sine Wave Generator and the
Envelope Generator. The audio output is obtained by multiplying the values
from these two components. In the original chip this is achieved by using
lookup tables with logarithms and exponentials. But on the Nexys4DDR we will
make use of the built-in DSPs. They fortunately are built for handling signed
numbers.

## Sine Wave Generation

The sine wave generator takes as input a (fractional) phase, and the output is
the function sin(2\*pi\*phase).  The phase will therefore be a value between 0
and 1, and the output will be between -1 and 1. So what should the accuracy
(resolution) of the input and output values be?

Well the output of this module feeds directly into the PDM module (ignoring for
the moment the Envelope Generator), so the output should have 12 bits as well.
This is the constant C\_SINE\_DATA\_WIDTH.

The output is interpreted as a signed integer in twos complement, so we have
the following correspondences:

| phase |   sine |  output |
| ----- |  ----- |  ------ |
| 0.000 |  0.000 |  0x000  |
| 0.250 |  1.000 |  0x7FF  |
| 0.750 | -1.000 |  0x801  |

The output value is therefore scaled by 0x7FF, i.e. by
2^(C\_SINE\_DATA\_WIDTH-1) - 1.  Note that the output 0x800 never occurs.

The sine wave generator is implemented as a big lookup table (ROM).
The data width of this ROM should be 12 bits as mentioned above.
We would like the same dynamic range on input and output, so the input range [0, 0.25]
should match the output range [0, 1]. This output range consumes 11 bits of resolution,
and corresponds to a quarter of the input range. This leads to an input resolution
of 13 bits.

The size of this ROM will be 12\*2^13 = 96 kbits, which fits in 3 BRAMs.

## Frequency Generation

The YM2151 generates frequencies from key values. It uses the following values:

* Octave (3 bits)
* Semitone (4 bits)
* Key Fraction (6 bits)

So a total of 13 bits to determine the frequency. This frequency is then
converted to a fractional phase increment by scaling with the clock frequency
of the module.

The desired frequency corresponds to 1 phase pr second, and the clock frequency
is cycles per second, so the quotient gives the (fractional) number of phases per
clock cycle.

There are 64 fractions in a semitone, and 12 semitones in an octave. Therefore
there are 768 fractions in an octave, and each fraction increases the frequency
by a factor of 2^(1/768) ~= 1.0009.

The note A4 has a frequency of 440 Hz.  The first index is C#0, which is 4
semitones above, but 5 octaves lower than A4. So C#0 has a frequency of around
17.3 Hz.

The conversion from key value to fractional phase increment is based on a
lookup table implemented in ROM. The input to this lookup table is the number
of fractions above C#, disregarding the octave.  This is because the Octave
corresponds to multiples of 2, and this can be calculated using simple shifts.

There are 768 fractions within an octave, so the address to this
phase\_increment ROM should have 10 bits. The output of this ROM contains the
fractional phase increment scaled up to an integer. It turns out that scaling
with 2^29 yields distinct integers in the range 1116 to 2230. From this we get
that the ROM should have 12 bits of output to accommodate values in this range.

The total size of the ROM becomes 12\*2^10 = 12 kbits, which fits within one
BRAM.

## Envelope Generator

A big part of the YM2151 is the envelope generator, the so-called ADSR-profile,
consisting of Attack, Decay, Sustain (also called Second Decay), and Release.
The last three steps all employ exponential decay. One common way to implement
the exponential decay is to store the sign and absolute logarithm of the value.
The exponential decay can be implemented as a simple subtraction.

As a consequence, we need an easy way to compute the exponential of a function.
This is done by a ROM.  So what should be the address and data widths of this
ROM?  Well, the output of the ROM is always a positive number, so must be
augmented with the sign. Therefore the width of the ROM need only be 11 bits.
This is the constant C\_EXP\_WIDTH.


