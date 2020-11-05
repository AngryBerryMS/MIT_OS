# Lab 9: File System
## Large files (moderate) ✔
bmap(): add these
```
static uint
bmap(struct inode *ip, uint bn)
{
...
  bn -= NINDIRECT;

  if(bn < NINDIRECT * NINDIRECT){
    // Load doubly-indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT+1]) == 0)
      ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    if((addr = a[bn/NINDIRECT]) == 0){
      a[bn/NINDIRECT] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    if((addr = a[bn%NINDIRECT]) == 0){
      a[bn%NINDIRECT] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }
...
}
```
itrunc()
```
void
itrunc(struct inode *ip)
{
  int i, j, k;
  struct buf *bp, *bpp;
  uint *a, *aa;
...
  if(ip->addrs[NDIRECT+1]){
    bp = bread(ip->dev, ip->addrs[NDIRECT+1]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
      if(a[j]){
        bpp = bread(ip->dev, a[j]);
        aa = (uint*)bpp->data;
        for(k = 0; k < NINDIRECT; k++){
          if(aa[k])
            bfree(ip->dev, aa[k]);
        }
        brelse(bpp);
        bfree(ip->dev, a[j]);
      }
    }
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT+1]);
    ip->addrs[NDIRECT+1] = 0;
  }
...
}
```
fs.h
```
#define NDIRECT 11
#define MAXFILE (NDIRECT + NINDIRECT + NINDIRECT * NINDIRECT)

struct dinode {
...
  uint addrs[NDIRECT+2];   // Data block addresses
};

```
file.h
```
struct inode {
...
  uint addrs[NDIRECT+2];
};
```
## Symbolic links (moderate) ✔
### I. add system call sys_symlink
```
refer to Lab 2
```
### II. kernel/fcntl.h
```
#define O_NOFOLLOW 0x800
```
### III. kernel/stat.h
```
#define T_SYMLINK 4   // symlink
```
### IV. kernel/sysfile.c
sys_open()
```
uint64
sys_open(void)
{
...
  int cnt = 0, length;
  char next[MAXPATH+1];
  if(!(omode & O_NOFOLLOW)){
    for( ;cnt < 10 && ip->type == T_SYMLINK; cnt++){
      readi(ip,0,(uint64)&length,0,4);
      readi(ip,0,(uint64)next,4,length);
      next[length] = 0;
      iunlockput(ip);
      ip = namei(next);
      if(ip == 0){
        // destination is symlink or target not exist
        end_op();
        return -1;
      }
      ilock(ip);
    }
  }
  if(cnt >= 10){
    // might have a cycle here
    iunlockput(ip);
    end_op();
    return -1;
  }
  

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
...
}
```
sys_symlink()
```
// return length of an array of char
int len(char *array){
  int res = 0;
  for( ;res < MAXPATH && array[res] != 0; res++);
  return res;
}

uint64 sys_symlink(void){
  char target[MAXPATH], path[MAXPATH];
  struct inode *newip;

  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    return -1;
  
  begin_op();
  // create a symlink file
  newip = create(path, T_SYMLINK, 0, 0);
  if(newip == 0){
    end_op();
    return -1;
  }

  // write the target path length and path into new inode
  int length = len(target);
  writei(newip,0,(uint64)&length,0,4);
  writei(newip,0,(uint64)target,4,length+1);
  iunlockput(newip);

  end_op();
  return 0;
}
```