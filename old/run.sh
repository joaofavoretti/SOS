#!/bin/bash

# Variables
EMULATOR=qemu-system-i386
BUILD_DIR=build

# Run start here
$EMULATOR -fda $BUILD_DIR/main_floppy.img
