# Chapter 6: Locking
## Overview
### I. What is concurrency?
Concurrency refers to situations in which multiple instruction streams are interleaved, due to multiprocessor parallelism, thread switching, or interrupts
### II. What is concurrency control?
Concurrency control refers to strategies aimed at correctness under concurrency, and abstractions that support them.
### III. pros/cons of lock
1. pro: provide mutual exclusion
2. con: may kill the performance, because it serializes concurrent operations.
## Race Conditions
### I. What is race condition?
1. a race condition is a situation in which a memory location is accessed concurrently, and at least one access is a write.
2. a race is often a sign of a bug, either a "lost update" or a "read of an incompletely-updated data structure".
3. the outcome of a race depends on the exact timing of the two CPU's involved and how their memory operations are ordered by the memory system, which can make race-included errors diffucult to reproduce and debug. (e.g adding print might change the timing and make the race disappear)
### II. Lock
1. the code between `acquire` and `release` is often called a `critical section`. 
2. when we say that a lock protects the data, we really mean that the lock protects some collection of invariants that apply to the data.
3. invariants are properties of data structures that are maintained across operations. 
4. operation may temporarily violate the invariants but must reestablish them before finishing. 
5. lock is going to protect the violated part. one CPU at a tie can operate on the data structure in the critical section.
6. locks serialize concurrent critical secions, the critical sections guarded by the same lock is atomic with respect to each other.
7. locks limit performance. We say that multiple processes `conflict` if they want the same lock at the same time, or that the lock experiences `contention`. A major challenge in kernel design is to avoid contention.
8. the placement of locks is also important for performance.
## Code: Locks
xv6 has `spinlock` and `sleep-lock`, we start with spinlocks. The important field in spinlock is `locked`, a word that is 0 when available and non-zero when held.
### I. structure
similar but not exactly the same!
```
// does not work! what if both CPU acquiring lock at the same time
void acquire(struct spinlock *lk) {
    for(;;) if(lk->locked == 0) {
        lk->locked = 1;
        break;
    }
}
```
### II. `amoswap r, a` atomic swap
1. this instruction use special hardware to prevent any other CPU from using the memory address between the read and the write
2. `acquire`: C library `__sync_lock_test_and_set`, returns the old (swapped) contents of lk->locked. In the loop, it keeps retrying(spining) until it has acquired the lock (when return 0). `acquire` records, for debugging, the CPU that acquired the lock. The `lk->cpu` field is protected by the lock and must only be changed while holding the lock.
3. `release`: C library `__sync_lock_release`, assign 0 to `lk->locked`
## Code: Using locks
### I. When are locks necessary?
1. any time a variable can be written by one CPU at the same time that another CPU can read or write it.
2. if an invariant involves multiple memory locations, typically all of them need to be protected by a single lock to ensure the invariant is maintained.
### II. different locking schemes:
1. big kernel lock: single lock that be acquired on entering the kernel and released on exiting the kernel.
2. coarse-grained locking: xv6 has a single free list protected by a single lock. If multiple processes on different CPUs try to allocate pages at the same time, each will have to wait for its turn by spinning in `acquire`, which reduces performance, since it's not useful work. If contention wasted much time, perhaps it can be changed into fine-grained locking.
3. fine-grained locking: xv6 has a seperate lock for each file. It can be made more fine-grained if one wanted to allow processes to simultaneously write different areas of the same file. Ultimately lock granularity decisions needs to be driven by performance as well as complexity.
## Deadlock and Lock Ordering
### I. What is deadlock?
two code paths needs locks A and B. code path 1 acquires locks A -> B, code path 2 acquires locks B -> A.
### II. lock-order chains
1. callers must invoke functions in a way that causes locks to be acquired in the agreed-on order.
2. xv6 has many lock-order chains of length two involving per-process locks.
### II. the difficulties in avoiding deadlock
1. sometimes the lock order conflicts with logical program structure. 
2. sometimes the identities of locks aren't known in advance, because one lock must be held in order to discover the identity of the lock to be acquired next. This kind of situation arises in the file system and code for `wait` and `exit`.
3. the danger of deadlock is often a constraint on how fine-grained one can make a locking scheme, since more locks often means more opportunity for deadlock.
## Locks and Interrupt Handlers
### I. What is the relationships between them?
some xv6 spinlocks protect data that is used by both threads and interrupt handlers. 
### II. What's the danger? 
for example, when `sys_sleep` is holding the lock, it's waiting for `clockintr` to return, but `clockintr` can't write to `ticks` because `sys_sleep` is holding it.
### III. How to solve?
disable interrupts when this CPU acquires any lock.
### IV. Handling nested critical sections
1. do a little book-keeping to cope with it.
2. `acquire` calls `push_off` and `release` calls `pop_off` to track the nesting level of locks on the current CPU. 
3. when that count reaches 0, `pop_off` restores the interrupt enable state that existed at the start of the outermost critical section. 
4. the `intr_off` and `intr_on` functions execute RISC-V instructions to disable and enable interrupts, respectively. 
5. it is important that `acquire` call `push_off` strictly before setting `lk->locked`. Otherwise there would be a brief window when the lock was held with interrupts enabled. Similarly, `release` call `pop_off` only after releasing the lock.
## Instruction and Memory Ordering
### I. memory model
1. Many compilers and CPUs execute code out of order to achieve higher performance. 
2. If an instruction takes many cycles to complete, a CPU may issue the instruction early so that it can overlap with other instructions and avoid CPU stalls. 
3. Compilers and CPUs follow rules when they re-order to ensure that they don't change the results of correctly-written serial code. However, it can change the results of concurrent code, and can easily lead to incorrect behavior on multiprocessors.
4. The CPU's ordering rules are called the `memory model`.
### II. memory barrier
xv6 uses `__sync_synchronize()` in both `acquire` and `release`. `__sync_synchronize()` is a `memory barrier`. It tells the compiler and CPU to not reorder loads or stores across the barrier.
## Sleep Locks
### I. Drawbacks of Spinlock
1. holding a spinlock for a long time would lead to waste if another process wanted to acquire it, since the acquiring process would waste CPU for a long time while spinning.
2. a process cannot yield the CPU while retaining a spinlock. 
### II. Why a process cannot yield while holding a spinlock?
1. might lead to deadlock if a second thread then tried to acquire the spinlock.
2. since `acquire` doesn't yield the CPU, the second thread's spinning might prevent the first thread from running and releasing the lock.
3. violate the requirement that interrupts must be off while a spinlock is held.
### III. sleep-lock
1. `acquiresleep` yields the CPU while waiting. 
2. At a high level, a sleep-lock has a `locked` field that is protected by a spinlock, and `acquiresleep`'s call to `sleep` atomically yields the CPU and releases the spinlock.
3. the result is that other threads can execute while `acquiresleep` waits.
4. because sleep-locks leave interrupts enabled, they cannot be used in interrupt handlers. 
5. because `acquiresleep` may yield the CPU, sleep-locks cannot be used inside spinlock critical sections (ok for sleep-lock critical sections).
### IV. applicable conditions
1. spin-locks are best suited to short critical sections.
2. sleep-locks work well for lengthy operations.
## Real World
### I. high difficulty
1. it's often best to conceal locks within higher-level constructs like synchronized queues.
2. it's wise to use a tool that attempts to identify race conditions, it's easy to miss an invariant that requires a lock.
### II. POSIX threads (Pthreads)
1. allow a user process to have several threads running concurrently on different CPUs. 
2. Pthreads has support for user-level locks, barriers, etc. 
3. Pthreads requires support from the Operating System. For example, it should be the case that if one pthread blocks in a system call, another pthread of the same process should be able to run on that CPU. Another example, when a Pthread changes its process's address space (map/unmap), the kernel must arrange that other CPUs that run threads of the same process to update the hardware page tables.
### III. Expenses Associated with Locks
1. it's expensive to implement locks without atomic instructions.
2. locks can be expensive if many CPUs try to acquire the same lock at the same time. If one CPU has a lock cached in its local cache, and another CPU must acquire that lock. Fetching a cache line from another CPU's cache can be orders of magnitude more expensive than fetching a line from a local cache.
3. to avoid the expenses, many OSs use lock-free data structures and algorithms. For example, it is possible to implement a linked list that requires no locks during list searchs, and one atomic instructions to insert an item in a list. But would be more complicated.
