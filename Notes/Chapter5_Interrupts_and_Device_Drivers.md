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

