# Chapter 1 Operating System Interfaces
## Process and Memory
### I. Saves
1. user-space memory (instructions, data, and stack) 
2. per-process state private 
### to the kernel.
### II. `fork` creates child process
1. child process has same memory content as the parent process initially
2. In the parent, `fork` returns child PID. In the child, `fork` returns zero. (one call two returns)
### III. `exit` terminates current process
1. stops executing and release resources.
2. `exit(0)` indicates success, `exit(1)` indicates failure.
### IV. `wait`
1. returns the PID of an exited(or killed) child, if none exited, it keeps waiting
2. no children: returns -1
3. doesn't care about the exit status: `wait((int*)0)`
### V. `exec`
1. `exec` takes two arguments: (a) the name of the file containing the
executable and (b) an array of string arguments.
2.  replaces the calling process’s memory with a new memory image loaded
from a file stored in the file system.
### VI. `sbrk`
1. call `sbrk(n)` grow its data memory by n bytes; `sbrk` returns the location of the new memory