#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){
    if(argc < 2){
        fprintf(2,"usage: xargs cmd [...]\n");
        exit(1);        
    }
    int flag = 1;
    char **newargv = malloc(sizeof(char*)*(argc+2));
    memcpy(newargv,argv,sizeof(char*)*(argc+1));
    newargv[argc+1] = 0; // null pointer for last one
    while(flag){
        char buf[512], *p = buf;
        while((flag = read(0,p,1)) && *p != '\n')
            p++;
        if(!flag) exit(0);
        *p = 0;
        newargv[argc] = buf;
        if(fork() == 0){
            exec(argv[1], newargv+1);
            exit(0);
        }
        wait(0);
    }
    exit(0);
}