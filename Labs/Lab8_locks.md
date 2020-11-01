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
## Buffer cache (hard)