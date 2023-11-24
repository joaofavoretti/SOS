#!/bin/bash

# Trying to use Bochs as a debugger
# bochs -f bochs.config

# Using QEMU + GDB as debugger
gdb -x gdbscript.gdb
