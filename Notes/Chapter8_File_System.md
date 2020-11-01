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