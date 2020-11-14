# Paper 5: Biscuit
## Related Work
### I. Memory Allocation
1. There is no consensus about whether a systems programming language should have automatic garbage-collection. 
2. Go supports concurrent garbage collector.
3. A hypothesis in the design of Biscuit is that Go’s single `general-purpose allocator` and `garbage collector` are suitable for a wide range of different kernel objects
### II. Kernel Heap Exhaustion
1. Linux running out of memory, it keeps process waits and retries. Kill an abusive process. Recover from allocation failures, undoing any changes made so far, perhaps unwinding through many function calls.
2. has a history of bugs. Worse, the final result will be an error return from a system call.
3. causes unexpected errors from system call
4. Biscuit’s reservation approach yields simpler code than Linux’s. 
5. Biscuit kernel heap allocations do not fail (much as with Linux’s contentious “too small to fail” rule
## Motivation
### I. why C?
supports low-level techniques: pointer arithmetic, easy escape from type enforcement, explicit memory allocation, custom allocators.
### II. why an HLL?
1. advantages: automatic memory management, type-safety, runtime typing and method dispatch, language support for threads and synchronization
2. certain kinds of bugs seem much less likely in an HLL than in C: buffer overruns, use-after-free bugs, bugs caused by reliance on C's relaxed type enforcement.
3. Concurrency: transient worker threads can be cumbersome in C because the code must decide when the last thread has stopped using any shared objects that need to be freed. It's easier in a garbage collected language.
4. Cost of garbage-collector: garbage collector and safety checks consume CPU times and can cause delays; expense of high-level features may deter their use; language runtime layer hides important mechanisms such as memory allocation; enforced abstraction and safety may reduce developers' implementation options.
## Overview
### I. Boot and Go Runtime
kernel space top to bottom: Biscuit, Go runtime, Shim.\
Shim layer provides memory allocation and control of execution contexts. Most of shim layer's activity occurs during initialization, for example to pre-allocate memory for the Go kernel heap.
### II. Processes and Kernel Goroutines
1. Biscuit provides user processes with a POSIX interface: `fork`, `exec` and so on, including kernel-supported threads and futexes.
2. hardware page protection to isolate user processes.
3. maintains a kernel goroutine per user thread, for system calls and handlers for page faults and exceptions.
### III. Interrupts
1. A Biscuit device interrupt handler marks an associated device-driver goroutine as runnable and then returns, as previous kernels have done.
2. Interrupt handlers cannot do much more without risk of deadlock, because the Go runtime does not turn off interrupts during sensitive operations such as goroutine context switch
### IV. Multi-Core and Synchronization
It guards its data structures using Go’s mutexes, and synchronizes using Go’s channels and condition variables.
### V. Virtual Memory
Biscuit uses page-table hardware to implement zero-fill-on-demand memory allocation, copyon-write fork, and lazy mapping of files (e.g., for exec) in which the PTEs are populated only when the process page-faults, and mmap
### VI. File System
1.  The file system has a file name lookup cache, a vnode cache, and a block cache
2. lookup in a read-lock-free directory cache
3. each file system call in a transaction and has a journal.
### VII. Network Stack
DMA and MSI interrupts
### VIII. Limitations
1. Biscuit does not support scheduling priority because it relies on the Go runtime scheduler.
2. Biscuit does not swap or page out to disk, and does not implement the reverse mapping that would be required to steal mapped pages. 
3. Biscuit lacks many security features like users, access control lists, or address space randomization
## Garbage Collection
### I. Go's collector
concurrent mark-and-sweep garbage collector
### II. Biscuit's Heap Size
1. at boot time, Biscuit allocates a fixed amount of RAM for its Go heap, defaulting to 1=32nd of total RAM. 
2. Go’s collector ordinarily expands the heap memory when live data exceeds half the existing heap memory
3. Biscuit disables this expansion.
## Avoiding Heap Exhaustion
### I. Approach: Reservations
Biscuit’s approach to kernel heap exhaustion has three elements
1. it purges caches and soft state as the heap nears exhaustion
2. code at the start of each system call waits until it can reserve enough heap space to complete the call
3. a kernel “killer” thread watches for processes that are consuming lots of kernel heap when the heap is near exhaustion, and kills them
4. benifits: a. Applications do not have to cope with system call failures due to kernel heap exhaustion. b. Kernel code does not see heap allocation failure (with a few exceptions), and need not include logic to recover from such failures midway through a system call
5. If there is no obvious “bad citizen,” this approach may block and/or kill valuable processes
6. Biscuit allocates physical memory pages from a separate allocator, not from the Go heap; page allocations can fail, and kernel code must check for failure and recover
### II. How Biscuit reserves
1. dedicates a fixed amount of RAM M for the kernel heap
2. maximum amount of simultaneously live data that it uses, called s.
```
reserve(s):
    g := last GC live bytes
    c := used bytes
    n := reserved bytes
    L := g + c + n
    M := heap RAM bytes
    if L + s < M:
        reserved bytes += s
    else:
        wake killer thread
        wait for OK from killer thread
release(s):
    a := bytes allocated by syscall
    if a < s:
        used bytes += a
    else:
        used bytes += s
    reserved bytes -= s
```
### III. Static Analysis to find `s`
#### A. Basic MaxLive Operation
1. MAXLIVE examines the call graph (using Go’s ssa and callgraph packages) to detect all allocations a system call may perform. It uses escape and pointer analysis (Go’s pointer package) to detect when an allocation does not “escape” above a certain point in the call graph, meaning that the allocation must be dead on return from that point
2. handles a few kinds of allocations specially: `go`, `defer`, `maps` and `slices`.
3. go -> escape allocation.
4. defer -> non-escaping allocation. but is not represented by an object in the SSA so MAXLIVE specifically considers it an allocation
5. Every insertion into a map or slice could double its allocated size. but MAXLIVE doesn't konw the old size. So we annotate the Biscuit source to declare the maximum size of slices and maps, which required 70 annotations.
#### B. handling loops
1. deep reservations. Each loop iteration tries to reserve enough heap for just the one iteration.
2. If there is insufficient free heap, the loop aborts and waits for free memory at the beginning of the system call, retrying when memory is available. 
3. Two loops (in exec and rename) needed code to undo changes after an allocation failure; the others did not.
4. Three system calls have particularly challenging loops: exit, fork, and exec. These calls can close many file descriptors, either directly or on error paths, and each close may end up updating the file system (e.g. on last close of a deleted file).
#### C. Kernel threads
A final area of special treatment applies to long-running kernel threads. An example is the filesystem logging thread, which acts on behalf of many processes. Each long-running kernel thread has its own kernel heap reservation. Since exit must always be able to proceed when the killer thread kills a process, kernel threads upon which exit depends must never release their heap reservation
#### D. Killer thread
1. The killer thread is woken up when a system call’s reservation fails
2. The thread first starts a garbage collection and waits for it to complete.
3. If memory still not enough, the killer thread asks each cache to free as many entries as possible, and collects again
4. If still not enough the killer thread finds the process with the largest total number of mapped memory regions, file descriptors, and threads, in the assumption that it is a genuine bad citizen, kills it, and again collects.
### IV. Limitations
1. garbage collector also needs memory.
2. reserve bitmap for work stack just in case, but it is slow
3. in our experiments, the garbage collector allocates at most 0.8% of the heap RAM for work stacks.
4. Because the Go collector doesn’t move objects, it doesn’t reduce fragmentation. Hence, there might be enough free memory but in fragments too small to satisfy a large allocation. To eliminate this risk, MAXLIVE should compute s for each size class of objects allocated during a system call
### V. Heap Exhaustion Summary