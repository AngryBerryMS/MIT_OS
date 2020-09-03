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
1. stops executing and release resources (memory and opened file).
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
## I/O and File descriptors
### I. file descriptor
1. stdin - 0, stdout - 1, stderr - 2.
2. `fork` and `exec` will copy the file descriptor from caller.
### II. functions 
1. `read(fd,buf,n)` reads `fd` at address `buf` of size `n`
2. `write(fd,buf,n)` writes `fd` at address `buf` of size `n`
3. `close(fd)` releases a fd, making it free for reuse by a future `open`, `pipe`, or `dup` system call. A newly allocated file descriptor is always the lowestnumbered unused descriptor of the current process.
### III. why `exec` and `fork` are seperate?
1.  redirect the child’s I/O without disturbing the I/O setup of the main
shell
2. The shell could modify its own I/O setup before calling `forkexec` (and then un-do those modifications); or `forkexec` could take instructions for I/O redirection as arguments; or (least attractively) every program like cat could
be taught to do its own I/O redirection.
## Pipes
A `pipe` is a small kernel buffer exposed to processes as a pair of file 
descriptors, one for reading and one for writing. Writing data to one end of the pipe makes that data available for reading from 
the other end of the pipe. Pipes provide a way for processes to communicate.
### I. how is `pipe` executed?
The child process creates a pipe to connect the left end of the
pipeline with the right end. Then it calls `fork` and `runcmd` for the left end of the pipeline and
fork and runcmd for the right end, and waits for both to finish
### II. difference between `pipe` and tmp file?
1. First, pipes automatically clean themselves up; with the file redirection, 
a shell would have to be careful to remove `/tmp/xyz` when done. 
2. Second, pipes can pass arbitrarily long streams of data, while file redirection requires enough free space on disk to store all the data. 
3. Third, pipes allow for parallel execution of pipeline stages, while the file
approach requires the first program to finish before the second starts. 
4. Fourth, if you are implementing inter-process communication, pipes’ blocking reads and writes are more efficient than the non-blocking semantics of files.
## File System
