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
## Lab 4: Traps
### I. Which registers contain arguments to functions? For example, which register holds 13 in main's call to printf?
```
a0 to a7 for integer and fa0 to fa7 for floats.
In this case, a2 holds 13 for printf
```
### II. Where is the call to function f in the assembly code for main? Where is the call to g? (Hint: the compiler may inline functions.)
```
main didn't call f, because compiler has optimized that process, in call.asm, it's straight 'li a1,12'
f did call g, but it is inline (directly use 'addiw a0, a0, 3')
```
### III. At what address is the function printf located?
```
0x628
```
### IV. What value is in the register ra just after the jalr to printf in main?
```
0x38, the address of next instruction after jalr
```
### V. Run the following code.
```
    unsigned int i = 0x00646c72;
    printf("H%x Wo%s", 57616, &i);
```
What is the output?
The output depends on that fact that the RISC-V is little-endian. If the RISC-V were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?
```
He110 World
57116 is e110 in hex and 0x00646c72 is 'dlr' according to ascii table.
If it's big endian, no need to change 57616 but need to reverse the value in i to 0x726c6400 (because it's read byte by byte).
```
### VI. In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?
```
	printf("x=%d y=%d", 3);
```
```
it prints value in register a2.
```