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
## Using threads (moderate) ✔
1. declear a lock
```
pthread_mutex_t lock[NBUCKET];            // declare a lock
```
2. new insert()
```
    static void 
*   insert(int key, int value, struct entry **p)
    {
        struct entry *e = malloc(sizeof(struct entry));
        e->key = key;
        e->value = value;
+       pthread_mutex_lock(&lock[key % NBUCKET]);       // acquire lock
*       e->next = *p;
        *p = e;
+       pthread_mutex_unlock(&lock[key % NBUCKET]);     // release lock
    }
```
3. new put()
```
*   insert(key, value, &table[i]);
```
4. add initlock to main()
```
  for(int i = 0; i < NBUCKET; i++){
    pthread_mutex_init(&lock[i], NULL); // initialize the lock
  }
```
## Barrier(moderate) ✔
```
static void 
barrier()
{
  round++;
  if(round == nthread){
    pthread_mutex_lock(&bstate.barrier_mutex);   
    pthread_cond_broadcast(&bstate.barrier_cond);   
    pthread_mutex_unlock(&bstate.barrier_mutex);
    round = 0;
    bstate.round++;
  } else {
    pthread_mutex_lock(&bstate.barrier_mutex);
    pthread_cond_wait(&bstate.barrier_cond,&bstate.barrier_mutex);   
    pthread_mutex_unlock(&bstate.barrier_mutex);
  }
}
```