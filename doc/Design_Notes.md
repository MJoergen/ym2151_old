# Design considerations

I initially started this project just writing a lot of code, but I gradually
realized that was the wrong approach. I need to first think of data
representation and signal widths and resolution.

## Audio signal generation

So let's start with the Nexys 4 DDR board. The audio output is a single bit
from the FPGA, which is passed through a 4th-order low pass filter at 15 kHz.
So to synthesize an audio signal, Pulse Width Modulation can be used. In this
approach the output bit is a single full-height digital pulse, but with a width
proportional to the analog value. The low-pass filter will then smooth out this
digital signal, essentially removing all the high frequency components.

The YM2151 chip itself works entirely differently. It has a serial output, with
a sampling frequency of 3.579545 MHz / 2 / 32 = 55.930 kHz.

## Pulse Width Modulation

The PWM module will take as input an analog value, represented as a fraction
between 0 and 1 that is encoded as an unsigned integer.  The PWM module works
in combination with the low-pass filter to give an approximate
Digital-To-Analog effect. In other words, the fractional analog value is
converted into a full-height digital pulse, but with a width proportional to
the analog value. The low-pass filter then converts this to a proportional
analog voltage on the audio output.

Note that there is a tradeoff between resolution in the time domain (i.e.
frequency response) and resolution in the voltage domain (i.e. signal-to-noise
ratio). With a PWM sampling rate of 100 MHz and an audio cutoff frequency of 15
kHz, the signal-to-noise ratio on the output of the PWM is 100000/15 ~= 6600.
I've therefore decided to use a density resolution of 12 bits, which gives a
signal-to-noise ratio of 4192.  With 6 dB for each bit, this corresponds to 72
dB. This is the constant C\_PWM\_WIDTH.

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
the input to the PWM module must be synchronous to the onboard clock. So
there must be a CDC between the YM2151 module and the PWM module.

## Signed values and two's complement
Since the sin function generates values in the interval -1 to 1, we will be
dealing with signed values. These signed values will be scaled to signed
integers and represented using two's complement. So there must be a conversion
from signed value (from the sin function) to an unsigned value (to the PWM
module).  Fortunately, this is easily done by inverting the MSB of the
corresponding integer.

So we have the following correspondence:

| signed | 2's comp |  pwm  |
| ------ | -------- | ----- |
|   -1   |  0x800   | 0x000 |
|   ~0   |  0xFFF   | 0x7FF |
|    0   |  0x000   | 0x800 |
|    1   |  0x7FF   | 0xFFF |

## Overflow and clipping
Since the YM2151 has eight channels that can generate sound simultaneously, the
resulting output waveform is the addition of each component. This addition
operation may overflow, and to resolve that we must apply clipping, i.e. if a
value increases beyond the maximum value, then we must cap of the waveform at
the maximum value.

However, this leads to severe distortion even when using only two sounds
channels.  To mitigate this, the YM2151 reduces the amplitude of each channel
by a factor of 4.  In practice, this works very well, and only in a few special
cases will it be necessary to do any clipping.

Checking the YM2151 emulator shows that a single sine-wave at no attenuation
has an output range of +/- 8191, which is a factor of 4 less than the maximum.
This is confirmed by analyzing in audacity, which shows an output power
amplitude of -12 dB.
This kind of makes sense, because otherwise, as soon as two channels becomes
active, there would be severe distortion due to clipping.

## Amplitude Modulation

The two main components of the YM2151 are the Sine Wave Generator and the
Envelope Generator.  The Envelop Generator acks to modulate the amplitude of
the signal from the Sine Wave Generator.  The audio output can be obtained by
multiplying the values from these two components. In the original chip this is
achieved by using lookup tables with logarithms and exponentials. But on the
Nexys4DDR we will make use of the built-in DSPs. They fortunately are built for
handling signed numbers.

## Sine Wave Generation

The sine wave generator takes as input a (fractional) phase, and the output is
the function sin(2\*pi\*phase).  The phase will therefore be a value between 0
and 1, and the output will be between -1 and 1. So what should the accuracy
(resolution) of the input and output values be?

Well the output of this module feeds directly into the PWM module (ignoring for
the moment the Envelope Generator), so the output should have 12 bits as well.
This is the constant C\_SINE\_DATA\_WIDTH.

The output is interpreted as a signed integer in twos complement, so we have
the following correspondences:

| phase |   sine | 2's comp |
| ----- |  ----- | -------- |
| 0.000 |  0.000 |  0x000   |
| 0.250 |  1.000 |  0x1FF   |
| 0.750 | -1.000 |  0xE01   |

The output value is therefore scaled by 0x1FF, i.e. by
2^(C\_SINE\_DATA\_WIDTH-3) - 1. Note that in the above table, the output value
has been scaled down by a factor of 4, to avoid overflow when combining
multiple channels.

The sine wave generator is implemented as a big lookup table (ROM).
The data width of this ROM should be 12 bits as mentioned above.
We would like the same dynamic range on input and output, so the input range [0, 0.25]
should match the output range [0, 1]. This output range consumes 11 bits of resolution,
and corresponds to a quarter of the input range. This leads to an input resolution
of 13 bits.

The size of this ROM will be 12\*2^13 = 96 kbits, which fits in 3 BRAMs.

## Frequency Generation

The note frequency is interpreted as 1 complete phase pr second, and the clock
frequency is cycles pr second, so the quotient of the note frequency and the
clock frequency gives the (fractional) number of phases pr clock cycle.  This
fractional value is scaled up by a factor of 2^24 and then rounded to the
nearest integer.

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

Each octave doubles the frequency, and this calculation can be readily
done by shifts. So only the notes within a single octave need be stored
in the ROM.

The above conversion is implemented in ROM, except that the Octave is not part
of the input. This is because the Octave corresponds to multiples of 2, and
this can be calculated using simple shifts.

It turns out that scaling with 2^24 yields distinct integers in the range 1116
to 2230. From this we get that the ROM should have 12 bits of output to
accommodate values in this range.

## Envelope Generator

A big part of the YM2151 is the envelope generator, the so-called ADSR-profile,
consisting of Attack, Decay, Sustain (also called Second Decay), and Release.
The last three steps all employ exponential decay. To confirm my
understanding of the documentation for the YM2151 I have made some experiments
with the emulator.

### Experiments with the emulator
Choosing a decay rate of $0B and a key code of $4A, the output volume is
measured to decrease at a rate of 96 dB pr 1795 ms.  This is a factor of two
different from the documentation, which gives the value 3444 ms for the
corresponding rate constant of 6:0, i.e. 11\*2+2 = 24. I suspect this is a bug
in the emulator.

Repeating the experiment with a decay rate of $0C gives a decay rate of 96 dB /
1100 ms, which corresponds to the decay rate of 96 dB / 2200 ms in the
documentation, where the rate constant is 6:2, i.e. 12\*2+2 = 26.

### Attenuation
Attenuation can be achieved by using a DSP to multiply the sine output by a
decaying factor. The decay itself can then be achieved by a simple shift and
subtract.  For instance, a shift by 6 and subsequent subtract gives a decay
factor of 1-2^(-6), which is the same as 0.136 dB.

The output resolution is 12 bits, which corresponds to 72 dB.  So to achieve
full attenuation of 72 dB requires 72/0.136 = 529 reductions. However, the
attenuation factor must have a significant amount of precision for this to
work. In fact, the precision of the attenuation factor must be the sum of the
output resolution (12 bits) and the shift (6 bits), so a total of 18 bits.
This fits nicely with the capabilities of a single DSP.

### Rate constant
The YM2151 chip uses a total of 64 different rate constants, where the rate constant
is defined as time (in ms) for output voltage attenuation of 96 dB. Some
selected values are:

| constant | rate (ms/96dB) |
| -------- | -------------- | 
|    63    |         6.73   |
|    62    |         6.73   |
|    61    |         6.73   |
|    60    |         6.73   |
|    59    |         7.49   |
|    56    |        13.45   |
|    52    |        26.91   |
|     8    |     55104.85   |
|     4    |    110209.71   |
|     3    |  infinity      |
|     0    |  infinity      |

So the dynamic range is really from 6.73 ms to infinity, corresponding to the
rate constants of 60 to 3. The rate increases by a factor of 2 for each
increase of 4 in rate constant.

In our implementation we will convert the rate constants into number of clock
cycles between each attenuation (i.e. 0.136 dB).  For the rate constant 4 this
is 110209.71 ms/(96 dB) * 0.136 dB/iter * 8333.333 cycles/ms = 1301087
cycles/iter, which fits with 21 bits.

So the attenuation cycle (shift 6 and subtract) will be applied once every this
many clock cycles, and that will lead to an attenuation rate corresponding to
the rate constant 4. A rate constant four higher (i.e. 8) has a delay exactly
half that number of clock cycles.

A rate constant of just one higher is achieved by dividing the required clock
cycle delay by 2^0.25. This will be implemented by having a total of four
different delay constants, corresponding to each of the four possible factors
of 2^0.25.

## Attack rate
Measuring using the emulator gives an attack time (from -96 dB to 0 dB) of
approx 390 ms, when using an attack rate of 7 and a key note of $6A.

## TODO
* Do some more work on the tutorial.
* Add key scaling to the rate calculations.
* Add combining within a singla channel (the connection register).
* Check Sustain Level, and implement Total Level.
* Implement Feedback.


