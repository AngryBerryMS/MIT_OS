#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

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