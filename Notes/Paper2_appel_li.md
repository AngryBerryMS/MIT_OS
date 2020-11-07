# Paper 2: Virtual Memory Primitives for User Programs
## Virtual Memory Primitives
1. trap: handle page-fault traps in user mode
2. prot1: decrease the accesibility of a page
3. protN: decrease the accesibility of N pages
4. unprot: increase the accesibility of a page.
5. dirty: return a list of dirtied pages since the previous call.
6. map2: map the same physical page at two different virtual addresses, at different levels of protection, in the same address space.
## Virtual Memory Applications
### I. Concurrent Garbage Collections
#### A. Baker's Algorithm
1. it's a sequential real-time copying collector algorithm
2. it divides the heap memory into two regions. `from-space` and `to-space`. 
3. at the beginning of a collection, all objects are in `from-space`
4. starting with registers and other global roots, the collector traces out the graph of objects reachable from the roots.
5. it copies each reachable object into `to-space`.
6. a pointer to an object from `from-space` is forwarded by making it point to the `to-space` copy of the old object.
7. after a scan, the rest in `from-space` are garbage.
#### B. Baker's algorithm invariants
1. the mutator sees only `to-space` pointers in its registers
2. objects in the new area contain `to-space` pointers only
3. objects in the scanned area contain `to-space` pointers only
4. objects in the unscanned area contain both
#### C. Concurrent Collector
1. instead of checking every pointer fetched from memory, it uses virtual-memory page protections to detect `from-space` memory references and to synchronize mutators and collectors.
2. it sets unscanned pages "no access"
3. whenever mutator tries to access unscanned pages, it will get a page-access trap
4. collector fields the trap and scans the objects on that page, copying objects and forwarding pointers if needed.
5. then it unprotects the page and resumes the mutator.
#### D. required primitives
trap, protN, unprot, map2
1. map2 is used so that the garbage collector can scan a page while it is still inaccessible to the mutators.
### III. Shared Virtual Memory
#### A. usage
on a network of computers, on a multicomputer without shared memories, and on a multiprocessor based on interconnection networks.
#### B. SVM layout
each node in the system consists of a processor and its memory. The nodes are connected by a fast message-passing network.
#### C. SVM
1. the address space is coherent at all times.
2. the address space is partitioned into pages. Pages that are marked "read-only" can have copies residing in the physical memories of many processors at the same time. But a page bering written can reside in only one.
3. a page fault may occur when the page containing the memory location is not in a processor's current physical memory. When this happens, memory mapping manager retrieves the page from either disk or the memory of another processor.
#### D. required primitives
trap, prot1, unprot
### IV. Concurrent Checkpointing
#### A. access protection page fault mechanism
1. all threads in the program being checkpointed are stopped
2. the writable main memory space for the program is saved (heap, globals, and the stacks for the individual threads)
3. enough state informatino is saved for each thread so that it can be restarted
4. the threads are restarted
#### B. instead of saving the writable main memory space to disk all at once
1. the accessibility of entire address space is set to read only
2. at this point, the threads of the checkpoint program are restarted and a copying thread sequentially scans the address space, copying the pages to a separate virtual address space as it goes.
3. after this, it sets access rights to "read/write"
#### C. incremental checkpoints
1. saving the pages that hae been changed since last checkpoint.
2. instead of protecting all the pages with "read-only", the algorithm can protect only "dirtied" pages since the previous checkpoint.
#### D. required primitives
trap, prot1, protN, unprot, dirty
### V. Generational Garbage Collection
#### A. two properties
1. younger records are much more likely to die soon
2. younger records tend to point to older records
#### B. in practice
1. records will be kept in several distinct areas `Gi` of memory, called generations
2. the collector will usually collect in the youngest generation.
3. to perform a collection in a generation, the collector needs to know about all pointers into the generation: these pointers can be in machine registers, in global variables, and on the stack.
#### C. how to detect older points to younger?
1. special hardware
2. compilers, two or more instructions are requried
#### D. detect assignments to old objects
1. if `dirty` available, the collector can examine dirtied pages to derive pointers from older generations to younger generations and process them
2. if no, use page protection mechanism: older generations can be write-protected, any stores into them will cause a trap. User trap-handler can save the address of the trapping page on a list for the garbage collector. Then the page will be unprotected to allow the store. At garbage-collection time the collector will need to scan the pages on the trap-list for possible pointers into the younger generation.
#### E. required primitives
trap, protN, unprot or just dirty
### VI. Persistent Stores
#### A. what is persistent stores
1. it is a dynamic allocation heap that persists from one program-invocation to the next.
2. need to commit its modifications, may `abort`
#### B. something to notice
1. traversals of pointers in the persistent store is just as fast as fetches and stores in main memory.
2. it's not distinguishable by the compiled code of a program from data structures in core.
3. persistent store is a memory-mapped disk file.
4. the permanent image must not be altered until the `commit`.
5. in-core image is modified, and only at the `commit` are the "dirty pages" written back to disk
6. before commit, should do a garbage collection
7. it can be augmented to cleanly handle concurrency and locking
#### C. required primitives
trap, unprot
### VII. Entending Addressability
#### A. pointer length
1. in any one run of a program against the persistent store, it is likely that fewer than 2^32 objects will be accessed
2. objects in core use 32-bit addresses, objects on disk use 64-bit addresses
3. when one of these 32-bit core pointers is dereferenced for the first time, a page fault may be occur.
4. the fault handler brings in another page from disk, translating it to short pointers.
#### B. required primitives
trap, unprot, prot1/protN
### VIII. Data-compressing paging
#### A. theory
In a typical linked data structure, many words point to nearby objects; many words are nil. Those words that contain integers instead of pointers often contain small integers or zero. In short, the information-theoretic entropy of the average word is small. Furthermore, a garbage collector can be made to put objects that point to each other in nearby locations, thus reducing the entropy per word to as little as 7 bits.
#### B. required primitives
trap, prot1 (or perhaps protN)
### IX. heap overflow detection
#### A. conventional implementation
1. mark the pages above the top of the stack invalid or no-access
2. if page fault, it allocates more pages and resume execution
3. trap, protN, unprot
#### B. detect heap-overflow in a garbage collected system
1. delete guard page
2. when the end of the allocatable memory is reached, a page-fault trap invokes the garbage collector.
3. prot1, trap