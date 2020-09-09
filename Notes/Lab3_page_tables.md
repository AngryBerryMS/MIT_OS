# Lab 3: Page Tables
## Print page table(easy)
## Simplify copyin/copyinstr (hard)
## (optional) Use super-pages to reduce the number of PTEs in page tables
## (optional) Extend your solution to support user programs that are as large as possible; that is, eliminate the restriction that user programs be smaller than PLIC.
## (optional) Unmap the first page of a user process so that dereferencing a null pointer will result in a fault. You will have to start the user text segment at, for example, 4096, instead of 0.