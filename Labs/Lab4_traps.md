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
## Alarm (hard) ✔
test0: see Lab2_system_calls.md for how to add a system call
files needs to be modified for system call: kernel/syscall.c, kernel/syscall.h, user/user.h, user/usys.pl, Makefile
add below in kernel/sysproc.c
```
uint64 sys_sigalarm(void){
  struct proc* p = myproc();
  // read param1
  argint(0, &p->ticks_interval);
  // read param2
  uint64 func;
  argaddr(1,&func);
  p->handler = (void (*)())func;
  return 0;
}

uint64 sys_sigreturn(void){
  // restore registers
  struct proc *p = myproc();
  p->ishandling = 0;
  memmove(p->trapframe,p->savedtrapframe,sizeof(struct proc));
  return 0;
}
```
add below in kernel/proc.c allocproc()
```
  if((p->savedtrapframe = (struct trapframe *)kalloc()) == 0){
    release(&p->lock);
    return 0;
  }
  p->ticks_passed = 0;
  p->ishandling = 0;
```
add these fields in struct proc in kernel/proc.h
```
  int ishandling;
  int ticks_interval;
  int ticks_passed;
  void (*handler)();
  struct trapframe *savedtrapframe;
```
change this part of kernel/trap.c into below
```
  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2){
    p->ticks_passed++;
    // if ticks_interval is 0, the handler() will never run
    if(p->ticks_passed == p->ticks_interval){
      p->ticks_passed = 0;
      if(p->ishandling == 0){
        memmove(p->savedtrapframe,p->trapframe,sizeof(struct proc));
        p->trapframe->epc = (uint64)p->handler;
        p->ishandling = 1;
      }
    }
    yield();
  }
```
## (optional) Print the names of the functions and line numbers in backtrace() instead of numerical addresses (hard).