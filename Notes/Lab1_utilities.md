# Lab 1: Utilities
## Boot xv6 (easy) ✔
``` 
make qemu
```
Note:
1. `Ctrl-p`: print process information
2. `Ctrl-a x`: quit qemu type
## sleep (easy) ✔
### I. add sleep to makefile
```
    UPROGS=\
        ...
+       $U/_sleep\
```
### II. creates `/user/sleep.c`
```
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){
  if(argc != 2){
      fprintf(2, "usage: sleep time\n");
      exit(1);
  } else {
      int time = atoi(argv[1]);
      sleep(time);
      exit(0);
  }
}
```
## pingpong (easy)
## primes (moderate)
## find (moderate)
## xargs (moderate)
## (optional) uptime (easy)
Write an uptime program that prints the uptime in terms of ticks using the uptime system call.
## (optinoal) find (easy)
Support regular expressions in name matching for find. grep.c has some primitive support for regular expressions.
## (optional) not print $ (moderate)
modify the shell to not print a $ when processing shell commands from a file
## (optional) support wait (easy)
modify the shell to support wait (easy)
## (optional) lists of commands (moderate)
modify the shell to support lists of commands, separated by ";" (moderate)
## (optional) sub-shells (moderate)
modify the shell to support sub-shells by implementing "(" and ")" (moderate)
## (optional) tab (easy)
modify the shell to support sub-shells by implementing "(" and ")"
## (optional) history (moderate)
modify the shell keep a history of passed shell commands (moderate)