struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  int active;  // is it in use? (free/inuse vs inactive)
  uint time;
  uint dev;
  uint blockno;
  struct sleeplock lock;
  uint refcnt;
  struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE];
};

