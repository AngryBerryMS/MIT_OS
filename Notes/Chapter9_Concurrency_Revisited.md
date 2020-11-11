# Chapter 9: Concurrency Revisited
## Locking Patterns
### I. one lock for the set of items, plus one lock per item
1. take block cache for example, we have a `bcache.lock` and we have a `buf.lock` for each buf item.
### II. nature of lock
1. the function of lock is to force other uses to wait, not to pin piece of data to a particular agent.
2. it's acquired at the start of an atomic sequence and released when the sequence ends.
3. example: `acquiresleep` in `ilock`.
### III. freeing an object
1. free an object implies freeing the embedded lock, it will cause the waiting thread malfunction.
2. solution: track how many references to the object exist, it's only freed when the last reference disappears.
3. examples: inode, pipe, file, buf.
## Lock-like Patterns
1. reference count / flag, example: inode, file, buf
2. disable interrupts, example: call `mycpu()`
3. a data object may be protected from concurrency in different ways at different points in its lifetime, and the protection may take the form of implicit structure rather than explicit locks.
4. physical page is free -> `kmem.lock`, allocated as a pipe -> `pi->lock`, new process's user memory -> the machanism that other process cannot use it.
## No Locks at all
### I. examples
1. spinlocks implementation
2. `started` variable in `main.c`
3. some uses of `p->parent` in `proc.c`
4. `p->killed`
### II. case
there are cases where one CPU or thread writes some data, and another CPU or thread reads the data, but there is no specific lock dedicated to protecting that data. Example: write child memory in `fork`
## Parallelism
### I. examples
1. pipes: each pipe has its own lock, so that it can be read/written simultaniously
2. context switching: may conflict on locks while searching for the table of processes for one that is `RUNNABLE`
3. concurrent calls to `fork`: wait each other for `pid_lock` and `kmem.lock`, search the process table for an `UNUSED` process.
### II. how to design a new scheme
1. it's possible to obtain more parallelism using a more elaborate design.
2. what to consider: a. how often the relavant operations are invoked. b. how long the code spends with a contended lock held. c. how many CPUs might be running conflicting operations at the same time. d. whether other parts of the code are more restrictive bottlenecks.