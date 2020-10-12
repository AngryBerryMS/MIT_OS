# Lab 5: Lazy Page Allocation
## Eliminate allocation from sbrk() (easy) ✔
in sys_sbrk() in kernel/sysproc.c
```
-   if(growproc(n) < 0)
-       return -1;
+   myproc()->sz += n;
```
## Lazy allocation (moderate) ✔
## Lazytests and Usertests (moderate) ✔
files to modify: kernel/sysproc.c, kernel/trap.c, kernel/vm.c
### I. new sys_sbrk()
```
uint64 sys_sbrk(void) {
  struct proc *p = myproc();
  uint64 addr = p->sz, read;
  argaddr(0, &read);
  long n = (long)read;
  if(n < 0){
    if(p->sz + n < 0){
      return -1;
    } else {
      uvmdealloc(p->pagetable, p->sz, p->sz+n);
    }
  }
  p->sz += n;
  return addr;
}
```
### II. kernel/trap.c
add function lazyalloc, which takes virtual memory address notmapped as input, it will examine its validity first, if it's beyond the assigned process size or it's within the range of guard page, it will return -1
```
int lazyalloc(uint64 notmapped){
  struct proc *p = myproc();
  pagetable_t pagetable = p->pagetable;
  char *mem;
  uint64 sp = p->trapframe->sp;
  if(notmapped > p->sz || (notmapped < sp) || (mem = kalloc()) == 0){
    return -1;
  } else {
    memset(mem,0,PGSIZE);
    if(mappages(pagetable, notmapped, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      return -1;
    }
  }
  return 0;
}
```
modify the if...else... block in usertrap(), there are two cases when the page is not mapped but already allocated to process. First case is system call, like read, write and pipe, here we judge the system call by register a7 and read corresponding va. If va is not valid, it will not call syscall() and directly set return value a0 to -1. Second case is page fault, when the va is invalid, we kill the process.
```
  if(r_scause() == 8){
    ...
    int num = p->trapframe->a7, valid = 0;
    uint64 va;
    if(num == 16 || num == 4 || num == 5){
      if(num == 16 || num == 5){ // sys_write sys_read
        argaddr(1, &va);
      } else if (num == 4) { // sys_pipe
        argaddr(0, &va);
      }
      if(walkaddr(p->pagetable,va) == 0){
        lazyalloc(PGROUNDDOWN(va));
      }
    }
    if(valid == -1){
      p->trapframe->a0 = -1;
    } else {
      syscall();
    }
  } else if((which_dev = devintr()) != 0){
    // ok
  } else if (r_scause() == 13 || r_scause() == 15){
    if(lazyalloc(PGROUNDDOWN(r_stval())) == -1)
      p->killed = 1;
  } else {
    ...
  }
```
### III. kernel/vm.c
uvmunmap()
```
    if((pte = walk(pagetable, a, 0)) == 0) continue; // page of pages not mapped
      // panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0) continue; // page not mapped
      // panic("uvmunmap: not mapped");
```
uvmcopy()
```
    if((pte = walk(old, i, 0)) == 0) continue; // page of pages not mapped
      // panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0) continue; // page not mapped
      // panic("uvmcopy: page not present");
```