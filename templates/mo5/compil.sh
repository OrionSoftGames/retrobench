#!/bin/bash
/media/orion/Data/programmation/mo5/asm6809/a09 -Bboot.bin bench_mo5.asm
/media/orion/Data/programmation/mo5/asm6809/a09 -bbench.bin ../../bench_cpu/6809/bench_cpu_6809.asm

if [ -f boot.bin ] && [ -f bench.bin ]; then
/media/orion/Data/programmation/mo5/utils/fd_boot_maker/fd_boot_maker bench.fd disk.inc 40 boot.bin bench.bin
fi

