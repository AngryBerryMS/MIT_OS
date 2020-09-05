# Chapter 2 Operating System Organization
An operating system must fulfill three requirements: 
1. multiplexing
2. isolation
3. interaction.
## User mode, supervisor mode, and system calls
### I. RISC-V has three modes in which the CPU can execute instructions:
1. machine mode
2. supervisor mode
3. user mode
### II. User space, Kernel Space
1. An application can execute only user-mode instructions -  running in user space.
2. While the software in supervisor mode can
execute privileged instructions - running in kernel space.
### III. How to invoke a kernel function
1.  Use a special instruction that switches the CPU from user mode
to supervisor mode and enters the kernel at an entry point specified by the kernel.
2. kernel validates the arguments of the system call, decide whether it is allowed, then deny/execute it
3. This process is controlled by kernel.
## Kernel Organization
### I. Monolithic kernel
The entire operating system resides in the kernel, so that the implementations of all system calls run in supervisor mode.
### II. Microkernel
Minimize the amount of operating system code that runs in 
supervisor mode, and execute the bulk of the operating system in user mode.
## Process Overview
### I. Content of Process:
1. user/supervisor mode flag
2. address spaces
3. time-slicing of threads
### II. Page Tables
Maps a `virtual address` (the address that an RISC-V instruction manipulates)
to a `physical address` (an address that the CPU chip sends to main memory)
### III. Layout of a process's virtual memory space
1. from low(address 0) to high: Instructions, Global Variables, Stack, Heap (for malloc, can expand).
2. factors limit the max size: min(# of bits the hardware uses to look up virtual address, pointer width).
3. at the top, there are `trampoline` and `trapframe` (see Chapter 4).
4. each process has a `thread` to execute the process's instructions, which can be suspended and resumed.
5. each process has two stacks: a `user stack` and a `kernel stack`: when executing user instructions, `user stack` is in use and `kernel stack` is empty. when entered kernel, kernel code executes on `kernel stack` while `user stack` is saved but not used. 
6. kernel can execute even if a process has wrecked its `user stack`. 
7. `p->stack` status: `allocated`, `ready to run`, `running`, `waiting for I/O`, `exiting`
8. `p->pagetable` is used when executing in `user space`. 
### IV. system call
1. `ecall` to make system call.
2. `sret` to return to user space. 
