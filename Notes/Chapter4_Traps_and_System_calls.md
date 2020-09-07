# Chapter 4 Traps and System calls
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