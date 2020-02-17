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
This will be the "Hello World" for the YM2151!

### Communicating with the YM2151 on the Commander X16.
The Commander X16 assigns two I/O ports for communicating with the YM2151:
$9FE0 and $9FE1. The YM2151 internally has a 256-byte virtual memory map. To
write a value to the YM2151, first the register address must be written to
$9FE0, and then the register value must be written to $9FE1.

For instance, the following sequence
```
POKE $9FE0, $28: POKE $9FE1, $4A
```
writes the value $4A to the virtual register address $28.

### Configuring channel 0 to play a simple sine save.
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

The tone A4 (frequency of 440 Hz) is achieved by using the value 4 for the
octave selector and the value 10 for the semitone selector.  This corresponds
to writing the value $4A to the register $28, which is achieved by the
following command:
```
POKE $9FE0, $28: POKE $9FE1, $4A
```

To play the slightly higher pitched E5 note, use the command:
```
POKE $9FE0, $28: POKE $9FE1, $54
```

All this is shown in the BASIC source file [tutorial1.bas](tutorial1.bas)

Now you can play individual notes on the YM2151!

## Episode 2 - Amplitude modulation
Each channel has an associated envelope generator that controls the amplitude
modulation of the output.

The waveform (also called "ADSR envelope") is characterized by the following
five parameters:
* Attack rate (bits 4-0 of register address $80)
* Decay rate (bits 4-0 of register address $A0)
* Sustain attenuation (bits 7-4 of register address $E0)
* Sustain rate (bits 4-0 of register address $C0)
* Release rate (bits 3-0 of register address $E0)

as well as the events "Key On" and "Key Off" (bit 3 of register address $08).

The first four parameters control the envelope after a "Key On" event, while
the last parameter controls the envelope after a "Key Off" event.

### ADSR envelope
When a "Key On" event is issued the envelope generated consists of the
following three phases:
1. "Attack phase" : The amplitude increases linearly up to the maximum at a
rate given by the "Attack Rate" parameter.
2. "Decay phase" :  The amplitude decreases exponentially at a rate given by
"Decay Rate" until the attenuation reaches the level given by "Sustain
attenuation".
3. "Sustain phase" : The amplitude decreases further at a rate given by
"Sustain Rate".

When a "Key Off" event is issued the envelope enters the last phase:
4. "Release phase" : The amplitude decreases at a rate given by "Release Rate".

To get a square envelope (i.e. maximum volume right after "Key On", and no
output right after "Key Off"), the following values suffice: Writing the value
$1F to register $80 (maximum Attack Rate), and the value $FF to the register
$E0 (maximum Release Rate, and maximum Sustain Attentuation).
```
POKE $9FE0, $80: POKE $9FE1, $1F
POKE $9FE0, $E0: POKE $9FE1, $FF
```
Those were exactly the values used in Episode 1 of the tutorial.

To send the "Key On" event write the value $08 to address $08:
```
POKE $9FE0, $08: POKE $9FE1, $08
```

To send the "Key Off" event write the value $00 to address $08:
```
POKE $9FE0, $08: POKE $9FE1, $00
```

To get a sound that more closely resembles a string instrument, where the
volume of the note slowly decays, one can add a Decay Rate of $0A to the
settings. This corresponds to writing the value $0A to register $A0.
```
POKE $9FE0, $A0: POKE $9FE1, $0A
```

All this is shown in the BASIC source file [tutorial2.bas](tutorial2.bas)


## Episode 3 - Controlling multiple channels
The YM2151 has eight independent channels (numbered 0 - 7), but the addressing
of these channels is somewhat convoluted. For most registers the lowest three
address bits determine the channel number. So for instance, the Key Code selector
for the eight channels are located in addresses $28 to $2F.

The one major difference is the Key On/Off register, where it is bits 2-0 of
the *value* that determines the channel. The register address is always the
same, i.e. $08.  So to send a Key On event to channel 1 you must write the
value $09 to register $08.

In this episode I will show a little [program](music.bas) that can play a
simple tune on the YM2151 using four channels.  One channel is for the melody
and the other three channels are for the accompaning chord. The idea with this
program is that it should be ease to modify for your own needs.

The program consists of two parts: Initialization and Musical Score. We'll
discuss each of these in the following:

### Initialization.
So far we have considered the following five registers for initializing a
channel:
* $2x : Waveform configuration. Set to $C7 for a simple sine wave.
* $8x : Attack Rate.
* $Ax : Decay Rate.
* $Cx : Sustain Rate.
* $Ex : Sustain Level and Release Rate.

where x is the channel number 0-7.

Since each of the four channels can have a separate configuration, and to make
the initialization generic, I've written the values in a number of DATA
statements in lines 1000-1310. Each line consists of five values that are
written to the above registers.

The actual writing to the YM2151 takes place in lines 800-960.

### Musical Score
The musical score is written in DATA statements in lines 2000-2700. To make it
easy to read and modify the music, I've chosen the following representation:
* Each line consists of the notes to play for each of the four channels.
* Eight lines represent one bar of the music.
* A note is represented in
  [https://en.wikipedia.org/wiki/Scientific_pitch_notation](scientific pitch
  notation).
* An empty string means the note continues from the previous line.

The above representation requires some processing to convert it into equivalent
writes to the YM2151.

First of all, reading each line of the musical score takes place in lines
1500-1580. The variable TI is the jiffie counter, which automatically
increments 60 times a second. The variable NT denotes when to proceed to the
next line, and this is updated in line 1570. In other words, this is where the
pace of the music is controlled.

Lines 1520-1560 loop over the four channels, and checks whether a new note is
to be processed, in which case it jumps to the routine in lines 1600-1670.
Here the note is expected to be in the variable N$ and the channel number in
the variable C.

Lines 1610-1630 serve to convert the string into a key code number. This is
done in comjunction with the array N() defined in lines 1400-1460.  The trick
is that the semitone variable K is a number from 0 to 6 corresponding to the
notes A to G. Each number is then mapped to the corresponding key code for the
YM2151. Finally, the note C is special in that the YM2151 considers it to
belong to a previous octave, and therefore we must decrement the octave number
in line 1630.

And that is it! You can now program the YM2151 to play any tune you like.

## Episode 4 - The waveform generator (part 1)

The way the YM2151 generates the waveform is quite convoluted, so we'll start
with something easy - feedback.

=====================================================================


Furthermore, the overall volume of the channel is controlled by the "Total level".

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


