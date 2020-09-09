# Lab 3: Page Tables
## Print page table(easy)
1. add prototype to kernel/defs.h
```
    // vm.c
    ...
+   void            vmprint(pagetable_t);
```
2. insert call in kernel/exec.c
```
int
exec(char *path, char **argv){
    ...
+   vmprint(pagetable);
    return argc;
    ...
}
```
3. create vmprint in kernel/vm.c
```
...
void vmprint(pagetable_t pagetable){
  printf("page table %p\n", pagetable);
  for(int i = 0; i < 512; i++){
    pagetable_t PTE_1 = (pagetable_t)(*(pagetable+i) << 2 & 0xfffff000);
    if(PTE_1){
      printf(" ..%d: pte %p pa %p\n", i, *(pagetable+i), PTE_1);
      for(int j = 0; j < 512; j++){
        pagetable_t PTE_2 = (pagetable_t)(*(PTE_1+j) << 2 & 0xfffff000);
        if(PTE_2){
          printf(" .. ..%d: pte %p pa %p\n", j, *(PTE_1+j), PTE_2);
          for(int k = 0; k < 512; k++){
            pagetable_t PTE_3 = (pagetable_t)(*(PTE_2+k) << 2 & 0xfffff000);
            if(PTE_3)
              printf(" .. .. ..%d: pte %p pa %p\n", k, *(PTE_2+k), PTE_3);
          }
        }
      }      
    }
  }
}
```
## Simplify copyin/copyinstr (hard)
## (optional) Use super-pages to reduce the number of PTEs in page tables
## (optional) Extend your solution to support user programs that are as large as possible; that is, eliminate the restriction that user programs be smaller than PLIC.
## (optional) Unmap the first page of a user process so that dereferencing a null pointer will result in a fault. You will have to start the user text segment at, for example, 4096, instead of 0.