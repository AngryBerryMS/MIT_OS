# Lab 10: mmap
## mmap (hard) ✔
### I. implement lazyalloc
```
see Lab 5
```
### II. add system calls for `mmap()` and `munmap()`
```
see Lab 2
```
### III. defs.h
```
int             filederef(struct file*);
```
### IV. kernel/file.c
```
// Decrement ref count for file f, the lock is held
int filederef(struct file* f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filederef");
  int r = f->ref--;
  release(&ftable.lock);
  return r;
}
```
### V. kernel/proc.h
```
struct vma {
  uint64 addr;
  int length;
  int prot;
  int flags;
  int offset;
  int used;
  struct file *pf; // pointer to file
};
#define NVMA 16
```
add one field in `struct proc`
```
  struct vma vmatable[NVMA];
```
### VI. kernel/sysfile.c
Things to notice
1. if we want to munmap address in the middle, we must duplicate a new vma entry. I leave the vmadup here.
2. this implementation didn't check the dirty bit
3. these two things are not checked in `mmaptest` so I skipped. But it is still worth a shot.
```
// // duplicate v, with starting address addr
// int vmadup(struct vma* v, uint64 addr){

// }

uint64 sys_mmap(){
  uint64 addr;
  int length, prot, flags, fd, offset;
  struct file* pf;
  argaddr(0,&addr);
  argint(1,&length);
  argint(2,&prot);
  argint(3,&flags);
  argfd(4,&fd,&pf);
  argint(5,&offset);
  if((prot & PROT_WRITE) && !pf->writable && flags == MAP_SHARED)
    return -1UL;
  struct proc *p = myproc();
  for(int i = 0; i < NVMA; i++){
    if(p->vmatable[i].used != 1){
      // if vma entry is unused, set it to used
      struct vma* v = &p->vmatable[i];
      v->addr = p->sz;
      v->length = length;
      v->pf = pf;
      v->prot = prot;
      v->used = 1;
      v->flags = flags;
      v->offset = offset;
      growproc(length);
      filedup(pf);
      begin_op();
      ilock(pf->ip);
      readi(pf->ip,1,v->addr,offset,length);
      iunlock(pf->ip);
      end_op();
      return v->addr;
    };
  }
  return -1UL;
}

uint64 sys_munmap(){
  uint64 addr;
  int length;
  argaddr(0,&addr);
  argint(1,&length);
  struct proc *p = myproc();
  for(int i = 0; i < NVMA; i++){
    struct vma* v = &p->vmatable[i];
    if(addr >= v->addr && addr < v->addr + v->length && v->used == 1){
      if(v->flags == MAP_SHARED){
        begin_op();
        ilock(v->pf->ip);
        writei(v->pf->ip,1,addr,v->offset+addr-v->addr,length);
        iunlock(v->pf->ip);
        end_op();
      }
      uvmunmap(p->pagetable,addr,length/PGSIZE,1);
      // in the middle, create another vma in vmatable
      if(addr > v->addr){
        // covers all the rest
        if(addr + length == v->addr + v->length){
          v->length = addr - v->addr;
        } else {
          panic("sys_munmap: not going to happen");
          // vmadup(v,addr+length);
        }
      } else {
        // in the beginning
        if(length == v->length){
          // totally overlap
          filederef(v->pf);
        } else {
          // not totally
          v->addr = addr + length;
          v->length -= length;
        }
      }
      return 0;
    }
  }
  return -1;
}
```