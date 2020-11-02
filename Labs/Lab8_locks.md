# Lab 8: Locks
## Memory allocator (moderate) ✔
### 1. kernel/kalloc.c
change kmem into an array, each CPU is assigned with an element
```
    struct {
        struct spinlock lock;
        struct run *freelist;
*   } kmem[NCPU];
```
kinit()
```
void
kinit()
{
  // initalize all the memory locks
  for(int i = 0; i < NCPU; i++){
    char name[5];
    strncpy(name,"kmem",4);
    name[5] = '0' + i;
    initlock(&kmem[1].lock, name);
  }

  // allocate all the memory to current CPU
  push_off();
  freerange(end, (void*)PHYSTOP);
  pop_off();
}
```
kfree()
```
void
kfree(void *pa)
{
...
  // add the freed page to current CPU
  push_off();
  int id = cpuid();
  acquire(&kmem[id].lock);
  r->next = kmem[id].freelist;
  kmem[id].freelist = r;
  release(&kmem[id].lock);
  pop_off();
}
```
kalloc()
```
void *
kalloc(void)
{
  struct run *r;
  push_off();
  int i = cpuid();
  acquire(&kmem[i].lock);
  r = kmem[i].freelist;
  if(r) {
    kmem[i].freelist = r->next;
  } else {
    // look for available freelists
    for(int ii = 0; ii < NCPU; ii++) if(ii != i){
      acquire(&kmem[ii].lock);
      r = kmem[ii].freelist;
      if(r){
        kmem[ii].freelist = r->next;
        release(&kmem[ii].lock);
        break;
      }
      release(&kmem[ii].lock);
    }
  }
  release(&kmem[i].lock);
  pop_off();
...
}
```
## Buffer cache (hard) ✔ (partial)
### 0. didn't pass `manywrites` in usertests
### 1. buf.h
add two fields
```
  int active;  // is it in use? (free/inuse vs inactive)
  uint time;
```
### 2. kernel/bio.c
global
```
#define NBUCKET 13
struct spinlock readlock;
struct {
  struct spinlock lock;
  struct buf buf[NBUF];
} bcache[NBUCKET];
```
binit()
```
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
```
bget()
```
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
```
findbucket() new function to find the bucket number of given buffer
```
int findbucket(struct buf *b){
  for(int i = 0; i < NBUCKET; i++){
    if(b >= bcache[i].buf && b <= (bcache[i].buf + NBUF)){
      return i;
    }
  }
  panic("findbucket");
}
```
others
```
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
```