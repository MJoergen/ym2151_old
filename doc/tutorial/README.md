# YM2151 Tutorial

This is a tutorial on how to get started making music on a YM2151. 

## Overview

The YM2151 has eight parallel sound channels and each sound channel consists 
of the following:

* A key note selector. This selects the base frequency (pitch) to be played.
* A waveform generator. This selects the timbre of the note.
* An envelope generator. This selects the amplitude modulation of the note.

All three of the above must be configured, in order to get sound out of the
YM2151 chip.

Furthermore, the YM2151 has a dedicated noise generator as well as a vibraro
generator.

In the following each of these parts will be described briefly.

## Episode 1 - making a single constant sine wave

In this first episode we will learn how to select different notes to play.
This will be the "Hello World" for the YM2151.

### Communicating with the YM2151.
The YM2151 uses two I/O ports for communication, $9FE0 and $9FE1. The YM2151
internally has a 256-byte virtual memory map. To write a value to the YM2151,
first the register address must be written to $9FE0, and then the register value
must be written to $9FE1.

For instance, the following sequence
```
POKE $9FE0, $28: POKE $9FE1, $4A
```
writes the register value $4A to the register address $28. This particular
command instructs the YM2151 to play the A4 note, which corresponds to 440 Hz.

### Configuring the YM2151.
As noted in the introduction the waveform generator and envelope generator must
be configured before the YM2151 will output any sounds. The bare minimum is
the following sequence of commands, which configures channel 0 to generate
a simple sine wave:
```
POKE $9FE0, $20: POKE $9FE1, $C7
POKE $9FE0, $80: POKE $9FE1, $1F
POKE $9FE0, $E0: POKE $9FE1, $0F
POKE $9FE0, $08: POKE $9FE1, $08
```
The above commands will all be explained in the following episodes of this
tutorial.  In this episode, we will focus on selecting which note to play.

### The note selector.
The key (base frequency) is made up of an octave selector (bits 6-4 of register
$28) and a semitone selector (bits 3-0 of register $28).  The chip supports 8
octaves, with 12 semitones within each octave.

The semitone selector is encoded as follows:

|  Note |  Value |
| ----- | ------ |
|   C#  |    0   |
|   D   |    1   |
|   D#  |    2   |
|   E   |    4   |
|   F   |    5   |
|   F#  |    6   |
|   G   |    8   |
|   G#  |    9   |
|   A   |   10   |
|   A#  |   12   |
|   B   |   13   |
|   C   |   14   |

The tone A4 (frequency of 440 Hz) is thus achieved by using the values 4 for the
octave selector and 10 for the semitone selector.  This corresponds to writing
the value $4A to the register $28, which is achieved by the following command:
```
POKE $9FE0, $28: POKE $9FE1, $4A
```

To play the slightly higer pitched E5 note, use the command:
```
POKE $9FE0, $28: POKE $9FE1, $54
```

## Episode 2 - Configuring the ADSR envelope.
Each channel has an associated envelope generator that controls the amplitude
modulation of the output.

The waveform is characterized by the following five parameters.
* Attack rate (AR)
* Decay rate (D1R)
* Sustain level (D1L)
* Sustain rate (D2R)
* Release rate (RR)
as well as the events "Key On" and "Key Off".

The first four parameters control the envelope after a "Key On" event, while the
last parameter controls the envelope after a "Key Off" event.

### ADSR envelope
When a "Key On" event is issued the envelope generated consists of the
following three phases:
1. "Attack phase" : The amplitude increases linearly up to the maximum at a
rate given by the "Attack Rate" parameter.
2. "Decay phase" :  The amplitude decreases exponentially at a rate given by
"Decay Rate" down to the level given by "Sustain Level".
3. "Sustain phase" : The amplitude decreases further at a rate given by
"Sustain Rate".  When a "Key Off" event is issued the envelope enters the last
phase:
4. "Release phase" : The amplitude decreases at a rate given by "Release Rate".

To get a square envelope (i.e. maximum volume right after "Key On", and no
output right after "Key Off"), the following values suffice: Writing the value
$1F to register $80 (Maximum Attack Rate), and the value $FF to the register
$E0 (Maximum Release Rate, and Maximum Decay Attentuation).

To get a sound that more closely resembles a string instrument, where the
volume of the note slowly decays, one can add a first decay rate of $0A to the
settings. This corresponds to writing the value $0A to register $A0.

The "Key On" event is triggered by writing the value $08 to the register $08.
The "Key Off" event is triggered by writing the value $00 to the register $08.


### The waveform generator
The timbre of the tone is controlled by four sine wave generators that can be
connected in various ways.

The four sine wave generators are named "Modulator 1", "Carrier 1", "Modulator 2",
and "Carrier 2".

They can be combined in series (composition of functions) or in parallel
(additive). Additionally, the generator "Modulator 1" has a built-in feedback
loop.

Each of the eight sound channels has a register containing the connection
function.  These are located in addresses $20 to $27, where bits 2-0 are the
connection function. In the same register, bit 7 enables the right output and
bit 6 enables the left output. Bits 5-3 control the feedback on Modulator 1.

The connection function has the following interpretation:

0. C2( M2( C1(M1) ) )
1. C2( M2(C1 + M1) )
2. C2( M2(C1) + M1 )
3. C2( M2 + C1(M1) )
4. C1(M1) + C2(M2)
5. C1(M1) + M2(M1) + C2(M1)
6. C1(M1) + M2 + C2
7. M1 + C1 + M2 + C2

To get a pure sine wave on the output, it is enough to write the value $C7 to
the register $20. This configures all four sine waves in a parallel connection,
and we will only be using the "Modulator1" generator.

## Summary
To play a single A4 note the following writes can be used:
* Write $1F to $80. Maximum Attack Rate for "Modulator1" on channel 0.
* Write $0A to $A0. First Decay Rate for "Modulator1" on channel 0.
* Write $FF to $E0. Maximum Release Rate for "Modulator1" on channel 0.
* Write $C7 to $20. Select connection mode 7 on channel 0.
* Write $4A to $28. Select key A4 on channel 0.
* Write $08 to $08. Trigger "key-on" on channel 0.

## The register interface:
| Address |  Bits  | Function | Description       | Abbreviation |
| ------- | ------ | -------- | ----------------- | ------------ |
|  $01    |   1    | Vibrato  | LFO reset         | TEST         |
|  $08    |  2-0   | Key      | Channel select    | CH #         |
|         |   3    |          | Carrier 2         | SM KON       |
|         |   4    |          | Modulator 2       | SM KON       |
|         |   5    |          | Carrier 1         | SM KON       |
|         |   6    |          | Modulator 1       | SM KON       |
|  $0F    |   7    | Noise    | NE                | NE           |
|         |  4-0   |          | Noise frequency   | NFRQ         |
|  $10    |  7-0   | General  | Timer A1          | CLKA1        |
|  $11    |  1-0   | General  | Timer A2          | CLKA2        |
|  $12    |  7-0   | General  | Timer B           | CLKB         |
|  $14    |   7    | General  | CSM               |              |
|         |  5-4   |          | F Reset           |              |
|         |  3-2   |          | IRQ Enable        |              |
|         |  1-0   |          | Load              |              |
|  $18    |  7-0   | Vibrato  | LFO frequency     | LFRQ         |
|  $19    |   7    | Vibrato  | Select            |              |
|         |  6-0   |          | Modulation depth  | PMD/AMD      |
|  $1B    |   7    | General  | CT2               |              |
|         |   6    | General  | CT1               |              |
|         |  1-0   | Vibrato  | LFO waveform      | W            |
|  $20    |   7    | Waveform | Right             |              |
|         |   6    | Waveform | Left              |              |
|         |  5-3   | Waveform | FB                |              |
|         |  2-0   | Waveform | Connect           |              |
| $28-$2F |  6-4   | Key      | Octave            | KC           |
|         |  3-0   | Key      | Note              | KC           |
| $30-$37 |  7-2   | Key      | Fraction          | KF           |
| $38-$3F |  6-4   | Vibrato  | PMS               |              |
|         |  1-0   | Vibrato  | AMS               |              |
| $40-$5F |  6-4   | Key      | Detune1           | DT1          |
|         |  3-0   | Key      | Phase Multiply    | MUL          |
| $60-$7F |  6-0   | Envelope | Total level       | TL           |
| $80-$9F |  7-6   | Envelope | Key Scale         | KS           |
|         |  4-0   | Envelope | Attack Rate       | AR           |
| $A0-$BF |   7    | Vibrato  | AM sensitivity    | AMS-EN       |
|         |  4-0   | Envelope | First Decay Rate  | D1R          |
| $C0-$DF |  7-6   | Key      | Detune2           | DT2          |
|         |  3-0   | Envelope | Second Decay Rate | D2R          |
| $E0-$FF |  7-4   | Envelope | First Decay Level | D1L          |
|         |  3-0   | Envelope | Release Rate      | RR           |


## Advanced stuff
There are a few other registers that influence the base frequency. These are:
KF, MUL, DT1, DT2, and PMS.

## References
This is based on the [original
documentation](http://map.grauw.nl/resources/sound/yamaha_ym2151_synthesis.pdf),
as well as the [MAME emulation](https://github.com/mamedev/mame/).


