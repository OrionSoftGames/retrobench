#!/bin/bash
nasm -f bin -o bench_ram_dos.com bench_dos.asm
cp *.com /media/orion/Data/programmation/dosroot/
