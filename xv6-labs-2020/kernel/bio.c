// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUCKET 13
struct spinlock readlock;
struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  // struct buf head;
} bcache[NBUCKET];

void binit(void) {
  for(int i = 0; i < NBUCKET; i++){
    char name[7];
    strncpy(name,"bcache",6);
    name[6] = 'a' + i;
    initlock(&bcache[i].lock, name);
  }
  // assign all buf to the first bucket
  for(int i = 0; i < NBUF; i++){
    bcache[0].buf[i].active = 1;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf* bget(uint dev, uint blockno) {
  // push_off();
  acquire(&readlock);
  struct buf *b;
  int id = blockno % NBUCKET;
  acquire(&bcache[id].lock);
  // Is the block already cached?
  for(int i = 0; i < NBUF; i++){
    b = &bcache[id].buf[i];
    if(b->dev == dev && b->blockno == blockno && b->active){
      b->refcnt++;
      b->time = ticks;
      release(&bcache[id].lock);
      // pop_off();
      release(&readlock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  struct buf *dst = 0, *src = 0;
  uint64 MIN = __INT64_MAX__;
  for(int i = 0; i < NBUF; i++){
    b = &bcache[id].buf[i];
    if(!b->active){
      dst = b;
    }
  }
  for(int i = 0; i < NBUCKET; i++){
    if(i != id && !holding(&bcache[i].lock)){
      acquire(&bcache[i].lock);
    }
    int clear = 0;
    for(int j = 0; j < NBUF; j++){
      b = &bcache[i].buf[j];
      if(b->active && b->time < MIN && b->refcnt == 0){
        src = b;
        MIN = b->time;
        clear = 1;
      }
    }
    if(clear){
      for(int ii = 0; ii < i; ii++){
        if(ii != id && holding(&bcache[ii].lock)){
          release(&bcache[ii].lock);
        }
      }
    }
  }
  if(MIN == __INT64_MAX__){
    panic("bget: no buffers");
  }
  if((uint64)dst == 0){
    dst = src;
  } else {
    src->active = 0;
    dst->active = 1;
  }
  dst->time = ticks;
  dst->dev = dev;
  dst->blockno = blockno;
  dst->valid = 0;
  dst->refcnt = 1;
  for(int i = 0; i < NBUCKET; i++) if(i != id && holding(&bcache[i].lock))
    release(&bcache[i].lock);
  release(&bcache[id].lock);
  release(&readlock);
  // pop_off();
  acquiresleep(&dst->lock);
  return dst;
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

int findbucket(struct buf *b){
  for(int i = 0; i < NBUCKET; i++){
    if(b >= bcache[i].buf && b <= (bcache[i].buf + NBUF)){
      return i;
    }
  }
  panic("findbucket");
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void brelse(struct buf *b) {
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);
  int id = findbucket(b);
  acquire(&bcache[id].lock);
  b->refcnt--;
  release(&bcache[id].lock);
}

void
bpin(struct buf *b) {
  int id = findbucket(b);
  acquire(&bcache[id].lock);
  b->refcnt++;
  release(&bcache[id].lock);
}

void
bunpin(struct buf *b) {
  int id = findbucket(b);
  acquire(&bcache[id].lock);
  b->refcnt--;
  release(&bcache[id].lock);
}


