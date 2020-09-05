#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char* fmtname(char *path) {
    char *p;
    for(p=path+strlen(path); p >= path && *p != '/'; p--);
    return ++p;
}

void find(char *path, char *name){
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;
    if((fd = open(path, 0)) < 0) return;
    if(fstat(fd, &st) < 0) return;
    switch(st.type){
    case T_FILE:
        if(strcmp(name,fmtname(path)) == 0)
            printf("%s\n", path);
        break;
    case T_DIR:
        if(strlen(path) + 1 + DIRSIZ + 1> sizeof buf)
            break;
        strcpy(buf, path);
        p = buf+strlen(buf);
        *p++ = '/';
        char *init = p;
        while(read(fd, &de, sizeof(de)) == sizeof(de)){
            p = init;
            if(de.inum == 0)
                continue;
            for(int i = 0; de.name[i] != 0; i++)
                *p++ = de.name[i];
            *p++ = 0;
            if(stat(buf, &st) < 0)
                continue;
            if(strcmp(fmtname(buf),".") != 0 && strcmp(fmtname(buf),"..") != 0)
                find(buf,name);
        }
        break;
    }
    close(fd);
}

int main(int argc, char *argv[]){
    if(argc != 3){
        fprintf(2,"usage: find dir name\n");
        exit(1);
    }
    find(argv[1],argv[2]);
    exit(0);
}