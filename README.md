# STM32MP157_Debian
Debian linux distribution for STM32MP157. Includes apt package manager.

## How to build
Run `linux.sh` script. This script is referenced from [digikey forum](https://forum.digikey.com/t/debian-getting-started-with-the-stm32mp157/12459). Script will also download linux kernel which is big and takes time. It also has to compile linux kernel, again taking a lot of time.

This builds linux kernel version 5.15.32-armv7-lpae-x23. And bootloader is for STM32MP157a-dk1. It can be used also with STM32MP157d-dk1.

Last part of the script needs sudo permission.