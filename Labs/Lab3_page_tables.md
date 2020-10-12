# Lab 3: Page Tables
## Print page table(easy) ✔
1. add prototype to `kernel/defs.h`
```
    // vm.c
    ...
+   void            vmprint(pagetable_t);
```
2. insert call in `kernel/exec.c`
```
int
exec(char *path, char **argv){
    ...
+   vmprint(pagetable);
    return argc;
    ...
}
```
3. create vmprint in `kernel/vm.c`
```
...
#define PAGETABLE_READ 512
void vmprint(pagetable_t pagetable){
  printf("page table %p\n", pagetable);
  for(int i = 0; i < PAGETABLE_READ; i++){
    pagetable_t PTE_1 = (pagetable_t)PTE2PA(pagetable[i]);
    if(pagetable[i] & PTE_V){
      printf(" ..%d: pte %p pa %p\n", i, pagetable[i], PTE_1);
      for(int j = 0; j < PAGETABLE_READ; j++){
        pagetable_t PTE_2 = (pagetable_t)PTE2PA(PTE_1[j]);
        if(PTE_1[j] & PTE_V){
          printf(" .. ..%d: pte %p pa %p\n", j, PTE_1[j], PTE_2);
          for(int k = 0; k < PAGETABLE_READ; k++){
            pagetable_t PTE_3 = (pagetable_t)PTE2PA(PTE_2[k]);
            if(PTE_2[k] & PTE_V)
              printf(" .. .. ..%d: pte %p pa %p\n", k, PTE_2[k], PTE_3);
          }
        }
      }      
    }
  }
}
```
## A kernel page table per process (hard) (actually bypassed) ❓ + Simplify copyin/copyinstr (hard) ✔
1. modify `kernel/exec.c`, so xv6 will create a kernel page table when run `exec()`
```
+ void vmcopy(pagetable_t pagetable1, pagetable_t pagetable2);
void exec(char *path, char **argv) {
  ...
+ uvmalloc(p->kpagetable,oldsz,sz);
+ vmcopy(p->pagetable,p->kpagetable);
  return argc;
}
```
2. modify `kernel/proc.c`\
add below references
```
extern pagetable_t kernel_pagetable;
extern pagetable_t pkvminit();
extern void vmcopy(pagetable_t pagetable1, pagetable_t pagetable2);
extern void pkvmmap(uint64 va, uint64 pa, uint64 sz, int perm, pagetable_t kpagetable);
void proc_freekpagetable(pagetable_t kpagetable, uint64 sz);
```
add some lines into `allocproc()` and `freeproc()` for the kpagetable
```
static struct proc* 
allocproc(void)
{
+ p->kpagetable = pkvminit();
+ vmcopy(kernel_pagetable,p->kpagetable);
}
...
static void
freeproc(struct proc *p)
{
+ if(p->kpagetable)
+   proc_freekpagetable(p->kpagetable, p->sz);
+ p->kpagetable = 0;
}
```
add function `proc_freekpagetable()` to free kernel part (user part skipped)
```
void proc_freekpagetable(pagetable_t kpagetable, uint64 sz) {
  uvmunmap(kpagetable, UART0, 1, 0);
  uvmunmap(kpagetable, VIRTIO0, 1, 0);
  uvmunmap(kpagetable, CLINT, 10, 0);
  uvmunmap(kpagetable, PLIC, 400, 0);
  uvmunmap(kpagetable, KERNBASE, (PHYSTOP - KERNBASE) / PGSIZE, 0);
  uvmunmap(kpagetable, TRAMPOLINE, 1, 0);
}
```
modify `userinit()` `growproc()` `fork()` and `scheduler()`
```
void
userinit(void)
{
  // after setting up this process's pagetable
+ uvmalloc(p->kpagetable,0,p->sz);
+ vmcopy(p->pagetable,p->kpagetable);
  release(&p->lock);
}
```
```
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
+   if (sz + n >= CLINT/5) {
+     return -1;
+   } else {
+     uvmalloc(p->kpagetable,sz,sz+n);
+   }
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
+   vmcopy(p->pagetable,p->kpagetable); 
  } else if(n < 0){
+   // if(sz <= PLIC)
+   //   uvmdealloc(p->kpagetable, sz, sz + n);
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}
```
```
int
fork(void)
{
  ...
  np->sz = p->sz;
+ uvmalloc(np->kpagetable,0,p->sz);
+ vmcopy(np->pagetable,np->kpagetable);
  np->parent = p;
  ...
}
```
```
void
scheduler(void)
{
  ...
        p->state = RUNNING;
+       w_satp(MAKE_SATP(p->kpagetable));
+       sfence_vma();
  ...
+     w_satp(MAKE_SATP(kernel_pagetable));
+     sfence_vma();
      intr_on();
}
```
3. modify `kernel/vm.c` \
add below code
```
extern int copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len);
extern int copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max);
void vmprint(pagetable_t pagetable);
void vmcopy(pagetable_t pagetable1, pagetable_t pagetable2);
void pkvmmap(uint64 va, uint64 pa, uint64 sz, int perm, pagetable_t kpagetable);
```
add `pkvinit()` to initialize kernel part of page table
```
// initialize kernel part of page table
pagetable_t pkvminit() {
  pagetable_t kpagetable = (pagetable_t) kalloc();
  memset(kpagetable, 0, PGSIZE);
  pkvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W, kpagetable);
  pkvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W, kpagetable);
  pkvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W, kpagetable);
  pkvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W, kpagetable);
  pkvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X, kpagetable);
  pkvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W, kpagetable);
  pkvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X, kpagetable);
  return kpagetable;
}
```
add `pkvmmap()` for mappage
```
void pkvmmap(uint64 va, uint64 pa, uint64 sz, int perm, pagetable_t kpagetable) {
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    panic("pkvmmap");
}
```
replace body of `copyin()` and `copyinstr()` with new call
```
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len) {
+ return copyin_new(pagetable,dst,srcva,len);
- *
}
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max){
+ return copyinstr_new(pagetable,dst,srcva,max);
- *
}
```
add function `vmcopy()` to copy the third level PTE from pagetable1 to pagetable2
```
#define PAGETABLE_LIMIT 512
// copy from 1 to 2
void vmcopy(pagetable_t pagetable1, pagetable_t pagetable2){
  int fromzero = (pagetable1 == kernel_pagetable) ? 0 : 1;
  for(int i = 0; i < PAGETABLE_LIMIT; i++){
    pagetable_t PTE_11 = (pagetable_t)PTE2PA(pagetable1[i]);
    pagetable_t PTE_21 = (pagetable_t)PTE2PA(pagetable2[i]);
    if(pagetable1[i] & PTE_V) for(int j = 0; j < PAGETABLE_LIMIT; j++){
      pagetable_t PTE_12 = (pagetable_t)PTE2PA(PTE_11[j]);
      pagetable_t PTE_22 = (pagetable_t)PTE2PA(PTE_21[j]);
      if(PTE_11[j] & PTE_V) for(int k = 0; k < PAGETABLE_LIMIT; k++){
        pagetable_t PTE_13 = (pagetable_t)PTE2PA(PTE_12[k]);
        pagetable_t PTE_23 = (pagetable_t)PTE2PA(PTE_22[k]);
        if((PTE_12[k] & PTE_V) && ((PTE_12[k] != PTE_22[k]) || (PTE_13 != PTE_23))){
          PTE_22[k] = PTE_12[k] & 0xffffffffffffffef; // clear PTE_U
          PTE_23 = PTE_23;
        } 
      } else if (fromzero) {
        return;
      }
    } else if (fromzero) {
        return;
    }
  }
}
```
4. add field in `proc` in `kernel/proc.h`
```
struct proc {
  ...
+ pagetable_t kpagetable;       // Kernel page table
}
```
## (optional) Use super-pages to reduce the number of PTEs in page tables
## (optional) Extend your solution to support user programs that are as large as possible; that is, eliminate the restriction that user programs be smaller than PLIC.
## (optional) Unmap the first page of a user process so that dereferencing a null pointer will result in a fault. You will have to start the user text segment at, for example, 4096, instead of 0.