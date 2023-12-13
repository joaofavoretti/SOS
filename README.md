# SOS: Simple Operating System

Very very simple 16-bit x86 operating system that I am trying to create to learn how to intall Linux on my computer xD

Required packets:

Tested on Ubuntu

```
make nasm qemu
mtools
```

## Disk addressing information

**CHS scheme**
3 different numbers to referenec a block in the disk; (track/Cylinder, Head, Sector)

Cylinder index: [0:]
Head Index: [0:]
Sector Index: [1:]

**LBA scheme**
1 number to reference a block in the disk (Logic Block Addressing) 
Block Index: [0:]

**Math**

Constans:
- Number of Sectors Per Track (on a single side)
- Number of Faces in total (Number of Heads Per Cylinder)

sector = (LBA % Number of Sectors Per Track) + 1
head = (LBA / Number of Sectors Per Track) % Number of Faces in Total
cylinder = (LBA / Number of Sectors Per Track) / Number of Faces in Total


(Information about the cylinder)
ah              al
0000    00dd    cccc    cccc

(Information about the sector)
ch              cl
cccc    cccc    00ss    ssss
