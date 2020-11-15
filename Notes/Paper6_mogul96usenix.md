# Paper 6: Eliminating Receive Livelock in an Interrupt-driven Kernel
## Introduction
### I. Problems with interrupt-driven systems
Interrupt-driven systems tend to perform badly under overload.
### II. receive livelock
the system is not deadlocked, but it makes no progress on any of its tasks
## Motivating Applications
### I. specific applications that can suffer from livelock
1. Host-based routing
2. Passive network monitoring
3. Network File Service
## Requirements for scheduling network tasks
### I. Conceptions
1. throughput: the rate at which the system delivers packets to their ultimate consumers.
2. MLFRR: Maximum Loss Free Receive Rate
3. target: system throughput, resonable latency and jitter (variance in delay), fair allocation of resources, and overall system stabability
4. Many applications, such as distributed systems and interactive multimedia, often depend more on low-latency, low-jitter communications than on high throughput.
## Interrupt-driven scheduling and its Consequences
### I. Problems with interrupt-driven System
1. receive livelocks under overload
2. increased latency for packet delivery or forwarding
3. starvation of packet transmission
### II. Description of an interrupt-driven system
1. Device interrupts normally have a fixed Interrupt Priority Level (IPL). And preempt all tasks running at a lower IPL.
2. The queues between steps executed at different IPLs provide some insulation against packet losses due to transient overloads, but typically they have fixed length limits.
3. Dispatching an interrupt is cosly. To avoid this, network device driver attempts to batch interrupts.
### III. Receive Livelock
A system could behave in one of three ways as the input load increases.
1. ideal system: delivered throughput always matches the offered load
2. realizable system: the delivered throughput keeps up with the offered load up to the Maximum Loss Free Receive Rate (MLFRR). Relatively constant after that.
3. system prone to receive livelock: throughput falls to zero after MLFRR. Batching can increase the MLFRR. Batching can shift the livelock point but cannot, by itself, prevent livelock.
### IV. Receive Latency under overload
### V. Starvation of transmits under overload
Packets may be awaiting transmission, but the transmitting interface is idle. We call this transmit starvation.
## Avoiding Livelock Through Better Scheduling
### I. Limiting the interrupt arrival rate
1. When the system is about to drop a received packet because an internal queue is full, this strongly suggests that it should disable input interrupts.
2. We also need a trigger for re-enabling input interrupts.
### II. Use of polling
1. a purely interrupt-driven system leads to livelock
2. a purely polling system adds unnecessary latency
3. we employ a hybrid design, in which the system polls only when triggered by an interrupt, and interrupts happen only while polling is suspended.
### III. Avoiding Preemption
make higher-level packet processing non-preemptable.
