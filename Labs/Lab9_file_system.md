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
## Symbolic links (moderate)