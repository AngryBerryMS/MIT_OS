# Paper 4: vmware
## Classical Virtualization
### I. de-privileging
Classical VM executes guest operating system directly, but at a reduced privilege level. The VMM interrupts traps from the de-privileged guest, and emulates the trapping instruction against the virtual machine state.
### II. primary and shadow structures
1. `shadow structures`: derived from guest-level `primary structures`
2. VMM maintains an image of the guest register, and refer to that image in instruction emulation as guest operations trap.
3. `off-CPU` privileged data, such as page tables, may reside in memory. In this case, guest accesses to the privileged state may not naturally coincide with trapping instructions.
### III. memory traces
VMMs typically use hardware page protection mechanisms to trap accesses to in-memory primary structures.
### IV. tracing example: x86 pagetable
1. `shadow page tables` to protect host from guest memory accesses.
2. VMware's VMM manages its shadow page tables as a cache of the guest page tables. As the guest accesses untouched regions, hardware page faults vector control to the VMM.
3. VMM distinguishes `true page faults`, caused by violations of the protection policy encoded in the guest PTEs, from `hidden page faults`, caused by misses in the shadow page table.
4. true page faults are forwarded to the guest.
5. hidden faults cause VMM to construct an appropriate shadow PTE and resume guest execution.
6. VMM uses traces to prevent its shadow PTEs from becoming incoherent with the guest PTEs.
## Obstacles to classical virtualization of x86
### I. x86 obstacles to virtualization
1. visibility of privileged state
2. lack of traps when privileged instructions run at user-level.
### II. Simple Binary Translation
1. properties: binary, dynamic, on demand, system level, subsetting, adaptive
2. most instructions can be translated identically, but there are several noteworthy exceptions: PC-relative addressing, direct control flow, indirect control flow, privileged instructions.
### III. Adaptive Binary Translation
1. modern CPUs have expensive traps
2. simple BT eliminates traps from privileged instructions, but traps from non-privileged instructions (loads and stores,accessing sensitive data such as page tables) still remains and is more frequent.
3. adaptive BT to essentially eliminate latter.
## Hardware Virtualization
### I. x86 architecture extensions
1. new arch supports `virtual machine control block`, or VMCB, conbines control state with a subset of the state of a guest virtual CPU.
2. `guest mode`: a new, less privileged execution mode.
3. `vmrun`: transfers from host to guest mode.
4. `exit`: return to guest mode.
5. VMM behaves as a hypervisor for a general-purpose OS might allow that OS to drive system peripherals, handle interrupts, or build page tables.
### II. Hardware VMM implementation
1. most of the emulation code is shared with software VMM, which includes peripheral device models, code for delivery of guests interrupts, and many infrastructure tasks such as logging, synchronization and interaction with the host OS.
2. hardware VMM also inherits the software VMM's implementation of the shadowing technique.
### III. Discussion
1. reducing the frequency of exits is the most important optimization for classical VMMs
2. The exit rate is a function of guest behavior, hardware design, and VMM software design: a guest that only computes never needs to exit; hardware provides means for throttling some exit types; and VMM design choices, particularly the use of traces and hidden page faults, directly impact the exit rate as shown with the fork example above.
