# Paper 8: RCU
## Introduction
### I. What is RCU
1. Kernel developers have used a variety of techniques to
improve concurrency, including fine-grained locks, lockfree data structures, per-CPU data structures, and readcopy-update (RCU).
2. RCU has high performance in the presence of concurrent readers and updaters.
### II. RCU primitives
1. readers access data structures within RCU `read-side critical sections`. (`rcu_read_lock`, `rcu_read_unlock`)
2. updaters use RCU `synchronization` to wait for all pre-existing RCU read-side critical sections to complete. (`synchronize_rcu`, which guarantees not to return until all the RCU critical sections executing when synchronize_rcu was called have completed.)
## RCU Requirements
### I. three requirements dictated by the kernel
1. support for concurrent readers, even during updates.
2. low computation and storage overhead.
3. deterministic completion time. 
### II. Why these requirements:
1. Linux kernel uses many data structures that are read and updated intensively, especially in the virtual file system (VFS) and in networking.
2. low space overhead: kernel must synchronize access to millions of kernel objects. low execution overhead: kernel accesses data structures frequently using extremely short code paths.
3. This is critical to real-time response, but also has important software-engineering benefits, including the ability to use RCU within nonmaskable interrupt (NMI) handlers
## RCU Design
```
void rcu_read_lock()
{
preempt_disable[cpu_id()]++;
}
void rcu_read_unlock()
{
preempt_disable[cpu_id()]--;
}
void synchronize_rcu(void)
{
for_each_cpu(int cpu)
run_on(cpu);
}
```
## Using RCU
### I. Wait for Completion
simplest use of RCU is waiting for pre-existing activities to complete. In this use case, the waiters use synchronize_rcu, or its asynchronous counterpart call_rcu, and waitees delimit their activities with RCU read-side critical sections.\
The Linux NMI system uses RCU to unregister NMI handlers.\
Three properties:
1. high performance.
2. entering and completing an RCU critical section always executes a deterministic number of instructions.
3. the implementation of the NMI system allows dynamically registering and unregistering NMI handlers.
### II. Reference Counting
1. RCU is a useful substitute for incrementing and decrementing reference counts. 
2. Rather than explicitly counting references to a particular data item, the data item’s users execute in RCU critical sections. 
3. To free a data item, a thread must prevent other threads from obtaining a pointer to the data item, then use call_rcu to free the memory.
### III. Type Safe Memory
Type safe memory is memory that retains its type after being deallocated.
### IV. Publish-Subscribe
1. In the publish-subscribe usage pattern, a writer initializes a data item, then uses rcu_assign_pointer to publish a pointer to it. 
2. Concurrent readers use rcu_dereference to traverse the pointer to the item, The rcu_assign_pointer and rcu_dereference primitives contain the architecture-specific memory barrier instructions and compiler directives necessary to ensure that the data is initialized before the new pointer becomes visible, and that any dereferencing of the new pointer occurs after the data is initialized
### V. Read-Write Lock Alternative
1. The most common use of RCU in Linux is as an alternative to a read-write lock. 
2. Reading threads access a data structure in an RCU critical section, and writing threads synchronize with other writing threads using spin locks. 
3. The guarantees provided by this RCU usage pattern are different than the guarantees provided by read-write locks. 
4. Although many subsystems in the Linux kernel can tolerate this difference, not all can. 
5. The next section describes some complimentry techniques that developers can use with RCU to provide the same guarantees as read-write locking, but with better performance