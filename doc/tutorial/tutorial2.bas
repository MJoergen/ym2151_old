10 REM THIS PROGRAM IS PART 2 OF THE YM2151 TUTORIAL.

100 REM CHANNEL 0 SINE WAVE GENERATION
110 POKE $9FE0, $20: POKE $9FE1, $C7

200 REM CHANNEL 0 ATTACK RATE
210 POKE $9FE0, $80: POKE $9FE1, $1F

220 REM CHANNEL 0 DECAY RATE
230 POKE $9FE0, $A0: POKE $9FE1, $0A

240 REM CHANNEL 0 SUSTAIN LEVEL, RELEASE RATE
250 POKE $9FE0, $E0: POKE $9FE1, $FF


300 REM CHANNEL 0 KEY CODE (E5)
310 POKE $9FE0, $28: POKE $9FE1, $54

320 REM CHANNEL 0 KEY ON
330 POKE $9FE0, $08: POKE $9FE1, $08

