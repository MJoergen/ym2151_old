# YM2151 tutorial

This is a tutorial on how to get started making music on a YM2151. 

## Overview

The YM2151 has eight parallel sound channels and each sound channel consists 
of the following:

* A key note selector. This selects the base frequency (pitch) to be played.
* A waveform generator. This selects the timbre of the note.
* An envelope generator. This selects the amplitude modulation of the note.

Each of the eight sound channels can individually be directed to either or both
of the left and right outputs.

Furthermore, the YM2151 has a dedicated noise generator as well as a vibraro
generator.

In the following each of these parts will be described briefly.

### The key note selector.
The key (base frequency) is made up of an octave selector (3 bits) and a
semitone selector (4 bits).  The chip thus supports 8 octaves, and 12 semitones
within each octave.

The semitone selector is encoded as follows:

| Semitone |  Value |
| -------- | ------ |
|    C#    |    0   |
|    D     |    1   |
|    D#    |    2   |
|    E     |    4   |
|    F     |    5   |
|    F#    |    6   |
|    G     |    8   |
|    G#    |    9   |
|    A     |   10   |
|    A#    |   12   |
|    B     |   13   |
|    C     |   14   |

Each of the eight sound channels has a register containing the key note
selector. These are located in addresses $28 to $2F, where bits 3-0 are the
semitone selectir, and bits 6-4 are the octave selector.

The tone A4 (frequency of 440 Hz) is achieved by using the values 4 for the
octave selector and 10 for the semitone selector.  This corresponds to writing
the value $4A to the register $28.

### The waveform generator
The timbre of the tone is controlled by four sine wave generators that can be
connected in various ways.

The four sine wave generators are named "Modulator 1", "Carrier 1", "Modulator 2",
and "Carrier 2".

They can be combined in series (composition of functions) or in parallel
(additive). Additionally, the generator "Modulator 1" has a built-in feedback
loop.

Each of the eight sound channels has a register containing the connection
function.  These are located in address $20 to $27, where bits 2-0 are the
connection function. In the same register, bit 7 enables the right output and
bit 6 enables the left output. Bits 6-4 control the feedback on Modulator 1.

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

### The envelope generator
Each of the four sine wave generators have an associated envelope generator
that controls the attenuation of the output.

The waveform is parametrized by the following five numbers:
* Attack rate (AR)
* First decay rate (D1R)
* First decay level (D1L)
* Second decay rate (D2R)
* Release rate (RR)

The first four values control the envelope after a "key-on" event, while the
last value controles the evelope after a "key-off" event.

To get a square envelope (i.e. maximum volume right after "key-on", and no
output right after "key-off"), the following values suffice: Writing the value
$1F to register $98 (Maximum Attack Rate), and the value $FF to the register
$F8 (Maximum Release Rate, and Maximum Decay Attentuation).

To get a sound that more closely resembles a string instrument, where the
volume of the note slowly decays, one can add a first decay rate of $0A to the
settings. This corresponds to writing the value $0A to register $B8.

The "key-on" event is triggered by writing the value $40 to the register $08.
The "key-off" event is triggered by writing the value $00 to the register $08.

## Summary
To play a single A4 note the following writes can be used:
* Write $1F to $98. Maximum Attack Rate for "Carrier2" on channel 0.
* Write $0A to $B8. First Decay Rate for "Carrier2" on channel 0.
* Write $FF to $F8. Maximum Release Rate for "Carrier2" on channel 0.
* Write $C7 to $20. Select connection mode 7 on channel 0.
* Write $4A to $28. Select key A4 on channel 0.
* Write $40 to $08. Trigger "key-on" on channel 0.

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


