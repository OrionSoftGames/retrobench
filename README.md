# RetroBench v0.1
Benchmarks for Retro CPU (work in progress)

## Why?
I'm a big fan of retro gaming and retro computing, I own several old school consoles and computers, and I was always curious of how the CPU of these old machines compare.
For example, comparing a 1MHz 6502 CPU to a 6809 CPU or even against a Z80.
Comparing an Atari ST 68000 to a Sega Genesis / Megadrive 68000.
How faster is a PC Engine compared to a Sega Genesis / Megadrive at about the same CPU speed.
How the Intel Pentium 75MHz compares to the Motorola 68060 @ 75MHz.
Can we compare a PS1 RISC 3000 CPU @ 33MHz to an Atari Jaguar RISC CPU @ 23MHz or even a GBA ARM7TDMI @ 16MHz ?
so much questions not answered... until now!

## Philosophy
Each benchmark is predefined as a fixed algorithm in C for validation.
Then each of these benchmark are hand written in assembly for the specific target CPU.
Then you have templates for each target platform embedding the corresponding benchmark assembly routine.

All is written in assembly language because you cannot trust a C compiler.
Let's say we do a benchmark in C and compile it using the latest GCC 15, then years later we use a new version of GCC and the generated code is faster, our benchmark will be invalidated.
Also, several old 8bits CPU are really not C compiler friendly.
So we stay with assembly.

I'm not an assembly language expert, so, this is open source and you can contribute to make better assembly routines.
at **ONE** condition: **DO NOT CHEAT!** (do not use pre-computed tables)
For example, the 6502 doesn't have a `MUL` or `DIV` instruction, we could use pre-computed tables, but that would annihilate the advantage of other CPUs having a `MUL` instruction.
For this, I made 2 type of benchmarks, one using the common assembly instructions that almost all CPU have, so we can compare every CPU using the common trunk.
Then I made another benchmark using the MUL instruction, so we can compare the CPU that have an advantage over the other ones, for example if you found that the 6809 is slower than the 6502 using the common assembly instructions, that is not really fair as the 6809 have advantage over the 6502 for example on the `MUL` instruction, so I made a benchmark measuring that advantage, if you cheat on the 6502 benchmark using precomputed tables, then you should also use precomputed tables on the 6809 benchmark and thus annihilate the advantage of its `MUL` instruction.

###### CPU Benchmark:
For this benchmark we use the Collatz algorithm, which is very simple to implement, it use a variety of basic instructions such as addition, shift, bit testing, conditionnal jump.
We add a CRC8 computation to verify the data output from the Collatz algorithm, the CRC8 is performed bit by bit to keep a pure CPU implementation (no lookup table used)
The Collatz algorithm is run from 1 to 702 included (because from 703 the result number overflows an uint16)

###### RAM Benchmark:
For this benchmark we generate a table of 7000 * 8bits random numbers from a predictive algorithm. (7000 only due to RAM limitation of PC Engine for example)
We then process a shell sort algorithm on this table (which is pretty RAM intensive)
We add a CRC8 computation to verify the data output from the sorted table, the CRC8 is performed using a 256 bytes CRC8 Lookup table to test RAM access again.

###### CPU-Specific Benchmark:
**TODO**
For this benchmark we generate 10000? points of Barnsley fern fractal using a signed MUL 16bits instruction or routine.
We add a CRC8 computation to verify the data output from the computed X/Y points, the CRC8 is performed using a 256 bytes CRC8 Lookup table.
*Bonus:* A graphic mode can be activated to just look at the Barnsley fern fractal without any benchmark being performed.

## Benchmark type
8bits CPU/systems are generaly slower with less memory than 16/32 CPU/systems, that is causing benchmark time to be so fast with faster CPU that it is no longer relevant.
If we extend the original benchmark, it will cause slow CPU to take ages to complete the benchmark or even overflow the RAM available.
That is why we will have 3 benchmark with different running length (changing the value of BENCHMARK_ITERATIONS)
One for slow / 8bits CPU, one for mid / 16bits CPU and a last one for faster / 32bits CPU.
Due to the Atari 16bits computers having speed issue depending on the screen resolution, all tests must be run in standard ST medium resolution.

## Platforms / Target Benchmark Time (slow / 8bits cpu benchmark)
| Target platforms  | CPU     | MHz     | CPU Bench | RAM Bench | CPU Spec Bench |
| ---               | ---     | ---     | ---       | ---       | ---            |
| Apple 1 replica   | 6502    | 1       | x         | x         | x              |
| Atari 2600        | 6507    | 1.19    | 7583ms    | no ram    | x              |
| Thomson MO5       | 6809    | 1       | x         | x         | x              |
| PC Engine         | HuC6280 | 7.16    | 1383ms    | 3250ms    | x              |
| Megadrive NTSC    | 68000   | 7.67    | 2750ms    | 1766ms    | x              |
| Atari ST          | 68000   | 8       | 2850ms    | 1815ms    | x              |
| PC DOS            | 8086 ?  | 8 ?     | x         | x         | x              |
| Mega-CD           | 68000   | 12.5    | x         | x         | x              |
| Atari Jaguar      | 68000   | 13.295  | x         | x         | x              |
| Atari Falcon      | 68030   | 16      | 115ms     | 60ms      | x              |
| GameBoy Advance   | ARM7    | 16      | x         | x         | x              |
| Megadrive 32x     | SH-2    | 23.011  | x         | x         | x              |
| Atari Jaguar      | GPU/DSP | 26.591  | x         | x         | x              |
| Playstation 1     | R3000   | 33.8688 | x         | x         | x              |
| Atari Falcon CT60 | 68060   | 75      | x         | x         | x              |
| PC DOS            | Pentium | 75      | x         | x         | x              |

## Platforms / Target Benchmark Time (mid / 16bits cpu benchmark)
**TBD**
| Target platforms  | CPU     | MHz     | CPU Bench | RAM Bench | CPU Spec Bench |
| ---               | ---     | ---     | ---       | ---       | ---            |
| Megadrive PAL     | 68000   | 7.67    | x         | x         | x              |
| Atari ST          | 68000   | 8       | x         | x         | x              |
| PC DOS            | 8086 ?  | 8       | x         | x         | x              |
| Atari Falcon      | 68030   | 16      | x         | x         | x              |
| GameBoy Advance   | ARM7    | 16      | x         | x         | x              |
| Playstation 1     | R3000   | 33.8688 | x         | x         | x              |
| Atari Falcon CT60 | 68060   | 75      | x         | x         | x              |
| PC DOS            | Pentium | 75      | x         | x         | x              |

## Platforms / Target Benchmark Time (fast / 32bits cpu benchmark)
**TBD**
| Target platforms  | CPU     | MHz     | CPU Bench | RAM Bench | CPU Spec Bench |
| ---               | ---     | ---     | ---       | ---       | ---            |
| Atari Falcon      | 68030   | 16      | x         | x         | x              |
| GameBoy Advance   | ARM7    | 16      | x         | x         | x              |
| Playstation 1     | R3000   | 33.8688 | x         | x         | x              |
| Atari Falcon CT60 | 68060   | 75      | x         | x         | x              |
| PC DOS            | Pentium | 75      | x         | x         | x              |

## Template for target platforms
Please try to keep everything in a single file, including data (such as font)
For now the compilation process is not really automated (partly because of the limited options available in the assemblers used) but I'm sure I will find a way around that.

###### In each benchmark we define 2 contant:
>
**BENCHMARK_ITERATIONS**: The number of iteration for this test (can vary between 8/16/32bits CPU test)
**BENCHMARK_CRC8_RESULT**: The CRC8 result value to verify the integrity of the generated data during the benchmark (verified by the template)
>

| Assembler used | CPU          | CRC8 is in variable or register: |
| ---            | ---          | ---                              |
| PCEAS          | 6502/HuC6280 | crc8 (in zero page, byte access) |
| NASM           | 8086         | cl                               |
| RMAC/RLN       | 68000        | d7.b                             |

