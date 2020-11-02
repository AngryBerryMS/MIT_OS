# Chapter 8: File System
### I. What's file system?
1. Support sharing of data among users and applications, and persistence so the data is still available after a reboot.
2. xv6 fs provides Unix-like files, directories and pathnames stored on a virtio disk for persistence.
### II. Challenges
1. Needs on-disk data structures to represent the tree of named directories and files.
2. Support `crash recovery`, which might interrupt a sequence of updates and leave inconsistent on-disk data structures.
3. Coordinate to maintain invariants.
4. Maintain an in-memory cache of popular blocks.
## Overview
### I. buffer cache layer
1. caches disk blocks.
2. synchronizes access, make sure only one kernel process at a time can modify the data in any particular block.
### II. logging layer
1. allows higher layers to wrap updates to several blocks in a transaction (atomic).
### III. inode layer
1. provides individual files, each as an inode with a unique i-number and some blocks holding the file's data.
### IV. directory layer
each directory as a special kind of inode whose content is a sequence of directory entries, each of which contains a file's name and i-number.
### V. pathname layer
provides hierarchical path names like `/usr/trm/xv6/fs.c`, and resolves them with recursive lookup.
### VI. file descriptor layer
abstracts many Unix resources (e.g., pipes, devices, files, etc.) using the file system interface, simplifying the lives of application programmers.
### VII. storage plan
1. `block 0` as boot sector
2. `block 1` is `superblock` which contains metadata about the file system.
3. `blocks starting at 2` hold the log
4. after the log are the `inodes`
5. after those come `bitmap blocks` tracking which data blocks are in use.
6. the remaining are `data blocks`
## Buffer cache layer
### I. interfaces - bread and bwrite
1. `bread` obtains a buf containing a copy of a block which can be read or modified in memory.
2. `bwrite` writes a modified buffer to the appropriate block on the list.
3. call `brelse` when it's done to release a buffer.
4. it uses a per-buffer sleep-lock to ensure only one thread at a time uses each buffer.
5. `bread` returns a locked buffer, `brelse` releases the lock
6. the cache use the least recently used buffer.
## Code: Buffer Cache
### I. `binit()`
buffer cache is a doubly-linked list (cycled) of buffers, length is `NBUF`.
### II. buffer states
two state fields
1. `valid`: has data been read from disk
2. `disk`: does disk "own" buf
### III. `bread`
1. `bread` calls `bget` to get a buffer for the given sector
2. if needs to be read from fisk, `bread` calls `virtio_disk_rw` to do that before returning the buffer.
### IV. `bget`
1. scans forwards to find if the buf with given device and sector numbers present, if yes, return it.
2. if not, scan backwards to find the least recently unused block and return it. (unused is indicated by `bufref`)
3. still not, it panics. It's more graceful to sleep until a buffer became free, though it may cause deadlock.
4. must be at most one cached buffer per disk sector for synchronization and ensure the user see it. It's ensured by `bache.lock`.
5. it is safe for `bget` to acquire the buffer's sleep-lock outside the `bcache.lock` critical section, since the non-zero `b->refcnt` prevents the buffer being reused for a different disk block.
### V. `bread`
once `bread`, the caller has exclusive use of the buffer and can read/write. If it writes, must call `bwrite` to change data before releasing, `bwrites` calls `virtio_disk_rw` to talk to the disk hardware.
### VI. `brelse`
it releases the sleep-lock and moves the buffer to the front of the linked list. Why move? Because it's organized by how recently it is used.
## Logging Layer
### I. how does system write to disk?
1. places a description of all the disk writes to do in a log on the disk.
2. writes a special `commit` record to the disk indicating that the log contains a complete operation.
3. copies the writes to the on-disk file system data structures.
4. erases log on disk
### II. recovery code
1. if log is marked as containing a complete operation, it copies the writes to where they belong in the on-disk file system.
2. if no, it ignores the log.
3. it finishes by erasing the log.
### III. why solve crashes problem during file system operations?
1. crash before commit -> not be marked as complete -> ignore -> repeat all the writes
2. crash after commit -> finish
## Log Design
### I. Overview
1. log is at a known fixed location, specified in the superlock.
2. consists of a header block followed by a sequence of updated block copies.
3. header block contains an array of sector numbers, one for each of the logged blocks, and the count of log blocks.
4. if count is 0 -> no transaction in the log; not 0 -> log contains a complete committed transaction with the indicated number of logged blocks.
5. a crash midway though a transaction with result count 0; after commit will result in a non-zero count.
### II. atomic
1. start and end of the sequence of writes must be atomic to crashes.
2. logging system can accumulate the writes of multiple system calls into one transaction.
3. a single commit may involve the writes of multiple complete system calls.
4. to avoid splitting system call across transactions, the logging system only commits when no file-system system calls are underways.
### III. `Group Commit`
1. reduce the number of disk operations, amortizes the fixed cost of a commit over multiple operations.
2. hands the disk system more concurrent writes at the same time.
### IV. fixed amount of space to hold the log
1. no single system call can be allowed to write more distinct blocks than there is space in the log. (a problem for `write` and `unlink`)
2. limited log space is that the logging system cannot allow a system call to start unless it is certain that the system call's writes will fit in the space remaining in the log.
## Code: Logging
### I. struct log
1. `log.outstanding`: how many FS sys calls are executing.
2. `committing`: in commit(), please wait.
### II. `begin_op()`
1. wait until the logging system is not currently committing and until there is enough unreserved log space to hold the writes from this call.
### III. `log_write`
1. is a proxy for `bwrite`.
2. records the block's sector number in memory, reserving it a slot in the log on disk, and pins the buffer in the block cache to prevent the block cache from evicting it.
3. `absorption`: absorbe several disk writes into one, file system can save log space and can achieve better performance.
### IV. `end_op`
1. decrements the count of outstanding system calls.
2. if the count is now zero, it commits the current transaction by calling `commit()`.
### V. commit()
four stages in this process
1. `write_log()` Write modified blocks from cache to log
2. `write_head()` Write header to disk -- the real commit
3. `install_trans` Now install writes to home locations
4. sets log.lh.n to 0 and `write_head()` Erase the transaction from the log
### VI. recovery
1. `fsinit` call `initlog` call `recover_from_log`.
2. `recover_from_log` reads the log header, and mimics the actions of `end_op` if the header indicates that the log contains a committed transaction.
## Code: Block Allocator
### I. bitmap
1. one bit per block, 0 is free, 1 is in use
2. `mkfs` sets the bits
### II. `balloc`
scans all blocks, find one block with bit 0, set it to 1 then return.
### III. `bfree`
1. clear the bit.
2. `balloc` and `bfree` must be called inside a transaction.
## Inode Layer
### I. two definitions
1. on-disk: containing a file's size and list of data block numbers.
2. in-memory: contains a copy of the on-disk inode as well as extra info needed within the kernel.
### II. on-disk inodes
1. packed into a contiguous area of disk.
2. Every inode is the same size. It is easy to find the nth inode on the disk. N is called the inode number or i-number.
3. `type`: files, directories and special files. type of 0: free.
4. `nlink`: counts the number of directory entries that refer to this inode. To recognize when it can be freed.
5. `size`: in byte
6. `addrs`: records the block numbers of the disk blocks holding the file's content.
### III. in-memory inodes
1. stores only if there are C pointers referring to that inode.
2. `ref` counts the pointers, when it's 0, free the in-memory inode.
3. `iget` and `iput` acquire and release pointers to an inode, modifying `ref`.
4. pointers can come from file descriptors, current working directories, and transient kernel code such as `exec`.
### IV. lock/lock-like mechanisms
1. `icache.lock`: a. inode is present in the cache at most once. b. cached inode's `ref` field counts the number of in-memory pointers to the cached inode.
2. `lock` field: sleep lock -> exclusivity.
3. `ref`: in-memory won't be freed
4. `nlink`: inode won't be free
### V. `iget`, `iput`
1. `iget()` is guaranteed to be valid until `iput()` (won't be deleted, memory won't be reused)
2. `iget()` call `ilock` and read from disk, if has not already been read, call `iunlock`
3. multiple processes can hold a C pointer to an inode returned by `iget()`, but only one can lock -> prevents deadlock.
### VI. `iupdate()`
mainly job is synchronization rather than caching.
## Code: Inodes
