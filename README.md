# retrobench v0.1
Benchmarks for Retro CPU

I'm a big fan of retro gaming and retro computing, I own several old school consoles and computers, and I was always curious of how the CPU of these old machines compare.
For example, comparing a 1MHz 6502 CPU to a 6809 CPU or even against a Z80.
Comparing an Atari ST 68000 to a Sega Genesis / Megadrive 68000.
How faster is a PC Engine 6502 derivative compared to a stock 6502.
How the Intel Pentium 75MHz compares to the Motorola 68060 @ 75MHz.
Can we compare a PS1 RISC 3000 CPU @ 33MHz to an Atari Jaguar RISC CPU @ 23MHz or even a GBA ARM7TDMI @ 16MHz ?
so much questions not answered... until now!

Each benchmark is predefined as a fixed algorithm in C for validation.
Then each of these benchmark are hand written in assembly for the specific target CPU.
Then you have templates for each target platform embedding the corresponding benchmark CPU assembly routine.

All is written in assembly language because you cannot trust a C compiler.
Let's say we do a benchmark in C and compile it using the latest GCC 15, then years later we use a new version of GCC and the generated code is faster, our benchmark will be invalidated.
Also, several old 8bits CPU are really not C compiler friendly.
So we stay with assembly.

I'm not an assembly language expert so this is open source and you can contribute to make better assembly routines.
at ONE condition: DO NOT CHEAT! (do not use pre-computed tables)
For example, the 6502 doesn't have a MUL or DIV instruction, we could use pre-computed tables, but that would annihilate the advantage of other CPUs having a MUL instruction.
See, I made 2 type of benchmarks, one using the common assembly instructions that almost all CPU have, so we can compare every CPU using the common trunk.
Then I made another benchmark using the MUL instruction, so we can compare the CPU that have an advantage over the other ones, for example if you found that the 6809 is slower than the 6502 using the common assembly instructions, that is not really fair as the 6809 have advantage over the 6502 for example on the MUL instruction, so I made a benchmark measuring that advantage, if you cheat on the 6502 benchmark using precomputed tables, then you should also use precomputed tables on the 6809 benchmark and thus annihilate the advantage of its MUL instruction.

Target platforms	CPU	MHz	Status
Apple 1 replica		6502	1	TODO
Atari 2600		6507	1.19	done (not enough ram for ram benchmark)
Thomson MO5		6809	1	TODO
PC Engine		HuC6280	7.16	TODO
Megadrive PAL		68000	7.67	TODO
Atari ST		68000	8	done
Atari Falcon		68030	16	done
GameBoy Advance		ARM7	16	TODO
Playstation 1		R3000	33.8688	TODO
Atari Falcon CT60	68060	75	done
PC DOS			Pentium	75	done

Benchmark type:
CPU: For this benchmark we use the Collatz algorithm, which is very simple to implement, it use a variety of basic instructions such as addition, shift, bit testing, conditionnal jump.
We add a CRC8 computation to verify the data output from the Collatz algorithm, the CRC8 is performed bit by bit to keep a pure CPU implementation (no lookup table used)
The Collatz algorithm is run from 1 to 446 included (because from 447 the result number overflows an int16)

RAM: For this benchmark we generate a table of 15000 8bits random numbers from a predictive algorithm.
We then process an insert sort algorithm on this table (which is pretty RAM intensive)
We add a CRC8 computation to verify the data output from the sorted table, the CRC8 is performed using a 256 bytes CRC8 Lookup table to test RAM access again.

CPU Specific: For this benchmark we generate 100000 points of Barnsley fern fractal using a signed MUL 16bits instruction or routine.
We add a CRC8 computation to verify the data output from the computed X/Y points, the CRC8 is performed using a 256 bytes CRC8 Lookup table.

Template for target platforms:
Please try to keep everything in a single file, including data (such as font)

Assembler used	CPU
DASM		6502
NASM		8086
VASM68k		68000

