# Answers to lab questions
## Lab 3: Page Tables
### I. Explain the output of vmprint in terms of Fig 3-4 from the text. What does page 0 contain? What is in page 2? When running in user mode, could the process read/write the memory mapped by page 1?
```
page 0 contains PTE and flags of vm 0x00000000 to 0x20000000
page 2 contains PTE and flags of vm 0x80000000 to 0xa0000000
the process can read/write because the read/write flags are set (b10 and b100).
```
### II. Explain why the second test srcva + len < srcva is necessary in copyin_new(): give concrete values for which the first test (srcva + len >= p->sz) fails but for which the second one (srcva + len < srcva) is true.
```
to avoid overflow, which may be taken advantage in security perspective
Example:
    srcva:  0x0000000080000000
    len:    0xffffffff80000000
    p->sz:  0x0000000002000000
```