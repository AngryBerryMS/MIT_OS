# Chapter 3 Page Tables
## Paging Hardware
### PTE
1. xv6 runs on `Sv39 RISC-V`, means only the bottom 39 bits of a 64-bit virtual address are used. Top 25 bits are not used.
2. xv6 page table is an array of 2^27 (27 comes from 39 - 12, 12 is the offset) `PTE`s (page table entries). Each PTE contains a 44-bit physical page number (`PPN`) and some flags. Which makes a 56-bit physical address. (2^56 bytes = 2^26 GB = 67108864 GB)
3. the offset 12 bits comes from page size 2^12 = 4096 bytes
### Three level structure
1. in sv39, page table is stored in physical memory as a three-level tree. The root is a 4096B page-table page that contains 512 PTEs (one is 8B).
2. Paging hardware raises a page-fault exception when an address is not present.
3. Three-level structure allows a page table to omit entire table pages when large ranges of virtual address have no mappings.
4. PTE flag bits: `PTE_V` - validity, `PTE_R` - read, `PTE_W` - write, `PTE_X` - execute, `PTE_U` - whether it's allowed in user mode code.
### Physical Address and Virtual address
1. each CPU keeps the physical address of root page-table into the `satp` register. Different CPU can run different processes.
2. physical memory refers to storage cells in DRAM. Instructions can only use virtual address.
## Kernel Address Space
### Layout
1. QEMU simulates a computer includes RAM starting at physical address 0x80000000(Kernel Base) and continuing through at least 0x86400000, which xv6 calls `PHYSTOP`.
### Direct Mapping
1. Kernel is located at same address in both virtual and physical address. Direct mapping simplifies the kernel code.
2. a couple of kernel virtual addresses that aren't direct-mapped: a. the trampoline page(mapped twice, once physical and once direct). b. kernel stack pages, each process has its own kernel stack.
### Mapping
1. kernel maps the pages for the trampoline and the kernel text with the permissions `PTE_R` and `PTE_X`
2. kernel maps the other pages with the permissions `PTE_R` and `PTE_W`.
3. mappings for guard pages are invalid.
## Creating an address space
1. `main` calss `kvminit` to create kernel's page table (physical memory). `kvminit` allocates a page of physical memory to hold the root page-table page. Then it calls `kvmmap` to install the translations that the kernel needs.
2. `kvmmap` calls `mappages` to install mappings to a page table for a range of virtual address, for each virtual address to be mapped, `mappages` calls `walk` to find the address of the `PTE` for that address. It then initialized the `PTE` and mark it with flags.
3. `walk` mimics the RISCV paging hardware as it looks up the `PTE` for a virtual address.
## Physical memory allocation
xv6 uses the physical memory between the end of the kernel and `PHYSTOP` for run-time allocation. It allocates and frees whole 4096B pages at a time.
## Physical Memory Allocator
free list
...
## Process address Space
### Process
1. use `kalloc` to allocate physical pages. It then adds `PTE`s to the process's page table that point to the new physical pages. xv6 leaves `PTE_V` clear in unused `PTE`s.
2. stack in xv6 is a single page, from high to low, there is a guard page below stak, once overflow, hardware generate a page-fault exception.
## sbrk
`sbrk` is the system call for a process to shrink or grow its memory.
## exec
`exec` reads a ELF binary, load its `proghdr`. it need to implement secure check to prevent malicious program to read kernel memory.
...
## Real World
real world kernel address not necessary to start from 0x8000000, it may be allocate dynamically.