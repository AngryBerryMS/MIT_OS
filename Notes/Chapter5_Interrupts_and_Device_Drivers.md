# Chapter 5 Interrupts and Device Drivers
## Overview
### I. What's a driver?
A driver is the code in an OS that manages a particular devices, it configures the device hardware, tells the device to perform operations, handles the resulting interrupts, and interacts with processes that may be waiting for I/O from the device.
### II. Device Interrupt
Device can generate interrupts if it wants attention from OS. 
### III. Top half & Bottom half
#### top half: kernel thread
called via system calls such as `read` and `write` that want the device to perform I/O. This code may ask the hardware to start an operation (e.g. ask the disk to read a block), then wait. Eventually the device completes the operation and raises an interrupts.
#### bottom half: interrupts
the driver's interrupt handler, acting as the bottom half, figures out what operation has completed, wakes up a waiting process and tells the hardware to start work on any waiting next operation.
## Code: Console input
### I. console input driver
1. the console driver accepts characters typed by a human via the UART serial-port hardware attached to the RISC-V.
2. UART is a 16550 chip emulated by QEMU. On a real computer, a 16550 would manage an RS232 serial link connecting to a terminal or other computer. On QEMU, it's connected to your keyboard and display.
3. UART appears to software as a set of `memory-mapped control registers`. There are some physical addresses that the RISC-V hardware connects to the UART device, so that loads and stores interact with the device hardware rather than RAM. 
4. the `memory-mapped control registers` starts at 0x10000000 or UART0. There are a handful of UART control registers, each is a byte. Their offsets from UART0 are defined in kernel/uart.c For example: a. LSR contain bits indicating whether input are ready to be read. b. characters can be read from RHR in FIFO. c. when FIFO is empty, LSR clears the "ready" bit. d. UART transmit hardware is largely independent of the receive harware, if software writes a byte to THR, the UART transmit that byte.
### II. procedures
1. `main` calls `consoleinit`, this code configures the UART to generate a `receive interrupt` when the UART receives each byte of input and a `transmit complete interrupt` each time the UART finishes sending a byte of output. 
2. xv6 shell reads from the console through file descriptor opened by init.c. Calls to the `read` system call make their way through the kernel to `consoleread`. `consoleread` waits for input to arrive (via interrupts) and be buffered in `cons.buf`, copies the input to user space, and returns to the user process after a whole line arrived. If user hasn't typed a full line yet, any reading processes will wait in the `sleep` call. 
3. user types a character -> UART hardware asks the RISC-V to raise an interrupt, which activates the trap handler.
4. trap handler calls `devintr` to look at the RISC-V `scause` register to discover that the interrupt is from an external device.
5. it asks hardware unit to call a hardware unit called PLIC to tell which device interrupted. If it was the UART, `devintr` calls `uartintr`.
6. `uartintr` reads any waiting input characters from the UART hardware and hands then to `consoleintr`, it doesn't wait for characters, since future input will raise a new interrupt.
7. the job of `consoleintr` is to accumulate input characters in `cons.buf` until a whole line arrives. `consoleintr` treats backspace and a few other characters specially. When a newline arrives, `consoleintr` wakes up a waiting `consoleread` (if there is one).
## Code: Console output
### I. Procedures
1. the device driver maintains an output buffer `uart_tx_buf` so that writing processes do not have to wait for the UART to finish seding
2. `uartputc` appends each character to the buffer, calls `uartstart` to start the device transmitting (if it is not) and returns. 
3. the only situation in which `uartputc` waits is if the buffer is already full.
4. each time UART finishes sending a byte, it generates an interrupt. `uartintr` calls `uartstart`, which checks that the device really has finished sending, and hands the device the next buffered output character.
5. if a process writes multiple bytes to the console, typically the first byte will be sent by `uartputc`'s call to `uartstart`, and the remaining buffered bytes will be sent by `uartstart` calls from `uartintr` as transmit complete interrupts arrive.
### II. purpose of buffering and interrupts
1. to decouple device activity from process activity.
2. the console driver can process input even when no process is waiting to read it. a subsequent read will see the input. Similar for the ouput.
3. decoupling can increase performance by allowing processes to execute concurrently with device I/O, and it's particularly important when the device is slow (like UART) or needs immediate attention.
4. this idea is sometimes called `I/O concurrency`.
## Concurrency in drivers
### I. three concurrency dangers
1. two processes on different CPUs might call `consoloeread` at the same time.
2. the hardware might ask a CPU to deliver a console (really UART) interrupt while that CPU is already executing inside `consoleread`.
3. the hardware might deliver a console interrupt on a different CPU while `consoleread` is executing.
### II. another care for concurrency
One process may be waiting for input from a device, but the interrupt signaling arrival of the input may arrive when a different process (or no process at all) is running. Thus interrupt handlers are not allowed to think about the process or code that they have interrupted.
## Timer Interrupts
### I. usage
1. xv6 uses timer interrupts to maintain its clock and switch among compute-bound processes.
2. yield calls in `usertrap` and `kerneltrap` cause this switching. 
3. timer interrupts are from clock hardware attached to CPU. it interrupts CPU periodically.
### II. machine mode environment
timer interrupts are seperate from the trap machanism. It's in machine mode, which doesn't have paging and has a seperate set of control registers.
### III. Implementation
1. code executed in machine mode in `start.c` before `main`, sets up to receive timer interrupts. 
2. part 1: program the CLINT hardware to generate an interrupt after a certain delay. 
3. part 2: set up a scratch area, analogous to the trapframe, to help the timer interrupt handler save registers and the address of the CLINT registers. 
4. Finally, start sets `mtvec` to `timervec` and enables timer interrupts.
### IV. machanism to avoid disturb kernel
1. kernel can't disable timer interrupts even during critical operations because timer interrupt is in machine mode.
2. to avoid this, handler asks the RISC-V to raise a `software interrupt` and immediately return. 
3. the RISC-V delivers software interrupts to the kernel with the ordinary trap machanism and allows the kernel to disable them. 
### V. MISC
1. machine mode timer interrupt vector is `timervec`2
2. it saves a few registers in the scratch area prepared by `start`, tells the CLINT when to generate the next timer interrupt, asks the RISC-V to raise a software interupt, restores registers, and returns. 
3. There is no C code in the timer interrupt handler.
## Real World
### I. drives
in many operating systems, the drivers account for more code than the core kernel. It can be troublesome due to complexity and poor documentations.
### II. DMA
1. UART driver retrives data a byte at a time by reading the UART control registers. It's called `programmed I/O`, it's simple but slow when data rate is high. 
2. Devices that need to move lots of data at high speed typically use direct memory access (DMA), which supports directly write/read RAM. 
3. Modern disk and network devices use DMA. It would prepare data in RAM, and use a single write to a control register to tell the device to process the prepared data.
4. UART driver copies incoming data first to a buffer in kernel, then to user space. the performance would be bad when the devices generates/consume data very quickly. Some operating systems are able to directly move data between user-space buffers and device hardware, often with DMA
### III. applicable situation
1. interrupts make sense when a device needs attention at unpredicable times and not too often.
2. interrupts have high CPU overhead.
3. high speed devices, such as networks and disk controllers, use tricks to reduce the need for interrupts. a. raise a single interrupts for a whole batch of incoming/outgoing requets. b. disable interrupts, check the device periodically (polling), which makes sense if the device performs operations very quickly, but it wastes CPU time if the device is mostly idle. Some drivers dynamically switch between polling and interrupts depending on the load.
