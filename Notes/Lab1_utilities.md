# Lab 1: Utilities
## Boot xv6 (easy) ✔
``` 
make qemu
```
Note:\
1. `Ctrl-p`: print process information
2. `Ctrl-a x`: quit qemu type
## sleep (easy) 
## pingpong (easy)
## primes (moderate)
## find (moderate)
## xargs (moderate)
### (optional) Write an uptime program that prints the uptime in terms of ticks using the uptime system call. (easy) 
### (optinoal) Support regular expressions in name matching for find. grep.c has some primitive support for regular expressions. (easy) 
### The xv6 shell (user/sh.c) is just another user program and you can improve it. It is a minimal shell and lacks many features found in real shell. For example, modify the shell to not print a $ when processing shell commands from a file (moderate), modify the shell to support wait (easy), modify the shell to support lists of commands, separated by ";" (moderate), modify the shell to support sub-shells by implementing "(" and ")" (moderate), modify the shell to support tab completion (easy), modify the shell to keep a history of passed shell commands (moderate), or anything else you would like your shell to do. (If you are very ambitious, you may have to modify the kernel to support the kernel features you need; xv6 doesn't support much.)