# Lab 4: traps
## RISC-V assembly (easy) ✔
see Answers.md
## Backtrace (moderate) ✔
see lab manual for changes made in defs.h, printf.c, riscv.h, sysproc.c
```
void backtrace(void){
  uint64 fp = r_fp(), stacktop = PGROUNDUP(fp);
  for(uint64 fp = r_fp(); fp < stacktop - 16; fp = *(uint64 *)(fp - 16))
    printf("%p\n", *(uint64 *)(fp - 8));
}
```
## Alarm (hard)
## (optional) Print the names of the functions and line numbers in backtrace() instead of numerical addresses (hard).