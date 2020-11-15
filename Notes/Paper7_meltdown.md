# Paper 7: Meltdown
## Introduction
### I. isolation
supervisor bit
1. this bit can only be set when entering kernel code.
2. it is cleared when switching to user processes.
### II. Meltdown
1. Meltdown exploits side-channel information available on most modern processors
2. The root cause: out-of-order execution.
## Background
### I. out-of-order execution
1. On the Intel architecture, the pipeline consists of the front-end, the execution engine (back-end) and the memory subsystem.
2. this algo is in execution engine
### II. Address Space
ASLR: randomizes the offsets where drivers are located on every boot.
### III. Cache Attacks
1. Cache side-channel attacks exploit timing differences that are introduced by the caches. 
2. cache attack techniques: Evict+Time, Prime+Probe, and Flush+Reload. 
3. Flush+Reload attacks work on a single cache line granularity. These attacks exploit the shared, inclusive last-level cache. An attacker frequently flushes a targeted memory location using the clflush instruction. By measuring the time it takes to reload the data, the attacker determines whether data was loaded into the cache by another process in the meantime.
## Building Blocks of the Attack
### I. Executing Transient Instruction
1. Accessing user-inaccessible pages, such as kernel pages, triggers an exception. 
2. two approaches: With exception handling, we catch the exception effectively occurring after executing the transient instruction sequence, and with exception suppression, we prevent the exception from occurring at all and instead redirect the control flow after executing the transient instruction sequence.
#### A. Exception Handling
A trivial approach is to fork the attacking application before accessing the invalid memory location that terminates the process and only access the invalid memory location in the child process.
#### B. Exception Suppression
If an exception occurs within the transaction, the architectural state is reset, and the program execution continues without disruption.
### II. Building a Covert Channel
After the transient instruction sequence accessed an accessible address, i.e., this is the sender of the covert channel; the address is cached for subsequent accesses. The receiver can then monitor whether the address has been loaded into the cache by measuring the access time to the address. Thus, the sender can transmit a ‘1’-bit by accessing an address which is loaded into the monitored cache, and a ‘0’-bit by not accessing such an address.