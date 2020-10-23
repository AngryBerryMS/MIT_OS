# Lab 6: Copy on Write
## Implement copy-on write(hard) ✔
### 0. usertests didn't pass
### 1. kernel/defs.h
add these declarations
```
// trap.c
int             cowalloc(pagetable_t, uint64);
...
// vm.c
pte_t*          walk(pagetable_t, uint64, int);
int             getvaidx(uint64);
int             vmcopy(pagetable_t, pagetable_t, uint64);
```
### 2. kernel/riscv.h
add these macros
unused but it's stated in lab manual
```
#define PTE_C (1L << 8) // COW
```
```
#define PAGETABLE_LIMIT 512
#define TOTPAGE 32768
```
### 3. kernel/kalloc.c
add array in beginning to count the number of page referrences. 
why I add PGCNT in kalloc? Can it be declared in other files? Because it is in the front of the Makefile topo order.

```
int PGCNT[TOTPAGE];
```
add below to kfree()
```
  if((long)pa >= KERNBASE && (long)pa < PHYSTOP && PGCNT[getvaidx((uint64)pa)] > 0){
    PGCNT[getvaidx((uint64)pa)]--;
    if(PGCNT[getvaidx((uint64)pa)] != 0){
      return;
    }
  }
```
add below to kalloc() right before return
```
  uint64 pa = (uint64)r;
  if((long)pa >= KERNBASE && (long)pa < PHYSTOP){
    // printf("kalloc %p %d\n", pa, getvaidx(pa));
    PGCNT[getvaidx(pa)]++; // set PGCNT
  }
```
### 4. kernel/fork.c
replace uvmcopy part with new vmcopy
```
  if(vmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
```
### 5. kernel/trap.c
```
// install new va for pagetable, return -1 to kill current process
int cowalloc(pagetable_t pagetable, uint64 va){
  if(va > MAXVA || walkaddr(pagetable, PGROUNDDOWN(va)) == 0)
    return -1;
  uint64 old = walkaddr(pagetable,PGROUNDDOWN(va));
  void* new = kalloc();
  if(new == 0){
    return -1;
  } else {
    memmove(new, (void*)old, PGSIZE);
    pte_t* pte = walk(pagetable, va, 0);
    *pte = PA2PTE((uint64)new)|PTE_W|PTE_FLAGS(*pte); // install and set W
    kfree((void*)old);
    return 0;
  }
}
```
add to usertrap()
```
    // ok
+ } else if(r_scause() == 13 || r_scause() == 15) {
+   if(cowalloc(p->pagetable, r_stval()) == -1) // no more pages available
+     p->killed = 1; 
  } else {
```
add to kerneltrap()
```
  if(r_scause() == 13 || r_scause() == 15){
    cowalloc(myproc()->pagetable, r_stval());
  } else if((which_dev = devintr()) == 0){
```
### 6. kernel/vm.c
add to beginning
```
extern int PGCNT[TOTPAGE];
```
comment this line in freewalk(), because then parent and child refers to the same page and you want to kfree the child pte, the leaf will not be freed because it's still in use for the parent.
```
// panic("freewalk: leaf");
```
modify copyout()
```
  uint64 n, va0, pa0;
+ pte_t *pte;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
+   pte = walk(pagetable, va0, 0);
+   if(!(*pte & PTE_W))
+     cowalloc(pagetable, va0);
...
  }
```
add this two functions
```
int getvaidx(uint64 pa){
  return (pa - KERNBASE) / PGSIZE; 
}

// copy from 1 to 2, return -1 when error occurs, return 0 when OK
int vmcopy(pagetable_t pagetable1, pagetable_t pagetable2, uint64 sz){
  uint64 mem, pagesleft = (sz + PGSIZE - 1) / PGSIZE;
  for(int i = 0; i < PAGETABLE_LIMIT; i++){
    pagetable_t PTE_11 = (pagetable_t)PTE2PA(pagetable1[i]);
    if(pagetable1[i] & PTE_V) {
      // install pagetable in pagetable2[i]
      if((mem = (uint64)kalloc()) == 0)
        return -1;
      pagetable2[i] = PA2PTE(mem) | PTE_V;
      memset((void *)mem,0,PGSIZE);
      pagetable_t PTE_21 = (pagetable_t)PTE2PA(pagetable2[i]);

      for(int j = 0; j < PAGETABLE_LIMIT; j++){
        pagetable_t PTE_12 = (pagetable_t)PTE2PA(PTE_11[j]);
        if(PTE_11[j] & PTE_V) {
          // install pagetable in PTE_21[j]
          if((mem = (uint64)kalloc()) == 0)
            return -1;
          PTE_21[j] = PA2PTE(mem) | PTE_V;
          memset((void *)mem,0,PGSIZE);
          pagetable_t PTE_22 = (pagetable_t)PTE2PA(PTE_21[j]);

          for(int k = 0; k < PAGETABLE_LIMIT; k++){
            if(pagesleft == 0) 
              return 0;
            if(PTE_12[k] & PTE_V){
              PTE_12[k] &= ~PTE_W; // clear W
              PTE_22[k] = (PTE_12[k] & ~0x3FF) | PTE_R | PTE_X | PTE_U | PTE_V; // copy from parent to child
              PGCNT[getvaidx(PTE2PA(PTE_12[k]))]++;
              pagesleft--;
            }
          }

        }
      }

    }
  }
  return 0;
}
```