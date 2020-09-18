# Chapter 4 Traps and System Calls
## Overview
### I. What is a trap?
CPU set aside ordinary execution of instructions and force a transfer of control to special code that handles the event.
### II. Three situations cause Trap
1. system call. `ecall`
2. exception. An instruction does something illegal.
3. device `interrupt`
### III. Usual Sequence of a Trap
1. trap forces a transfer of control into the kernel.
2. kernel saves registers and other state.
3. kernel executes appropriate handler code (e.g a system call implementation or a device driver).
4. kernel restores the saved state and returns from the trap.
5. original code resumes where it left off.
### IV. xv6 trap handling proceeds in 4 stages
1. hardware actions taken by the RISC-V CPU.
2. an assembly "vector" that prepares the way for kernel C code.
3. C trap handler that decides what to do with the trap
4. system call or device service routine.
### V. MISC
1. Commonality of the 3 trap -> a kernel could handle all traps with a single code path.
2. It turns out to be convenient to have separate assembly vectors and C trap handlers for three distinct cases: a. traps from user space, b. traps from kernel space, c. timer interrupts.
## RISC-V trap machinery
### I. Control registers
#### A. Overview
1. Below registers relate to traps handled in supervisor mode, cannot be read/written in user mode.
2. There is an equivalent set of control registers for machine mode, xv6 uses them only for the special case of timer interrupts.
3. Each CPU on a multi-core chip has its own set of these registers, and more than one CPU may be handling a trap at any given time.
#### B. important ones
1. `stvec`: the kernel writes the address of its trap handler here; the RISC-V jumps here to handle a trap.
2. `sepc`: when a trap occurs, RISC-V saves the PC here (since PC is then overwritten with `stvec`). The `sret` (return from trap) instruction copies `sepc` to the `pc`. The kernel can write to `sepc` to control where `sret` goes.
3. `scause`: The RISC-V puts a number here that describes the reason for the trap.
4. `sscratch`: The kernel places a value here that comes in handy at the very start of a trap handler.
5. `sstatus`: The SIE bit in `sstatus` controls whether device interrupts are enabled. If the kernel clears SIE, the RISC-V will defer device interrupts until the kernel sets SIE. The SPP bit indicates whether a trap came from user mode or supervisor mode, and controls to what mode `sret` returns.
### II. Procedures to RISC-V hardware to force a trap
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
### I. Overview
#### A. Situation
1. system call (`ecall`)
2. does something illegal
3. device interrupts
#### B. High level Path
`uservec` -> `usertrap` -> `usertrapret` -> `userret`
#### C. Challenge
`satp` points to user page table which doesn't map the kernel.
### II. How to solve the challenge?
#### A. Theory
1. user page table must include a mapping for `uservec`, the trap vector instructions that `stvec` points to.
2. `uservec` must switch `satp` to the kernel page table.
3. `uservec` must be mapped at the same address in both kernel page table and user page table.
#### B. Practice
use `trampoline` page to contain `uservec`, the contents are set in `trampoline.S` and when executing user code, `stvec` is set to `uservec`.
### III. Procedures Explained
#### A. `uservec`
1. When `uservec` starts, all 32 registers contain values owned by the interrupted code, but `uservec` needs to be able to modify some registers in order to set `satp` and generate addresses to save the registers. RISC-V provides `sscratch` register. The `csrrw` instruction at the start of `uservec` swaps `a0` and `sscratch`. Now `a0` can be used.
2. Thus after swapping `a0` and `sscratch`, `a0` holds a pointer to the current process's trapframe (reason see below), `uservec` now saves all user registers there.
#### B. `trapframe`
1. `trapframe` contains a. pointers to the current process's kernel stack. b. the current CPU's hartid. c. the address of the kernel page table.
2. When creating each process, xv6 allocates a page for the process's trapframe, and map `TRAPFRAME` just below `TRAMPOLINE`.
3. p->trapframe also points to the trapframe, though at its physical address so the kernel can use it through the kernel page table.
4. Before entering user space, kernel previously set `sscratch` to point to `trapframe` of current process.
#### C. `usertrap`
1. It's used to determine the cause of the trap, process it and return.
2. It first changes `stvec` so that a trap while in the kernel will be handled by `kernelvec`. It saves the `sepc` (the saved user program counter), again because there might be a process switch in `usertrap` that could cause `sepc` to be overwritten. 
3. If the trap is system call, `syscall` handles it; if a device interrupt, `devintr`; otherwise exception, the kernel kills the faulting process.
4. The system call path adds 4 to the saved user `pc` because RISC-V, in the case of a system call, leaves the program pointer pointing to the `ecall` instruction. 
5. On the way out, `usertrap` checks if the process has been killed or should yield the CPU (if this trap is a timer interrupt)
#### D. `usertrapret`
1. First step to return to user space is call `usertrapret`.
2. This function sets up the RISC-V control registers to prepare for a future trap from user space, which involves a. changing `stvec` to refer to `uservec`, b. preparing the trapframe fields that `uservec` relies on, c. setting `sepc` to the previously saved user program counter. 
3. At the end, `usertrapret` calls `userret` on the trampoline page that is mapped in both user and kernel page tables. The reson is that assembly code in `userret` will switch page tables.
#### E. `userret`
1. `usertrapret`'s call to `userret` passes a pointer to the process's user page table in `a0` and `TRAPFRAME` in `a1`. `userret` switches `satp` to the process's user page table.
2. `userret` switches `satp` back to user page table. 
3. `userret` copies the trapframe's saved user `a0` to `sscratch` in preparation for a later swap with `TRAPFRAME`. From this point on, the only data `userret` can use is the register contents and the content of the trapframe. Next `userret` restores saved user registers from the trapframe, does a final swap of `a0` and `sscratch` to restore `a0` and save `TRAPFRAME` for the next trap, and uses `sret` to return to user space.
## Code: Calling System Calls
1. user place system call number in register `a7`, arguments in `a0` and `a1`.
2. system call numbers match the entries in the `syscalls` array (a table of function pointers)
3. `ecall` instruction traps into the kernel and executes `uservec`, `usertrap` and then `syscall`.
4. `syscall()` retrieves the system call number from `a7` and use it to index into `syscalls`
5. for the first system call, `a7` contains `SYS_exec`, resulting in a call to the system call implementation function `sys_exec`.
6. `syscall` records return value in `p->trapframe->a0`, which the user space `exec()` will return. 
7. for the return value, negative indicates error, zero or positive number indicates success. If system call number is invalid, it returns `-1`.
## Code: System Call Arguments
### I. functions used to retrive system call arguments
`argint`, `argaddr` and `argfd` retrieves the nth system call argument from the trap frame as an integer, pointer, or a file descriptor. They all call `argraw` to retrieve the appropriate saved user register.
### II. Pointers as argument
1. two challanges: a. the user program may be buggy or malicious and may pass the kernel an invalid pointer or a pointer intended to trick the kernel to accessing kernel memory instead of user memory. b. the xv6 kernel page table mappings are not the same as the user page table mappings, so the kernel cannot use ordinary instructions to load or store from user-supplied addresses.
2. to solve the challenges, kernel implements functions that safely transfer data to and from user-supplied addresses. `fetchstr` is an example. `fetchstr` calls `copyinstr` which copies up to `max` bytes to `dst` from virtual address `srcva` in the user page table `pagetable`, it uses `walkaddr` to determine the physical address `pa0` for `srcva`, which solves(b). Then `copyinstr` can directly copy string bytes from `pa0` to `dst`. `walkaddr` checks the user-supplied virtual address of part of the process's user address space, which solves(a). A similar function `copyout` copies data from kernel to a user-supplied address.
## Traps from Kernel Space
### I. Difference between registers in user/kernel code
When kernel is execuring, `stvec` points at `kernelvec`, since xv6 already in the kernel, `kernelvec` can rely on `satp` being set to the kernel page table, and on the stack pointer referring to a valid kernel stack, `kernelvec` saves all registers so that the interrupted code can eventually resume without disturbance.
### II. Procedures Explained
#### A. `kernelvec`
1. `kernelvec` saves the registers on the stack of the interrupted kernel thread.
2. `kernelvec` jumps to `kerneltrap` after saving registers.
#### B. `kerneltrap`
1. `kerneltrap` is prepared for 2 types of traps: a. device interrupts (call `devintr`) and exceptions (call `panic` and stops executing).
2. if called due to a timer interrupt, and a kernel thread is running (rather than a scheduler thread), `kerneltrap` calls `yield` to give other threads a chance to run. At some point one of those threads will yield, and let our thread and its `kerneltrap` resume again.
#### C. resume the interrupted thread
1. `yield` may have disturbed the saved `sepc` and the saved previous mode in `sstatus`. It now restores those control registers and returns to `kernelvec`. `kernelvec` pops the saved registers from the stack and executes `sret`, which copies `sepc` to `pc` and resumes the interrupted kernel code.
2. It's worth thinking through how the trap return happens if `kerneltrap` called `yield` due to a timer interrupt.
### III. window time
xv6 sets a CPU's `stvec` to `kernelvec` when that CPU enters the kernel from user space (in `usertrap`). There's a window of time when the kernel is executing but `stvec` is set to `uservec`. It's crucial that device interrups be disabled during that window until it sets `stvec`.
## Page-fault Exceptions
xv6's response to exception is quite boring: If in user space, kernel kills it. If in kernel, kernel panics. Real Operating SYstems often respond in much more interesting ways.
### I. types of `page-fault exceptions`
1. load page faults (when a load instruction cannot translate its virtual address)
2. store page faults (when a store instruction cannot translate its virtual address)
3. instruction page faults (when the address for an instruction doesn't translate)
#### Note:
The value in `scause` register indicates the type of the page fault. The `stval` contains address cannot be translated.
### II. copy-on-write (COW) fork
1. parent and child initially share all physical pages, but map them read-only.
2. when the child or parent executes a store instruction, the CPU raises a page-fault exception.
3. Kernel makes a copy of the page that contains the faulted address. It maps one copy read/write in the child's address space and other copy read/write in the parent's address space.
4. After updating the page tables, the kernel resumes the faulting process at the instruction that caused the fault. Because the kernel has updated the relevant PTE to allow writes, the faulting instruction will now execute without a fault.
5. COW works well for `fork` because often the child calls `exec` immediately after the fork, replacing its address space with a new address space. In that common case, the child will experience only a few page faults, and the kernel can avoid making a complete copy. Furthermore, COW fork is transparent: no modifications to applications are necessary for them to benefit.
### III. lazy allocation
1. when an application calls `sbrk`, the kernel grows the address space, but marks the new addresses as not valid in the page table. 
2. on a page fault on one of those new addresses, the kernel allocates physical memory and maps it into the page table.
### IV. paging from disk
1. if applications need more memory than the available physical RAM, the kernel can evict some pages: write them to a storage device such as a disk and mark their PTEs as not valid.
2. if an application reads or writes an evicted page, the CPU will experience a page fault. The kernel can then inspect the faulting address. If the address belongs to a page that is on disk, the kernel allocates a page of physical memory, and resumes the application. To make room for the page, the kernel may have to evict another page. This feature requires no changes to applications, and works well if applications have locality of reference (i.e., they use only a subset of their memory at any given time).
### V. other features combine paging and page-fault exceptions:
1. automatically extending stacks
2. memory-mapped files.
## Real World
### I. the advantage of mapping kernel page table into user page table
1. No need to implement trampoline pages.
2. No need to switch page table when trapping from user space to kernel.
3. Allow kernel code to directly dereference user pointers.
### II. disadvantages
security bugs like Meltdown and Spectre.