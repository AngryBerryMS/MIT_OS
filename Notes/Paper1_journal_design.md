# Paper 1: Journaling the Linux ext2fs File System
## Introduction
### I. what can we design in a filesystem
1. layout of data on disk (or alternatively, perhaps, its network protocol, if the filesystem is not local)
2. details of internal caching
3. algorithms used to schedule disk IO
### II. what are our goals
1. performance
2. compatibility with existing applications
3. reliability
### III. filesystem reliability
1. Preservation: data which was stable on disk before the crash should never ever be damaged.
2. Predictability: failure modes from which we have to recover should be predictable in order for us to recover reliably
3. Atomicity: recorvery is atomic
### IV. existing implementations
1. ext2fs offers preservation, but no predicatability and atomicity
2. preservation requires the writes to disk in a predictable order.
3. `synchronous metadata update`: wait for the first writes to complete before submitting the next ones to the device driver. Slow.
4. `deferred ordered write`: maintain an ordering between the disk buffers in memory. Ensure when we eventually go to write back the data, we never write a block until all of its predecessors are safely on disk. Cannot handle cyclic dependencies.
5. `soft updates`: selectively rolling back specific updates within a buffer. Adopted by FreeBSD.
6. all of above share a common problem: recovery needs to scan the entire disk in order to find and repair any uncompleted operations.
7. `Log-Structured Filesystems`: only preserve new version of incomplete updates in disk.
8. `Journaling`: log enhanced. Preserve both old and new.
## Designing a New Filesystem for Linux
### I. Anatomy of a Transaction
1. transaction contains all of the changed metadata (i.e, file length, bitmap, last modified time)
2. ordering between transactions. A transaction which modifies a block on disk cannot commit after a transaction which reads that new data and then updates the disk based on what it read.
### II. Merging Transactions
#### Differences between Filesystem and Database
1. filesystem have no transaction abort (check before make transaction)
2. short-lived
#### How we take advantage of this?
create a new transaction every so often, allow all filesystem service calls to add their updates.
#### When to start transaction / commit?
depends on user. It involves a trade-off which affects system performance. Longer the waiting time of commit, more filesystem operations can be merged, less IO operations, but also larger window for loss of updates.
### III. On-disk representation
it is compatible with ext2fs, since it already have reserved inodes for the filesystem journal and a set of compatibility bitmaps.
### IV. Format of the Filesystem Journal
#### Three different types of data blocks of the journal
1. metadata
2. descriptor
3. header
#### Metadata Block
1. entire contents of a single block of filesystem metadata as updated by a transaction
2. must write whole block even if the change is small, but it doesn't matter because we can easily batch the journal IO and can save much CPU work.
#### buffer_head
1. it's the structure of every buffer in the buffer cache
2. write an entire block to a new location without disturbing the buffer_head. We can create a new, temporary buffer_head, copy the description from the old one, then edit the device block number then submit.
#### Descriptor Blocks
1. blocks describe other journal metadata blocks. 
2. both descriptor blocks and metadata blocks are written sequentially to the journal, starting again from the start of the journal whenever we run off the end.
3. log has head and tail.
4. when we run out of log space, we stall new log writes and wait.
#### Header Blocks
journal file contains a number of header blocks at fixed locations. Which records the current head and tail of the journal plus a sequence number.
### V. Committing and Checkpointing the Journal
#### When to commit
1. waited a long time
2. run out of space in the journal
#### Steps to Commit and Checkpoint
1. close the transaction
2. start flushing the transaction to disk
3. wait for all outstanding filesystem operations in this transaction to complete
4. wait for all outstanding transaction updates to be completely recorded in this journal
5. update the journal header blocks to record the new head and tail of the log, committing the transaction to disk.
6. when we wrote transaction's updated buffers out to the journal, we marked them as pinning the transaction in the journal. These buffers become unpinned only when they have been synced to their homes on disk.
### VI. Collisions between Transactions
to increase performance, we do not completely suspend filesystem updates when we are committing a transaction. Rather, we create a new compound transaction in which to record updates which arrive while we commit the old transaction.
#### Problem: an update wants access to a metadata buffer already owned by another, older transaction is currently being committed.
1. if it only wants to read, it's OK/
2. if it wants to write, let old copy commit first. Make a new copy of the buffer, and waiting for old.