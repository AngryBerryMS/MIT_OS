#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){
    int p1[2], p2[2];
    pipe(p1);
    pipe(p2);
    if(fork() == 0){
        char buf[1];
        read(p1[0],buf,1);
        if(*buf == 'A')
            fprintf(2,"%d: received ping\n",getpid());
        write(p2[1],"B",1);
        close(p2[1]);
    } else {
        char buf[1];
        write(p1[1],"A",1);
        read(p2[0],buf,1);
        if(*buf == 'B')
            fprintf(2,"%d: received pong\n",getpid());
        close(p1[1]);
    }
    exit(0);
}