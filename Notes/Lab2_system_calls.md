# Lab 2: System Calls
## System call tracing (moderate) ✔
### I. add trace to makefile
```
    UPROGS=\
        ...
+       $U/_trace\
```
### II. add trace to user/user.h
```
// system calls
    ...
+   int trace(int);
```
### III. add trace to user/usys.pl, which modify `user/usys.S` the actual system call stubs
```
    ...
+   entry("trace");
```
### IV. add trace to kernel/syscall.h
```
    ...
+   #define SYS_trace  22
```
### V. add `tracemask` to struct proc in kernel/proc.h
```
struct proc {
    ...
+   int tracemask;
}
```
### VI. implement `sys_trace()` in kernel/sysproc.c
```
uint64
sys_trace(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  myproc()->tracemask = n;
  return 0;
}
```
### VII. modify `fork()` to copy `tracemask` from parent process to child process in proc.c
```
int
fork(void)
{
    ...
+   // Copy the trace mask from parent to child
+   np->tracemask = p->tracemask;
    ...
}
```
### VIII. modify kernel/syscall.c for indexing, modify `sys_call()` as well
```
    ...
+   extern uint64 sys_trace(void);
    ...
static uint64 (*syscalls[])(void) = {
    ...
+   [SYS_trace]   sys_trace,
};
```
add the following array
```
char * syscall_name[NELEM(syscalls)] = {
  "",  "fork", "exit", "wait", "pipe",
  "read", "kill", "exec", "fstat", "chdir",
  "dup", "getpid", "sbrk", "sleep", "uptime",
  "open", "write", "mknod", "unlink", "link",
  "mkdir", "close", "trace"
};
```
modify `sys_call()`
```
void
syscall(void)
{
...
    if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
        p->trapframe->a0 = syscalls[num]();
+       // print trace output
+       if((1 << num) & p->tracemask)
+           printf("%d: syscall %s -> %d\n",p->pid,syscall_name[num],p->trapframe->a0);
    } else {
...
    }
}
```
Note: refer to https://medium.com/@viduniwickramarachchi/add-a-new-system-call-in-xv6-5486c2437573 for better understanding.
## Sysinfo (moderate) ❌ (kernel/sysinfo.h is missing, waiting for update)
### I. add sysinfotest to makefile
```
    UPROGS=\
        ...
+       $U/_sysinfotest\
```
### II. add sysinfotest to user/user.h
```
    ...
+   struct sysinfo;
    // system calls
    ...
+   int sysinfo(struct sysinfo *);
```
### III. add sysinfotest to user/usys.pl, which modify `user/usys.S` the actual system call stubs
```
    ...
+   entry("sysinfotest");
```
### IV. add sysinfotest to kernel/syscall.h
```
    ...
+   #define SYS_sysinfotest  23
```
## (optional) Print the system call arguments for traced system calls (easy)
## (optional) Compute the load average and export it through sysinfo(moderate)