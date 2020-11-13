# Lab 11: Networking
## Network Driver (hard) ❌
```
can pass the ping test and single process ping test occasionally.
maybe it's an issue of network stabability / UDP reliability
```
kernel/e1000.c add one more lock
```
struct spinlock e1000_lock2;
...
    initlock(&e1000_lock2, "e10002");
```
kernel/e1000.c e1000_transmit()
```
int e1000_transmit(struct mbuf *m) {
  // TX ring index
  acquire(&e1000_lock);
  int i = regs[E1000_TDT];
  struct tx_desc* desc = &tx_ring[i];

  // E1000 hasn't finished the corresponding previous 
  // transmission request, so return an error.
  if(!(desc->status & E1000_TXD_STAT_DD)){
    release(&e1000_lock);
    return -1;
  }

  // free the last mbuf that was transmitted from that 
  // descriptor (if there was one)
  if(tx_mbufs[i]){
    mbuffree(tx_mbufs[i]);
  }

  // fill in the descriptor, set the necessary cmd flags
  // stash away a pointer to the mbuf 
  desc->addr = (uint64)m->head;
  desc->length = m->len;
  desc->cmd |= E1000_TXD_CMD_RS;
  if(!m->next)
    desc->cmd |= E1000_TXD_CMD_EOP;
  tx_mbufs[i] = m;
  
  // update the ring position
  regs[E1000_TDT] = (i + 1) % TX_RING_SIZE;
  release(&e1000_lock);
  return 0;
}
```
e1000_recv()
```
static void e1000_recv(void) {
  // RX ring index
  acquire(&e1000_lock2);
  int i = (regs[E1000_RDT] + 1) % RX_RING_SIZE;
  struct rx_desc* desc = &rx_ring[i];
  
  // check if a new packet is available
  if(!(desc->status & E1000_RXD_STAT_DD)){
    release(&e1000_lock2);
    return;
  }

  // update the mbuf's length
  // Deliver the mbuf to the network stack
  rx_mbufs[i]->len = desc->length;
  net_rx(rx_mbufs[i]);
  
  // allocate a new mbuf
  // Program its data pointer (m->head) into the descriptor. 
  // Clear the descriptor's status bits to zero.
  struct mbuf* m = rx_mbufs[i] = mbufalloc(0);
  if (!m){
    panic("e1000_recv");
  }
  desc->addr = (uint64)m->head;
  desc->status = 0;

  // update the ring position
  regs[E1000_RDT] = i;
  release(&e1000_lock2);
}
```
