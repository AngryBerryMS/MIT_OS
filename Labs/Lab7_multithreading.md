# Lab 7: Multithreading
## Uthread: switching between threads (moderate) ✔
### I. uthread.c
implement threading similar to processing switching
1. add context
```
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};
```
2. `struct thread`
```
  struct context context;
```
2. change declaration of `thread_switch`
```
extern void thread_switch(struct context*, struct context*);
```
3. in `thread_scheduler()`
```
thread_switch(&t->context, &next_thread->context);
```
4. in `thread_create()`
```
  t->context.ra = (uint64)func;
  t->context.sp = (uint64)t->stack + STACK_SIZE;
```
## Using threads (moderate)
## Barrier(moderate)