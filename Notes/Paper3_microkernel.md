# Paper 3: Microkernel
## I. L4 Essentials
### A. based on two concepts
1. threads and address space.
2. thread communication: IPC, can construct RPS and controlled thread migration.
### B. basic idea
1. support recursive construction of address spaces by user-level servers outside the kernel.
2. initial address space σ represents the physical memory. Further address spaces can be constructed by `granting`, `mapping` and `unmapping`.
### C. pagers
1. all address spaces are constructed and maintained by user-level servers, also called `pagers`
2. only grant, map and unmap are inside kernel.
3. when page fault occurs, micro kernel send IPC to the pager currently associated with the faulting thread.
### D. misc
1. I/O ports are treated as parts of address spaces
2. hardware interrupts are handled as IPC
3. exceptions and traps are synchronous to the raising thread. Kernel simply mirrors them to the user level.
4. `small-address-space` optimization. Whenever the currently-used portion of an address space is "small", 4MB up to 512MB, this logical space can be physically shared through all page tables and protected by Pentium's segment mechanism. When it's more than 512MB, kernel switches it back to the normal 3GB space model
## II. Linux Essentials
### A. architecture-independent
1. includes process and resource management, file systems, networking subsystems and all device drivers.
2. these are about 98% of the Linux/x86 source distribution of kernel and device drivers
### B. interrupt handlers
1. top halves: highest priority, triggerd by hardware interrups, can interrups each other
2. bottom halves: next lower priority, can be interrupted by top halves but not by other bottom halves or the Linux kernel.
## III. The Linux Server
1. Linux server requests memory from pager σ.
2. σ also keeps and maintains the user process.
3. it leads to double memory consumption, but it's not a problem when speaking to performance.
4. uses interrupt disabling for synchronization and critical sections, same as Linux
## IV. Interrupt Handling and Device Drivers
```
interrupt handler thread:
    do
        wait for interrups {L4-IPC}
        top half interrupt handler()
    od .
```
## V. Linux User Processes
1. each `Linux user process` is implemented as an L4 task
2. Linux server creates these tasks and specifies itself as their associated pager.
3. L4 then converts any Linux user-process page fault into an RPC to the Linux server
4. Linux server maps the emulation library and the signal thread code into an otherwise unused high-address part of each user address space
5. for example, `getpid` or `read` system call is always issued to the server and never handled locally
## VI. System-Call Mechanisms
### A. three concurrently usable system-call interfaces
1. modified `libc.so` which uses L4 IPC primitives to call the Linux server
2. modified `libc.a`
3. user-level exception handler
### B. improved address-space switching
1. all Linux server threads execute in a small address spaces which enables improved address-space switching by simulating a tagged TLB on the Pentium processor.
2. this affects all IPCs with the Linux server: system calls, page faults and hardware interrupts.
3. avoiding TLB flushes improves IPC performance.
## VII. Signaling
1. kernel delivers signals to user processes by directly manipulating their stack, stack pointer and instruction pointer.
2. an additional signal-handler thread was added to each Linux user process.
## VIII. Scheduling
1. whenever a system call completes and the server's reschedule flag is not set, the server resumes the corresponding user thread and then sleeps waiting for a new system call message or a wakeup message from one of the interrupt handling threads
2. uses hard priorities with round-robin scheduling per priority.
## IX. Supporting Tagged TLBs or Small Spaces
what is tagged TLB
```
With tagged TLBs, there is extra space in every TLB entry which stores an 8-bit “Address Space ID (ASID)”. In addition, the page tables now store a bit for every last-level entry which specifies whether that entry is “global” or not. When the MMU misses on a “non-global” page table entry, the TLB stores the result of the hardware page-table walk along with the current ASID. Later, when you access that same virtual address again, the MMU looks up the entry in the TLB. If the current ASID matches the stored ASID, then it uses the cached entry. Otherwise, it “misses” and re-walks the page tables. In essence, this dodges the security and safety problems of not flushing the TLB by checking an ASID number whenever it looks up an entry in the TLB.
```