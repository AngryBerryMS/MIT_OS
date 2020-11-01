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
1. caches disk blocks and synchronizes access
