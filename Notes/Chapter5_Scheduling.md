# Chapter 7: Scheduling
## Multiplexing
### I. situations of swithching from one process to another
1. `sleep` and `wakeup` mechanism switches when a process waits for a. device or pipe I/O to complete, b. waits for a child to exit, c. waits in the `sleep` system call.
2. xv6 periodically forces a switch to cope with processes that compute for long period without sleeping.
### II. challenges in implementation
1. how to switch from one process to another? context switching.
2. how to force switches in a way that is transparent to user processes? standard technique of driving context switches with timer interrupts.
3. many CPUs may be switching among processes concurrently, and a locking plan is necessary to avoid races.
4. a process's memory and other resources must be freed when the process exits, but it cannot do all of this itself because for example it can't free its own kernel stack while still using it.
5. each core of a multi-core machine must remember which process it is executiing so that system calls affect the correct process's kernel state.
6. `sleep` and `wakeup` allow a process to give up the CPU and sleep waiting for an event, and allows another process to wake the first process up.
## Code: Context Switching
### I. steps of context switching
for example, switch from shell to cat.
1. a user-kernel trnaisition (system call or interrupt) to the old process's kernel thread
2. a context switch to the current CPU's scheduler thread.
3. a context switch to a new process's kernel thread
4. a trap return to the user-level process.
### II. switching between kernel thread and scheduler thread.
1. xv6 scheduler has a dedicated thread (saved registers and stack) per CPU because it is not safe for the scheduler execute on the old process's kernel stack: some other core might wake the process up and run it, it would be a disaster to use the same stack on two different cores.
2. `swtch` performs the saves and restores register sets(called contexts) for a kernel thread switch. The sp and pc are saved/restored means the CPU will switch stacks and switch what code it is executing
3. context is contained in a `struct context`, it's contained in a process's `struct proc` or a CPU's `struct cpu`.
4. `swtch` takes two arguments: `struct context *old` and `struct context *new`, it saves the current registers in `old` and loads registers from `new` then return.
5. the process is: `usertrap` -> `yield` -> `sched` -> `swtch` to save current context in `p->context` and switch to the scheduler context previously saved in `cpu->scheduler`.
6. `swtch` only saved `callee-saved registers`, `caller-saved registers` are saved on the stack by calling C code. `swtch` knows the offset of each register's field in `struct context`. 
7. `swtch` saves the `ra` register instead of `pc`. `ra` holds the return address from which `swtch` was called.
8. `swtch` saves current register set -> restores registers of new context -> executing -> return to `ra` (it returns on the new thread's stack).
## Code: Scheduling
### I. Steps (yield, sleep and exit follows this convention)
1. process acquire process lock `p->lock`, release any other locks it is holding
2. update its own state (p->state)
3. call `sched`.
4. `sched` double checks those conditions and check if interupts are disabled (which implicates lock)
5. `sched` calls `swtch` to save the current context in `p->context` and switch to the scheduler context in `cpu -> scheduler`.
6. `swtch` returns on the scheduler's stack as though the `scheduler`'s `swtch` had returned.
7. The scheduler continues the `for` loop, finds a process to run, switches to it, and the cycle repeats.
### II. lock passing
1. xv6 holds `p->lock` across calls to `swtch`: caller already hold the lock, and control of the lock passes to the switched-to code. 
2. This is unusual. But it is because `p->lock` protects invariants on the process's `state` and `context` fields that are not true while executing in `swtch`.
3. otherwise: if `p->lock` were not held during `swtch`: a different CPU might decide to run the process after `yield` had set its state to RUNNABLE, but before `swtch` caused it to stop using its own kernel stack. The result would be two CPUs running on the same stack.
### III. two invariants
1. if a process is `RUNNING`, a timer interrupt's `yield` must be able to safely switch away from the process, which means CPU registers must hold the process's register values and `c->proc` must refer to the process.
2. if a process is `RUNNABLE`, it must be safe for an idle CPU's `scheduler` to run it, which means that `p->context` must hold the process's registers, no CPU is executing on the process's kernel stack, and no CPU's `c-proc` refers to the process. 
### III. MISC
1. kernel thread always gives up its CPU in `sched` and always switches to the same location in the scheduler, which always switches to some kernel thread that previously called `sched`.
2. One case when the scheduler's call to `swtch` does not end up in `sched`: when a new process is first scheduled, it begins at `forkret`, which exists to release the `p->lock`. otherwise, the new process could start at `usertrapret`
## Code: mycpu and myproc
### I. `struct cpu` contents
1. current process
2. saved registers
3. count of nested spinlocks needed to manage interrupt disabling
### II. indexing the CPU
1. RISC-V numbers its CPUs, giving each a `hartid`, which stores in `tp` register.
2. `mstart` sets the `tp` register early in the CPU's boot sequence, while still in machine mode.
3. `usertrapret` saves `tp` in the trampoline page, because user process might modify `tp`.
4. `uservec` restores that saved `tp` when entering the kernel from user space. The compiler guarantees never to use the `tp` register.
5. in supervisor mode, one cannot read hartid directly, otherwise it would be more convenient.
### III. disable interrupts during use `mycpu()`
1. return values of `cpuid` and `mycpu` are fragile. If timer interrupts and yield to another CPU, the values will no longer be valid.
2. to solve this, xv6 requires that callers disable interrups and only enable them after they finish using the returned `struct cpu`.
### IV. `myproc()` steps
1. disables interrupts
2. invokes `mycpu`
3. fetch current process pointer (`c->proc`)
4. enable interrupts
5. returns `struct proc` pointer
6. return value is safe to use even if the interrupts are enabled, because the pointer will stay valid even if the CPU change.
## Sleep and Wakeup
### I. Purpose
1. provide a way for processes to interact intentinoally.
2. often called `sequence coordination or conditional synchronization`.
### II. What is Sleep and Wakeup?
1. `sleep(chan)` sleeps on the arbitrary value `chan`, called the `wait channel`. 
2. `sleep` puts the calling process to sleep, releasing the CPU for other work.
3. `wakeup(chan)` wakes all processes sleeping on `chan` (if any), causing their `sleep` calls to return.
4. if no processes are waiting on `chan`, `wakeup` does nothing.
### III. `lost wake-up` problem
1. imagine A and B. B sleeps until A done something.
2. after the while(false) line, if CPU yields to A, then A did that thing, but B keeps sleeping and missed the wake up opportunity.
### IV. `condition lock` to sleep
1. to solve `lost wake-up` problem, B must acquire a lock to prevent A doing the job between the judgement and sleep.
2. B must pass the `condition lock` to `sleep` so it can release the lock after B is marked as asleep and waiting on the sleep channel.
3. the lock will force A to wait until B falls asleep.
## Code: Sleep and Wakeup
### I. idea
1. `sleep` record the sleep channel, mark the current process as `SLEEPING` then call `sched` to release the CPU.
2. `wakeup` loops over the process table to find a process sleeping on the given wait channel and marks it as `RUNNABLE`.
3. it's important that `wakeup` is called while holding the condition lock.
4. callers of `sleep` and `wakeup` can use any multually convenient number as the channel. xv6 often uses the address of a kernel data structure involved in the waiting.
5. minor complication: when `wait` calls `sleep`, the `p->lock` is same as `lk` and it's already held. So we don't need to acquire and release.
### II. why it won't miss a wakeup
1. the sleeping process holds either the condition lock or its own `p->lock` or both from a point before it checks the condition to a point after it is marked `SLEEPING`.
2. the process calling `wakeup` holds both of those locks in a `wakeup` loop.
3. thus the waker either makes the condition true before the consuming thread checks the condition; or the waker's `wakeup` examines the sleeping thread strictly after it has been marked `SLEEPING`. 
### III. multiple processes sleeping on the same channel
1. example: more than one process reading from a pipe.
2. a single call to `wakeup` will wake them all up. But only first run will read data. Rest will find they have no data to read. They must sleep again. 
3. the wakeup like this is called "spurious"
4. because of this, `sleep` is always called inside a loop that checks the condition.
5. no harm is done when facing this condition.
## Code: Pipes
### I. pipe structure
1. `struct pipe` contains a `lock` and a `data` buffer. The fields `nread` and `nwrite` count the total number of bytes read from and written to the buffer. 
2. The buffer wraps around: next of PIPESIZE-1 is 0. Counts do not wrap.
3. full buffer: nwrite == nread + PIPESIZE; empty buffer: nwrite == nread.
### II. implementation of `pipewrite`
1. acquire the pipe's lock, which protects the counts, the data and their associated invariants.
2. loops over the bytes being written, adding each to the pipe in turn.
3. when buffer fills, `pipewrite` calls `wakeup` to alert any sleeping readers and then sleeps on `&pi->nwrite` to wait for a read to take some bytes out of the buffer.
4. `sleep` releases `pi->lock` as part of putting `pipewrite`'s process to sleep.
### III. implementation of `piperead`
1. when `pipewrite` writing data, `piperead` keeps spinning and waiting for the lock to be available for `acquire`
2. it finds `pi->nread != pi->nwrite`, so it falls through to the for loop, copies data out of the pipe, increments `nread`.
3. when finished, `piperead` calls `wakeup` to wake corresponding writer by channel. Then it sleeps on `&pi->nread`.
### IV. seperate sleep channels
pipe code uses separate sleep channels for reader and writeer. This might make the system more efficient in the unlikely event that there are lots of readers and writers waiting for the same pipe. When there are multiple readers or writers, all but the first will sleep again.
## Code: Wait, Exit, and Kill
### I. interactions between `wait` and `exit`
1. when child dies, the parent may be sleeping in `wait`, or may be doing something else. In the latter case, a subsequent call must observe child's death.
2. in xv6, caller of exit will be put into the `ZOMBIE` state, where it stays until the parent's `wait` notices it, changes child state to `UNUSED`, copies the child's exit status, and returns the child's process ID to the parent.
3. if parent exits before child, parent gives child to the `init` process, which perpetually calls wait, thus every child has a parent to clean up after it.
4. the challenge of this implementation is the possibility of races and deadlock between parent and child `wait` and `exit`, as well as `exit` and `exit`
### II. Wait
1. `wait` uses the calling process's `p->lock` as the condition lock to avoid lost wakeups, and it acquires that lock at the start.
2. it scans the process table, if found a child in `ZOMBIE` state, it frees that child's resources and its `proc` structure, copies the child's exit status to the address supplied to `wait` (if not 0), returns the child's process ID. 
3. if no child exited, parent keeps sleep and then scan
4. condition lock being released in `sleep` is the waiting process's `p->lock`.
5. `wait` often holds two locks: a. its own lock first then try to acquire b. child's lock
6. all xv6 must obey same locking order (parent, then child) in order to avoid deadlock.
7. `wait` looks at every process's `np->parent` without holding `np->lock` which looks like a violation but actually safe. Because a process's `parent` field is only changed by its parent.
### III. Exit
1. `exit` records the exit status, frees some resources, gives any child to the `init` process, wakes up the parent in case it is in `wait`, marks the caller as a zombie, and permanently yields the CPU. 
2. must hold parent's lock while it sets state to `ZOMBIE` and wakes parent up because parent's lock is the condition lock that guards against lost wakeups in `wait`.
3. must hold its own `p->lock`, because otherwise the parent might see it in `ZOMBIE` and free it while it is still running.
4. lock acquisision order is important to avoid deadlock: since `wait` acquries the parent's lock before the child's lock, `exit` must use the same order.
5. `exit` calls `wakeup1` which wakes up only the parent and only if it is sleeping in `wait`. It may look incorrect for the child to wake up the parent before setting its state to `ZOMBIE`, but that is safe. Although `wakeup1` may cause the parent to run, the loop in `wait` cannot examine the child until the child's `p->lock` is released by `scheduler`, so `wait` can't look at the exiting process until well after `exit` has set its state to `ZOMBIE`
### IV. Kill
1. sets the victim's `p->killed` and if it is sleeping, wakes it up.
2. eventually the victim will enter/leave the kernel, at which point code in `usertrap` will call `exit`.
3. sometimes xv6 `sleep` loops do not check `p->killed` because the code is in the middle of a multi-step system call that should be atomic. 
## Read World
### I. scheduling policy
1. `round robin`, used in xv6
2. real OS allow processes to have priorities. But need to gearantee fairness and high throughput.
3. `priority inversion`: can happen when a low-priority and high-priority process share a lot, high wait for one.
4. `convoy`: many high are waiting for a low.
### II. `lost wakeup` challenge
1. xv6, FreeBSD: add an explicit lock to `sleep`
2. Plan 9: `sleep` uses a call back function that runs with the scheduling lock held just before going to sleep. The function serves as a last-minute check of the sleep condition to avoid lost wakeups.
3. Linux: `sleep` uses an explicit process queue, called a wait queue, instead of a wait channel. The queue was its own internal lock.
### III. Scanning in `wakeup`
1. replace `chan` in both `sleep` and `wakeup` with a data structure that holds a list of processes sleeping on that data structure, such as Linux's wait queue.
2. Plan 9: `sleep` and `wakeup` call that structure a rendezvous point or `Rendez`. Many thread libraries refer to the same structure as a condition variable. In the context, the operations `sleep` and `wakeup` are called `wait` and `signal`.
3. All of these machanisms share the same flavor: the sleep condition is protected by some kind of lock dropped atomically during sleep.
### IV. drawback: `wakeup` wakes up too many processes
1. it's called `thundering herd`.
2. two primitives for wake up: `signal` wakes up one process; `broadcast` wakes up all waiting processes.
### V. `Semaphores`
1. often used for synchronization.
2. count typically corresponds to something lie the number of bytes available in a pipe buffer, the number of zombie children that a process has. 
3. count the number of wakeups that occured can solve the `lost wakeup` problem. It also avoids spurious wakeup and thundering herd problem.
### VI. `kill`
1. xv6 implementation is not entirely satisfactory:
2. sleep loops which should check for `p->killed`, but there is a race between `sleep` and `kill`. 
3. if `kill` wins, the killing may be quite a bit later or never.
### VII. MISC
A real OS would find free `proc` structures with an explicit free list in constant time instead of the linear-time search in `allocproc`
