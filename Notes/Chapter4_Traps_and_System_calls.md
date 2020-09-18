# Chapter 4 Traps and System Calls
## Overview
### What is a trap?
CPU set aside ordinary execution of instructions and force a transfer of control to special code that handles the event.
### Three situations cause Trap
1. system call. `ecall`
2. exception. An instruction does something illegal.
3. device `interrupt`
### Usual Sequence of a Trap
1. trap forces a transfer of control into the kernel.
2. kernel saves registers and other state.
3. kernel executes appropriate handler code (e.g a system call implementation or a device driver).
4. kernel restores the saved state and returns from the trap.
5. original code resumes where it left off.
### xv6 trap handling proceeds in 4 stages
1. hardware actions taken by the RISC-V CPU.
2. an assembly "vector" that prepares the way for kernel C code.
3. C trap handler that decides what to do with the trap
4. system call or device service routine.
### MISC
1. Commonality of the 3 trap -> a kernel could handle all traps with a single code path.
2. It turns out to be convenient to have separate assembly vectors and C trap handlers for three distinct cases: a. traps from user space, b. traps from kernel space, c. timer interrupts.
## RISC-V trap machinery
### Control registers
#### Overview
1. Below registers relate to traps handled in supervisor mode, cannot be read/written in user mode.
2. There is an equivalent set of control registers for machine mode, xv6 uses them only for the special case of timer interrupts.
3. Each CPU on a multi-core chip has its own set of these registers, and more than one CPU may be handling a trap at any given time.
#### important ones
1. `stvec`: the kernel writes the address of its trap handler here; the RISC-V jumps here to handle a trap.
2. `sepc`: when a trap occurs, RISC-V saves the PC here (since PC is then overwritten with `stvec`). The `sret` (return from trap) instruction copies `sepc` to the `pc`. The kernel can write to `sepc` to control where `sret` goes.
3. `scause`: The RISC-V puts a number here that describes the reason for the trap.
4. `sscratch`: The kernel places a value here that comes in handy at the very start of a trap handler.
5. `sstatus`: The SIE bit in `sstatus` controls whether device interrupts are enabled. If the kernel clears SIE, the RISC-V will defer device interrupts until the kernel sets SIE. The SPP bit indicates whether a trap came from user mode or supervisor mode, and controls to what mode `sret` returns.
### Procedures to RISC-V hardware to force a trap
1. if the trap is a device interrupt, and the `sstatus` SIE bit is clear, don't do any of the following.
2. disable interrupts by clearing SIE.
3. copy the `pc` to `sepc`.
4. save the current mode (user or supervisor) in the SPP bit in `sstatus`.
5. set `scause` to reflect the trap's cause
6. set the mode to supervisor
7. copy `stvec` to the `pc`.
8. start executing at the new `pc`.
#### Note:
1. CPU doesn't switch to the page table / switch to a stack in the kernel / save any registers other than the `pc`.
2. Can it be further simplified? No.
## Traps from user space
## Calling System Calls
1. user place system call number in register `a7`, arguments in `a0` and `a1`.
2. system call numbers match the entries in the `syscalls` array (a table of function pointers)
3. `ecall` instruction traps into the kernel and executes `uservec`, `usertrap` and then `syscall`.
4. `syscall()` retrieves the system call number from `a7` and use it to index into `syscalls`
5. for the first system call, `a7` contains `SYS_exec`, resulting in a call to the system call implementation function `sys_exec`.
6. `syscall` records return value in `p->trapframe->a0`, which the user space `exec()` will return. 
7. for the return value, negative indicates error, zero or positive number indicates success. If system call number is invalid, it returns `-1`.
## System Call Arguments
### I. functions used to retrive system call arguments
`argint`, `argaddr` and `argfd` retrieves the nth system call argument from the trap frame as an integer, pointer, or a file descriptor. They all call `argraw` to retrieve the appropriate saved user register.
### II. Pointers as argument
1. two challanges: a. the user program may be buggy or malicious and may pass the kernel an invalid pointer or a pointer intended to trick the kernel to accessing kernel memory instead of user memory. b. the xv6 kernel page table mappings are not the same as the user page table mappings, so the kernel cannot use ordinary instructions to load or store from user-supplied addresses.
2. to solve the challenges, kernel implements functions that safely transfer data to and from user-supplied addresses. `fetchstr` is an example. `fetchstr` calls `copyinstr` which copies up to `max` bytes to `dst` from virtual address `srcva` in the user page table `pagetable`, it uses `walkaddr` to determine the physical address `pa0` for `srcva`, which solves(b). Then `copyinstr` can directly copy string bytes from `pa0` to `dst`. `walkaddr` checks the user-supplied virtual address of part of the process's user address space, which solves(a). A similar function `copyout` copies data from kernel to a user-supplied address.