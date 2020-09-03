# Lab 1: Utilities
## Boot xv6 (easy) ✔
``` 
make qemu
```
Note:
1. `Ctrl-p`: print process information
2. `Ctrl-a x`: quit qemu type
## sleep (easy) ✔
### I. add sleep to makefile
```
    UPROGS=\
        ...
+       $U/_sleep\
```
### II. creates `/user/sleep.c`
```
...
int main(int argc, char *argv[]){
  if(argc != 2){
      fprintf(2, "usage: sleep time\n");
      exit(1);
  } else {
      int time = atoi(argv[1]);
      sleep(time);
      exit(0);
  }
}
```
## pingpong (easy) ✔
### I. add pingpong to makefile
```
    UPROGS=\
        ...
+       $U/_pingpong\
```
### II. creates `/user/pingpong.c`
```
...
int main(int argc, char *argv[]){
    int p1[2], p2[2];
    pipe(p1);
    pipe(p2);
    char buf[1];
    if(fork() == 0){
        if(read(p1[0],buf,1))
            fprintf(2,"%d: received ping\n",getpid());
        write(p2[1],"B",1);
        close(p2[1]);
    } else {
        write(p1[1],"A",1);
        if(read(p2[0],buf,1))
            fprintf(2,"%d: received pong\n",getpid());
        close(p1[1]);
    }
    exit(0);
}
```
## primes (moderate) ✔
### I. add primes to makefile
```
    UPROGS=\
        ...
+       $U/_primes\
```
### II. creates `/user/primes.c`
```
...
int main(int argc, char *argv[]){
    int p[2][2];
    pipe(p[0]);
    for(int i = 2; i <= 35; i++)
        write(p[0][1],&i,1);
    close(p[0][1]);
    int idx = 0, sieve, num;
    while(fork() == 0){
        if(read(p[idx][0],&sieve,1)){
            fprintf(2,"prime %d\n",sieve);
            pipe(p[1^idx]);
            while(read(p[idx][0],&num,1)){
                if(num % sieve != 0)
                    write(p[idx^1][1],&num,1);
            }
            close(p[1^idx][1]);
            idx ^= 1;
        } else {
            exit(0);
        }
    }
    wait(0);
    exit(0);
}
```
## find (moderate)
## xargs (moderate)
## (optional) uptime (easy)
Write an uptime program that prints the uptime in terms of ticks using the uptime system call.
## (optinoal) find (easy)
Support regular expressions in name matching for find. grep.c has some primitive support for regular expressions.
## (optional) not print $ (moderate)
modify the shell to not print a $ when processing shell commands from a file
## (optional) support wait (easy)
modify the shell to support wait (easy)
## (optional) lists of commands (moderate)
modify the shell to support lists of commands, separated by ";" (moderate)
## (optional) sub-shells (moderate)
modify the shell to support sub-shells by implementing "(" and ")" (moderate)
## (optional) tab (easy)
modify the shell to support sub-shells by implementing "(" and ")"
## (optional) history (moderate)
modify the shell keep a history of passed shell commands (moderate)