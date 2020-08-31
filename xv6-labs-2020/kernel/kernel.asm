
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	af478793          	addi	a5,a5,-1292 # 80005b50 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	344080e7          	jalr	836(ra) # 8000246a <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	800080e7          	jalr	-2048(ra) # 800019ca <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	fe0080e7          	jalr	-32(ra) # 800021ba <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	1fe080e7          	jalr	510(ra) # 80002414 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	1ca080e7          	jalr	458(ra) # 800024c0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	ef0080e7          	jalr	-272(ra) # 8000233a <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	53478793          	addi	a5,a5,1332 # 800219b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	a98080e7          	jalr	-1384(ra) # 8000233a <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	87e080e7          	jalr	-1922(ra) # 800021ba <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	e16080e7          	jalr	-490(ra) # 800019ae <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	de4080e7          	jalr	-540(ra) # 800019ae <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	dd8080e7          	jalr	-552(ra) # 800019ae <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	dc0080e7          	jalr	-576(ra) # 800019ae <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d80080e7          	jalr	-640(ra) # 800019ae <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	42e50513          	addi	a0,a0,1070 # 80008070 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	d54080e7          	jalr	-684(ra) # 800019ae <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3e650513          	addi	a0,a0,998 # 80008078 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3ee50513          	addi	a0,a0,1006 # 80008090 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	3ae50513          	addi	a0,a0,942 # 80008098 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	aee080e7          	jalr	-1298(ra) # 8000199e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	ad2080e7          	jalr	-1326(ra) # 8000199e <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	1e250513          	addi	a0,a0,482 # 800080b8 <digits+0x78>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0d8080e7          	jalr	216(ra) # 80000fbe <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00001097          	auipc	ra,0x1
    80000ef2:	714080e7          	jalr	1812(ra) # 80002602 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	c9a080e7          	jalr	-870(ra) # 80005b90 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	000080e7          	jalr	ra # 80001efe <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    printfinit();
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	85e080e7          	jalr	-1954(ra) # 8000076c <printfinit>
    printf("\n");
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1b250513          	addi	a0,a0,434 # 800080c8 <digits+0x88>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66e080e7          	jalr	1646(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f26:	00007517          	auipc	a0,0x7
    80000f2a:	17a50513          	addi	a0,a0,378 # 800080a0 <digits+0x60>
    80000f2e:	fffff097          	auipc	ra,0xfffff
    80000f32:	65e080e7          	jalr	1630(ra) # 8000058c <printf>
    printf("\n");
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	19250513          	addi	a0,a0,402 # 800080c8 <digits+0x88>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	64e080e7          	jalr	1614(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	b8c080e7          	jalr	-1140(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	2a0080e7          	jalr	672(ra) # 800011ee <kvminit>
    kvminithart();   // turn on paging
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	068080e7          	jalr	104(ra) # 80000fbe <kvminithart>
    procinit();      // process table
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	970080e7          	jalr	-1680(ra) # 800018ce <procinit>
    trapinit();      // trap vectors
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	674080e7          	jalr	1652(ra) # 800025da <trapinit>
    trapinithart();  // install kernel trap vector
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	694080e7          	jalr	1684(ra) # 80002602 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	c04080e7          	jalr	-1020(ra) # 80005b7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	c12080e7          	jalr	-1006(ra) # 80005b90 <plicinithart>
    binit();         // buffer cache
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	dbc080e7          	jalr	-580(ra) # 80002d42 <binit>
    iinit();         // inode cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	44e080e7          	jalr	1102(ra) # 800033dc <iinit>
    fileinit();      // file table
    80000f96:	00003097          	auipc	ra,0x3
    80000f9a:	3ec080e7          	jalr	1004(ra) # 80004382 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f9e:	00005097          	auipc	ra,0x5
    80000fa2:	cfa080e7          	jalr	-774(ra) # 80005c98 <virtio_disk_init>
    userinit();      // first user process
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	cee080e7          	jalr	-786(ra) # 80001c94 <userinit>
    __sync_synchronize();
    80000fae:	0ff0000f          	fence
    started = 1;
    80000fb2:	4785                	li	a5,1
    80000fb4:	00008717          	auipc	a4,0x8
    80000fb8:	04f72c23          	sw	a5,88(a4) # 8000900c <started>
    80000fbc:	b789                	j	80000efe <main+0x56>

0000000080000fbe <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fbe:	1141                	addi	sp,sp,-16
    80000fc0:	e422                	sd	s0,8(sp)
    80000fc2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fc4:	00008797          	auipc	a5,0x8
    80000fc8:	04c7b783          	ld	a5,76(a5) # 80009010 <kernel_pagetable>
    80000fcc:	83b1                	srli	a5,a5,0xc
    80000fce:	577d                	li	a4,-1
    80000fd0:	177e                	slli	a4,a4,0x3f
    80000fd2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fd4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fd8:	12000073          	sfence.vma
  sfence_vma();
}
    80000fdc:	6422                	ld	s0,8(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret

0000000080000fe2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe2:	7139                	addi	sp,sp,-64
    80000fe4:	fc06                	sd	ra,56(sp)
    80000fe6:	f822                	sd	s0,48(sp)
    80000fe8:	f426                	sd	s1,40(sp)
    80000fea:	f04a                	sd	s2,32(sp)
    80000fec:	ec4e                	sd	s3,24(sp)
    80000fee:	e852                	sd	s4,16(sp)
    80000ff0:	e456                	sd	s5,8(sp)
    80000ff2:	e05a                	sd	s6,0(sp)
    80000ff4:	0080                	addi	s0,sp,64
    80000ff6:	84aa                	mv	s1,a0
    80000ff8:	89ae                	mv	s3,a1
    80000ffa:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ffc:	57fd                	li	a5,-1
    80000ffe:	83e9                	srli	a5,a5,0x1a
    80001000:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001002:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001004:	04b7f263          	bgeu	a5,a1,80001048 <walk+0x66>
    panic("walk");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	0c850513          	addi	a0,a0,200 # 800080d0 <digits+0x90>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	532080e7          	jalr	1330(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001018:	060a8663          	beqz	s5,80001084 <walk+0xa2>
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	af2080e7          	jalr	-1294(ra) # 80000b0e <kalloc>
    80001024:	84aa                	mv	s1,a0
    80001026:	c529                	beqz	a0,80001070 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001028:	6605                	lui	a2,0x1
    8000102a:	4581                	li	a1,0
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	cce080e7          	jalr	-818(ra) # 80000cfa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001034:	00c4d793          	srli	a5,s1,0xc
    80001038:	07aa                	slli	a5,a5,0xa
    8000103a:	0017e793          	ori	a5,a5,1
    8000103e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001042:	3a5d                	addiw	s4,s4,-9
    80001044:	036a0063          	beq	s4,s6,80001064 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001048:	0149d933          	srl	s2,s3,s4
    8000104c:	1ff97913          	andi	s2,s2,511
    80001050:	090e                	slli	s2,s2,0x3
    80001052:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001054:	00093483          	ld	s1,0(s2)
    80001058:	0014f793          	andi	a5,s1,1
    8000105c:	dfd5                	beqz	a5,80001018 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000105e:	80a9                	srli	s1,s1,0xa
    80001060:	04b2                	slli	s1,s1,0xc
    80001062:	b7c5                	j	80001042 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001064:	00c9d513          	srli	a0,s3,0xc
    80001068:	1ff57513          	andi	a0,a0,511
    8000106c:	050e                	slli	a0,a0,0x3
    8000106e:	9526                	add	a0,a0,s1
}
    80001070:	70e2                	ld	ra,56(sp)
    80001072:	7442                	ld	s0,48(sp)
    80001074:	74a2                	ld	s1,40(sp)
    80001076:	7902                	ld	s2,32(sp)
    80001078:	69e2                	ld	s3,24(sp)
    8000107a:	6a42                	ld	s4,16(sp)
    8000107c:	6aa2                	ld	s5,8(sp)
    8000107e:	6b02                	ld	s6,0(sp)
    80001080:	6121                	addi	sp,sp,64
    80001082:	8082                	ret
        return 0;
    80001084:	4501                	li	a0,0
    80001086:	b7ed                	j	80001070 <walk+0x8e>

0000000080001088 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001088:	57fd                	li	a5,-1
    8000108a:	83e9                	srli	a5,a5,0x1a
    8000108c:	00b7f463          	bgeu	a5,a1,80001094 <walkaddr+0xc>
    return 0;
    80001090:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001092:	8082                	ret
{
    80001094:	1141                	addi	sp,sp,-16
    80001096:	e406                	sd	ra,8(sp)
    80001098:	e022                	sd	s0,0(sp)
    8000109a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000109c:	4601                	li	a2,0
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	f44080e7          	jalr	-188(ra) # 80000fe2 <walk>
  if(pte == 0)
    800010a6:	c105                	beqz	a0,800010c6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010a8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010aa:	0117f693          	andi	a3,a5,17
    800010ae:	4745                	li	a4,17
    return 0;
    800010b0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b2:	00e68663          	beq	a3,a4,800010be <walkaddr+0x36>
}
    800010b6:	60a2                	ld	ra,8(sp)
    800010b8:	6402                	ld	s0,0(sp)
    800010ba:	0141                	addi	sp,sp,16
    800010bc:	8082                	ret
  pa = PTE2PA(*pte);
    800010be:	00a7d513          	srli	a0,a5,0xa
    800010c2:	0532                	slli	a0,a0,0xc
  return pa;
    800010c4:	bfcd                	j	800010b6 <walkaddr+0x2e>
    return 0;
    800010c6:	4501                	li	a0,0
    800010c8:	b7fd                	j	800010b6 <walkaddr+0x2e>

00000000800010ca <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010ca:	1101                	addi	sp,sp,-32
    800010cc:	ec06                	sd	ra,24(sp)
    800010ce:	e822                	sd	s0,16(sp)
    800010d0:	e426                	sd	s1,8(sp)
    800010d2:	1000                	addi	s0,sp,32
    800010d4:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010d6:	1552                	slli	a0,a0,0x34
    800010d8:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010dc:	4601                	li	a2,0
    800010de:	00008517          	auipc	a0,0x8
    800010e2:	f3253503          	ld	a0,-206(a0) # 80009010 <kernel_pagetable>
    800010e6:	00000097          	auipc	ra,0x0
    800010ea:	efc080e7          	jalr	-260(ra) # 80000fe2 <walk>
  if(pte == 0)
    800010ee:	cd09                	beqz	a0,80001108 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010f0:	6108                	ld	a0,0(a0)
    800010f2:	00157793          	andi	a5,a0,1
    800010f6:	c38d                	beqz	a5,80001118 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010f8:	8129                	srli	a0,a0,0xa
    800010fa:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010fc:	9526                	add	a0,a0,s1
    800010fe:	60e2                	ld	ra,24(sp)
    80001100:	6442                	ld	s0,16(sp)
    80001102:	64a2                	ld	s1,8(sp)
    80001104:	6105                	addi	sp,sp,32
    80001106:	8082                	ret
    panic("kvmpa");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	432080e7          	jalr	1074(ra) # 80000542 <panic>
    panic("kvmpa");
    80001118:	00007517          	auipc	a0,0x7
    8000111c:	fc050513          	addi	a0,a0,-64 # 800080d8 <digits+0x98>
    80001120:	fffff097          	auipc	ra,0xfffff
    80001124:	422080e7          	jalr	1058(ra) # 80000542 <panic>

0000000080001128 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001128:	715d                	addi	sp,sp,-80
    8000112a:	e486                	sd	ra,72(sp)
    8000112c:	e0a2                	sd	s0,64(sp)
    8000112e:	fc26                	sd	s1,56(sp)
    80001130:	f84a                	sd	s2,48(sp)
    80001132:	f44e                	sd	s3,40(sp)
    80001134:	f052                	sd	s4,32(sp)
    80001136:	ec56                	sd	s5,24(sp)
    80001138:	e85a                	sd	s6,16(sp)
    8000113a:	e45e                	sd	s7,8(sp)
    8000113c:	0880                	addi	s0,sp,80
    8000113e:	8aaa                	mv	s5,a0
    80001140:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001142:	777d                	lui	a4,0xfffff
    80001144:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001148:	167d                	addi	a2,a2,-1
    8000114a:	00b609b3          	add	s3,a2,a1
    8000114e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001152:	893e                	mv	s2,a5
    80001154:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001158:	6b85                	lui	s7,0x1
    8000115a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115e:	4605                	li	a2,1
    80001160:	85ca                	mv	a1,s2
    80001162:	8556                	mv	a0,s5
    80001164:	00000097          	auipc	ra,0x0
    80001168:	e7e080e7          	jalr	-386(ra) # 80000fe2 <walk>
    8000116c:	c51d                	beqz	a0,8000119a <mappages+0x72>
    if(*pte & PTE_V)
    8000116e:	611c                	ld	a5,0(a0)
    80001170:	8b85                	andi	a5,a5,1
    80001172:	ef81                	bnez	a5,8000118a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001174:	80b1                	srli	s1,s1,0xc
    80001176:	04aa                	slli	s1,s1,0xa
    80001178:	0164e4b3          	or	s1,s1,s6
    8000117c:	0014e493          	ori	s1,s1,1
    80001180:	e104                	sd	s1,0(a0)
    if(a == last)
    80001182:	03390863          	beq	s2,s3,800011b2 <mappages+0x8a>
    a += PGSIZE;
    80001186:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001188:	bfc9                	j	8000115a <mappages+0x32>
      panic("remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5650513          	addi	a0,a0,-170 # 800080e0 <digits+0xa0>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3b0080e7          	jalr	944(ra) # 80000542 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x74>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011c0:	86ae                	mv	a3,a1
    800011c2:	85aa                	mv	a1,a0
    800011c4:	00008517          	auipc	a0,0x8
    800011c8:	e4c53503          	ld	a0,-436(a0) # 80009010 <kernel_pagetable>
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f5c080e7          	jalr	-164(ra) # 80001128 <mappages>
    800011d4:	e509                	bnez	a0,800011de <kvmmap+0x28>
}
    800011d6:	60a2                	ld	ra,8(sp)
    800011d8:	6402                	ld	s0,0(sp)
    800011da:	0141                	addi	sp,sp,16
    800011dc:	8082                	ret
    panic("kvmmap");
    800011de:	00007517          	auipc	a0,0x7
    800011e2:	f0a50513          	addi	a0,a0,-246 # 800080e8 <digits+0xa8>
    800011e6:	fffff097          	auipc	ra,0xfffff
    800011ea:	35c080e7          	jalr	860(ra) # 80000542 <panic>

00000000800011ee <kvminit>:
{
    800011ee:	1101                	addi	sp,sp,-32
    800011f0:	ec06                	sd	ra,24(sp)
    800011f2:	e822                	sd	s0,16(sp)
    800011f4:	e426                	sd	s1,8(sp)
    800011f6:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	916080e7          	jalr	-1770(ra) # 80000b0e <kalloc>
    80001200:	00008797          	auipc	a5,0x8
    80001204:	e0a7b823          	sd	a0,-496(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001208:	6605                	lui	a2,0x1
    8000120a:	4581                	li	a1,0
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	aee080e7          	jalr	-1298(ra) # 80000cfa <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001214:	4699                	li	a3,6
    80001216:	6605                	lui	a2,0x1
    80001218:	100005b7          	lui	a1,0x10000
    8000121c:	10000537          	lui	a0,0x10000
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f96080e7          	jalr	-106(ra) # 800011b6 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001228:	4699                	li	a3,6
    8000122a:	6605                	lui	a2,0x1
    8000122c:	100015b7          	lui	a1,0x10001
    80001230:	10001537          	lui	a0,0x10001
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f82080e7          	jalr	-126(ra) # 800011b6 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000123c:	4699                	li	a3,6
    8000123e:	6641                	lui	a2,0x10
    80001240:	020005b7          	lui	a1,0x2000
    80001244:	02000537          	lui	a0,0x2000
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f6e080e7          	jalr	-146(ra) # 800011b6 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001250:	4699                	li	a3,6
    80001252:	00400637          	lui	a2,0x400
    80001256:	0c0005b7          	lui	a1,0xc000
    8000125a:	0c000537          	lui	a0,0xc000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f58080e7          	jalr	-168(ra) # 800011b6 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001266:	00007497          	auipc	s1,0x7
    8000126a:	d9a48493          	addi	s1,s1,-614 # 80008000 <etext>
    8000126e:	46a9                	li	a3,10
    80001270:	80007617          	auipc	a2,0x80007
    80001274:	d9060613          	addi	a2,a2,-624 # 8000 <_entry-0x7fff8000>
    80001278:	4585                	li	a1,1
    8000127a:	05fe                	slli	a1,a1,0x1f
    8000127c:	852e                	mv	a0,a1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001286:	4699                	li	a3,6
    80001288:	4645                	li	a2,17
    8000128a:	066e                	slli	a2,a2,0x1b
    8000128c:	8e05                	sub	a2,a2,s1
    8000128e:	85a6                	mv	a1,s1
    80001290:	8526                	mv	a0,s1
    80001292:	00000097          	auipc	ra,0x0
    80001296:	f24080e7          	jalr	-220(ra) # 800011b6 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000129a:	46a9                	li	a3,10
    8000129c:	6605                	lui	a2,0x1
    8000129e:	00006597          	auipc	a1,0x6
    800012a2:	d6258593          	addi	a1,a1,-670 # 80007000 <_trampoline>
    800012a6:	04000537          	lui	a0,0x4000
    800012aa:	157d                	addi	a0,a0,-1
    800012ac:	0532                	slli	a0,a0,0xc
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	f08080e7          	jalr	-248(ra) # 800011b6 <kvmmap>
}
    800012b6:	60e2                	ld	ra,24(sp)
    800012b8:	6442                	ld	s0,16(sp)
    800012ba:	64a2                	ld	s1,8(sp)
    800012bc:	6105                	addi	sp,sp,32
    800012be:	8082                	ret

00000000800012c0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c0:	715d                	addi	sp,sp,-80
    800012c2:	e486                	sd	ra,72(sp)
    800012c4:	e0a2                	sd	s0,64(sp)
    800012c6:	fc26                	sd	s1,56(sp)
    800012c8:	f84a                	sd	s2,48(sp)
    800012ca:	f44e                	sd	s3,40(sp)
    800012cc:	f052                	sd	s4,32(sp)
    800012ce:	ec56                	sd	s5,24(sp)
    800012d0:	e85a                	sd	s6,16(sp)
    800012d2:	e45e                	sd	s7,8(sp)
    800012d4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012d6:	03459793          	slli	a5,a1,0x34
    800012da:	e795                	bnez	a5,80001306 <uvmunmap+0x46>
    800012dc:	8a2a                	mv	s4,a0
    800012de:	892e                	mv	s2,a1
    800012e0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	0632                	slli	a2,a2,0xc
    800012e4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ea:	6b05                	lui	s6,0x1
    800012ec:	0735e263          	bltu	a1,s3,80001350 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012f0:	60a6                	ld	ra,72(sp)
    800012f2:	6406                	ld	s0,64(sp)
    800012f4:	74e2                	ld	s1,56(sp)
    800012f6:	7942                	ld	s2,48(sp)
    800012f8:	79a2                	ld	s3,40(sp)
    800012fa:	7a02                	ld	s4,32(sp)
    800012fc:	6ae2                	ld	s5,24(sp)
    800012fe:	6b42                	ld	s6,16(sp)
    80001300:	6ba2                	ld	s7,8(sp)
    80001302:	6161                	addi	sp,sp,80
    80001304:	8082                	ret
    panic("uvmunmap: not aligned");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	dea50513          	addi	a0,a0,-534 # 800080f0 <digits+0xb0>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	234080e7          	jalr	564(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	df250513          	addi	a0,a0,-526 # 80008108 <digits+0xc8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	224080e7          	jalr	548(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	df250513          	addi	a0,a0,-526 # 80008118 <digits+0xd8>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	214080e7          	jalr	532(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001336:	00007517          	auipc	a0,0x7
    8000133a:	dfa50513          	addi	a0,a0,-518 # 80008130 <digits+0xf0>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	204080e7          	jalr	516(ra) # 80000542 <panic>
    *pte = 0;
    80001346:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	995a                	add	s2,s2,s6
    8000134c:	fb3972e3          	bgeu	s2,s3,800012f0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001350:	4601                	li	a2,0
    80001352:	85ca                	mv	a1,s2
    80001354:	8552                	mv	a0,s4
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	c8c080e7          	jalr	-884(ra) # 80000fe2 <walk>
    8000135e:	84aa                	mv	s1,a0
    80001360:	d95d                	beqz	a0,80001316 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001362:	6108                	ld	a0,0(a0)
    80001364:	00157793          	andi	a5,a0,1
    80001368:	dfdd                	beqz	a5,80001326 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136a:	3ff57793          	andi	a5,a0,1023
    8000136e:	fd7784e3          	beq	a5,s7,80001336 <uvmunmap+0x76>
    if(do_free){
    80001372:	fc0a8ae3          	beqz	s5,80001346 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001376:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001378:	0532                	slli	a0,a0,0xc
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	698080e7          	jalr	1688(ra) # 80000a12 <kfree>
    80001382:	b7d1                	j	80001346 <uvmunmap+0x86>

0000000080001384 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001384:	1101                	addi	sp,sp,-32
    80001386:	ec06                	sd	ra,24(sp)
    80001388:	e822                	sd	s0,16(sp)
    8000138a:	e426                	sd	s1,8(sp)
    8000138c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	780080e7          	jalr	1920(ra) # 80000b0e <kalloc>
    80001396:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001398:	c519                	beqz	a0,800013a6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000139a:	6605                	lui	a2,0x1
    8000139c:	4581                	li	a1,0
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	95c080e7          	jalr	-1700(ra) # 80000cfa <memset>
  return pagetable;
}
    800013a6:	8526                	mv	a0,s1
    800013a8:	60e2                	ld	ra,24(sp)
    800013aa:	6442                	ld	s0,16(sp)
    800013ac:	64a2                	ld	s1,8(sp)
    800013ae:	6105                	addi	sp,sp,32
    800013b0:	8082                	ret

00000000800013b2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b2:	7179                	addi	sp,sp,-48
    800013b4:	f406                	sd	ra,40(sp)
    800013b6:	f022                	sd	s0,32(sp)
    800013b8:	ec26                	sd	s1,24(sp)
    800013ba:	e84a                	sd	s2,16(sp)
    800013bc:	e44e                	sd	s3,8(sp)
    800013be:	e052                	sd	s4,0(sp)
    800013c0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c2:	6785                	lui	a5,0x1
    800013c4:	04f67863          	bgeu	a2,a5,80001414 <uvminit+0x62>
    800013c8:	8a2a                	mv	s4,a0
    800013ca:	89ae                	mv	s3,a1
    800013cc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	740080e7          	jalr	1856(ra) # 80000b0e <kalloc>
    800013d6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	91e080e7          	jalr	-1762(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e4:	4779                	li	a4,30
    800013e6:	86ca                	mv	a3,s2
    800013e8:	6605                	lui	a2,0x1
    800013ea:	4581                	li	a1,0
    800013ec:	8552                	mv	a0,s4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	d3a080e7          	jalr	-710(ra) # 80001128 <mappages>
  memmove(mem, src, sz);
    800013f6:	8626                	mv	a2,s1
    800013f8:	85ce                	mv	a1,s3
    800013fa:	854a                	mv	a0,s2
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	95a080e7          	jalr	-1702(ra) # 80000d56 <memmove>
}
    80001404:	70a2                	ld	ra,40(sp)
    80001406:	7402                	ld	s0,32(sp)
    80001408:	64e2                	ld	s1,24(sp)
    8000140a:	6942                	ld	s2,16(sp)
    8000140c:	69a2                	ld	s3,8(sp)
    8000140e:	6a02                	ld	s4,0(sp)
    80001410:	6145                	addi	sp,sp,48
    80001412:	8082                	ret
    panic("inituvm: more than a page");
    80001414:	00007517          	auipc	a0,0x7
    80001418:	d3450513          	addi	a0,a0,-716 # 80008148 <digits+0x108>
    8000141c:	fffff097          	auipc	ra,0xfffff
    80001420:	126080e7          	jalr	294(ra) # 80000542 <panic>

0000000080001424 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001424:	1101                	addi	sp,sp,-32
    80001426:	ec06                	sd	ra,24(sp)
    80001428:	e822                	sd	s0,16(sp)
    8000142a:	e426                	sd	s1,8(sp)
    8000142c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000142e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001430:	00b67d63          	bgeu	a2,a1,8000144a <uvmdealloc+0x26>
    80001434:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001436:	6785                	lui	a5,0x1
    80001438:	17fd                	addi	a5,a5,-1
    8000143a:	00f60733          	add	a4,a2,a5
    8000143e:	767d                	lui	a2,0xfffff
    80001440:	8f71                	and	a4,a4,a2
    80001442:	97ae                	add	a5,a5,a1
    80001444:	8ff1                	and	a5,a5,a2
    80001446:	00f76863          	bltu	a4,a5,80001456 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000144a:	8526                	mv	a0,s1
    8000144c:	60e2                	ld	ra,24(sp)
    8000144e:	6442                	ld	s0,16(sp)
    80001450:	64a2                	ld	s1,8(sp)
    80001452:	6105                	addi	sp,sp,32
    80001454:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001456:	8f99                	sub	a5,a5,a4
    80001458:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000145a:	4685                	li	a3,1
    8000145c:	0007861b          	sext.w	a2,a5
    80001460:	85ba                	mv	a1,a4
    80001462:	00000097          	auipc	ra,0x0
    80001466:	e5e080e7          	jalr	-418(ra) # 800012c0 <uvmunmap>
    8000146a:	b7c5                	j	8000144a <uvmdealloc+0x26>

000000008000146c <uvmalloc>:
  if(newsz < oldsz)
    8000146c:	0ab66163          	bltu	a2,a1,8000150e <uvmalloc+0xa2>
{
    80001470:	7139                	addi	sp,sp,-64
    80001472:	fc06                	sd	ra,56(sp)
    80001474:	f822                	sd	s0,48(sp)
    80001476:	f426                	sd	s1,40(sp)
    80001478:	f04a                	sd	s2,32(sp)
    8000147a:	ec4e                	sd	s3,24(sp)
    8000147c:	e852                	sd	s4,16(sp)
    8000147e:	e456                	sd	s5,8(sp)
    80001480:	0080                	addi	s0,sp,64
    80001482:	8aaa                	mv	s5,a0
    80001484:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001486:	6985                	lui	s3,0x1
    80001488:	19fd                	addi	s3,s3,-1
    8000148a:	95ce                	add	a1,a1,s3
    8000148c:	79fd                	lui	s3,0xfffff
    8000148e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001492:	08c9f063          	bgeu	s3,a2,80001512 <uvmalloc+0xa6>
    80001496:	894e                	mv	s2,s3
    mem = kalloc();
    80001498:	fffff097          	auipc	ra,0xfffff
    8000149c:	676080e7          	jalr	1654(ra) # 80000b0e <kalloc>
    800014a0:	84aa                	mv	s1,a0
    if(mem == 0){
    800014a2:	c51d                	beqz	a0,800014d0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014a4:	6605                	lui	a2,0x1
    800014a6:	4581                	li	a1,0
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	852080e7          	jalr	-1966(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014b0:	4779                	li	a4,30
    800014b2:	86a6                	mv	a3,s1
    800014b4:	6605                	lui	a2,0x1
    800014b6:	85ca                	mv	a1,s2
    800014b8:	8556                	mv	a0,s5
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	c6e080e7          	jalr	-914(ra) # 80001128 <mappages>
    800014c2:	e905                	bnez	a0,800014f2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014c4:	6785                	lui	a5,0x1
    800014c6:	993e                	add	s2,s2,a5
    800014c8:	fd4968e3          	bltu	s2,s4,80001498 <uvmalloc+0x2c>
  return newsz;
    800014cc:	8552                	mv	a0,s4
    800014ce:	a809                	j	800014e0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014d0:	864e                	mv	a2,s3
    800014d2:	85ca                	mv	a1,s2
    800014d4:	8556                	mv	a0,s5
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	f4e080e7          	jalr	-178(ra) # 80001424 <uvmdealloc>
      return 0;
    800014de:	4501                	li	a0,0
}
    800014e0:	70e2                	ld	ra,56(sp)
    800014e2:	7442                	ld	s0,48(sp)
    800014e4:	74a2                	ld	s1,40(sp)
    800014e6:	7902                	ld	s2,32(sp)
    800014e8:	69e2                	ld	s3,24(sp)
    800014ea:	6a42                	ld	s4,16(sp)
    800014ec:	6aa2                	ld	s5,8(sp)
    800014ee:	6121                	addi	sp,sp,64
    800014f0:	8082                	ret
      kfree(mem);
    800014f2:	8526                	mv	a0,s1
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	51e080e7          	jalr	1310(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014fc:	864e                	mv	a2,s3
    800014fe:	85ca                	mv	a1,s2
    80001500:	8556                	mv	a0,s5
    80001502:	00000097          	auipc	ra,0x0
    80001506:	f22080e7          	jalr	-222(ra) # 80001424 <uvmdealloc>
      return 0;
    8000150a:	4501                	li	a0,0
    8000150c:	bfd1                	j	800014e0 <uvmalloc+0x74>
    return oldsz;
    8000150e:	852e                	mv	a0,a1
}
    80001510:	8082                	ret
  return newsz;
    80001512:	8532                	mv	a0,a2
    80001514:	b7f1                	j	800014e0 <uvmalloc+0x74>

0000000080001516 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001516:	7179                	addi	sp,sp,-48
    80001518:	f406                	sd	ra,40(sp)
    8000151a:	f022                	sd	s0,32(sp)
    8000151c:	ec26                	sd	s1,24(sp)
    8000151e:	e84a                	sd	s2,16(sp)
    80001520:	e44e                	sd	s3,8(sp)
    80001522:	e052                	sd	s4,0(sp)
    80001524:	1800                	addi	s0,sp,48
    80001526:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001528:	84aa                	mv	s1,a0
    8000152a:	6905                	lui	s2,0x1
    8000152c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152e:	4985                	li	s3,1
    80001530:	a821                	j	80001548 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001532:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001534:	0532                	slli	a0,a0,0xc
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	fe0080e7          	jalr	-32(ra) # 80001516 <freewalk>
      pagetable[i] = 0;
    8000153e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001542:	04a1                	addi	s1,s1,8
    80001544:	03248163          	beq	s1,s2,80001566 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001548:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000154a:	00f57793          	andi	a5,a0,15
    8000154e:	ff3782e3          	beq	a5,s3,80001532 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001552:	8905                	andi	a0,a0,1
    80001554:	d57d                	beqz	a0,80001542 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001556:	00007517          	auipc	a0,0x7
    8000155a:	c1250513          	addi	a0,a0,-1006 # 80008168 <digits+0x128>
    8000155e:	fffff097          	auipc	ra,0xfffff
    80001562:	fe4080e7          	jalr	-28(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    80001566:	8552                	mv	a0,s4
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	4aa080e7          	jalr	1194(ra) # 80000a12 <kfree>
}
    80001570:	70a2                	ld	ra,40(sp)
    80001572:	7402                	ld	s0,32(sp)
    80001574:	64e2                	ld	s1,24(sp)
    80001576:	6942                	ld	s2,16(sp)
    80001578:	69a2                	ld	s3,8(sp)
    8000157a:	6a02                	ld	s4,0(sp)
    8000157c:	6145                	addi	sp,sp,48
    8000157e:	8082                	ret

0000000080001580 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001580:	1101                	addi	sp,sp,-32
    80001582:	ec06                	sd	ra,24(sp)
    80001584:	e822                	sd	s0,16(sp)
    80001586:	e426                	sd	s1,8(sp)
    80001588:	1000                	addi	s0,sp,32
    8000158a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000158c:	e999                	bnez	a1,800015a2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000158e:	8526                	mv	a0,s1
    80001590:	00000097          	auipc	ra,0x0
    80001594:	f86080e7          	jalr	-122(ra) # 80001516 <freewalk>
}
    80001598:	60e2                	ld	ra,24(sp)
    8000159a:	6442                	ld	s0,16(sp)
    8000159c:	64a2                	ld	s1,8(sp)
    8000159e:	6105                	addi	sp,sp,32
    800015a0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	167d                	addi	a2,a2,-1
    800015a6:	962e                	add	a2,a2,a1
    800015a8:	4685                	li	a3,1
    800015aa:	8231                	srli	a2,a2,0xc
    800015ac:	4581                	li	a1,0
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	d12080e7          	jalr	-750(ra) # 800012c0 <uvmunmap>
    800015b6:	bfe1                	j	8000158e <uvmfree+0xe>

00000000800015b8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b8:	c679                	beqz	a2,80001686 <uvmcopy+0xce>
{
    800015ba:	715d                	addi	sp,sp,-80
    800015bc:	e486                	sd	ra,72(sp)
    800015be:	e0a2                	sd	s0,64(sp)
    800015c0:	fc26                	sd	s1,56(sp)
    800015c2:	f84a                	sd	s2,48(sp)
    800015c4:	f44e                	sd	s3,40(sp)
    800015c6:	f052                	sd	s4,32(sp)
    800015c8:	ec56                	sd	s5,24(sp)
    800015ca:	e85a                	sd	s6,16(sp)
    800015cc:	e45e                	sd	s7,8(sp)
    800015ce:	0880                	addi	s0,sp,80
    800015d0:	8b2a                	mv	s6,a0
    800015d2:	8aae                	mv	s5,a1
    800015d4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015d6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015d8:	4601                	li	a2,0
    800015da:	85ce                	mv	a1,s3
    800015dc:	855a                	mv	a0,s6
    800015de:	00000097          	auipc	ra,0x0
    800015e2:	a04080e7          	jalr	-1532(ra) # 80000fe2 <walk>
    800015e6:	c531                	beqz	a0,80001632 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015e8:	6118                	ld	a4,0(a0)
    800015ea:	00177793          	andi	a5,a4,1
    800015ee:	cbb1                	beqz	a5,80001642 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015f0:	00a75593          	srli	a1,a4,0xa
    800015f4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015f8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	512080e7          	jalr	1298(ra) # 80000b0e <kalloc>
    80001604:	892a                	mv	s2,a0
    80001606:	c939                	beqz	a0,8000165c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001608:	6605                	lui	a2,0x1
    8000160a:	85de                	mv	a1,s7
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	74a080e7          	jalr	1866(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001614:	8726                	mv	a4,s1
    80001616:	86ca                	mv	a3,s2
    80001618:	6605                	lui	a2,0x1
    8000161a:	85ce                	mv	a1,s3
    8000161c:	8556                	mv	a0,s5
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	b0a080e7          	jalr	-1270(ra) # 80001128 <mappages>
    80001626:	e515                	bnez	a0,80001652 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001628:	6785                	lui	a5,0x1
    8000162a:	99be                	add	s3,s3,a5
    8000162c:	fb49e6e3          	bltu	s3,s4,800015d8 <uvmcopy+0x20>
    80001630:	a081                	j	80001670 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001632:	00007517          	auipc	a0,0x7
    80001636:	b4650513          	addi	a0,a0,-1210 # 80008178 <digits+0x138>
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	f08080e7          	jalr	-248(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    80001642:	00007517          	auipc	a0,0x7
    80001646:	b5650513          	addi	a0,a0,-1194 # 80008198 <digits+0x158>
    8000164a:	fffff097          	auipc	ra,0xfffff
    8000164e:	ef8080e7          	jalr	-264(ra) # 80000542 <panic>
      kfree(mem);
    80001652:	854a                	mv	a0,s2
    80001654:	fffff097          	auipc	ra,0xfffff
    80001658:	3be080e7          	jalr	958(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000165c:	4685                	li	a3,1
    8000165e:	00c9d613          	srli	a2,s3,0xc
    80001662:	4581                	li	a1,0
    80001664:	8556                	mv	a0,s5
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	c5a080e7          	jalr	-934(ra) # 800012c0 <uvmunmap>
  return -1;
    8000166e:	557d                	li	a0,-1
}
    80001670:	60a6                	ld	ra,72(sp)
    80001672:	6406                	ld	s0,64(sp)
    80001674:	74e2                	ld	s1,56(sp)
    80001676:	7942                	ld	s2,48(sp)
    80001678:	79a2                	ld	s3,40(sp)
    8000167a:	7a02                	ld	s4,32(sp)
    8000167c:	6ae2                	ld	s5,24(sp)
    8000167e:	6b42                	ld	s6,16(sp)
    80001680:	6ba2                	ld	s7,8(sp)
    80001682:	6161                	addi	sp,sp,80
    80001684:	8082                	ret
  return 0;
    80001686:	4501                	li	a0,0
}
    80001688:	8082                	ret

000000008000168a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000168a:	1141                	addi	sp,sp,-16
    8000168c:	e406                	sd	ra,8(sp)
    8000168e:	e022                	sd	s0,0(sp)
    80001690:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001692:	4601                	li	a2,0
    80001694:	00000097          	auipc	ra,0x0
    80001698:	94e080e7          	jalr	-1714(ra) # 80000fe2 <walk>
  if(pte == 0)
    8000169c:	c901                	beqz	a0,800016ac <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000169e:	611c                	ld	a5,0(a0)
    800016a0:	9bbd                	andi	a5,a5,-17
    800016a2:	e11c                	sd	a5,0(a0)
}
    800016a4:	60a2                	ld	ra,8(sp)
    800016a6:	6402                	ld	s0,0(sp)
    800016a8:	0141                	addi	sp,sp,16
    800016aa:	8082                	ret
    panic("uvmclear");
    800016ac:	00007517          	auipc	a0,0x7
    800016b0:	b0c50513          	addi	a0,a0,-1268 # 800081b8 <digits+0x178>
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	e8e080e7          	jalr	-370(ra) # 80000542 <panic>

00000000800016bc <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016bc:	c6bd                	beqz	a3,8000172a <copyout+0x6e>
{
    800016be:	715d                	addi	sp,sp,-80
    800016c0:	e486                	sd	ra,72(sp)
    800016c2:	e0a2                	sd	s0,64(sp)
    800016c4:	fc26                	sd	s1,56(sp)
    800016c6:	f84a                	sd	s2,48(sp)
    800016c8:	f44e                	sd	s3,40(sp)
    800016ca:	f052                	sd	s4,32(sp)
    800016cc:	ec56                	sd	s5,24(sp)
    800016ce:	e85a                	sd	s6,16(sp)
    800016d0:	e45e                	sd	s7,8(sp)
    800016d2:	e062                	sd	s8,0(sp)
    800016d4:	0880                	addi	s0,sp,80
    800016d6:	8b2a                	mv	s6,a0
    800016d8:	8c2e                	mv	s8,a1
    800016da:	8a32                	mv	s4,a2
    800016dc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016de:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016e0:	6a85                	lui	s5,0x1
    800016e2:	a015                	j	80001706 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016e4:	9562                	add	a0,a0,s8
    800016e6:	0004861b          	sext.w	a2,s1
    800016ea:	85d2                	mv	a1,s4
    800016ec:	41250533          	sub	a0,a0,s2
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	666080e7          	jalr	1638(ra) # 80000d56 <memmove>

    len -= n;
    800016f8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016fc:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016fe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001702:	02098263          	beqz	s3,80001726 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001706:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000170a:	85ca                	mv	a1,s2
    8000170c:	855a                	mv	a0,s6
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	97a080e7          	jalr	-1670(ra) # 80001088 <walkaddr>
    if(pa0 == 0)
    80001716:	cd01                	beqz	a0,8000172e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001718:	418904b3          	sub	s1,s2,s8
    8000171c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000171e:	fc99f3e3          	bgeu	s3,s1,800016e4 <copyout+0x28>
    80001722:	84ce                	mv	s1,s3
    80001724:	b7c1                	j	800016e4 <copyout+0x28>
  }
  return 0;
    80001726:	4501                	li	a0,0
    80001728:	a021                	j	80001730 <copyout+0x74>
    8000172a:	4501                	li	a0,0
}
    8000172c:	8082                	ret
      return -1;
    8000172e:	557d                	li	a0,-1
}
    80001730:	60a6                	ld	ra,72(sp)
    80001732:	6406                	ld	s0,64(sp)
    80001734:	74e2                	ld	s1,56(sp)
    80001736:	7942                	ld	s2,48(sp)
    80001738:	79a2                	ld	s3,40(sp)
    8000173a:	7a02                	ld	s4,32(sp)
    8000173c:	6ae2                	ld	s5,24(sp)
    8000173e:	6b42                	ld	s6,16(sp)
    80001740:	6ba2                	ld	s7,8(sp)
    80001742:	6c02                	ld	s8,0(sp)
    80001744:	6161                	addi	sp,sp,80
    80001746:	8082                	ret

0000000080001748 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001748:	caa5                	beqz	a3,800017b8 <copyin+0x70>
{
    8000174a:	715d                	addi	sp,sp,-80
    8000174c:	e486                	sd	ra,72(sp)
    8000174e:	e0a2                	sd	s0,64(sp)
    80001750:	fc26                	sd	s1,56(sp)
    80001752:	f84a                	sd	s2,48(sp)
    80001754:	f44e                	sd	s3,40(sp)
    80001756:	f052                	sd	s4,32(sp)
    80001758:	ec56                	sd	s5,24(sp)
    8000175a:	e85a                	sd	s6,16(sp)
    8000175c:	e45e                	sd	s7,8(sp)
    8000175e:	e062                	sd	s8,0(sp)
    80001760:	0880                	addi	s0,sp,80
    80001762:	8b2a                	mv	s6,a0
    80001764:	8a2e                	mv	s4,a1
    80001766:	8c32                	mv	s8,a2
    80001768:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000176a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000176c:	6a85                	lui	s5,0x1
    8000176e:	a01d                	j	80001794 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001770:	018505b3          	add	a1,a0,s8
    80001774:	0004861b          	sext.w	a2,s1
    80001778:	412585b3          	sub	a1,a1,s2
    8000177c:	8552                	mv	a0,s4
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	5d8080e7          	jalr	1496(ra) # 80000d56 <memmove>

    len -= n;
    80001786:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000178a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000178c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001790:	02098263          	beqz	s3,800017b4 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001794:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001798:	85ca                	mv	a1,s2
    8000179a:	855a                	mv	a0,s6
    8000179c:	00000097          	auipc	ra,0x0
    800017a0:	8ec080e7          	jalr	-1812(ra) # 80001088 <walkaddr>
    if(pa0 == 0)
    800017a4:	cd01                	beqz	a0,800017bc <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017a6:	418904b3          	sub	s1,s2,s8
    800017aa:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ac:	fc99f2e3          	bgeu	s3,s1,80001770 <copyin+0x28>
    800017b0:	84ce                	mv	s1,s3
    800017b2:	bf7d                	j	80001770 <copyin+0x28>
  }
  return 0;
    800017b4:	4501                	li	a0,0
    800017b6:	a021                	j	800017be <copyin+0x76>
    800017b8:	4501                	li	a0,0
}
    800017ba:	8082                	ret
      return -1;
    800017bc:	557d                	li	a0,-1
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6c02                	ld	s8,0(sp)
    800017d2:	6161                	addi	sp,sp,80
    800017d4:	8082                	ret

00000000800017d6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017d6:	c6c5                	beqz	a3,8000187e <copyinstr+0xa8>
{
    800017d8:	715d                	addi	sp,sp,-80
    800017da:	e486                	sd	ra,72(sp)
    800017dc:	e0a2                	sd	s0,64(sp)
    800017de:	fc26                	sd	s1,56(sp)
    800017e0:	f84a                	sd	s2,48(sp)
    800017e2:	f44e                	sd	s3,40(sp)
    800017e4:	f052                	sd	s4,32(sp)
    800017e6:	ec56                	sd	s5,24(sp)
    800017e8:	e85a                	sd	s6,16(sp)
    800017ea:	e45e                	sd	s7,8(sp)
    800017ec:	0880                	addi	s0,sp,80
    800017ee:	8a2a                	mv	s4,a0
    800017f0:	8b2e                	mv	s6,a1
    800017f2:	8bb2                	mv	s7,a2
    800017f4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017f6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f8:	6985                	lui	s3,0x1
    800017fa:	a035                	j	80001826 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017fc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001800:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000180a:	60a6                	ld	ra,72(sp)
    8000180c:	6406                	ld	s0,64(sp)
    8000180e:	74e2                	ld	s1,56(sp)
    80001810:	7942                	ld	s2,48(sp)
    80001812:	79a2                	ld	s3,40(sp)
    80001814:	7a02                	ld	s4,32(sp)
    80001816:	6ae2                	ld	s5,24(sp)
    80001818:	6b42                	ld	s6,16(sp)
    8000181a:	6ba2                	ld	s7,8(sp)
    8000181c:	6161                	addi	sp,sp,80
    8000181e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001820:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001824:	c8a9                	beqz	s1,80001876 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001826:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000182a:	85ca                	mv	a1,s2
    8000182c:	8552                	mv	a0,s4
    8000182e:	00000097          	auipc	ra,0x0
    80001832:	85a080e7          	jalr	-1958(ra) # 80001088 <walkaddr>
    if(pa0 == 0)
    80001836:	c131                	beqz	a0,8000187a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001838:	41790833          	sub	a6,s2,s7
    8000183c:	984e                	add	a6,a6,s3
    if(n > max)
    8000183e:	0104f363          	bgeu	s1,a6,80001844 <copyinstr+0x6e>
    80001842:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001844:	955e                	add	a0,a0,s7
    80001846:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000184a:	fc080be3          	beqz	a6,80001820 <copyinstr+0x4a>
    8000184e:	985a                	add	a6,a6,s6
    80001850:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001852:	41650633          	sub	a2,a0,s6
    80001856:	14fd                	addi	s1,s1,-1
    80001858:	9b26                	add	s6,s6,s1
    8000185a:	00f60733          	add	a4,a2,a5
    8000185e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001862:	df49                	beqz	a4,800017fc <copyinstr+0x26>
        *dst = *p;
    80001864:	00e78023          	sb	a4,0(a5)
      --max;
    80001868:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000186c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000186e:	ff0796e3          	bne	a5,a6,8000185a <copyinstr+0x84>
      dst++;
    80001872:	8b42                	mv	s6,a6
    80001874:	b775                	j	80001820 <copyinstr+0x4a>
    80001876:	4781                	li	a5,0
    80001878:	b769                	j	80001802 <copyinstr+0x2c>
      return -1;
    8000187a:	557d                	li	a0,-1
    8000187c:	b779                	j	8000180a <copyinstr+0x34>
  int got_null = 0;
    8000187e:	4781                	li	a5,0
  if(got_null){
    80001880:	0017b793          	seqz	a5,a5
    80001884:	40f00533          	neg	a0,a5
}
    80001888:	8082                	ret

000000008000188a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000188a:	1101                	addi	sp,sp,-32
    8000188c:	ec06                	sd	ra,24(sp)
    8000188e:	e822                	sd	s0,16(sp)
    80001890:	e426                	sd	s1,8(sp)
    80001892:	1000                	addi	s0,sp,32
    80001894:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	2ee080e7          	jalr	750(ra) # 80000b84 <holding>
    8000189e:	c909                	beqz	a0,800018b0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018a0:	749c                	ld	a5,40(s1)
    800018a2:	00978f63          	beq	a5,s1,800018c0 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018a6:	60e2                	ld	ra,24(sp)
    800018a8:	6442                	ld	s0,16(sp)
    800018aa:	64a2                	ld	s1,8(sp)
    800018ac:	6105                	addi	sp,sp,32
    800018ae:	8082                	ret
    panic("wakeup1");
    800018b0:	00007517          	auipc	a0,0x7
    800018b4:	91850513          	addi	a0,a0,-1768 # 800081c8 <digits+0x188>
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	c8a080e7          	jalr	-886(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018c0:	4c98                	lw	a4,24(s1)
    800018c2:	4785                	li	a5,1
    800018c4:	fef711e3          	bne	a4,a5,800018a6 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018c8:	4789                	li	a5,2
    800018ca:	cc9c                	sw	a5,24(s1)
}
    800018cc:	bfe9                	j	800018a6 <wakeup1+0x1c>

00000000800018ce <procinit>:
{
    800018ce:	715d                	addi	sp,sp,-80
    800018d0:	e486                	sd	ra,72(sp)
    800018d2:	e0a2                	sd	s0,64(sp)
    800018d4:	fc26                	sd	s1,56(sp)
    800018d6:	f84a                	sd	s2,48(sp)
    800018d8:	f44e                	sd	s3,40(sp)
    800018da:	f052                	sd	s4,32(sp)
    800018dc:	ec56                	sd	s5,24(sp)
    800018de:	e85a                	sd	s6,16(sp)
    800018e0:	e45e                	sd	s7,8(sp)
    800018e2:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018e4:	00007597          	auipc	a1,0x7
    800018e8:	8ec58593          	addi	a1,a1,-1812 # 800081d0 <digits+0x190>
    800018ec:	00010517          	auipc	a0,0x10
    800018f0:	06450513          	addi	a0,a0,100 # 80011950 <pid_lock>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	27a080e7          	jalr	634(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	00010917          	auipc	s2,0x10
    80001900:	46c90913          	addi	s2,s2,1132 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001904:	00007b97          	auipc	s7,0x7
    80001908:	8d4b8b93          	addi	s7,s7,-1836 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000190c:	8b4a                	mv	s6,s2
    8000190e:	00006a97          	auipc	s5,0x6
    80001912:	6f2a8a93          	addi	s5,s5,1778 # 80008000 <etext>
    80001916:	040009b7          	lui	s3,0x4000
    8000191a:	19fd                	addi	s3,s3,-1
    8000191c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191e:	00016a17          	auipc	s4,0x16
    80001922:	e4aa0a13          	addi	s4,s4,-438 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001926:	85de                	mv	a1,s7
    80001928:	854a                	mv	a0,s2
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	244080e7          	jalr	580(ra) # 80000b6e <initlock>
      char *pa = kalloc();
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	1dc080e7          	jalr	476(ra) # 80000b0e <kalloc>
    8000193a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000193c:	c929                	beqz	a0,8000198e <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000193e:	416904b3          	sub	s1,s2,s6
    80001942:	848d                	srai	s1,s1,0x3
    80001944:	000ab783          	ld	a5,0(s5)
    80001948:	02f484b3          	mul	s1,s1,a5
    8000194c:	2485                	addiw	s1,s1,1
    8000194e:	00d4949b          	slliw	s1,s1,0xd
    80001952:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001956:	4699                	li	a3,6
    80001958:	6605                	lui	a2,0x1
    8000195a:	8526                	mv	a0,s1
    8000195c:	00000097          	auipc	ra,0x0
    80001960:	85a080e7          	jalr	-1958(ra) # 800011b6 <kvmmap>
      p->kstack = va;
    80001964:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16890913          	addi	s2,s2,360
    8000196c:	fb491de3          	bne	s2,s4,80001926 <procinit+0x58>
  kvminithart();
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	64e080e7          	jalr	1614(ra) # 80000fbe <kvminithart>
}
    80001978:	60a6                	ld	ra,72(sp)
    8000197a:	6406                	ld	s0,64(sp)
    8000197c:	74e2                	ld	s1,56(sp)
    8000197e:	7942                	ld	s2,48(sp)
    80001980:	79a2                	ld	s3,40(sp)
    80001982:	7a02                	ld	s4,32(sp)
    80001984:	6ae2                	ld	s5,24(sp)
    80001986:	6b42                	ld	s6,16(sp)
    80001988:	6ba2                	ld	s7,8(sp)
    8000198a:	6161                	addi	sp,sp,80
    8000198c:	8082                	ret
        panic("kalloc");
    8000198e:	00007517          	auipc	a0,0x7
    80001992:	85250513          	addi	a0,a0,-1966 # 800081e0 <digits+0x1a0>
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	bac080e7          	jalr	-1108(ra) # 80000542 <panic>

000000008000199e <cpuid>:
{
    8000199e:	1141                	addi	sp,sp,-16
    800019a0:	e422                	sd	s0,8(sp)
    800019a2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a4:	8512                	mv	a0,tp
}
    800019a6:	2501                	sext.w	a0,a0
    800019a8:	6422                	ld	s0,8(sp)
    800019aa:	0141                	addi	sp,sp,16
    800019ac:	8082                	ret

00000000800019ae <mycpu>:
mycpu(void) {
    800019ae:	1141                	addi	sp,sp,-16
    800019b0:	e422                	sd	s0,8(sp)
    800019b2:	0800                	addi	s0,sp,16
    800019b4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019b6:	2781                	sext.w	a5,a5
    800019b8:	079e                	slli	a5,a5,0x7
}
    800019ba:	00010517          	auipc	a0,0x10
    800019be:	fae50513          	addi	a0,a0,-82 # 80011968 <cpus>
    800019c2:	953e                	add	a0,a0,a5
    800019c4:	6422                	ld	s0,8(sp)
    800019c6:	0141                	addi	sp,sp,16
    800019c8:	8082                	ret

00000000800019ca <myproc>:
myproc(void) {
    800019ca:	1101                	addi	sp,sp,-32
    800019cc:	ec06                	sd	ra,24(sp)
    800019ce:	e822                	sd	s0,16(sp)
    800019d0:	e426                	sd	s1,8(sp)
    800019d2:	1000                	addi	s0,sp,32
  push_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	1de080e7          	jalr	478(ra) # 80000bb2 <push_off>
    800019dc:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019de:	2781                	sext.w	a5,a5
    800019e0:	079e                	slli	a5,a5,0x7
    800019e2:	00010717          	auipc	a4,0x10
    800019e6:	f6e70713          	addi	a4,a4,-146 # 80011950 <pid_lock>
    800019ea:	97ba                	add	a5,a5,a4
    800019ec:	6f84                	ld	s1,24(a5)
  pop_off();
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	264080e7          	jalr	612(ra) # 80000c52 <pop_off>
}
    800019f6:	8526                	mv	a0,s1
    800019f8:	60e2                	ld	ra,24(sp)
    800019fa:	6442                	ld	s0,16(sp)
    800019fc:	64a2                	ld	s1,8(sp)
    800019fe:	6105                	addi	sp,sp,32
    80001a00:	8082                	ret

0000000080001a02 <forkret>:
{
    80001a02:	1141                	addi	sp,sp,-16
    80001a04:	e406                	sd	ra,8(sp)
    80001a06:	e022                	sd	s0,0(sp)
    80001a08:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a0a:	00000097          	auipc	ra,0x0
    80001a0e:	fc0080e7          	jalr	-64(ra) # 800019ca <myproc>
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	2a0080e7          	jalr	672(ra) # 80000cb2 <release>
  if (first) {
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	df67a783          	lw	a5,-522(a5) # 80008810 <first.1>
    80001a22:	eb89                	bnez	a5,80001a34 <forkret+0x32>
  usertrapret();
    80001a24:	00001097          	auipc	ra,0x1
    80001a28:	bf6080e7          	jalr	-1034(ra) # 8000261a <usertrapret>
}
    80001a2c:	60a2                	ld	ra,8(sp)
    80001a2e:	6402                	ld	s0,0(sp)
    80001a30:	0141                	addi	sp,sp,16
    80001a32:	8082                	ret
    first = 0;
    80001a34:	00007797          	auipc	a5,0x7
    80001a38:	dc07ae23          	sw	zero,-548(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001a3c:	4505                	li	a0,1
    80001a3e:	00002097          	auipc	ra,0x2
    80001a42:	91e080e7          	jalr	-1762(ra) # 8000335c <fsinit>
    80001a46:	bff9                	j	80001a24 <forkret+0x22>

0000000080001a48 <allocpid>:
allocpid() {
    80001a48:	1101                	addi	sp,sp,-32
    80001a4a:	ec06                	sd	ra,24(sp)
    80001a4c:	e822                	sd	s0,16(sp)
    80001a4e:	e426                	sd	s1,8(sp)
    80001a50:	e04a                	sd	s2,0(sp)
    80001a52:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a54:	00010917          	auipc	s2,0x10
    80001a58:	efc90913          	addi	s2,s2,-260 # 80011950 <pid_lock>
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	1a0080e7          	jalr	416(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001a66:	00007797          	auipc	a5,0x7
    80001a6a:	dae78793          	addi	a5,a5,-594 # 80008814 <nextpid>
    80001a6e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a70:	0014871b          	addiw	a4,s1,1
    80001a74:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a76:	854a                	mv	a0,s2
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	23a080e7          	jalr	570(ra) # 80000cb2 <release>
}
    80001a80:	8526                	mv	a0,s1
    80001a82:	60e2                	ld	ra,24(sp)
    80001a84:	6442                	ld	s0,16(sp)
    80001a86:	64a2                	ld	s1,8(sp)
    80001a88:	6902                	ld	s2,0(sp)
    80001a8a:	6105                	addi	sp,sp,32
    80001a8c:	8082                	ret

0000000080001a8e <proc_pagetable>:
{
    80001a8e:	1101                	addi	sp,sp,-32
    80001a90:	ec06                	sd	ra,24(sp)
    80001a92:	e822                	sd	s0,16(sp)
    80001a94:	e426                	sd	s1,8(sp)
    80001a96:	e04a                	sd	s2,0(sp)
    80001a98:	1000                	addi	s0,sp,32
    80001a9a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	8e8080e7          	jalr	-1816(ra) # 80001384 <uvmcreate>
    80001aa4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa6:	c121                	beqz	a0,80001ae6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa8:	4729                	li	a4,10
    80001aaa:	00005697          	auipc	a3,0x5
    80001aae:	55668693          	addi	a3,a3,1366 # 80007000 <_trampoline>
    80001ab2:	6605                	lui	a2,0x1
    80001ab4:	040005b7          	lui	a1,0x4000
    80001ab8:	15fd                	addi	a1,a1,-1
    80001aba:	05b2                	slli	a1,a1,0xc
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	66c080e7          	jalr	1644(ra) # 80001128 <mappages>
    80001ac4:	02054863          	bltz	a0,80001af4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac8:	4719                	li	a4,6
    80001aca:	05893683          	ld	a3,88(s2)
    80001ace:	6605                	lui	a2,0x1
    80001ad0:	020005b7          	lui	a1,0x2000
    80001ad4:	15fd                	addi	a1,a1,-1
    80001ad6:	05b6                	slli	a1,a1,0xd
    80001ad8:	8526                	mv	a0,s1
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	64e080e7          	jalr	1614(ra) # 80001128 <mappages>
    80001ae2:	02054163          	bltz	a0,80001b04 <proc_pagetable+0x76>
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret
    uvmfree(pagetable, 0);
    80001af4:	4581                	li	a1,0
    80001af6:	8526                	mv	a0,s1
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	a88080e7          	jalr	-1400(ra) # 80001580 <uvmfree>
    return 0;
    80001b00:	4481                	li	s1,0
    80001b02:	b7d5                	j	80001ae6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b04:	4681                	li	a3,0
    80001b06:	4605                	li	a2,1
    80001b08:	040005b7          	lui	a1,0x4000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b2                	slli	a1,a1,0xc
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	7ae080e7          	jalr	1966(ra) # 800012c0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1a:	4581                	li	a1,0
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	a62080e7          	jalr	-1438(ra) # 80001580 <uvmfree>
    return 0;
    80001b26:	4481                	li	s1,0
    80001b28:	bf7d                	j	80001ae6 <proc_pagetable+0x58>

0000000080001b2a <proc_freepagetable>:
{
    80001b2a:	1101                	addi	sp,sp,-32
    80001b2c:	ec06                	sd	ra,24(sp)
    80001b2e:	e822                	sd	s0,16(sp)
    80001b30:	e426                	sd	s1,8(sp)
    80001b32:	e04a                	sd	s2,0(sp)
    80001b34:	1000                	addi	s0,sp,32
    80001b36:	84aa                	mv	s1,a0
    80001b38:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3a:	4681                	li	a3,0
    80001b3c:	4605                	li	a2,1
    80001b3e:	040005b7          	lui	a1,0x4000
    80001b42:	15fd                	addi	a1,a1,-1
    80001b44:	05b2                	slli	a1,a1,0xc
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	77a080e7          	jalr	1914(ra) # 800012c0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4e:	4681                	li	a3,0
    80001b50:	4605                	li	a2,1
    80001b52:	020005b7          	lui	a1,0x2000
    80001b56:	15fd                	addi	a1,a1,-1
    80001b58:	05b6                	slli	a1,a1,0xd
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	764080e7          	jalr	1892(ra) # 800012c0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b64:	85ca                	mv	a1,s2
    80001b66:	8526                	mv	a0,s1
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	a18080e7          	jalr	-1512(ra) # 80001580 <uvmfree>
}
    80001b70:	60e2                	ld	ra,24(sp)
    80001b72:	6442                	ld	s0,16(sp)
    80001b74:	64a2                	ld	s1,8(sp)
    80001b76:	6902                	ld	s2,0(sp)
    80001b78:	6105                	addi	sp,sp,32
    80001b7a:	8082                	ret

0000000080001b7c <freeproc>:
{
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	1000                	addi	s0,sp,32
    80001b86:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b88:	6d28                	ld	a0,88(a0)
    80001b8a:	c509                	beqz	a0,80001b94 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	e86080e7          	jalr	-378(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001b94:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b98:	68a8                	ld	a0,80(s1)
    80001b9a:	c511                	beqz	a0,80001ba6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9c:	64ac                	ld	a1,72(s1)
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	f8c080e7          	jalr	-116(ra) # 80001b2a <proc_freepagetable>
  p->pagetable = 0;
    80001ba6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001baa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bae:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bb2:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bb6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bba:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bbe:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bc2:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bc6:	0004ac23          	sw	zero,24(s1)
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <allocproc>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	e04a                	sd	s2,0(sp)
    80001bde:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be0:	00010497          	auipc	s1,0x10
    80001be4:	18848493          	addi	s1,s1,392 # 80011d68 <proc>
    80001be8:	00016917          	auipc	s2,0x16
    80001bec:	b8090913          	addi	s2,s2,-1152 # 80017768 <tickslock>
    acquire(&p->lock);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	00c080e7          	jalr	12(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001bfa:	4c9c                	lw	a5,24(s1)
    80001bfc:	cf81                	beqz	a5,80001c14 <allocproc+0x40>
      release(&p->lock);
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	0b2080e7          	jalr	178(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c08:	16848493          	addi	s1,s1,360
    80001c0c:	ff2492e3          	bne	s1,s2,80001bf0 <allocproc+0x1c>
  return 0;
    80001c10:	4481                	li	s1,0
    80001c12:	a0b9                	j	80001c60 <allocproc+0x8c>
  p->pid = allocpid();
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e34080e7          	jalr	-460(ra) # 80001a48 <allocpid>
    80001c1c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	ef0080e7          	jalr	-272(ra) # 80000b0e <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e60080e7          	jalr	-416(ra) # 80001a8e <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c129                	beqz	a0,80001c7c <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0b4080e7          	jalr	180(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db478793          	addi	a5,a5,-588 # 80001a02 <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	042080e7          	jalr	66(ra) # 80000cb2 <release>
    return 0;
    80001c78:	84ca                	mv	s1,s2
    80001c7a:	b7dd                	j	80001c60 <allocproc+0x8c>
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	efe080e7          	jalr	-258(ra) # 80001b7c <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	02a080e7          	jalr	42(ra) # 80000cb2 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	b7f9                	j	80001c60 <allocproc+0x8c>

0000000080001c94 <userinit>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	f36080e7          	jalr	-202(ra) # 80001bd4 <allocproc>
    80001ca6:	84aa                	mv	s1,a0
  initproc = p;
    80001ca8:	00007797          	auipc	a5,0x7
    80001cac:	36a7b823          	sd	a0,880(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb0:	03400613          	li	a2,52
    80001cb4:	00007597          	auipc	a1,0x7
    80001cb8:	b6c58593          	addi	a1,a1,-1172 # 80008820 <initcode>
    80001cbc:	6928                	ld	a0,80(a0)
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	6f4080e7          	jalr	1780(ra) # 800013b2 <uvminit>
  p->sz = PGSIZE;
    80001cc6:	6785                	lui	a5,0x1
    80001cc8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd0:	6cb8                	ld	a4,88(s1)
    80001cd2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd4:	4641                	li	a2,16
    80001cd6:	00006597          	auipc	a1,0x6
    80001cda:	51258593          	addi	a1,a1,1298 # 800081e8 <digits+0x1a8>
    80001cde:	15848513          	addi	a0,s1,344
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	16a080e7          	jalr	362(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	50e50513          	addi	a0,a0,1294 # 800081f8 <digits+0x1b8>
    80001cf2:	00002097          	auipc	ra,0x2
    80001cf6:	092080e7          	jalr	146(ra) # 80003d84 <namei>
    80001cfa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfe:	4789                	li	a5,2
    80001d00:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	fae080e7          	jalr	-82(ra) # 80000cb2 <release>
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <growproc>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	ca6080e7          	jalr	-858(ra) # 800019ca <myproc>
    80001d2c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d2e:	652c                	ld	a1,72(a0)
    80001d30:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d34:	00904f63          	bgtz	s1,80001d52 <growproc+0x3c>
  } else if(n < 0){
    80001d38:	0204cc63          	bltz	s1,80001d70 <growproc+0x5a>
  p->sz = sz;
    80001d3c:	1602                	slli	a2,a2,0x20
    80001d3e:	9201                	srli	a2,a2,0x20
    80001d40:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d52:	9e25                	addw	a2,a2,s1
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	1582                	slli	a1,a1,0x20
    80001d5a:	9181                	srli	a1,a1,0x20
    80001d5c:	6928                	ld	a0,80(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	70e080e7          	jalr	1806(ra) # 8000146c <uvmalloc>
    80001d66:	0005061b          	sext.w	a2,a0
    80001d6a:	fa69                	bnez	a2,80001d3c <growproc+0x26>
      return -1;
    80001d6c:	557d                	li	a0,-1
    80001d6e:	bfe1                	j	80001d46 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d70:	9e25                	addw	a2,a2,s1
    80001d72:	1602                	slli	a2,a2,0x20
    80001d74:	9201                	srli	a2,a2,0x20
    80001d76:	1582                	slli	a1,a1,0x20
    80001d78:	9181                	srli	a1,a1,0x20
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	6a8080e7          	jalr	1704(ra) # 80001424 <uvmdealloc>
    80001d84:	0005061b          	sext.w	a2,a0
    80001d88:	bf55                	j	80001d3c <growproc+0x26>

0000000080001d8a <fork>:
{
    80001d8a:	7139                	addi	sp,sp,-64
    80001d8c:	fc06                	sd	ra,56(sp)
    80001d8e:	f822                	sd	s0,48(sp)
    80001d90:	f426                	sd	s1,40(sp)
    80001d92:	f04a                	sd	s2,32(sp)
    80001d94:	ec4e                	sd	s3,24(sp)
    80001d96:	e852                	sd	s4,16(sp)
    80001d98:	e456                	sd	s5,8(sp)
    80001d9a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	c2e080e7          	jalr	-978(ra) # 800019ca <myproc>
    80001da4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	e2e080e7          	jalr	-466(ra) # 80001bd4 <allocproc>
    80001dae:	c17d                	beqz	a0,80001e94 <fork+0x10a>
    80001db0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db2:	048ab603          	ld	a2,72(s5)
    80001db6:	692c                	ld	a1,80(a0)
    80001db8:	050ab503          	ld	a0,80(s5)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	7fc080e7          	jalr	2044(ra) # 800015b8 <uvmcopy>
    80001dc4:	04054a63          	bltz	a0,80001e18 <fork+0x8e>
  np->sz = p->sz;
    80001dc8:	048ab783          	ld	a5,72(s5)
    80001dcc:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001dd0:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd4:	058ab683          	ld	a3,88(s5)
    80001dd8:	87b6                	mv	a5,a3
    80001dda:	058a3703          	ld	a4,88(s4)
    80001dde:	12068693          	addi	a3,a3,288
    80001de2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de6:	6788                	ld	a0,8(a5)
    80001de8:	6b8c                	ld	a1,16(a5)
    80001dea:	6f90                	ld	a2,24(a5)
    80001dec:	01073023          	sd	a6,0(a4)
    80001df0:	e708                	sd	a0,8(a4)
    80001df2:	eb0c                	sd	a1,16(a4)
    80001df4:	ef10                	sd	a2,24(a4)
    80001df6:	02078793          	addi	a5,a5,32
    80001dfa:	02070713          	addi	a4,a4,32
    80001dfe:	fed792e3          	bne	a5,a3,80001de2 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e02:	058a3783          	ld	a5,88(s4)
    80001e06:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e0a:	0d0a8493          	addi	s1,s5,208
    80001e0e:	0d0a0913          	addi	s2,s4,208
    80001e12:	150a8993          	addi	s3,s5,336
    80001e16:	a00d                	j	80001e38 <fork+0xae>
    freeproc(np);
    80001e18:	8552                	mv	a0,s4
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	d62080e7          	jalr	-670(ra) # 80001b7c <freeproc>
    release(&np->lock);
    80001e22:	8552                	mv	a0,s4
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e8e080e7          	jalr	-370(ra) # 80000cb2 <release>
    return -1;
    80001e2c:	54fd                	li	s1,-1
    80001e2e:	a889                	j	80001e80 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e30:	04a1                	addi	s1,s1,8
    80001e32:	0921                	addi	s2,s2,8
    80001e34:	01348b63          	beq	s1,s3,80001e4a <fork+0xc0>
    if(p->ofile[i])
    80001e38:	6088                	ld	a0,0(s1)
    80001e3a:	d97d                	beqz	a0,80001e30 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	5d8080e7          	jalr	1496(ra) # 80004414 <filedup>
    80001e44:	00a93023          	sd	a0,0(s2)
    80001e48:	b7e5                	j	80001e30 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e4a:	150ab503          	ld	a0,336(s5)
    80001e4e:	00001097          	auipc	ra,0x1
    80001e52:	748080e7          	jalr	1864(ra) # 80003596 <idup>
    80001e56:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5a:	4641                	li	a2,16
    80001e5c:	158a8593          	addi	a1,s5,344
    80001e60:	158a0513          	addi	a0,s4,344
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	fe8080e7          	jalr	-24(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001e6c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e70:	4789                	li	a5,2
    80001e72:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	e3a080e7          	jalr	-454(ra) # 80000cb2 <release>
}
    80001e80:	8526                	mv	a0,s1
    80001e82:	70e2                	ld	ra,56(sp)
    80001e84:	7442                	ld	s0,48(sp)
    80001e86:	74a2                	ld	s1,40(sp)
    80001e88:	7902                	ld	s2,32(sp)
    80001e8a:	69e2                	ld	s3,24(sp)
    80001e8c:	6a42                	ld	s4,16(sp)
    80001e8e:	6aa2                	ld	s5,8(sp)
    80001e90:	6121                	addi	sp,sp,64
    80001e92:	8082                	ret
    return -1;
    80001e94:	54fd                	li	s1,-1
    80001e96:	b7ed                	j	80001e80 <fork+0xf6>

0000000080001e98 <reparent>:
{
    80001e98:	7179                	addi	sp,sp,-48
    80001e9a:	f406                	sd	ra,40(sp)
    80001e9c:	f022                	sd	s0,32(sp)
    80001e9e:	ec26                	sd	s1,24(sp)
    80001ea0:	e84a                	sd	s2,16(sp)
    80001ea2:	e44e                	sd	s3,8(sp)
    80001ea4:	e052                	sd	s4,0(sp)
    80001ea6:	1800                	addi	s0,sp,48
    80001ea8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eaa:	00010497          	auipc	s1,0x10
    80001eae:	ebe48493          	addi	s1,s1,-322 # 80011d68 <proc>
      pp->parent = initproc;
    80001eb2:	00007a17          	auipc	s4,0x7
    80001eb6:	166a0a13          	addi	s4,s4,358 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eba:	00016997          	auipc	s3,0x16
    80001ebe:	8ae98993          	addi	s3,s3,-1874 # 80017768 <tickslock>
    80001ec2:	a029                	j	80001ecc <reparent+0x34>
    80001ec4:	16848493          	addi	s1,s1,360
    80001ec8:	03348363          	beq	s1,s3,80001eee <reparent+0x56>
    if(pp->parent == p){
    80001ecc:	709c                	ld	a5,32(s1)
    80001ece:	ff279be3          	bne	a5,s2,80001ec4 <reparent+0x2c>
      acquire(&pp->lock);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	d2a080e7          	jalr	-726(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80001edc:	000a3783          	ld	a5,0(s4)
    80001ee0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ee2:	8526                	mv	a0,s1
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	dce080e7          	jalr	-562(ra) # 80000cb2 <release>
    80001eec:	bfe1                	j	80001ec4 <reparent+0x2c>
}
    80001eee:	70a2                	ld	ra,40(sp)
    80001ef0:	7402                	ld	s0,32(sp)
    80001ef2:	64e2                	ld	s1,24(sp)
    80001ef4:	6942                	ld	s2,16(sp)
    80001ef6:	69a2                	ld	s3,8(sp)
    80001ef8:	6a02                	ld	s4,0(sp)
    80001efa:	6145                	addi	sp,sp,48
    80001efc:	8082                	ret

0000000080001efe <scheduler>:
{
    80001efe:	7139                	addi	sp,sp,-64
    80001f00:	fc06                	sd	ra,56(sp)
    80001f02:	f822                	sd	s0,48(sp)
    80001f04:	f426                	sd	s1,40(sp)
    80001f06:	f04a                	sd	s2,32(sp)
    80001f08:	ec4e                	sd	s3,24(sp)
    80001f0a:	e852                	sd	s4,16(sp)
    80001f0c:	e456                	sd	s5,8(sp)
    80001f0e:	e05a                	sd	s6,0(sp)
    80001f10:	0080                	addi	s0,sp,64
    80001f12:	8792                	mv	a5,tp
  int id = r_tp();
    80001f14:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f16:	00779a93          	slli	s5,a5,0x7
    80001f1a:	00010717          	auipc	a4,0x10
    80001f1e:	a3670713          	addi	a4,a4,-1482 # 80011950 <pid_lock>
    80001f22:	9756                	add	a4,a4,s5
    80001f24:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f28:	00010717          	auipc	a4,0x10
    80001f2c:	a4870713          	addi	a4,a4,-1464 # 80011970 <cpus+0x8>
    80001f30:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f32:	4989                	li	s3,2
        p->state = RUNNING;
    80001f34:	4b0d                	li	s6,3
        c->proc = p;
    80001f36:	079e                	slli	a5,a5,0x7
    80001f38:	00010a17          	auipc	s4,0x10
    80001f3c:	a18a0a13          	addi	s4,s4,-1512 # 80011950 <pid_lock>
    80001f40:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f42:	00016917          	auipc	s2,0x16
    80001f46:	82690913          	addi	s2,s2,-2010 # 80017768 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f4e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f52:	10079073          	csrw	sstatus,a5
    80001f56:	00010497          	auipc	s1,0x10
    80001f5a:	e1248493          	addi	s1,s1,-494 # 80011d68 <proc>
    80001f5e:	a811                	j	80001f72 <scheduler+0x74>
      release(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d50080e7          	jalr	-688(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f6a:	16848493          	addi	s1,s1,360
    80001f6e:	fd248ee3          	beq	s1,s2,80001f4a <scheduler+0x4c>
      acquire(&p->lock);
    80001f72:	8526                	mv	a0,s1
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	c8a080e7          	jalr	-886(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    80001f7c:	4c9c                	lw	a5,24(s1)
    80001f7e:	ff3791e3          	bne	a5,s3,80001f60 <scheduler+0x62>
        p->state = RUNNING;
    80001f82:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f86:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f8a:	06048593          	addi	a1,s1,96
    80001f8e:	8556                	mv	a0,s5
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	5e0080e7          	jalr	1504(ra) # 80002570 <swtch>
        c->proc = 0;
    80001f98:	000a3c23          	sd	zero,24(s4)
    80001f9c:	b7d1                	j	80001f60 <scheduler+0x62>

0000000080001f9e <sched>:
{
    80001f9e:	7179                	addi	sp,sp,-48
    80001fa0:	f406                	sd	ra,40(sp)
    80001fa2:	f022                	sd	s0,32(sp)
    80001fa4:	ec26                	sd	s1,24(sp)
    80001fa6:	e84a                	sd	s2,16(sp)
    80001fa8:	e44e                	sd	s3,8(sp)
    80001faa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	a1e080e7          	jalr	-1506(ra) # 800019ca <myproc>
    80001fb4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	bce080e7          	jalr	-1074(ra) # 80000b84 <holding>
    80001fbe:	c93d                	beqz	a0,80002034 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	00010717          	auipc	a4,0x10
    80001fca:	98a70713          	addi	a4,a4,-1654 # 80011950 <pid_lock>
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	0907a703          	lw	a4,144(a5)
    80001fd4:	4785                	li	a5,1
    80001fd6:	06f71763          	bne	a4,a5,80002044 <sched+0xa6>
  if(p->state == RUNNING)
    80001fda:	4c98                	lw	a4,24(s1)
    80001fdc:	478d                	li	a5,3
    80001fde:	06f70b63          	beq	a4,a5,80002054 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe8:	efb5                	bnez	a5,80002064 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fea:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fec:	00010917          	auipc	s2,0x10
    80001ff0:	96490913          	addi	s2,s2,-1692 # 80011950 <pid_lock>
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	97ca                	add	a5,a5,s2
    80001ffa:	0947a983          	lw	s3,148(a5)
    80001ffe:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	00010597          	auipc	a1,0x10
    80002008:	96c58593          	addi	a1,a1,-1684 # 80011970 <cpus+0x8>
    8000200c:	95be                	add	a1,a1,a5
    8000200e:	06048513          	addi	a0,s1,96
    80002012:	00000097          	auipc	ra,0x0
    80002016:	55e080e7          	jalr	1374(ra) # 80002570 <swtch>
    8000201a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	97ca                	add	a5,a5,s2
    80002022:	0937aa23          	sw	s3,148(a5)
}
    80002026:	70a2                	ld	ra,40(sp)
    80002028:	7402                	ld	s0,32(sp)
    8000202a:	64e2                	ld	s1,24(sp)
    8000202c:	6942                	ld	s2,16(sp)
    8000202e:	69a2                	ld	s3,8(sp)
    80002030:	6145                	addi	sp,sp,48
    80002032:	8082                	ret
    panic("sched p->lock");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1cc50513          	addi	a0,a0,460 # 80008200 <digits+0x1c0>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	506080e7          	jalr	1286(ra) # 80000542 <panic>
    panic("sched locks");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	1cc50513          	addi	a0,a0,460 # 80008210 <digits+0x1d0>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4f6080e7          	jalr	1270(ra) # 80000542 <panic>
    panic("sched running");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1cc50513          	addi	a0,a0,460 # 80008220 <digits+0x1e0>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4e6080e7          	jalr	1254(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002064:	00006517          	auipc	a0,0x6
    80002068:	1cc50513          	addi	a0,a0,460 # 80008230 <digits+0x1f0>
    8000206c:	ffffe097          	auipc	ra,0xffffe
    80002070:	4d6080e7          	jalr	1238(ra) # 80000542 <panic>

0000000080002074 <exit>:
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	e052                	sd	s4,0(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	944080e7          	jalr	-1724(ra) # 800019ca <myproc>
    8000208e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002090:	00007797          	auipc	a5,0x7
    80002094:	f887b783          	ld	a5,-120(a5) # 80009018 <initproc>
    80002098:	0d050493          	addi	s1,a0,208
    8000209c:	15050913          	addi	s2,a0,336
    800020a0:	02a79363          	bne	a5,a0,800020c6 <exit+0x52>
    panic("init exiting");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	1a450513          	addi	a0,a0,420 # 80008248 <digits+0x208>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	496080e7          	jalr	1174(ra) # 80000542 <panic>
      fileclose(f);
    800020b4:	00002097          	auipc	ra,0x2
    800020b8:	3b2080e7          	jalr	946(ra) # 80004466 <fileclose>
      p->ofile[fd] = 0;
    800020bc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020c0:	04a1                	addi	s1,s1,8
    800020c2:	01248563          	beq	s1,s2,800020cc <exit+0x58>
    if(p->ofile[fd]){
    800020c6:	6088                	ld	a0,0(s1)
    800020c8:	f575                	bnez	a0,800020b4 <exit+0x40>
    800020ca:	bfdd                	j	800020c0 <exit+0x4c>
  begin_op();
    800020cc:	00002097          	auipc	ra,0x2
    800020d0:	ec8080e7          	jalr	-312(ra) # 80003f94 <begin_op>
  iput(p->cwd);
    800020d4:	1509b503          	ld	a0,336(s3)
    800020d8:	00001097          	auipc	ra,0x1
    800020dc:	6b6080e7          	jalr	1718(ra) # 8000378e <iput>
  end_op();
    800020e0:	00002097          	auipc	ra,0x2
    800020e4:	f34080e7          	jalr	-204(ra) # 80004014 <end_op>
  p->cwd = 0;
    800020e8:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800020ec:	00007497          	auipc	s1,0x7
    800020f0:	f2c48493          	addi	s1,s1,-212 # 80009018 <initproc>
    800020f4:	6088                	ld	a0,0(s1)
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	b08080e7          	jalr	-1272(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    800020fe:	6088                	ld	a0,0(s1)
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	78a080e7          	jalr	1930(ra) # 8000188a <wakeup1>
  release(&initproc->lock);
    80002108:	6088                	ld	a0,0(s1)
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ba8080e7          	jalr	-1112(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002112:	854e                	mv	a0,s3
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	aea080e7          	jalr	-1302(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    8000211c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002120:	854e                	mv	a0,s3
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	b90080e7          	jalr	-1136(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	ad2080e7          	jalr	-1326(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002134:	854e                	mv	a0,s3
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	ac8080e7          	jalr	-1336(ra) # 80000bfe <acquire>
  reparent(p);
    8000213e:	854e                	mv	a0,s3
    80002140:	00000097          	auipc	ra,0x0
    80002144:	d58080e7          	jalr	-680(ra) # 80001e98 <reparent>
  wakeup1(original_parent);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	740080e7          	jalr	1856(ra) # 8000188a <wakeup1>
  p->xstate = status;
    80002152:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002156:	4791                	li	a5,4
    80002158:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000215c:	8526                	mv	a0,s1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b54080e7          	jalr	-1196(ra) # 80000cb2 <release>
  sched();
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	e38080e7          	jalr	-456(ra) # 80001f9e <sched>
  panic("zombie exit");
    8000216e:	00006517          	auipc	a0,0x6
    80002172:	0ea50513          	addi	a0,a0,234 # 80008258 <digits+0x218>
    80002176:	ffffe097          	auipc	ra,0xffffe
    8000217a:	3cc080e7          	jalr	972(ra) # 80000542 <panic>

000000008000217e <yield>:
{
    8000217e:	1101                	addi	sp,sp,-32
    80002180:	ec06                	sd	ra,24(sp)
    80002182:	e822                	sd	s0,16(sp)
    80002184:	e426                	sd	s1,8(sp)
    80002186:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	842080e7          	jalr	-1982(ra) # 800019ca <myproc>
    80002190:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	a6c080e7          	jalr	-1428(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    8000219a:	4789                	li	a5,2
    8000219c:	cc9c                	sw	a5,24(s1)
  sched();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	e00080e7          	jalr	-512(ra) # 80001f9e <sched>
  release(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	b0a080e7          	jalr	-1270(ra) # 80000cb2 <release>
}
    800021b0:	60e2                	ld	ra,24(sp)
    800021b2:	6442                	ld	s0,16(sp)
    800021b4:	64a2                	ld	s1,8(sp)
    800021b6:	6105                	addi	sp,sp,32
    800021b8:	8082                	ret

00000000800021ba <sleep>:
{
    800021ba:	7179                	addi	sp,sp,-48
    800021bc:	f406                	sd	ra,40(sp)
    800021be:	f022                	sd	s0,32(sp)
    800021c0:	ec26                	sd	s1,24(sp)
    800021c2:	e84a                	sd	s2,16(sp)
    800021c4:	e44e                	sd	s3,8(sp)
    800021c6:	1800                	addi	s0,sp,48
    800021c8:	89aa                	mv	s3,a0
    800021ca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	7fe080e7          	jalr	2046(ra) # 800019ca <myproc>
    800021d4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800021d6:	05250663          	beq	a0,s2,80002222 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	a24080e7          	jalr	-1500(ra) # 80000bfe <acquire>
    release(lk);
    800021e2:	854a                	mv	a0,s2
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	ace080e7          	jalr	-1330(ra) # 80000cb2 <release>
  p->chan = chan;
    800021ec:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800021f0:	4785                	li	a5,1
    800021f2:	cc9c                	sw	a5,24(s1)
  sched();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	daa080e7          	jalr	-598(ra) # 80001f9e <sched>
  p->chan = 0;
    800021fc:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	ab0080e7          	jalr	-1360(ra) # 80000cb2 <release>
    acquire(lk);
    8000220a:	854a                	mv	a0,s2
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9f2080e7          	jalr	-1550(ra) # 80000bfe <acquire>
}
    80002214:	70a2                	ld	ra,40(sp)
    80002216:	7402                	ld	s0,32(sp)
    80002218:	64e2                	ld	s1,24(sp)
    8000221a:	6942                	ld	s2,16(sp)
    8000221c:	69a2                	ld	s3,8(sp)
    8000221e:	6145                	addi	sp,sp,48
    80002220:	8082                	ret
  p->chan = chan;
    80002222:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002226:	4785                	li	a5,1
    80002228:	cd1c                	sw	a5,24(a0)
  sched();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	d74080e7          	jalr	-652(ra) # 80001f9e <sched>
  p->chan = 0;
    80002232:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002236:	bff9                	j	80002214 <sleep+0x5a>

0000000080002238 <wait>:
{
    80002238:	715d                	addi	sp,sp,-80
    8000223a:	e486                	sd	ra,72(sp)
    8000223c:	e0a2                	sd	s0,64(sp)
    8000223e:	fc26                	sd	s1,56(sp)
    80002240:	f84a                	sd	s2,48(sp)
    80002242:	f44e                	sd	s3,40(sp)
    80002244:	f052                	sd	s4,32(sp)
    80002246:	ec56                	sd	s5,24(sp)
    80002248:	e85a                	sd	s6,16(sp)
    8000224a:	e45e                	sd	s7,8(sp)
    8000224c:	0880                	addi	s0,sp,80
    8000224e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	77a080e7          	jalr	1914(ra) # 800019ca <myproc>
    80002258:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	9a4080e7          	jalr	-1628(ra) # 80000bfe <acquire>
    havekids = 0;
    80002262:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002264:	4a11                	li	s4,4
        havekids = 1;
    80002266:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002268:	00015997          	auipc	s3,0x15
    8000226c:	50098993          	addi	s3,s3,1280 # 80017768 <tickslock>
    havekids = 0;
    80002270:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002272:	00010497          	auipc	s1,0x10
    80002276:	af648493          	addi	s1,s1,-1290 # 80011d68 <proc>
    8000227a:	a08d                	j	800022dc <wait+0xa4>
          pid = np->pid;
    8000227c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002280:	000b0e63          	beqz	s6,8000229c <wait+0x64>
    80002284:	4691                	li	a3,4
    80002286:	03448613          	addi	a2,s1,52
    8000228a:	85da                	mv	a1,s6
    8000228c:	05093503          	ld	a0,80(s2)
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	42c080e7          	jalr	1068(ra) # 800016bc <copyout>
    80002298:	02054263          	bltz	a0,800022bc <wait+0x84>
          freeproc(np);
    8000229c:	8526                	mv	a0,s1
    8000229e:	00000097          	auipc	ra,0x0
    800022a2:	8de080e7          	jalr	-1826(ra) # 80001b7c <freeproc>
          release(&np->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	a0a080e7          	jalr	-1526(ra) # 80000cb2 <release>
          release(&p->lock);
    800022b0:	854a                	mv	a0,s2
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	a00080e7          	jalr	-1536(ra) # 80000cb2 <release>
          return pid;
    800022ba:	a8a9                	j	80002314 <wait+0xdc>
            release(&np->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9f4080e7          	jalr	-1548(ra) # 80000cb2 <release>
            release(&p->lock);
    800022c6:	854a                	mv	a0,s2
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9ea080e7          	jalr	-1558(ra) # 80000cb2 <release>
            return -1;
    800022d0:	59fd                	li	s3,-1
    800022d2:	a089                	j	80002314 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800022d4:	16848493          	addi	s1,s1,360
    800022d8:	03348463          	beq	s1,s3,80002300 <wait+0xc8>
      if(np->parent == p){
    800022dc:	709c                	ld	a5,32(s1)
    800022de:	ff279be3          	bne	a5,s2,800022d4 <wait+0x9c>
        acquire(&np->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	91a080e7          	jalr	-1766(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    800022ec:	4c9c                	lw	a5,24(s1)
    800022ee:	f94787e3          	beq	a5,s4,8000227c <wait+0x44>
        release(&np->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	9be080e7          	jalr	-1602(ra) # 80000cb2 <release>
        havekids = 1;
    800022fc:	8756                	mv	a4,s5
    800022fe:	bfd9                	j	800022d4 <wait+0x9c>
    if(!havekids || p->killed){
    80002300:	c701                	beqz	a4,80002308 <wait+0xd0>
    80002302:	03092783          	lw	a5,48(s2)
    80002306:	c39d                	beqz	a5,8000232c <wait+0xf4>
      release(&p->lock);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	9a8080e7          	jalr	-1624(ra) # 80000cb2 <release>
      return -1;
    80002312:	59fd                	li	s3,-1
}
    80002314:	854e                	mv	a0,s3
    80002316:	60a6                	ld	ra,72(sp)
    80002318:	6406                	ld	s0,64(sp)
    8000231a:	74e2                	ld	s1,56(sp)
    8000231c:	7942                	ld	s2,48(sp)
    8000231e:	79a2                	ld	s3,40(sp)
    80002320:	7a02                	ld	s4,32(sp)
    80002322:	6ae2                	ld	s5,24(sp)
    80002324:	6b42                	ld	s6,16(sp)
    80002326:	6ba2                	ld	s7,8(sp)
    80002328:	6161                	addi	sp,sp,80
    8000232a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000232c:	85ca                	mv	a1,s2
    8000232e:	854a                	mv	a0,s2
    80002330:	00000097          	auipc	ra,0x0
    80002334:	e8a080e7          	jalr	-374(ra) # 800021ba <sleep>
    havekids = 0;
    80002338:	bf25                	j	80002270 <wait+0x38>

000000008000233a <wakeup>:
{
    8000233a:	7139                	addi	sp,sp,-64
    8000233c:	fc06                	sd	ra,56(sp)
    8000233e:	f822                	sd	s0,48(sp)
    80002340:	f426                	sd	s1,40(sp)
    80002342:	f04a                	sd	s2,32(sp)
    80002344:	ec4e                	sd	s3,24(sp)
    80002346:	e852                	sd	s4,16(sp)
    80002348:	e456                	sd	s5,8(sp)
    8000234a:	0080                	addi	s0,sp,64
    8000234c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000234e:	00010497          	auipc	s1,0x10
    80002352:	a1a48493          	addi	s1,s1,-1510 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002356:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002358:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000235a:	00015917          	auipc	s2,0x15
    8000235e:	40e90913          	addi	s2,s2,1038 # 80017768 <tickslock>
    80002362:	a811                	j	80002376 <wakeup+0x3c>
    release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	94c080e7          	jalr	-1716(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000236e:	16848493          	addi	s1,s1,360
    80002372:	03248063          	beq	s1,s2,80002392 <wakeup+0x58>
    acquire(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	886080e7          	jalr	-1914(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002380:	4c9c                	lw	a5,24(s1)
    80002382:	ff3791e3          	bne	a5,s3,80002364 <wakeup+0x2a>
    80002386:	749c                	ld	a5,40(s1)
    80002388:	fd479ee3          	bne	a5,s4,80002364 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000238c:	0154ac23          	sw	s5,24(s1)
    80002390:	bfd1                	j	80002364 <wakeup+0x2a>
}
    80002392:	70e2                	ld	ra,56(sp)
    80002394:	7442                	ld	s0,48(sp)
    80002396:	74a2                	ld	s1,40(sp)
    80002398:	7902                	ld	s2,32(sp)
    8000239a:	69e2                	ld	s3,24(sp)
    8000239c:	6a42                	ld	s4,16(sp)
    8000239e:	6aa2                	ld	s5,8(sp)
    800023a0:	6121                	addi	sp,sp,64
    800023a2:	8082                	ret

00000000800023a4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023a4:	7179                	addi	sp,sp,-48
    800023a6:	f406                	sd	ra,40(sp)
    800023a8:	f022                	sd	s0,32(sp)
    800023aa:	ec26                	sd	s1,24(sp)
    800023ac:	e84a                	sd	s2,16(sp)
    800023ae:	e44e                	sd	s3,8(sp)
    800023b0:	1800                	addi	s0,sp,48
    800023b2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023b4:	00010497          	auipc	s1,0x10
    800023b8:	9b448493          	addi	s1,s1,-1612 # 80011d68 <proc>
    800023bc:	00015997          	auipc	s3,0x15
    800023c0:	3ac98993          	addi	s3,s3,940 # 80017768 <tickslock>
    acquire(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	838080e7          	jalr	-1992(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    800023ce:	5c9c                	lw	a5,56(s1)
    800023d0:	01278d63          	beq	a5,s2,800023ea <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8dc080e7          	jalr	-1828(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023de:	16848493          	addi	s1,s1,360
    800023e2:	ff3491e3          	bne	s1,s3,800023c4 <kill+0x20>
  }
  return -1;
    800023e6:	557d                	li	a0,-1
    800023e8:	a821                	j	80002400 <kill+0x5c>
      p->killed = 1;
    800023ea:	4785                	li	a5,1
    800023ec:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800023ee:	4c98                	lw	a4,24(s1)
    800023f0:	00f70f63          	beq	a4,a5,8000240e <kill+0x6a>
      release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8bc080e7          	jalr	-1860(ra) # 80000cb2 <release>
      return 0;
    800023fe:	4501                	li	a0,0
}
    80002400:	70a2                	ld	ra,40(sp)
    80002402:	7402                	ld	s0,32(sp)
    80002404:	64e2                	ld	s1,24(sp)
    80002406:	6942                	ld	s2,16(sp)
    80002408:	69a2                	ld	s3,8(sp)
    8000240a:	6145                	addi	sp,sp,48
    8000240c:	8082                	ret
        p->state = RUNNABLE;
    8000240e:	4789                	li	a5,2
    80002410:	cc9c                	sw	a5,24(s1)
    80002412:	b7cd                	j	800023f4 <kill+0x50>

0000000080002414 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002414:	7179                	addi	sp,sp,-48
    80002416:	f406                	sd	ra,40(sp)
    80002418:	f022                	sd	s0,32(sp)
    8000241a:	ec26                	sd	s1,24(sp)
    8000241c:	e84a                	sd	s2,16(sp)
    8000241e:	e44e                	sd	s3,8(sp)
    80002420:	e052                	sd	s4,0(sp)
    80002422:	1800                	addi	s0,sp,48
    80002424:	84aa                	mv	s1,a0
    80002426:	892e                	mv	s2,a1
    80002428:	89b2                	mv	s3,a2
    8000242a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	59e080e7          	jalr	1438(ra) # 800019ca <myproc>
  if(user_dst){
    80002434:	c08d                	beqz	s1,80002456 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002436:	86d2                	mv	a3,s4
    80002438:	864e                	mv	a2,s3
    8000243a:	85ca                	mv	a1,s2
    8000243c:	6928                	ld	a0,80(a0)
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	27e080e7          	jalr	638(ra) # 800016bc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002446:	70a2                	ld	ra,40(sp)
    80002448:	7402                	ld	s0,32(sp)
    8000244a:	64e2                	ld	s1,24(sp)
    8000244c:	6942                	ld	s2,16(sp)
    8000244e:	69a2                	ld	s3,8(sp)
    80002450:	6a02                	ld	s4,0(sp)
    80002452:	6145                	addi	sp,sp,48
    80002454:	8082                	ret
    memmove((char *)dst, src, len);
    80002456:	000a061b          	sext.w	a2,s4
    8000245a:	85ce                	mv	a1,s3
    8000245c:	854a                	mv	a0,s2
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	8f8080e7          	jalr	-1800(ra) # 80000d56 <memmove>
    return 0;
    80002466:	8526                	mv	a0,s1
    80002468:	bff9                	j	80002446 <either_copyout+0x32>

000000008000246a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000246a:	7179                	addi	sp,sp,-48
    8000246c:	f406                	sd	ra,40(sp)
    8000246e:	f022                	sd	s0,32(sp)
    80002470:	ec26                	sd	s1,24(sp)
    80002472:	e84a                	sd	s2,16(sp)
    80002474:	e44e                	sd	s3,8(sp)
    80002476:	e052                	sd	s4,0(sp)
    80002478:	1800                	addi	s0,sp,48
    8000247a:	892a                	mv	s2,a0
    8000247c:	84ae                	mv	s1,a1
    8000247e:	89b2                	mv	s3,a2
    80002480:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	548080e7          	jalr	1352(ra) # 800019ca <myproc>
  if(user_src){
    8000248a:	c08d                	beqz	s1,800024ac <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000248c:	86d2                	mv	a3,s4
    8000248e:	864e                	mv	a2,s3
    80002490:	85ca                	mv	a1,s2
    80002492:	6928                	ld	a0,80(a0)
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	2b4080e7          	jalr	692(ra) # 80001748 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000249c:	70a2                	ld	ra,40(sp)
    8000249e:	7402                	ld	s0,32(sp)
    800024a0:	64e2                	ld	s1,24(sp)
    800024a2:	6942                	ld	s2,16(sp)
    800024a4:	69a2                	ld	s3,8(sp)
    800024a6:	6a02                	ld	s4,0(sp)
    800024a8:	6145                	addi	sp,sp,48
    800024aa:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ac:	000a061b          	sext.w	a2,s4
    800024b0:	85ce                	mv	a1,s3
    800024b2:	854a                	mv	a0,s2
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	8a2080e7          	jalr	-1886(ra) # 80000d56 <memmove>
    return 0;
    800024bc:	8526                	mv	a0,s1
    800024be:	bff9                	j	8000249c <either_copyin+0x32>

00000000800024c0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024c0:	715d                	addi	sp,sp,-80
    800024c2:	e486                	sd	ra,72(sp)
    800024c4:	e0a2                	sd	s0,64(sp)
    800024c6:	fc26                	sd	s1,56(sp)
    800024c8:	f84a                	sd	s2,48(sp)
    800024ca:	f44e                	sd	s3,40(sp)
    800024cc:	f052                	sd	s4,32(sp)
    800024ce:	ec56                	sd	s5,24(sp)
    800024d0:	e85a                	sd	s6,16(sp)
    800024d2:	e45e                	sd	s7,8(sp)
    800024d4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	bf250513          	addi	a0,a0,-1038 # 800080c8 <digits+0x88>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	0ae080e7          	jalr	174(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024e6:	00010497          	auipc	s1,0x10
    800024ea:	9da48493          	addi	s1,s1,-1574 # 80011ec0 <proc+0x158>
    800024ee:	00015917          	auipc	s2,0x15
    800024f2:	3d290913          	addi	s2,s2,978 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800024f8:	00006997          	auipc	s3,0x6
    800024fc:	d7098993          	addi	s3,s3,-656 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002500:	00006a97          	auipc	s5,0x6
    80002504:	d70a8a93          	addi	s5,s5,-656 # 80008270 <digits+0x230>
    printf("\n");
    80002508:	00006a17          	auipc	s4,0x6
    8000250c:	bc0a0a13          	addi	s4,s4,-1088 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002510:	00006b97          	auipc	s7,0x6
    80002514:	d98b8b93          	addi	s7,s7,-616 # 800082a8 <states.0>
    80002518:	a00d                	j	8000253a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000251a:	ee06a583          	lw	a1,-288(a3)
    8000251e:	8556                	mv	a0,s5
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	06c080e7          	jalr	108(ra) # 8000058c <printf>
    printf("\n");
    80002528:	8552                	mv	a0,s4
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	062080e7          	jalr	98(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002532:	16848493          	addi	s1,s1,360
    80002536:	03248263          	beq	s1,s2,8000255a <procdump+0x9a>
    if(p->state == UNUSED)
    8000253a:	86a6                	mv	a3,s1
    8000253c:	ec04a783          	lw	a5,-320(s1)
    80002540:	dbed                	beqz	a5,80002532 <procdump+0x72>
      state = "???";
    80002542:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002544:	fcfb6be3          	bltu	s6,a5,8000251a <procdump+0x5a>
    80002548:	02079713          	slli	a4,a5,0x20
    8000254c:	01d75793          	srli	a5,a4,0x1d
    80002550:	97de                	add	a5,a5,s7
    80002552:	6390                	ld	a2,0(a5)
    80002554:	f279                	bnez	a2,8000251a <procdump+0x5a>
      state = "???";
    80002556:	864e                	mv	a2,s3
    80002558:	b7c9                	j	8000251a <procdump+0x5a>
  }
}
    8000255a:	60a6                	ld	ra,72(sp)
    8000255c:	6406                	ld	s0,64(sp)
    8000255e:	74e2                	ld	s1,56(sp)
    80002560:	7942                	ld	s2,48(sp)
    80002562:	79a2                	ld	s3,40(sp)
    80002564:	7a02                	ld	s4,32(sp)
    80002566:	6ae2                	ld	s5,24(sp)
    80002568:	6b42                	ld	s6,16(sp)
    8000256a:	6ba2                	ld	s7,8(sp)
    8000256c:	6161                	addi	sp,sp,80
    8000256e:	8082                	ret

0000000080002570 <swtch>:
    80002570:	00153023          	sd	ra,0(a0)
    80002574:	00253423          	sd	sp,8(a0)
    80002578:	e900                	sd	s0,16(a0)
    8000257a:	ed04                	sd	s1,24(a0)
    8000257c:	03253023          	sd	s2,32(a0)
    80002580:	03353423          	sd	s3,40(a0)
    80002584:	03453823          	sd	s4,48(a0)
    80002588:	03553c23          	sd	s5,56(a0)
    8000258c:	05653023          	sd	s6,64(a0)
    80002590:	05753423          	sd	s7,72(a0)
    80002594:	05853823          	sd	s8,80(a0)
    80002598:	05953c23          	sd	s9,88(a0)
    8000259c:	07a53023          	sd	s10,96(a0)
    800025a0:	07b53423          	sd	s11,104(a0)
    800025a4:	0005b083          	ld	ra,0(a1)
    800025a8:	0085b103          	ld	sp,8(a1)
    800025ac:	6980                	ld	s0,16(a1)
    800025ae:	6d84                	ld	s1,24(a1)
    800025b0:	0205b903          	ld	s2,32(a1)
    800025b4:	0285b983          	ld	s3,40(a1)
    800025b8:	0305ba03          	ld	s4,48(a1)
    800025bc:	0385ba83          	ld	s5,56(a1)
    800025c0:	0405bb03          	ld	s6,64(a1)
    800025c4:	0485bb83          	ld	s7,72(a1)
    800025c8:	0505bc03          	ld	s8,80(a1)
    800025cc:	0585bc83          	ld	s9,88(a1)
    800025d0:	0605bd03          	ld	s10,96(a1)
    800025d4:	0685bd83          	ld	s11,104(a1)
    800025d8:	8082                	ret

00000000800025da <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025da:	1141                	addi	sp,sp,-16
    800025dc:	e406                	sd	ra,8(sp)
    800025de:	e022                	sd	s0,0(sp)
    800025e0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025e2:	00006597          	auipc	a1,0x6
    800025e6:	cee58593          	addi	a1,a1,-786 # 800082d0 <states.0+0x28>
    800025ea:	00015517          	auipc	a0,0x15
    800025ee:	17e50513          	addi	a0,a0,382 # 80017768 <tickslock>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	57c080e7          	jalr	1404(ra) # 80000b6e <initlock>
}
    800025fa:	60a2                	ld	ra,8(sp)
    800025fc:	6402                	ld	s0,0(sp)
    800025fe:	0141                	addi	sp,sp,16
    80002600:	8082                	ret

0000000080002602 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002602:	1141                	addi	sp,sp,-16
    80002604:	e422                	sd	s0,8(sp)
    80002606:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002608:	00003797          	auipc	a5,0x3
    8000260c:	4b878793          	addi	a5,a5,1208 # 80005ac0 <kernelvec>
    80002610:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002614:	6422                	ld	s0,8(sp)
    80002616:	0141                	addi	sp,sp,16
    80002618:	8082                	ret

000000008000261a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000261a:	1141                	addi	sp,sp,-16
    8000261c:	e406                	sd	ra,8(sp)
    8000261e:	e022                	sd	s0,0(sp)
    80002620:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002622:	fffff097          	auipc	ra,0xfffff
    80002626:	3a8080e7          	jalr	936(ra) # 800019ca <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000262a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000262e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002630:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002634:	00005617          	auipc	a2,0x5
    80002638:	9cc60613          	addi	a2,a2,-1588 # 80007000 <_trampoline>
    8000263c:	00005697          	auipc	a3,0x5
    80002640:	9c468693          	addi	a3,a3,-1596 # 80007000 <_trampoline>
    80002644:	8e91                	sub	a3,a3,a2
    80002646:	040007b7          	lui	a5,0x4000
    8000264a:	17fd                	addi	a5,a5,-1
    8000264c:	07b2                	slli	a5,a5,0xc
    8000264e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002650:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002654:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002656:	180026f3          	csrr	a3,satp
    8000265a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000265c:	6d38                	ld	a4,88(a0)
    8000265e:	6134                	ld	a3,64(a0)
    80002660:	6585                	lui	a1,0x1
    80002662:	96ae                	add	a3,a3,a1
    80002664:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002666:	6d38                	ld	a4,88(a0)
    80002668:	00000697          	auipc	a3,0x0
    8000266c:	13868693          	addi	a3,a3,312 # 800027a0 <usertrap>
    80002670:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002672:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002674:	8692                	mv	a3,tp
    80002676:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002678:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000267c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002680:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002684:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002688:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000268a:	6f18                	ld	a4,24(a4)
    8000268c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002690:	692c                	ld	a1,80(a0)
    80002692:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002694:	00005717          	auipc	a4,0x5
    80002698:	9fc70713          	addi	a4,a4,-1540 # 80007090 <userret>
    8000269c:	8f11                	sub	a4,a4,a2
    8000269e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026a0:	577d                	li	a4,-1
    800026a2:	177e                	slli	a4,a4,0x3f
    800026a4:	8dd9                	or	a1,a1,a4
    800026a6:	02000537          	lui	a0,0x2000
    800026aa:	157d                	addi	a0,a0,-1
    800026ac:	0536                	slli	a0,a0,0xd
    800026ae:	9782                	jalr	a5
}
    800026b0:	60a2                	ld	ra,8(sp)
    800026b2:	6402                	ld	s0,0(sp)
    800026b4:	0141                	addi	sp,sp,16
    800026b6:	8082                	ret

00000000800026b8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026b8:	1101                	addi	sp,sp,-32
    800026ba:	ec06                	sd	ra,24(sp)
    800026bc:	e822                	sd	s0,16(sp)
    800026be:	e426                	sd	s1,8(sp)
    800026c0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026c2:	00015497          	auipc	s1,0x15
    800026c6:	0a648493          	addi	s1,s1,166 # 80017768 <tickslock>
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	532080e7          	jalr	1330(ra) # 80000bfe <acquire>
  ticks++;
    800026d4:	00007517          	auipc	a0,0x7
    800026d8:	94c50513          	addi	a0,a0,-1716 # 80009020 <ticks>
    800026dc:	411c                	lw	a5,0(a0)
    800026de:	2785                	addiw	a5,a5,1
    800026e0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	c58080e7          	jalr	-936(ra) # 8000233a <wakeup>
  release(&tickslock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5c6080e7          	jalr	1478(ra) # 80000cb2 <release>
}
    800026f4:	60e2                	ld	ra,24(sp)
    800026f6:	6442                	ld	s0,16(sp)
    800026f8:	64a2                	ld	s1,8(sp)
    800026fa:	6105                	addi	sp,sp,32
    800026fc:	8082                	ret

00000000800026fe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026fe:	1101                	addi	sp,sp,-32
    80002700:	ec06                	sd	ra,24(sp)
    80002702:	e822                	sd	s0,16(sp)
    80002704:	e426                	sd	s1,8(sp)
    80002706:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002708:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000270c:	00074d63          	bltz	a4,80002726 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002710:	57fd                	li	a5,-1
    80002712:	17fe                	slli	a5,a5,0x3f
    80002714:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002716:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002718:	06f70363          	beq	a4,a5,8000277e <devintr+0x80>
  }
}
    8000271c:	60e2                	ld	ra,24(sp)
    8000271e:	6442                	ld	s0,16(sp)
    80002720:	64a2                	ld	s1,8(sp)
    80002722:	6105                	addi	sp,sp,32
    80002724:	8082                	ret
     (scause & 0xff) == 9){
    80002726:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000272a:	46a5                	li	a3,9
    8000272c:	fed792e3          	bne	a5,a3,80002710 <devintr+0x12>
    int irq = plic_claim();
    80002730:	00003097          	auipc	ra,0x3
    80002734:	498080e7          	jalr	1176(ra) # 80005bc8 <plic_claim>
    80002738:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000273a:	47a9                	li	a5,10
    8000273c:	02f50763          	beq	a0,a5,8000276a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002740:	4785                	li	a5,1
    80002742:	02f50963          	beq	a0,a5,80002774 <devintr+0x76>
    return 1;
    80002746:	4505                	li	a0,1
    } else if(irq){
    80002748:	d8f1                	beqz	s1,8000271c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000274a:	85a6                	mv	a1,s1
    8000274c:	00006517          	auipc	a0,0x6
    80002750:	b8c50513          	addi	a0,a0,-1140 # 800082d8 <states.0+0x30>
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	e38080e7          	jalr	-456(ra) # 8000058c <printf>
      plic_complete(irq);
    8000275c:	8526                	mv	a0,s1
    8000275e:	00003097          	auipc	ra,0x3
    80002762:	48e080e7          	jalr	1166(ra) # 80005bec <plic_complete>
    return 1;
    80002766:	4505                	li	a0,1
    80002768:	bf55                	j	8000271c <devintr+0x1e>
      uartintr();
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	258080e7          	jalr	600(ra) # 800009c2 <uartintr>
    80002772:	b7ed                	j	8000275c <devintr+0x5e>
      virtio_disk_intr();
    80002774:	00004097          	auipc	ra,0x4
    80002778:	8f2080e7          	jalr	-1806(ra) # 80006066 <virtio_disk_intr>
    8000277c:	b7c5                	j	8000275c <devintr+0x5e>
    if(cpuid() == 0){
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	220080e7          	jalr	544(ra) # 8000199e <cpuid>
    80002786:	c901                	beqz	a0,80002796 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002788:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000278c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000278e:	14479073          	csrw	sip,a5
    return 2;
    80002792:	4509                	li	a0,2
    80002794:	b761                	j	8000271c <devintr+0x1e>
      clockintr();
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	f22080e7          	jalr	-222(ra) # 800026b8 <clockintr>
    8000279e:	b7ed                	j	80002788 <devintr+0x8a>

00000000800027a0 <usertrap>:
{
    800027a0:	1101                	addi	sp,sp,-32
    800027a2:	ec06                	sd	ra,24(sp)
    800027a4:	e822                	sd	s0,16(sp)
    800027a6:	e426                	sd	s1,8(sp)
    800027a8:	e04a                	sd	s2,0(sp)
    800027aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027b0:	1007f793          	andi	a5,a5,256
    800027b4:	e3ad                	bnez	a5,80002816 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b6:	00003797          	auipc	a5,0x3
    800027ba:	30a78793          	addi	a5,a5,778 # 80005ac0 <kernelvec>
    800027be:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027c2:	fffff097          	auipc	ra,0xfffff
    800027c6:	208080e7          	jalr	520(ra) # 800019ca <myproc>
    800027ca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027cc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027ce:	14102773          	csrr	a4,sepc
    800027d2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027d4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027d8:	47a1                	li	a5,8
    800027da:	04f71c63          	bne	a4,a5,80002832 <usertrap+0x92>
    if(p->killed)
    800027de:	591c                	lw	a5,48(a0)
    800027e0:	e3b9                	bnez	a5,80002826 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027e2:	6cb8                	ld	a4,88(s1)
    800027e4:	6f1c                	ld	a5,24(a4)
    800027e6:	0791                	addi	a5,a5,4
    800027e8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f2:	10079073          	csrw	sstatus,a5
    syscall();
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	2e0080e7          	jalr	736(ra) # 80002ad6 <syscall>
  if(p->killed)
    800027fe:	589c                	lw	a5,48(s1)
    80002800:	ebc1                	bnez	a5,80002890 <usertrap+0xf0>
  usertrapret();
    80002802:	00000097          	auipc	ra,0x0
    80002806:	e18080e7          	jalr	-488(ra) # 8000261a <usertrapret>
}
    8000280a:	60e2                	ld	ra,24(sp)
    8000280c:	6442                	ld	s0,16(sp)
    8000280e:	64a2                	ld	s1,8(sp)
    80002810:	6902                	ld	s2,0(sp)
    80002812:	6105                	addi	sp,sp,32
    80002814:	8082                	ret
    panic("usertrap: not from user mode");
    80002816:	00006517          	auipc	a0,0x6
    8000281a:	ae250513          	addi	a0,a0,-1310 # 800082f8 <states.0+0x50>
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	d24080e7          	jalr	-732(ra) # 80000542 <panic>
      exit(-1);
    80002826:	557d                	li	a0,-1
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	84c080e7          	jalr	-1972(ra) # 80002074 <exit>
    80002830:	bf4d                	j	800027e2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002832:	00000097          	auipc	ra,0x0
    80002836:	ecc080e7          	jalr	-308(ra) # 800026fe <devintr>
    8000283a:	892a                	mv	s2,a0
    8000283c:	c501                	beqz	a0,80002844 <usertrap+0xa4>
  if(p->killed)
    8000283e:	589c                	lw	a5,48(s1)
    80002840:	c3a1                	beqz	a5,80002880 <usertrap+0xe0>
    80002842:	a815                	j	80002876 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002844:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002848:	5c90                	lw	a2,56(s1)
    8000284a:	00006517          	auipc	a0,0x6
    8000284e:	ace50513          	addi	a0,a0,-1330 # 80008318 <states.0+0x70>
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	d3a080e7          	jalr	-710(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000285a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000285e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002862:	00006517          	auipc	a0,0x6
    80002866:	ae650513          	addi	a0,a0,-1306 # 80008348 <states.0+0xa0>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	d22080e7          	jalr	-734(ra) # 8000058c <printf>
    p->killed = 1;
    80002872:	4785                	li	a5,1
    80002874:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002876:	557d                	li	a0,-1
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	7fc080e7          	jalr	2044(ra) # 80002074 <exit>
  if(which_dev == 2)
    80002880:	4789                	li	a5,2
    80002882:	f8f910e3          	bne	s2,a5,80002802 <usertrap+0x62>
    yield();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	8f8080e7          	jalr	-1800(ra) # 8000217e <yield>
    8000288e:	bf95                	j	80002802 <usertrap+0x62>
  int which_dev = 0;
    80002890:	4901                	li	s2,0
    80002892:	b7d5                	j	80002876 <usertrap+0xd6>

0000000080002894 <kerneltrap>:
{
    80002894:	7179                	addi	sp,sp,-48
    80002896:	f406                	sd	ra,40(sp)
    80002898:	f022                	sd	s0,32(sp)
    8000289a:	ec26                	sd	s1,24(sp)
    8000289c:	e84a                	sd	s2,16(sp)
    8000289e:	e44e                	sd	s3,8(sp)
    800028a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028aa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ae:	1004f793          	andi	a5,s1,256
    800028b2:	cb85                	beqz	a5,800028e2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028b8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028ba:	ef85                	bnez	a5,800028f2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	e42080e7          	jalr	-446(ra) # 800026fe <devintr>
    800028c4:	cd1d                	beqz	a0,80002902 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028c6:	4789                	li	a5,2
    800028c8:	06f50a63          	beq	a0,a5,8000293c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028cc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d0:	10049073          	csrw	sstatus,s1
}
    800028d4:	70a2                	ld	ra,40(sp)
    800028d6:	7402                	ld	s0,32(sp)
    800028d8:	64e2                	ld	s1,24(sp)
    800028da:	6942                	ld	s2,16(sp)
    800028dc:	69a2                	ld	s3,8(sp)
    800028de:	6145                	addi	sp,sp,48
    800028e0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a8650513          	addi	a0,a0,-1402 # 80008368 <states.0+0xc0>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c58080e7          	jalr	-936(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800028f2:	00006517          	auipc	a0,0x6
    800028f6:	a9e50513          	addi	a0,a0,-1378 # 80008390 <states.0+0xe8>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c48080e7          	jalr	-952(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002902:	85ce                	mv	a1,s3
    80002904:	00006517          	auipc	a0,0x6
    80002908:	aac50513          	addi	a0,a0,-1364 # 800083b0 <states.0+0x108>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c80080e7          	jalr	-896(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002914:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002918:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	aa450513          	addi	a0,a0,-1372 # 800083c0 <states.0+0x118>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c68080e7          	jalr	-920(ra) # 8000058c <printf>
    panic("kerneltrap");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	aac50513          	addi	a0,a0,-1364 # 800083d8 <states.0+0x130>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c0e080e7          	jalr	-1010(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000293c:	fffff097          	auipc	ra,0xfffff
    80002940:	08e080e7          	jalr	142(ra) # 800019ca <myproc>
    80002944:	d541                	beqz	a0,800028cc <kerneltrap+0x38>
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	084080e7          	jalr	132(ra) # 800019ca <myproc>
    8000294e:	4d18                	lw	a4,24(a0)
    80002950:	478d                	li	a5,3
    80002952:	f6f71de3          	bne	a4,a5,800028cc <kerneltrap+0x38>
    yield();
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	828080e7          	jalr	-2008(ra) # 8000217e <yield>
    8000295e:	b7bd                	j	800028cc <kerneltrap+0x38>

0000000080002960 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002960:	1101                	addi	sp,sp,-32
    80002962:	ec06                	sd	ra,24(sp)
    80002964:	e822                	sd	s0,16(sp)
    80002966:	e426                	sd	s1,8(sp)
    80002968:	1000                	addi	s0,sp,32
    8000296a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	05e080e7          	jalr	94(ra) # 800019ca <myproc>
  switch (n) {
    80002974:	4795                	li	a5,5
    80002976:	0497e163          	bltu	a5,s1,800029b8 <argraw+0x58>
    8000297a:	048a                	slli	s1,s1,0x2
    8000297c:	00006717          	auipc	a4,0x6
    80002980:	a9470713          	addi	a4,a4,-1388 # 80008410 <states.0+0x168>
    80002984:	94ba                	add	s1,s1,a4
    80002986:	409c                	lw	a5,0(s1)
    80002988:	97ba                	add	a5,a5,a4
    8000298a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000298c:	6d3c                	ld	a5,88(a0)
    8000298e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002990:	60e2                	ld	ra,24(sp)
    80002992:	6442                	ld	s0,16(sp)
    80002994:	64a2                	ld	s1,8(sp)
    80002996:	6105                	addi	sp,sp,32
    80002998:	8082                	ret
    return p->trapframe->a1;
    8000299a:	6d3c                	ld	a5,88(a0)
    8000299c:	7fa8                	ld	a0,120(a5)
    8000299e:	bfcd                	j	80002990 <argraw+0x30>
    return p->trapframe->a2;
    800029a0:	6d3c                	ld	a5,88(a0)
    800029a2:	63c8                	ld	a0,128(a5)
    800029a4:	b7f5                	j	80002990 <argraw+0x30>
    return p->trapframe->a3;
    800029a6:	6d3c                	ld	a5,88(a0)
    800029a8:	67c8                	ld	a0,136(a5)
    800029aa:	b7dd                	j	80002990 <argraw+0x30>
    return p->trapframe->a4;
    800029ac:	6d3c                	ld	a5,88(a0)
    800029ae:	6bc8                	ld	a0,144(a5)
    800029b0:	b7c5                	j	80002990 <argraw+0x30>
    return p->trapframe->a5;
    800029b2:	6d3c                	ld	a5,88(a0)
    800029b4:	6fc8                	ld	a0,152(a5)
    800029b6:	bfe9                	j	80002990 <argraw+0x30>
  panic("argraw");
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	a3050513          	addi	a0,a0,-1488 # 800083e8 <states.0+0x140>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	b82080e7          	jalr	-1150(ra) # 80000542 <panic>

00000000800029c8 <fetchaddr>:
{
    800029c8:	1101                	addi	sp,sp,-32
    800029ca:	ec06                	sd	ra,24(sp)
    800029cc:	e822                	sd	s0,16(sp)
    800029ce:	e426                	sd	s1,8(sp)
    800029d0:	e04a                	sd	s2,0(sp)
    800029d2:	1000                	addi	s0,sp,32
    800029d4:	84aa                	mv	s1,a0
    800029d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	ff2080e7          	jalr	-14(ra) # 800019ca <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029e0:	653c                	ld	a5,72(a0)
    800029e2:	02f4f863          	bgeu	s1,a5,80002a12 <fetchaddr+0x4a>
    800029e6:	00848713          	addi	a4,s1,8
    800029ea:	02e7e663          	bltu	a5,a4,80002a16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029ee:	46a1                	li	a3,8
    800029f0:	8626                	mv	a2,s1
    800029f2:	85ca                	mv	a1,s2
    800029f4:	6928                	ld	a0,80(a0)
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	d52080e7          	jalr	-686(ra) # 80001748 <copyin>
    800029fe:	00a03533          	snez	a0,a0
    80002a02:	40a00533          	neg	a0,a0
}
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	64a2                	ld	s1,8(sp)
    80002a0c:	6902                	ld	s2,0(sp)
    80002a0e:	6105                	addi	sp,sp,32
    80002a10:	8082                	ret
    return -1;
    80002a12:	557d                	li	a0,-1
    80002a14:	bfcd                	j	80002a06 <fetchaddr+0x3e>
    80002a16:	557d                	li	a0,-1
    80002a18:	b7fd                	j	80002a06 <fetchaddr+0x3e>

0000000080002a1a <fetchstr>:
{
    80002a1a:	7179                	addi	sp,sp,-48
    80002a1c:	f406                	sd	ra,40(sp)
    80002a1e:	f022                	sd	s0,32(sp)
    80002a20:	ec26                	sd	s1,24(sp)
    80002a22:	e84a                	sd	s2,16(sp)
    80002a24:	e44e                	sd	s3,8(sp)
    80002a26:	1800                	addi	s0,sp,48
    80002a28:	892a                	mv	s2,a0
    80002a2a:	84ae                	mv	s1,a1
    80002a2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f9c080e7          	jalr	-100(ra) # 800019ca <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a36:	86ce                	mv	a3,s3
    80002a38:	864a                	mv	a2,s2
    80002a3a:	85a6                	mv	a1,s1
    80002a3c:	6928                	ld	a0,80(a0)
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	d98080e7          	jalr	-616(ra) # 800017d6 <copyinstr>
  if(err < 0)
    80002a46:	00054763          	bltz	a0,80002a54 <fetchstr+0x3a>
  return strlen(buf);
    80002a4a:	8526                	mv	a0,s1
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	432080e7          	jalr	1074(ra) # 80000e7e <strlen>
}
    80002a54:	70a2                	ld	ra,40(sp)
    80002a56:	7402                	ld	s0,32(sp)
    80002a58:	64e2                	ld	s1,24(sp)
    80002a5a:	6942                	ld	s2,16(sp)
    80002a5c:	69a2                	ld	s3,8(sp)
    80002a5e:	6145                	addi	sp,sp,48
    80002a60:	8082                	ret

0000000080002a62 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a62:	1101                	addi	sp,sp,-32
    80002a64:	ec06                	sd	ra,24(sp)
    80002a66:	e822                	sd	s0,16(sp)
    80002a68:	e426                	sd	s1,8(sp)
    80002a6a:	1000                	addi	s0,sp,32
    80002a6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	ef2080e7          	jalr	-270(ra) # 80002960 <argraw>
    80002a76:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a78:	4501                	li	a0,0
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret

0000000080002a84 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	1000                	addi	s0,sp,32
    80002a8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	ed0080e7          	jalr	-304(ra) # 80002960 <argraw>
    80002a98:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a9a:	4501                	li	a0,0
    80002a9c:	60e2                	ld	ra,24(sp)
    80002a9e:	6442                	ld	s0,16(sp)
    80002aa0:	64a2                	ld	s1,8(sp)
    80002aa2:	6105                	addi	sp,sp,32
    80002aa4:	8082                	ret

0000000080002aa6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	addi	s0,sp,32
    80002ab2:	84ae                	mv	s1,a1
    80002ab4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	eaa080e7          	jalr	-342(ra) # 80002960 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002abe:	864a                	mv	a2,s2
    80002ac0:	85a6                	mv	a1,s1
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	f58080e7          	jalr	-168(ra) # 80002a1a <fetchstr>
}
    80002aca:	60e2                	ld	ra,24(sp)
    80002acc:	6442                	ld	s0,16(sp)
    80002ace:	64a2                	ld	s1,8(sp)
    80002ad0:	6902                	ld	s2,0(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret

0000000080002ad6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	e04a                	sd	s2,0(sp)
    80002ae0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	ee8080e7          	jalr	-280(ra) # 800019ca <myproc>
    80002aea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002aec:	05853903          	ld	s2,88(a0)
    80002af0:	0a893783          	ld	a5,168(s2)
    80002af4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002af8:	37fd                	addiw	a5,a5,-1
    80002afa:	4751                	li	a4,20
    80002afc:	00f76f63          	bltu	a4,a5,80002b1a <syscall+0x44>
    80002b00:	00369713          	slli	a4,a3,0x3
    80002b04:	00006797          	auipc	a5,0x6
    80002b08:	92478793          	addi	a5,a5,-1756 # 80008428 <syscalls>
    80002b0c:	97ba                	add	a5,a5,a4
    80002b0e:	639c                	ld	a5,0(a5)
    80002b10:	c789                	beqz	a5,80002b1a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b12:	9782                	jalr	a5
    80002b14:	06a93823          	sd	a0,112(s2)
    80002b18:	a839                	j	80002b36 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b1a:	15848613          	addi	a2,s1,344
    80002b1e:	5c8c                	lw	a1,56(s1)
    80002b20:	00006517          	auipc	a0,0x6
    80002b24:	8d050513          	addi	a0,a0,-1840 # 800083f0 <states.0+0x148>
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	a64080e7          	jalr	-1436(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b30:	6cbc                	ld	a5,88(s1)
    80002b32:	577d                	li	a4,-1
    80002b34:	fbb8                	sd	a4,112(a5)
  }
}
    80002b36:	60e2                	ld	ra,24(sp)
    80002b38:	6442                	ld	s0,16(sp)
    80002b3a:	64a2                	ld	s1,8(sp)
    80002b3c:	6902                	ld	s2,0(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret

0000000080002b42 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b4a:	fec40593          	addi	a1,s0,-20
    80002b4e:	4501                	li	a0,0
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	f12080e7          	jalr	-238(ra) # 80002a62 <argint>
    return -1;
    80002b58:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b5a:	00054963          	bltz	a0,80002b6c <sys_exit+0x2a>
  exit(n);
    80002b5e:	fec42503          	lw	a0,-20(s0)
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	512080e7          	jalr	1298(ra) # 80002074 <exit>
  return 0;  // not reached
    80002b6a:	4781                	li	a5,0
}
    80002b6c:	853e                	mv	a0,a5
    80002b6e:	60e2                	ld	ra,24(sp)
    80002b70:	6442                	ld	s0,16(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret

0000000080002b76 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b76:	1141                	addi	sp,sp,-16
    80002b78:	e406                	sd	ra,8(sp)
    80002b7a:	e022                	sd	s0,0(sp)
    80002b7c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	e4c080e7          	jalr	-436(ra) # 800019ca <myproc>
}
    80002b86:	5d08                	lw	a0,56(a0)
    80002b88:	60a2                	ld	ra,8(sp)
    80002b8a:	6402                	ld	s0,0(sp)
    80002b8c:	0141                	addi	sp,sp,16
    80002b8e:	8082                	ret

0000000080002b90 <sys_fork>:

uint64
sys_fork(void)
{
    80002b90:	1141                	addi	sp,sp,-16
    80002b92:	e406                	sd	ra,8(sp)
    80002b94:	e022                	sd	s0,0(sp)
    80002b96:	0800                	addi	s0,sp,16
  return fork();
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	1f2080e7          	jalr	498(ra) # 80001d8a <fork>
}
    80002ba0:	60a2                	ld	ra,8(sp)
    80002ba2:	6402                	ld	s0,0(sp)
    80002ba4:	0141                	addi	sp,sp,16
    80002ba6:	8082                	ret

0000000080002ba8 <sys_wait>:

uint64
sys_wait(void)
{
    80002ba8:	1101                	addi	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bb0:	fe840593          	addi	a1,s0,-24
    80002bb4:	4501                	li	a0,0
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	ece080e7          	jalr	-306(ra) # 80002a84 <argaddr>
    80002bbe:	87aa                	mv	a5,a0
    return -1;
    80002bc0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bc2:	0007c863          	bltz	a5,80002bd2 <sys_wait+0x2a>
  return wait(p);
    80002bc6:	fe843503          	ld	a0,-24(s0)
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	66e080e7          	jalr	1646(ra) # 80002238 <wait>
}
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	6105                	addi	sp,sp,32
    80002bd8:	8082                	ret

0000000080002bda <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bda:	7179                	addi	sp,sp,-48
    80002bdc:	f406                	sd	ra,40(sp)
    80002bde:	f022                	sd	s0,32(sp)
    80002be0:	ec26                	sd	s1,24(sp)
    80002be2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002be4:	fdc40593          	addi	a1,s0,-36
    80002be8:	4501                	li	a0,0
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	e78080e7          	jalr	-392(ra) # 80002a62 <argint>
    return -1;
    80002bf2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002bf4:	00054f63          	bltz	a0,80002c12 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	dd2080e7          	jalr	-558(ra) # 800019ca <myproc>
    80002c00:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c02:	fdc42503          	lw	a0,-36(s0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	110080e7          	jalr	272(ra) # 80001d16 <growproc>
    80002c0e:	00054863          	bltz	a0,80002c1e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c12:	8526                	mv	a0,s1
    80002c14:	70a2                	ld	ra,40(sp)
    80002c16:	7402                	ld	s0,32(sp)
    80002c18:	64e2                	ld	s1,24(sp)
    80002c1a:	6145                	addi	sp,sp,48
    80002c1c:	8082                	ret
    return -1;
    80002c1e:	54fd                	li	s1,-1
    80002c20:	bfcd                	j	80002c12 <sys_sbrk+0x38>

0000000080002c22 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c22:	7139                	addi	sp,sp,-64
    80002c24:	fc06                	sd	ra,56(sp)
    80002c26:	f822                	sd	s0,48(sp)
    80002c28:	f426                	sd	s1,40(sp)
    80002c2a:	f04a                	sd	s2,32(sp)
    80002c2c:	ec4e                	sd	s3,24(sp)
    80002c2e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c30:	fcc40593          	addi	a1,s0,-52
    80002c34:	4501                	li	a0,0
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	e2c080e7          	jalr	-468(ra) # 80002a62 <argint>
    return -1;
    80002c3e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c40:	06054563          	bltz	a0,80002caa <sys_sleep+0x88>
  acquire(&tickslock);
    80002c44:	00015517          	auipc	a0,0x15
    80002c48:	b2450513          	addi	a0,a0,-1244 # 80017768 <tickslock>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	fb2080e7          	jalr	-78(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002c54:	00006917          	auipc	s2,0x6
    80002c58:	3cc92903          	lw	s2,972(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002c5c:	fcc42783          	lw	a5,-52(s0)
    80002c60:	cf85                	beqz	a5,80002c98 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c62:	00015997          	auipc	s3,0x15
    80002c66:	b0698993          	addi	s3,s3,-1274 # 80017768 <tickslock>
    80002c6a:	00006497          	auipc	s1,0x6
    80002c6e:	3b648493          	addi	s1,s1,950 # 80009020 <ticks>
    if(myproc()->killed){
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d58080e7          	jalr	-680(ra) # 800019ca <myproc>
    80002c7a:	591c                	lw	a5,48(a0)
    80002c7c:	ef9d                	bnez	a5,80002cba <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c7e:	85ce                	mv	a1,s3
    80002c80:	8526                	mv	a0,s1
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	538080e7          	jalr	1336(ra) # 800021ba <sleep>
  while(ticks - ticks0 < n){
    80002c8a:	409c                	lw	a5,0(s1)
    80002c8c:	412787bb          	subw	a5,a5,s2
    80002c90:	fcc42703          	lw	a4,-52(s0)
    80002c94:	fce7efe3          	bltu	a5,a4,80002c72 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c98:	00015517          	auipc	a0,0x15
    80002c9c:	ad050513          	addi	a0,a0,-1328 # 80017768 <tickslock>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	012080e7          	jalr	18(ra) # 80000cb2 <release>
  return 0;
    80002ca8:	4781                	li	a5,0
}
    80002caa:	853e                	mv	a0,a5
    80002cac:	70e2                	ld	ra,56(sp)
    80002cae:	7442                	ld	s0,48(sp)
    80002cb0:	74a2                	ld	s1,40(sp)
    80002cb2:	7902                	ld	s2,32(sp)
    80002cb4:	69e2                	ld	s3,24(sp)
    80002cb6:	6121                	addi	sp,sp,64
    80002cb8:	8082                	ret
      release(&tickslock);
    80002cba:	00015517          	auipc	a0,0x15
    80002cbe:	aae50513          	addi	a0,a0,-1362 # 80017768 <tickslock>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	ff0080e7          	jalr	-16(ra) # 80000cb2 <release>
      return -1;
    80002cca:	57fd                	li	a5,-1
    80002ccc:	bff9                	j	80002caa <sys_sleep+0x88>

0000000080002cce <sys_kill>:

uint64
sys_kill(void)
{
    80002cce:	1101                	addi	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cd6:	fec40593          	addi	a1,s0,-20
    80002cda:	4501                	li	a0,0
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	d86080e7          	jalr	-634(ra) # 80002a62 <argint>
    80002ce4:	87aa                	mv	a5,a0
    return -1;
    80002ce6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ce8:	0007c863          	bltz	a5,80002cf8 <sys_kill+0x2a>
  return kill(pid);
    80002cec:	fec42503          	lw	a0,-20(s0)
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	6b4080e7          	jalr	1716(ra) # 800023a4 <kill>
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	6105                	addi	sp,sp,32
    80002cfe:	8082                	ret

0000000080002d00 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	e426                	sd	s1,8(sp)
    80002d08:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d0a:	00015517          	auipc	a0,0x15
    80002d0e:	a5e50513          	addi	a0,a0,-1442 # 80017768 <tickslock>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	eec080e7          	jalr	-276(ra) # 80000bfe <acquire>
  xticks = ticks;
    80002d1a:	00006497          	auipc	s1,0x6
    80002d1e:	3064a483          	lw	s1,774(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d22:	00015517          	auipc	a0,0x15
    80002d26:	a4650513          	addi	a0,a0,-1466 # 80017768 <tickslock>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	f88080e7          	jalr	-120(ra) # 80000cb2 <release>
  return xticks;
}
    80002d32:	02049513          	slli	a0,s1,0x20
    80002d36:	9101                	srli	a0,a0,0x20
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret

0000000080002d42 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d42:	7179                	addi	sp,sp,-48
    80002d44:	f406                	sd	ra,40(sp)
    80002d46:	f022                	sd	s0,32(sp)
    80002d48:	ec26                	sd	s1,24(sp)
    80002d4a:	e84a                	sd	s2,16(sp)
    80002d4c:	e44e                	sd	s3,8(sp)
    80002d4e:	e052                	sd	s4,0(sp)
    80002d50:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d52:	00005597          	auipc	a1,0x5
    80002d56:	78658593          	addi	a1,a1,1926 # 800084d8 <syscalls+0xb0>
    80002d5a:	00015517          	auipc	a0,0x15
    80002d5e:	a2650513          	addi	a0,a0,-1498 # 80017780 <bcache>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	e0c080e7          	jalr	-500(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d6a:	0001d797          	auipc	a5,0x1d
    80002d6e:	a1678793          	addi	a5,a5,-1514 # 8001f780 <bcache+0x8000>
    80002d72:	0001d717          	auipc	a4,0x1d
    80002d76:	c7670713          	addi	a4,a4,-906 # 8001f9e8 <bcache+0x8268>
    80002d7a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d7e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d82:	00015497          	auipc	s1,0x15
    80002d86:	a1648493          	addi	s1,s1,-1514 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002d8a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d8c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d8e:	00005a17          	auipc	s4,0x5
    80002d92:	752a0a13          	addi	s4,s4,1874 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002d96:	2b893783          	ld	a5,696(s2)
    80002d9a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d9c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002da0:	85d2                	mv	a1,s4
    80002da2:	01048513          	addi	a0,s1,16
    80002da6:	00001097          	auipc	ra,0x1
    80002daa:	4b2080e7          	jalr	1202(ra) # 80004258 <initsleeplock>
    bcache.head.next->prev = b;
    80002dae:	2b893783          	ld	a5,696(s2)
    80002db2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002db4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002db8:	45848493          	addi	s1,s1,1112
    80002dbc:	fd349de3          	bne	s1,s3,80002d96 <binit+0x54>
  }
}
    80002dc0:	70a2                	ld	ra,40(sp)
    80002dc2:	7402                	ld	s0,32(sp)
    80002dc4:	64e2                	ld	s1,24(sp)
    80002dc6:	6942                	ld	s2,16(sp)
    80002dc8:	69a2                	ld	s3,8(sp)
    80002dca:	6a02                	ld	s4,0(sp)
    80002dcc:	6145                	addi	sp,sp,48
    80002dce:	8082                	ret

0000000080002dd0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dd0:	7179                	addi	sp,sp,-48
    80002dd2:	f406                	sd	ra,40(sp)
    80002dd4:	f022                	sd	s0,32(sp)
    80002dd6:	ec26                	sd	s1,24(sp)
    80002dd8:	e84a                	sd	s2,16(sp)
    80002dda:	e44e                	sd	s3,8(sp)
    80002ddc:	1800                	addi	s0,sp,48
    80002dde:	892a                	mv	s2,a0
    80002de0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002de2:	00015517          	auipc	a0,0x15
    80002de6:	99e50513          	addi	a0,a0,-1634 # 80017780 <bcache>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	e14080e7          	jalr	-492(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002df2:	0001d497          	auipc	s1,0x1d
    80002df6:	c464b483          	ld	s1,-954(s1) # 8001fa38 <bcache+0x82b8>
    80002dfa:	0001d797          	auipc	a5,0x1d
    80002dfe:	bee78793          	addi	a5,a5,-1042 # 8001f9e8 <bcache+0x8268>
    80002e02:	02f48f63          	beq	s1,a5,80002e40 <bread+0x70>
    80002e06:	873e                	mv	a4,a5
    80002e08:	a021                	j	80002e10 <bread+0x40>
    80002e0a:	68a4                	ld	s1,80(s1)
    80002e0c:	02e48a63          	beq	s1,a4,80002e40 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e10:	449c                	lw	a5,8(s1)
    80002e12:	ff279ce3          	bne	a5,s2,80002e0a <bread+0x3a>
    80002e16:	44dc                	lw	a5,12(s1)
    80002e18:	ff3799e3          	bne	a5,s3,80002e0a <bread+0x3a>
      b->refcnt++;
    80002e1c:	40bc                	lw	a5,64(s1)
    80002e1e:	2785                	addiw	a5,a5,1
    80002e20:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e22:	00015517          	auipc	a0,0x15
    80002e26:	95e50513          	addi	a0,a0,-1698 # 80017780 <bcache>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	e88080e7          	jalr	-376(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002e32:	01048513          	addi	a0,s1,16
    80002e36:	00001097          	auipc	ra,0x1
    80002e3a:	45c080e7          	jalr	1116(ra) # 80004292 <acquiresleep>
      return b;
    80002e3e:	a8b9                	j	80002e9c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e40:	0001d497          	auipc	s1,0x1d
    80002e44:	bf04b483          	ld	s1,-1040(s1) # 8001fa30 <bcache+0x82b0>
    80002e48:	0001d797          	auipc	a5,0x1d
    80002e4c:	ba078793          	addi	a5,a5,-1120 # 8001f9e8 <bcache+0x8268>
    80002e50:	00f48863          	beq	s1,a5,80002e60 <bread+0x90>
    80002e54:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e56:	40bc                	lw	a5,64(s1)
    80002e58:	cf81                	beqz	a5,80002e70 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e5a:	64a4                	ld	s1,72(s1)
    80002e5c:	fee49de3          	bne	s1,a4,80002e56 <bread+0x86>
  panic("bget: no buffers");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	68850513          	addi	a0,a0,1672 # 800084e8 <syscalls+0xc0>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	6da080e7          	jalr	1754(ra) # 80000542 <panic>
      b->dev = dev;
    80002e70:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e74:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e78:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e7c:	4785                	li	a5,1
    80002e7e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e80:	00015517          	auipc	a0,0x15
    80002e84:	90050513          	addi	a0,a0,-1792 # 80017780 <bcache>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	e2a080e7          	jalr	-470(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002e90:	01048513          	addi	a0,s1,16
    80002e94:	00001097          	auipc	ra,0x1
    80002e98:	3fe080e7          	jalr	1022(ra) # 80004292 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002e9c:	409c                	lw	a5,0(s1)
    80002e9e:	cb89                	beqz	a5,80002eb0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ea0:	8526                	mv	a0,s1
    80002ea2:	70a2                	ld	ra,40(sp)
    80002ea4:	7402                	ld	s0,32(sp)
    80002ea6:	64e2                	ld	s1,24(sp)
    80002ea8:	6942                	ld	s2,16(sp)
    80002eaa:	69a2                	ld	s3,8(sp)
    80002eac:	6145                	addi	sp,sp,48
    80002eae:	8082                	ret
    virtio_disk_rw(b, 0);
    80002eb0:	4581                	li	a1,0
    80002eb2:	8526                	mv	a0,s1
    80002eb4:	00003097          	auipc	ra,0x3
    80002eb8:	f28080e7          	jalr	-216(ra) # 80005ddc <virtio_disk_rw>
    b->valid = 1;
    80002ebc:	4785                	li	a5,1
    80002ebe:	c09c                	sw	a5,0(s1)
  return b;
    80002ec0:	b7c5                	j	80002ea0 <bread+0xd0>

0000000080002ec2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ec2:	1101                	addi	sp,sp,-32
    80002ec4:	ec06                	sd	ra,24(sp)
    80002ec6:	e822                	sd	s0,16(sp)
    80002ec8:	e426                	sd	s1,8(sp)
    80002eca:	1000                	addi	s0,sp,32
    80002ecc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ece:	0541                	addi	a0,a0,16
    80002ed0:	00001097          	auipc	ra,0x1
    80002ed4:	45c080e7          	jalr	1116(ra) # 8000432c <holdingsleep>
    80002ed8:	cd01                	beqz	a0,80002ef0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002eda:	4585                	li	a1,1
    80002edc:	8526                	mv	a0,s1
    80002ede:	00003097          	auipc	ra,0x3
    80002ee2:	efe080e7          	jalr	-258(ra) # 80005ddc <virtio_disk_rw>
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret
    panic("bwrite");
    80002ef0:	00005517          	auipc	a0,0x5
    80002ef4:	61050513          	addi	a0,a0,1552 # 80008500 <syscalls+0xd8>
    80002ef8:	ffffd097          	auipc	ra,0xffffd
    80002efc:	64a080e7          	jalr	1610(ra) # 80000542 <panic>

0000000080002f00 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	e426                	sd	s1,8(sp)
    80002f08:	e04a                	sd	s2,0(sp)
    80002f0a:	1000                	addi	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0e:	01050913          	addi	s2,a0,16
    80002f12:	854a                	mv	a0,s2
    80002f14:	00001097          	auipc	ra,0x1
    80002f18:	418080e7          	jalr	1048(ra) # 8000432c <holdingsleep>
    80002f1c:	c92d                	beqz	a0,80002f8e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f1e:	854a                	mv	a0,s2
    80002f20:	00001097          	auipc	ra,0x1
    80002f24:	3c8080e7          	jalr	968(ra) # 800042e8 <releasesleep>

  acquire(&bcache.lock);
    80002f28:	00015517          	auipc	a0,0x15
    80002f2c:	85850513          	addi	a0,a0,-1960 # 80017780 <bcache>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	cce080e7          	jalr	-818(ra) # 80000bfe <acquire>
  b->refcnt--;
    80002f38:	40bc                	lw	a5,64(s1)
    80002f3a:	37fd                	addiw	a5,a5,-1
    80002f3c:	0007871b          	sext.w	a4,a5
    80002f40:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f42:	eb05                	bnez	a4,80002f72 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f44:	68bc                	ld	a5,80(s1)
    80002f46:	64b8                	ld	a4,72(s1)
    80002f48:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f4a:	64bc                	ld	a5,72(s1)
    80002f4c:	68b8                	ld	a4,80(s1)
    80002f4e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f50:	0001d797          	auipc	a5,0x1d
    80002f54:	83078793          	addi	a5,a5,-2000 # 8001f780 <bcache+0x8000>
    80002f58:	2b87b703          	ld	a4,696(a5)
    80002f5c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f5e:	0001d717          	auipc	a4,0x1d
    80002f62:	a8a70713          	addi	a4,a4,-1398 # 8001f9e8 <bcache+0x8268>
    80002f66:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f68:	2b87b703          	ld	a4,696(a5)
    80002f6c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f6e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f72:	00015517          	auipc	a0,0x15
    80002f76:	80e50513          	addi	a0,a0,-2034 # 80017780 <bcache>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	d38080e7          	jalr	-712(ra) # 80000cb2 <release>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	64a2                	ld	s1,8(sp)
    80002f88:	6902                	ld	s2,0(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret
    panic("brelse");
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	57a50513          	addi	a0,a0,1402 # 80008508 <syscalls+0xe0>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5ac080e7          	jalr	1452(ra) # 80000542 <panic>

0000000080002f9e <bpin>:

void
bpin(struct buf *b) {
    80002f9e:	1101                	addi	sp,sp,-32
    80002fa0:	ec06                	sd	ra,24(sp)
    80002fa2:	e822                	sd	s0,16(sp)
    80002fa4:	e426                	sd	s1,8(sp)
    80002fa6:	1000                	addi	s0,sp,32
    80002fa8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	7d650513          	addi	a0,a0,2006 # 80017780 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	c4c080e7          	jalr	-948(ra) # 80000bfe <acquire>
  b->refcnt++;
    80002fba:	40bc                	lw	a5,64(s1)
    80002fbc:	2785                	addiw	a5,a5,1
    80002fbe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	7c050513          	addi	a0,a0,1984 # 80017780 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	cea080e7          	jalr	-790(ra) # 80000cb2 <release>
}
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	64a2                	ld	s1,8(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <bunpin>:

void
bunpin(struct buf *b) {
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
    80002fe4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	79a50513          	addi	a0,a0,1946 # 80017780 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	c10080e7          	jalr	-1008(ra) # 80000bfe <acquire>
  b->refcnt--;
    80002ff6:	40bc                	lw	a5,64(s1)
    80002ff8:	37fd                	addiw	a5,a5,-1
    80002ffa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	78450513          	addi	a0,a0,1924 # 80017780 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	cae080e7          	jalr	-850(ra) # 80000cb2 <release>
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	e04a                	sd	s2,0(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003024:	00d5d59b          	srliw	a1,a1,0xd
    80003028:	0001d797          	auipc	a5,0x1d
    8000302c:	e347a783          	lw	a5,-460(a5) # 8001fe5c <sb+0x1c>
    80003030:	9dbd                	addw	a1,a1,a5
    80003032:	00000097          	auipc	ra,0x0
    80003036:	d9e080e7          	jalr	-610(ra) # 80002dd0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000303a:	0074f713          	andi	a4,s1,7
    8000303e:	4785                	li	a5,1
    80003040:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003044:	14ce                	slli	s1,s1,0x33
    80003046:	90d9                	srli	s1,s1,0x36
    80003048:	00950733          	add	a4,a0,s1
    8000304c:	05874703          	lbu	a4,88(a4)
    80003050:	00e7f6b3          	and	a3,a5,a4
    80003054:	c69d                	beqz	a3,80003082 <bfree+0x6c>
    80003056:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003058:	94aa                	add	s1,s1,a0
    8000305a:	fff7c793          	not	a5,a5
    8000305e:	8ff9                	and	a5,a5,a4
    80003060:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003064:	00001097          	auipc	ra,0x1
    80003068:	106080e7          	jalr	262(ra) # 8000416a <log_write>
  brelse(bp);
    8000306c:	854a                	mv	a0,s2
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	e92080e7          	jalr	-366(ra) # 80002f00 <brelse>
}
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	64a2                	ld	s1,8(sp)
    8000307c:	6902                	ld	s2,0(sp)
    8000307e:	6105                	addi	sp,sp,32
    80003080:	8082                	ret
    panic("freeing free block");
    80003082:	00005517          	auipc	a0,0x5
    80003086:	48e50513          	addi	a0,a0,1166 # 80008510 <syscalls+0xe8>
    8000308a:	ffffd097          	auipc	ra,0xffffd
    8000308e:	4b8080e7          	jalr	1208(ra) # 80000542 <panic>

0000000080003092 <balloc>:
{
    80003092:	711d                	addi	sp,sp,-96
    80003094:	ec86                	sd	ra,88(sp)
    80003096:	e8a2                	sd	s0,80(sp)
    80003098:	e4a6                	sd	s1,72(sp)
    8000309a:	e0ca                	sd	s2,64(sp)
    8000309c:	fc4e                	sd	s3,56(sp)
    8000309e:	f852                	sd	s4,48(sp)
    800030a0:	f456                	sd	s5,40(sp)
    800030a2:	f05a                	sd	s6,32(sp)
    800030a4:	ec5e                	sd	s7,24(sp)
    800030a6:	e862                	sd	s8,16(sp)
    800030a8:	e466                	sd	s9,8(sp)
    800030aa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ac:	0001d797          	auipc	a5,0x1d
    800030b0:	d987a783          	lw	a5,-616(a5) # 8001fe44 <sb+0x4>
    800030b4:	cbd1                	beqz	a5,80003148 <balloc+0xb6>
    800030b6:	8baa                	mv	s7,a0
    800030b8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030ba:	0001db17          	auipc	s6,0x1d
    800030be:	d86b0b13          	addi	s6,s6,-634 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030c2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030c4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030c6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030c8:	6c89                	lui	s9,0x2
    800030ca:	a831                	j	800030e6 <balloc+0x54>
    brelse(bp);
    800030cc:	854a                	mv	a0,s2
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	e32080e7          	jalr	-462(ra) # 80002f00 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030d6:	015c87bb          	addw	a5,s9,s5
    800030da:	00078a9b          	sext.w	s5,a5
    800030de:	004b2703          	lw	a4,4(s6)
    800030e2:	06eaf363          	bgeu	s5,a4,80003148 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030e6:	41fad79b          	sraiw	a5,s5,0x1f
    800030ea:	0137d79b          	srliw	a5,a5,0x13
    800030ee:	015787bb          	addw	a5,a5,s5
    800030f2:	40d7d79b          	sraiw	a5,a5,0xd
    800030f6:	01cb2583          	lw	a1,28(s6)
    800030fa:	9dbd                	addw	a1,a1,a5
    800030fc:	855e                	mv	a0,s7
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	cd2080e7          	jalr	-814(ra) # 80002dd0 <bread>
    80003106:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003108:	004b2503          	lw	a0,4(s6)
    8000310c:	000a849b          	sext.w	s1,s5
    80003110:	8662                	mv	a2,s8
    80003112:	faa4fde3          	bgeu	s1,a0,800030cc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003116:	41f6579b          	sraiw	a5,a2,0x1f
    8000311a:	01d7d69b          	srliw	a3,a5,0x1d
    8000311e:	00c6873b          	addw	a4,a3,a2
    80003122:	00777793          	andi	a5,a4,7
    80003126:	9f95                	subw	a5,a5,a3
    80003128:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000312c:	4037571b          	sraiw	a4,a4,0x3
    80003130:	00e906b3          	add	a3,s2,a4
    80003134:	0586c683          	lbu	a3,88(a3)
    80003138:	00d7f5b3          	and	a1,a5,a3
    8000313c:	cd91                	beqz	a1,80003158 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313e:	2605                	addiw	a2,a2,1
    80003140:	2485                	addiw	s1,s1,1
    80003142:	fd4618e3          	bne	a2,s4,80003112 <balloc+0x80>
    80003146:	b759                	j	800030cc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	3e050513          	addi	a0,a0,992 # 80008528 <syscalls+0x100>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	3f2080e7          	jalr	1010(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003158:	974a                	add	a4,a4,s2
    8000315a:	8fd5                	or	a5,a5,a3
    8000315c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003160:	854a                	mv	a0,s2
    80003162:	00001097          	auipc	ra,0x1
    80003166:	008080e7          	jalr	8(ra) # 8000416a <log_write>
        brelse(bp);
    8000316a:	854a                	mv	a0,s2
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	d94080e7          	jalr	-620(ra) # 80002f00 <brelse>
  bp = bread(dev, bno);
    80003174:	85a6                	mv	a1,s1
    80003176:	855e                	mv	a0,s7
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	c58080e7          	jalr	-936(ra) # 80002dd0 <bread>
    80003180:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003182:	40000613          	li	a2,1024
    80003186:	4581                	li	a1,0
    80003188:	05850513          	addi	a0,a0,88
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	b6e080e7          	jalr	-1170(ra) # 80000cfa <memset>
  log_write(bp);
    80003194:	854a                	mv	a0,s2
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	fd4080e7          	jalr	-44(ra) # 8000416a <log_write>
  brelse(bp);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	d60080e7          	jalr	-672(ra) # 80002f00 <brelse>
}
    800031a8:	8526                	mv	a0,s1
    800031aa:	60e6                	ld	ra,88(sp)
    800031ac:	6446                	ld	s0,80(sp)
    800031ae:	64a6                	ld	s1,72(sp)
    800031b0:	6906                	ld	s2,64(sp)
    800031b2:	79e2                	ld	s3,56(sp)
    800031b4:	7a42                	ld	s4,48(sp)
    800031b6:	7aa2                	ld	s5,40(sp)
    800031b8:	7b02                	ld	s6,32(sp)
    800031ba:	6be2                	ld	s7,24(sp)
    800031bc:	6c42                	ld	s8,16(sp)
    800031be:	6ca2                	ld	s9,8(sp)
    800031c0:	6125                	addi	sp,sp,96
    800031c2:	8082                	ret

00000000800031c4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031c4:	7179                	addi	sp,sp,-48
    800031c6:	f406                	sd	ra,40(sp)
    800031c8:	f022                	sd	s0,32(sp)
    800031ca:	ec26                	sd	s1,24(sp)
    800031cc:	e84a                	sd	s2,16(sp)
    800031ce:	e44e                	sd	s3,8(sp)
    800031d0:	e052                	sd	s4,0(sp)
    800031d2:	1800                	addi	s0,sp,48
    800031d4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031d6:	47ad                	li	a5,11
    800031d8:	04b7fe63          	bgeu	a5,a1,80003234 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031dc:	ff45849b          	addiw	s1,a1,-12
    800031e0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031e4:	0ff00793          	li	a5,255
    800031e8:	0ae7e463          	bltu	a5,a4,80003290 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031ec:	08052583          	lw	a1,128(a0)
    800031f0:	c5b5                	beqz	a1,8000325c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800031f2:	00092503          	lw	a0,0(s2)
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	bda080e7          	jalr	-1062(ra) # 80002dd0 <bread>
    800031fe:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003200:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003204:	02049713          	slli	a4,s1,0x20
    80003208:	01e75593          	srli	a1,a4,0x1e
    8000320c:	00b784b3          	add	s1,a5,a1
    80003210:	0004a983          	lw	s3,0(s1)
    80003214:	04098e63          	beqz	s3,80003270 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003218:	8552                	mv	a0,s4
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	ce6080e7          	jalr	-794(ra) # 80002f00 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003222:	854e                	mv	a0,s3
    80003224:	70a2                	ld	ra,40(sp)
    80003226:	7402                	ld	s0,32(sp)
    80003228:	64e2                	ld	s1,24(sp)
    8000322a:	6942                	ld	s2,16(sp)
    8000322c:	69a2                	ld	s3,8(sp)
    8000322e:	6a02                	ld	s4,0(sp)
    80003230:	6145                	addi	sp,sp,48
    80003232:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003234:	02059793          	slli	a5,a1,0x20
    80003238:	01e7d593          	srli	a1,a5,0x1e
    8000323c:	00b504b3          	add	s1,a0,a1
    80003240:	0504a983          	lw	s3,80(s1)
    80003244:	fc099fe3          	bnez	s3,80003222 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003248:	4108                	lw	a0,0(a0)
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	e48080e7          	jalr	-440(ra) # 80003092 <balloc>
    80003252:	0005099b          	sext.w	s3,a0
    80003256:	0534a823          	sw	s3,80(s1)
    8000325a:	b7e1                	j	80003222 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000325c:	4108                	lw	a0,0(a0)
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	e34080e7          	jalr	-460(ra) # 80003092 <balloc>
    80003266:	0005059b          	sext.w	a1,a0
    8000326a:	08b92023          	sw	a1,128(s2)
    8000326e:	b751                	j	800031f2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003270:	00092503          	lw	a0,0(s2)
    80003274:	00000097          	auipc	ra,0x0
    80003278:	e1e080e7          	jalr	-482(ra) # 80003092 <balloc>
    8000327c:	0005099b          	sext.w	s3,a0
    80003280:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003284:	8552                	mv	a0,s4
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	ee4080e7          	jalr	-284(ra) # 8000416a <log_write>
    8000328e:	b769                	j	80003218 <bmap+0x54>
  panic("bmap: out of range");
    80003290:	00005517          	auipc	a0,0x5
    80003294:	2b050513          	addi	a0,a0,688 # 80008540 <syscalls+0x118>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2aa080e7          	jalr	682(ra) # 80000542 <panic>

00000000800032a0 <iget>:
{
    800032a0:	7179                	addi	sp,sp,-48
    800032a2:	f406                	sd	ra,40(sp)
    800032a4:	f022                	sd	s0,32(sp)
    800032a6:	ec26                	sd	s1,24(sp)
    800032a8:	e84a                	sd	s2,16(sp)
    800032aa:	e44e                	sd	s3,8(sp)
    800032ac:	e052                	sd	s4,0(sp)
    800032ae:	1800                	addi	s0,sp,48
    800032b0:	89aa                	mv	s3,a0
    800032b2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800032b4:	0001d517          	auipc	a0,0x1d
    800032b8:	bac50513          	addi	a0,a0,-1108 # 8001fe60 <icache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	942080e7          	jalr	-1726(ra) # 80000bfe <acquire>
  empty = 0;
    800032c4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800032c6:	0001d497          	auipc	s1,0x1d
    800032ca:	bb248493          	addi	s1,s1,-1102 # 8001fe78 <icache+0x18>
    800032ce:	0001e697          	auipc	a3,0x1e
    800032d2:	63a68693          	addi	a3,a3,1594 # 80021908 <log>
    800032d6:	a039                	j	800032e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032d8:	02090b63          	beqz	s2,8000330e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800032dc:	08848493          	addi	s1,s1,136
    800032e0:	02d48a63          	beq	s1,a3,80003314 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032e4:	449c                	lw	a5,8(s1)
    800032e6:	fef059e3          	blez	a5,800032d8 <iget+0x38>
    800032ea:	4098                	lw	a4,0(s1)
    800032ec:	ff3716e3          	bne	a4,s3,800032d8 <iget+0x38>
    800032f0:	40d8                	lw	a4,4(s1)
    800032f2:	ff4713e3          	bne	a4,s4,800032d8 <iget+0x38>
      ip->ref++;
    800032f6:	2785                	addiw	a5,a5,1
    800032f8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800032fa:	0001d517          	auipc	a0,0x1d
    800032fe:	b6650513          	addi	a0,a0,-1178 # 8001fe60 <icache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	9b0080e7          	jalr	-1616(ra) # 80000cb2 <release>
      return ip;
    8000330a:	8926                	mv	s2,s1
    8000330c:	a03d                	j	8000333a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000330e:	f7f9                	bnez	a5,800032dc <iget+0x3c>
    80003310:	8926                	mv	s2,s1
    80003312:	b7e9                	j	800032dc <iget+0x3c>
  if(empty == 0)
    80003314:	02090c63          	beqz	s2,8000334c <iget+0xac>
  ip->dev = dev;
    80003318:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000331c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003320:	4785                	li	a5,1
    80003322:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003326:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000332a:	0001d517          	auipc	a0,0x1d
    8000332e:	b3650513          	addi	a0,a0,-1226 # 8001fe60 <icache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	980080e7          	jalr	-1664(ra) # 80000cb2 <release>
}
    8000333a:	854a                	mv	a0,s2
    8000333c:	70a2                	ld	ra,40(sp)
    8000333e:	7402                	ld	s0,32(sp)
    80003340:	64e2                	ld	s1,24(sp)
    80003342:	6942                	ld	s2,16(sp)
    80003344:	69a2                	ld	s3,8(sp)
    80003346:	6a02                	ld	s4,0(sp)
    80003348:	6145                	addi	sp,sp,48
    8000334a:	8082                	ret
    panic("iget: no inodes");
    8000334c:	00005517          	auipc	a0,0x5
    80003350:	20c50513          	addi	a0,a0,524 # 80008558 <syscalls+0x130>
    80003354:	ffffd097          	auipc	ra,0xffffd
    80003358:	1ee080e7          	jalr	494(ra) # 80000542 <panic>

000000008000335c <fsinit>:
fsinit(int dev) {
    8000335c:	7179                	addi	sp,sp,-48
    8000335e:	f406                	sd	ra,40(sp)
    80003360:	f022                	sd	s0,32(sp)
    80003362:	ec26                	sd	s1,24(sp)
    80003364:	e84a                	sd	s2,16(sp)
    80003366:	e44e                	sd	s3,8(sp)
    80003368:	1800                	addi	s0,sp,48
    8000336a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000336c:	4585                	li	a1,1
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	a62080e7          	jalr	-1438(ra) # 80002dd0 <bread>
    80003376:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003378:	0001d997          	auipc	s3,0x1d
    8000337c:	ac898993          	addi	s3,s3,-1336 # 8001fe40 <sb>
    80003380:	02000613          	li	a2,32
    80003384:	05850593          	addi	a1,a0,88
    80003388:	854e                	mv	a0,s3
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	9cc080e7          	jalr	-1588(ra) # 80000d56 <memmove>
  brelse(bp);
    80003392:	8526                	mv	a0,s1
    80003394:	00000097          	auipc	ra,0x0
    80003398:	b6c080e7          	jalr	-1172(ra) # 80002f00 <brelse>
  if(sb.magic != FSMAGIC)
    8000339c:	0009a703          	lw	a4,0(s3)
    800033a0:	102037b7          	lui	a5,0x10203
    800033a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033a8:	02f71263          	bne	a4,a5,800033cc <fsinit+0x70>
  initlog(dev, &sb);
    800033ac:	0001d597          	auipc	a1,0x1d
    800033b0:	a9458593          	addi	a1,a1,-1388 # 8001fe40 <sb>
    800033b4:	854a                	mv	a0,s2
    800033b6:	00001097          	auipc	ra,0x1
    800033ba:	b3a080e7          	jalr	-1222(ra) # 80003ef0 <initlog>
}
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6145                	addi	sp,sp,48
    800033ca:	8082                	ret
    panic("invalid file system");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	19c50513          	addi	a0,a0,412 # 80008568 <syscalls+0x140>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	16e080e7          	jalr	366(ra) # 80000542 <panic>

00000000800033dc <iinit>:
{
    800033dc:	7179                	addi	sp,sp,-48
    800033de:	f406                	sd	ra,40(sp)
    800033e0:	f022                	sd	s0,32(sp)
    800033e2:	ec26                	sd	s1,24(sp)
    800033e4:	e84a                	sd	s2,16(sp)
    800033e6:	e44e                	sd	s3,8(sp)
    800033e8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800033ea:	00005597          	auipc	a1,0x5
    800033ee:	19658593          	addi	a1,a1,406 # 80008580 <syscalls+0x158>
    800033f2:	0001d517          	auipc	a0,0x1d
    800033f6:	a6e50513          	addi	a0,a0,-1426 # 8001fe60 <icache>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	774080e7          	jalr	1908(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003402:	0001d497          	auipc	s1,0x1d
    80003406:	a8648493          	addi	s1,s1,-1402 # 8001fe88 <icache+0x28>
    8000340a:	0001e997          	auipc	s3,0x1e
    8000340e:	50e98993          	addi	s3,s3,1294 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003412:	00005917          	auipc	s2,0x5
    80003416:	17690913          	addi	s2,s2,374 # 80008588 <syscalls+0x160>
    8000341a:	85ca                	mv	a1,s2
    8000341c:	8526                	mv	a0,s1
    8000341e:	00001097          	auipc	ra,0x1
    80003422:	e3a080e7          	jalr	-454(ra) # 80004258 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003426:	08848493          	addi	s1,s1,136
    8000342a:	ff3498e3          	bne	s1,s3,8000341a <iinit+0x3e>
}
    8000342e:	70a2                	ld	ra,40(sp)
    80003430:	7402                	ld	s0,32(sp)
    80003432:	64e2                	ld	s1,24(sp)
    80003434:	6942                	ld	s2,16(sp)
    80003436:	69a2                	ld	s3,8(sp)
    80003438:	6145                	addi	sp,sp,48
    8000343a:	8082                	ret

000000008000343c <ialloc>:
{
    8000343c:	715d                	addi	sp,sp,-80
    8000343e:	e486                	sd	ra,72(sp)
    80003440:	e0a2                	sd	s0,64(sp)
    80003442:	fc26                	sd	s1,56(sp)
    80003444:	f84a                	sd	s2,48(sp)
    80003446:	f44e                	sd	s3,40(sp)
    80003448:	f052                	sd	s4,32(sp)
    8000344a:	ec56                	sd	s5,24(sp)
    8000344c:	e85a                	sd	s6,16(sp)
    8000344e:	e45e                	sd	s7,8(sp)
    80003450:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003452:	0001d717          	auipc	a4,0x1d
    80003456:	9fa72703          	lw	a4,-1542(a4) # 8001fe4c <sb+0xc>
    8000345a:	4785                	li	a5,1
    8000345c:	04e7fa63          	bgeu	a5,a4,800034b0 <ialloc+0x74>
    80003460:	8aaa                	mv	s5,a0
    80003462:	8bae                	mv	s7,a1
    80003464:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003466:	0001da17          	auipc	s4,0x1d
    8000346a:	9daa0a13          	addi	s4,s4,-1574 # 8001fe40 <sb>
    8000346e:	00048b1b          	sext.w	s6,s1
    80003472:	0044d793          	srli	a5,s1,0x4
    80003476:	018a2583          	lw	a1,24(s4)
    8000347a:	9dbd                	addw	a1,a1,a5
    8000347c:	8556                	mv	a0,s5
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	952080e7          	jalr	-1710(ra) # 80002dd0 <bread>
    80003486:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003488:	05850993          	addi	s3,a0,88
    8000348c:	00f4f793          	andi	a5,s1,15
    80003490:	079a                	slli	a5,a5,0x6
    80003492:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003494:	00099783          	lh	a5,0(s3)
    80003498:	c785                	beqz	a5,800034c0 <ialloc+0x84>
    brelse(bp);
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	a66080e7          	jalr	-1434(ra) # 80002f00 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034a2:	0485                	addi	s1,s1,1
    800034a4:	00ca2703          	lw	a4,12(s4)
    800034a8:	0004879b          	sext.w	a5,s1
    800034ac:	fce7e1e3          	bltu	a5,a4,8000346e <ialloc+0x32>
  panic("ialloc: no inodes");
    800034b0:	00005517          	auipc	a0,0x5
    800034b4:	0e050513          	addi	a0,a0,224 # 80008590 <syscalls+0x168>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	08a080e7          	jalr	138(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800034c0:	04000613          	li	a2,64
    800034c4:	4581                	li	a1,0
    800034c6:	854e                	mv	a0,s3
    800034c8:	ffffe097          	auipc	ra,0xffffe
    800034cc:	832080e7          	jalr	-1998(ra) # 80000cfa <memset>
      dip->type = type;
    800034d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034d4:	854a                	mv	a0,s2
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	c94080e7          	jalr	-876(ra) # 8000416a <log_write>
      brelse(bp);
    800034de:	854a                	mv	a0,s2
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a20080e7          	jalr	-1504(ra) # 80002f00 <brelse>
      return iget(dev, inum);
    800034e8:	85da                	mv	a1,s6
    800034ea:	8556                	mv	a0,s5
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	db4080e7          	jalr	-588(ra) # 800032a0 <iget>
}
    800034f4:	60a6                	ld	ra,72(sp)
    800034f6:	6406                	ld	s0,64(sp)
    800034f8:	74e2                	ld	s1,56(sp)
    800034fa:	7942                	ld	s2,48(sp)
    800034fc:	79a2                	ld	s3,40(sp)
    800034fe:	7a02                	ld	s4,32(sp)
    80003500:	6ae2                	ld	s5,24(sp)
    80003502:	6b42                	ld	s6,16(sp)
    80003504:	6ba2                	ld	s7,8(sp)
    80003506:	6161                	addi	sp,sp,80
    80003508:	8082                	ret

000000008000350a <iupdate>:
{
    8000350a:	1101                	addi	sp,sp,-32
    8000350c:	ec06                	sd	ra,24(sp)
    8000350e:	e822                	sd	s0,16(sp)
    80003510:	e426                	sd	s1,8(sp)
    80003512:	e04a                	sd	s2,0(sp)
    80003514:	1000                	addi	s0,sp,32
    80003516:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003518:	415c                	lw	a5,4(a0)
    8000351a:	0047d79b          	srliw	a5,a5,0x4
    8000351e:	0001d597          	auipc	a1,0x1d
    80003522:	93a5a583          	lw	a1,-1734(a1) # 8001fe58 <sb+0x18>
    80003526:	9dbd                	addw	a1,a1,a5
    80003528:	4108                	lw	a0,0(a0)
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	8a6080e7          	jalr	-1882(ra) # 80002dd0 <bread>
    80003532:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003534:	05850793          	addi	a5,a0,88
    80003538:	40c8                	lw	a0,4(s1)
    8000353a:	893d                	andi	a0,a0,15
    8000353c:	051a                	slli	a0,a0,0x6
    8000353e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003540:	04449703          	lh	a4,68(s1)
    80003544:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003548:	04649703          	lh	a4,70(s1)
    8000354c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003550:	04849703          	lh	a4,72(s1)
    80003554:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003558:	04a49703          	lh	a4,74(s1)
    8000355c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003560:	44f8                	lw	a4,76(s1)
    80003562:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003564:	03400613          	li	a2,52
    80003568:	05048593          	addi	a1,s1,80
    8000356c:	0531                	addi	a0,a0,12
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	7e8080e7          	jalr	2024(ra) # 80000d56 <memmove>
  log_write(bp);
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	bf2080e7          	jalr	-1038(ra) # 8000416a <log_write>
  brelse(bp);
    80003580:	854a                	mv	a0,s2
    80003582:	00000097          	auipc	ra,0x0
    80003586:	97e080e7          	jalr	-1666(ra) # 80002f00 <brelse>
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6902                	ld	s2,0(sp)
    80003592:	6105                	addi	sp,sp,32
    80003594:	8082                	ret

0000000080003596 <idup>:
{
    80003596:	1101                	addi	sp,sp,-32
    80003598:	ec06                	sd	ra,24(sp)
    8000359a:	e822                	sd	s0,16(sp)
    8000359c:	e426                	sd	s1,8(sp)
    8000359e:	1000                	addi	s0,sp,32
    800035a0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800035a2:	0001d517          	auipc	a0,0x1d
    800035a6:	8be50513          	addi	a0,a0,-1858 # 8001fe60 <icache>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	654080e7          	jalr	1620(ra) # 80000bfe <acquire>
  ip->ref++;
    800035b2:	449c                	lw	a5,8(s1)
    800035b4:	2785                	addiw	a5,a5,1
    800035b6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800035b8:	0001d517          	auipc	a0,0x1d
    800035bc:	8a850513          	addi	a0,a0,-1880 # 8001fe60 <icache>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	6f2080e7          	jalr	1778(ra) # 80000cb2 <release>
}
    800035c8:	8526                	mv	a0,s1
    800035ca:	60e2                	ld	ra,24(sp)
    800035cc:	6442                	ld	s0,16(sp)
    800035ce:	64a2                	ld	s1,8(sp)
    800035d0:	6105                	addi	sp,sp,32
    800035d2:	8082                	ret

00000000800035d4 <ilock>:
{
    800035d4:	1101                	addi	sp,sp,-32
    800035d6:	ec06                	sd	ra,24(sp)
    800035d8:	e822                	sd	s0,16(sp)
    800035da:	e426                	sd	s1,8(sp)
    800035dc:	e04a                	sd	s2,0(sp)
    800035de:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035e0:	c115                	beqz	a0,80003604 <ilock+0x30>
    800035e2:	84aa                	mv	s1,a0
    800035e4:	451c                	lw	a5,8(a0)
    800035e6:	00f05f63          	blez	a5,80003604 <ilock+0x30>
  acquiresleep(&ip->lock);
    800035ea:	0541                	addi	a0,a0,16
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	ca6080e7          	jalr	-858(ra) # 80004292 <acquiresleep>
  if(ip->valid == 0){
    800035f4:	40bc                	lw	a5,64(s1)
    800035f6:	cf99                	beqz	a5,80003614 <ilock+0x40>
}
    800035f8:	60e2                	ld	ra,24(sp)
    800035fa:	6442                	ld	s0,16(sp)
    800035fc:	64a2                	ld	s1,8(sp)
    800035fe:	6902                	ld	s2,0(sp)
    80003600:	6105                	addi	sp,sp,32
    80003602:	8082                	ret
    panic("ilock");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	fa450513          	addi	a0,a0,-92 # 800085a8 <syscalls+0x180>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f36080e7          	jalr	-202(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003614:	40dc                	lw	a5,4(s1)
    80003616:	0047d79b          	srliw	a5,a5,0x4
    8000361a:	0001d597          	auipc	a1,0x1d
    8000361e:	83e5a583          	lw	a1,-1986(a1) # 8001fe58 <sb+0x18>
    80003622:	9dbd                	addw	a1,a1,a5
    80003624:	4088                	lw	a0,0(s1)
    80003626:	fffff097          	auipc	ra,0xfffff
    8000362a:	7aa080e7          	jalr	1962(ra) # 80002dd0 <bread>
    8000362e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003630:	05850593          	addi	a1,a0,88
    80003634:	40dc                	lw	a5,4(s1)
    80003636:	8bbd                	andi	a5,a5,15
    80003638:	079a                	slli	a5,a5,0x6
    8000363a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000363c:	00059783          	lh	a5,0(a1)
    80003640:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003644:	00259783          	lh	a5,2(a1)
    80003648:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000364c:	00459783          	lh	a5,4(a1)
    80003650:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003654:	00659783          	lh	a5,6(a1)
    80003658:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000365c:	459c                	lw	a5,8(a1)
    8000365e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003660:	03400613          	li	a2,52
    80003664:	05b1                	addi	a1,a1,12
    80003666:	05048513          	addi	a0,s1,80
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	6ec080e7          	jalr	1772(ra) # 80000d56 <memmove>
    brelse(bp);
    80003672:	854a                	mv	a0,s2
    80003674:	00000097          	auipc	ra,0x0
    80003678:	88c080e7          	jalr	-1908(ra) # 80002f00 <brelse>
    ip->valid = 1;
    8000367c:	4785                	li	a5,1
    8000367e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003680:	04449783          	lh	a5,68(s1)
    80003684:	fbb5                	bnez	a5,800035f8 <ilock+0x24>
      panic("ilock: no type");
    80003686:	00005517          	auipc	a0,0x5
    8000368a:	f2a50513          	addi	a0,a0,-214 # 800085b0 <syscalls+0x188>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	eb4080e7          	jalr	-332(ra) # 80000542 <panic>

0000000080003696 <iunlock>:
{
    80003696:	1101                	addi	sp,sp,-32
    80003698:	ec06                	sd	ra,24(sp)
    8000369a:	e822                	sd	s0,16(sp)
    8000369c:	e426                	sd	s1,8(sp)
    8000369e:	e04a                	sd	s2,0(sp)
    800036a0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036a2:	c905                	beqz	a0,800036d2 <iunlock+0x3c>
    800036a4:	84aa                	mv	s1,a0
    800036a6:	01050913          	addi	s2,a0,16
    800036aa:	854a                	mv	a0,s2
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	c80080e7          	jalr	-896(ra) # 8000432c <holdingsleep>
    800036b4:	cd19                	beqz	a0,800036d2 <iunlock+0x3c>
    800036b6:	449c                	lw	a5,8(s1)
    800036b8:	00f05d63          	blez	a5,800036d2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036bc:	854a                	mv	a0,s2
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	c2a080e7          	jalr	-982(ra) # 800042e8 <releasesleep>
}
    800036c6:	60e2                	ld	ra,24(sp)
    800036c8:	6442                	ld	s0,16(sp)
    800036ca:	64a2                	ld	s1,8(sp)
    800036cc:	6902                	ld	s2,0(sp)
    800036ce:	6105                	addi	sp,sp,32
    800036d0:	8082                	ret
    panic("iunlock");
    800036d2:	00005517          	auipc	a0,0x5
    800036d6:	eee50513          	addi	a0,a0,-274 # 800085c0 <syscalls+0x198>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	e68080e7          	jalr	-408(ra) # 80000542 <panic>

00000000800036e2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036e2:	7179                	addi	sp,sp,-48
    800036e4:	f406                	sd	ra,40(sp)
    800036e6:	f022                	sd	s0,32(sp)
    800036e8:	ec26                	sd	s1,24(sp)
    800036ea:	e84a                	sd	s2,16(sp)
    800036ec:	e44e                	sd	s3,8(sp)
    800036ee:	e052                	sd	s4,0(sp)
    800036f0:	1800                	addi	s0,sp,48
    800036f2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036f4:	05050493          	addi	s1,a0,80
    800036f8:	08050913          	addi	s2,a0,128
    800036fc:	a021                	j	80003704 <itrunc+0x22>
    800036fe:	0491                	addi	s1,s1,4
    80003700:	01248d63          	beq	s1,s2,8000371a <itrunc+0x38>
    if(ip->addrs[i]){
    80003704:	408c                	lw	a1,0(s1)
    80003706:	dde5                	beqz	a1,800036fe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003708:	0009a503          	lw	a0,0(s3)
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	90a080e7          	jalr	-1782(ra) # 80003016 <bfree>
      ip->addrs[i] = 0;
    80003714:	0004a023          	sw	zero,0(s1)
    80003718:	b7dd                	j	800036fe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000371a:	0809a583          	lw	a1,128(s3)
    8000371e:	e185                	bnez	a1,8000373e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003720:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003724:	854e                	mv	a0,s3
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	de4080e7          	jalr	-540(ra) # 8000350a <iupdate>
}
    8000372e:	70a2                	ld	ra,40(sp)
    80003730:	7402                	ld	s0,32(sp)
    80003732:	64e2                	ld	s1,24(sp)
    80003734:	6942                	ld	s2,16(sp)
    80003736:	69a2                	ld	s3,8(sp)
    80003738:	6a02                	ld	s4,0(sp)
    8000373a:	6145                	addi	sp,sp,48
    8000373c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000373e:	0009a503          	lw	a0,0(s3)
    80003742:	fffff097          	auipc	ra,0xfffff
    80003746:	68e080e7          	jalr	1678(ra) # 80002dd0 <bread>
    8000374a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000374c:	05850493          	addi	s1,a0,88
    80003750:	45850913          	addi	s2,a0,1112
    80003754:	a021                	j	8000375c <itrunc+0x7a>
    80003756:	0491                	addi	s1,s1,4
    80003758:	01248b63          	beq	s1,s2,8000376e <itrunc+0x8c>
      if(a[j])
    8000375c:	408c                	lw	a1,0(s1)
    8000375e:	dde5                	beqz	a1,80003756 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003760:	0009a503          	lw	a0,0(s3)
    80003764:	00000097          	auipc	ra,0x0
    80003768:	8b2080e7          	jalr	-1870(ra) # 80003016 <bfree>
    8000376c:	b7ed                	j	80003756 <itrunc+0x74>
    brelse(bp);
    8000376e:	8552                	mv	a0,s4
    80003770:	fffff097          	auipc	ra,0xfffff
    80003774:	790080e7          	jalr	1936(ra) # 80002f00 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003778:	0809a583          	lw	a1,128(s3)
    8000377c:	0009a503          	lw	a0,0(s3)
    80003780:	00000097          	auipc	ra,0x0
    80003784:	896080e7          	jalr	-1898(ra) # 80003016 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003788:	0809a023          	sw	zero,128(s3)
    8000378c:	bf51                	j	80003720 <itrunc+0x3e>

000000008000378e <iput>:
{
    8000378e:	1101                	addi	sp,sp,-32
    80003790:	ec06                	sd	ra,24(sp)
    80003792:	e822                	sd	s0,16(sp)
    80003794:	e426                	sd	s1,8(sp)
    80003796:	e04a                	sd	s2,0(sp)
    80003798:	1000                	addi	s0,sp,32
    8000379a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000379c:	0001c517          	auipc	a0,0x1c
    800037a0:	6c450513          	addi	a0,a0,1732 # 8001fe60 <icache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	45a080e7          	jalr	1114(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037ac:	4498                	lw	a4,8(s1)
    800037ae:	4785                	li	a5,1
    800037b0:	02f70363          	beq	a4,a5,800037d6 <iput+0x48>
  ip->ref--;
    800037b4:	449c                	lw	a5,8(s1)
    800037b6:	37fd                	addiw	a5,a5,-1
    800037b8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037ba:	0001c517          	auipc	a0,0x1c
    800037be:	6a650513          	addi	a0,a0,1702 # 8001fe60 <icache>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	4f0080e7          	jalr	1264(ra) # 80000cb2 <release>
}
    800037ca:	60e2                	ld	ra,24(sp)
    800037cc:	6442                	ld	s0,16(sp)
    800037ce:	64a2                	ld	s1,8(sp)
    800037d0:	6902                	ld	s2,0(sp)
    800037d2:	6105                	addi	sp,sp,32
    800037d4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037d6:	40bc                	lw	a5,64(s1)
    800037d8:	dff1                	beqz	a5,800037b4 <iput+0x26>
    800037da:	04a49783          	lh	a5,74(s1)
    800037de:	fbf9                	bnez	a5,800037b4 <iput+0x26>
    acquiresleep(&ip->lock);
    800037e0:	01048913          	addi	s2,s1,16
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	aac080e7          	jalr	-1364(ra) # 80004292 <acquiresleep>
    release(&icache.lock);
    800037ee:	0001c517          	auipc	a0,0x1c
    800037f2:	67250513          	addi	a0,a0,1650 # 8001fe60 <icache>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	4bc080e7          	jalr	1212(ra) # 80000cb2 <release>
    itrunc(ip);
    800037fe:	8526                	mv	a0,s1
    80003800:	00000097          	auipc	ra,0x0
    80003804:	ee2080e7          	jalr	-286(ra) # 800036e2 <itrunc>
    ip->type = 0;
    80003808:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000380c:	8526                	mv	a0,s1
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	cfc080e7          	jalr	-772(ra) # 8000350a <iupdate>
    ip->valid = 0;
    80003816:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	acc080e7          	jalr	-1332(ra) # 800042e8 <releasesleep>
    acquire(&icache.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	63c50513          	addi	a0,a0,1596 # 8001fe60 <icache>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	3d2080e7          	jalr	978(ra) # 80000bfe <acquire>
    80003834:	b741                	j	800037b4 <iput+0x26>

0000000080003836 <iunlockput>:
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	1000                	addi	s0,sp,32
    80003840:	84aa                	mv	s1,a0
  iunlock(ip);
    80003842:	00000097          	auipc	ra,0x0
    80003846:	e54080e7          	jalr	-428(ra) # 80003696 <iunlock>
  iput(ip);
    8000384a:	8526                	mv	a0,s1
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	f42080e7          	jalr	-190(ra) # 8000378e <iput>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret

000000008000385e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000385e:	1141                	addi	sp,sp,-16
    80003860:	e422                	sd	s0,8(sp)
    80003862:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003864:	411c                	lw	a5,0(a0)
    80003866:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003868:	415c                	lw	a5,4(a0)
    8000386a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000386c:	04451783          	lh	a5,68(a0)
    80003870:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003874:	04a51783          	lh	a5,74(a0)
    80003878:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000387c:	04c56783          	lwu	a5,76(a0)
    80003880:	e99c                	sd	a5,16(a1)
}
    80003882:	6422                	ld	s0,8(sp)
    80003884:	0141                	addi	sp,sp,16
    80003886:	8082                	ret

0000000080003888 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003888:	457c                	lw	a5,76(a0)
    8000388a:	0ed7e863          	bltu	a5,a3,8000397a <readi+0xf2>
{
    8000388e:	7159                	addi	sp,sp,-112
    80003890:	f486                	sd	ra,104(sp)
    80003892:	f0a2                	sd	s0,96(sp)
    80003894:	eca6                	sd	s1,88(sp)
    80003896:	e8ca                	sd	s2,80(sp)
    80003898:	e4ce                	sd	s3,72(sp)
    8000389a:	e0d2                	sd	s4,64(sp)
    8000389c:	fc56                	sd	s5,56(sp)
    8000389e:	f85a                	sd	s6,48(sp)
    800038a0:	f45e                	sd	s7,40(sp)
    800038a2:	f062                	sd	s8,32(sp)
    800038a4:	ec66                	sd	s9,24(sp)
    800038a6:	e86a                	sd	s10,16(sp)
    800038a8:	e46e                	sd	s11,8(sp)
    800038aa:	1880                	addi	s0,sp,112
    800038ac:	8baa                	mv	s7,a0
    800038ae:	8c2e                	mv	s8,a1
    800038b0:	8ab2                	mv	s5,a2
    800038b2:	84b6                	mv	s1,a3
    800038b4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038b6:	9f35                	addw	a4,a4,a3
    return 0;
    800038b8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038ba:	08d76f63          	bltu	a4,a3,80003958 <readi+0xd0>
  if(off + n > ip->size)
    800038be:	00e7f463          	bgeu	a5,a4,800038c6 <readi+0x3e>
    n = ip->size - off;
    800038c2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038c6:	0a0b0863          	beqz	s6,80003976 <readi+0xee>
    800038ca:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038cc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038d0:	5cfd                	li	s9,-1
    800038d2:	a82d                	j	8000390c <readi+0x84>
    800038d4:	020a1d93          	slli	s11,s4,0x20
    800038d8:	020ddd93          	srli	s11,s11,0x20
    800038dc:	05890793          	addi	a5,s2,88
    800038e0:	86ee                	mv	a3,s11
    800038e2:	963e                	add	a2,a2,a5
    800038e4:	85d6                	mv	a1,s5
    800038e6:	8562                	mv	a0,s8
    800038e8:	fffff097          	auipc	ra,0xfffff
    800038ec:	b2c080e7          	jalr	-1236(ra) # 80002414 <either_copyout>
    800038f0:	05950d63          	beq	a0,s9,8000394a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800038f4:	854a                	mv	a0,s2
    800038f6:	fffff097          	auipc	ra,0xfffff
    800038fa:	60a080e7          	jalr	1546(ra) # 80002f00 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038fe:	013a09bb          	addw	s3,s4,s3
    80003902:	009a04bb          	addw	s1,s4,s1
    80003906:	9aee                	add	s5,s5,s11
    80003908:	0569f663          	bgeu	s3,s6,80003954 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000390c:	000ba903          	lw	s2,0(s7)
    80003910:	00a4d59b          	srliw	a1,s1,0xa
    80003914:	855e                	mv	a0,s7
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	8ae080e7          	jalr	-1874(ra) # 800031c4 <bmap>
    8000391e:	0005059b          	sext.w	a1,a0
    80003922:	854a                	mv	a0,s2
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	4ac080e7          	jalr	1196(ra) # 80002dd0 <bread>
    8000392c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000392e:	3ff4f613          	andi	a2,s1,1023
    80003932:	40cd07bb          	subw	a5,s10,a2
    80003936:	413b073b          	subw	a4,s6,s3
    8000393a:	8a3e                	mv	s4,a5
    8000393c:	2781                	sext.w	a5,a5
    8000393e:	0007069b          	sext.w	a3,a4
    80003942:	f8f6f9e3          	bgeu	a3,a5,800038d4 <readi+0x4c>
    80003946:	8a3a                	mv	s4,a4
    80003948:	b771                	j	800038d4 <readi+0x4c>
      brelse(bp);
    8000394a:	854a                	mv	a0,s2
    8000394c:	fffff097          	auipc	ra,0xfffff
    80003950:	5b4080e7          	jalr	1460(ra) # 80002f00 <brelse>
  }
  return tot;
    80003954:	0009851b          	sext.w	a0,s3
}
    80003958:	70a6                	ld	ra,104(sp)
    8000395a:	7406                	ld	s0,96(sp)
    8000395c:	64e6                	ld	s1,88(sp)
    8000395e:	6946                	ld	s2,80(sp)
    80003960:	69a6                	ld	s3,72(sp)
    80003962:	6a06                	ld	s4,64(sp)
    80003964:	7ae2                	ld	s5,56(sp)
    80003966:	7b42                	ld	s6,48(sp)
    80003968:	7ba2                	ld	s7,40(sp)
    8000396a:	7c02                	ld	s8,32(sp)
    8000396c:	6ce2                	ld	s9,24(sp)
    8000396e:	6d42                	ld	s10,16(sp)
    80003970:	6da2                	ld	s11,8(sp)
    80003972:	6165                	addi	sp,sp,112
    80003974:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003976:	89da                	mv	s3,s6
    80003978:	bff1                	j	80003954 <readi+0xcc>
    return 0;
    8000397a:	4501                	li	a0,0
}
    8000397c:	8082                	ret

000000008000397e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000397e:	457c                	lw	a5,76(a0)
    80003980:	10d7e663          	bltu	a5,a3,80003a8c <writei+0x10e>
{
    80003984:	7159                	addi	sp,sp,-112
    80003986:	f486                	sd	ra,104(sp)
    80003988:	f0a2                	sd	s0,96(sp)
    8000398a:	eca6                	sd	s1,88(sp)
    8000398c:	e8ca                	sd	s2,80(sp)
    8000398e:	e4ce                	sd	s3,72(sp)
    80003990:	e0d2                	sd	s4,64(sp)
    80003992:	fc56                	sd	s5,56(sp)
    80003994:	f85a                	sd	s6,48(sp)
    80003996:	f45e                	sd	s7,40(sp)
    80003998:	f062                	sd	s8,32(sp)
    8000399a:	ec66                	sd	s9,24(sp)
    8000399c:	e86a                	sd	s10,16(sp)
    8000399e:	e46e                	sd	s11,8(sp)
    800039a0:	1880                	addi	s0,sp,112
    800039a2:	8baa                	mv	s7,a0
    800039a4:	8c2e                	mv	s8,a1
    800039a6:	8ab2                	mv	s5,a2
    800039a8:	8936                	mv	s2,a3
    800039aa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ac:	00e687bb          	addw	a5,a3,a4
    800039b0:	0ed7e063          	bltu	a5,a3,80003a90 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039b4:	00043737          	lui	a4,0x43
    800039b8:	0cf76e63          	bltu	a4,a5,80003a94 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039bc:	0a0b0763          	beqz	s6,80003a6a <writei+0xec>
    800039c0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039c6:	5cfd                	li	s9,-1
    800039c8:	a091                	j	80003a0c <writei+0x8e>
    800039ca:	02099d93          	slli	s11,s3,0x20
    800039ce:	020ddd93          	srli	s11,s11,0x20
    800039d2:	05848793          	addi	a5,s1,88
    800039d6:	86ee                	mv	a3,s11
    800039d8:	8656                	mv	a2,s5
    800039da:	85e2                	mv	a1,s8
    800039dc:	953e                	add	a0,a0,a5
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	a8c080e7          	jalr	-1396(ra) # 8000246a <either_copyin>
    800039e6:	07950263          	beq	a0,s9,80003a4a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039ea:	8526                	mv	a0,s1
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	77e080e7          	jalr	1918(ra) # 8000416a <log_write>
    brelse(bp);
    800039f4:	8526                	mv	a0,s1
    800039f6:	fffff097          	auipc	ra,0xfffff
    800039fa:	50a080e7          	jalr	1290(ra) # 80002f00 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039fe:	01498a3b          	addw	s4,s3,s4
    80003a02:	0129893b          	addw	s2,s3,s2
    80003a06:	9aee                	add	s5,s5,s11
    80003a08:	056a7663          	bgeu	s4,s6,80003a54 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a0c:	000ba483          	lw	s1,0(s7)
    80003a10:	00a9559b          	srliw	a1,s2,0xa
    80003a14:	855e                	mv	a0,s7
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	7ae080e7          	jalr	1966(ra) # 800031c4 <bmap>
    80003a1e:	0005059b          	sext.w	a1,a0
    80003a22:	8526                	mv	a0,s1
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	3ac080e7          	jalr	940(ra) # 80002dd0 <bread>
    80003a2c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a2e:	3ff97513          	andi	a0,s2,1023
    80003a32:	40ad07bb          	subw	a5,s10,a0
    80003a36:	414b073b          	subw	a4,s6,s4
    80003a3a:	89be                	mv	s3,a5
    80003a3c:	2781                	sext.w	a5,a5
    80003a3e:	0007069b          	sext.w	a3,a4
    80003a42:	f8f6f4e3          	bgeu	a3,a5,800039ca <writei+0x4c>
    80003a46:	89ba                	mv	s3,a4
    80003a48:	b749                	j	800039ca <writei+0x4c>
      brelse(bp);
    80003a4a:	8526                	mv	a0,s1
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	4b4080e7          	jalr	1204(ra) # 80002f00 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003a54:	04cba783          	lw	a5,76(s7)
    80003a58:	0127f463          	bgeu	a5,s2,80003a60 <writei+0xe2>
      ip->size = off;
    80003a5c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003a60:	855e                	mv	a0,s7
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	aa8080e7          	jalr	-1368(ra) # 8000350a <iupdate>
  }

  return n;
    80003a6a:	000b051b          	sext.w	a0,s6
}
    80003a6e:	70a6                	ld	ra,104(sp)
    80003a70:	7406                	ld	s0,96(sp)
    80003a72:	64e6                	ld	s1,88(sp)
    80003a74:	6946                	ld	s2,80(sp)
    80003a76:	69a6                	ld	s3,72(sp)
    80003a78:	6a06                	ld	s4,64(sp)
    80003a7a:	7ae2                	ld	s5,56(sp)
    80003a7c:	7b42                	ld	s6,48(sp)
    80003a7e:	7ba2                	ld	s7,40(sp)
    80003a80:	7c02                	ld	s8,32(sp)
    80003a82:	6ce2                	ld	s9,24(sp)
    80003a84:	6d42                	ld	s10,16(sp)
    80003a86:	6da2                	ld	s11,8(sp)
    80003a88:	6165                	addi	sp,sp,112
    80003a8a:	8082                	ret
    return -1;
    80003a8c:	557d                	li	a0,-1
}
    80003a8e:	8082                	ret
    return -1;
    80003a90:	557d                	li	a0,-1
    80003a92:	bff1                	j	80003a6e <writei+0xf0>
    return -1;
    80003a94:	557d                	li	a0,-1
    80003a96:	bfe1                	j	80003a6e <writei+0xf0>

0000000080003a98 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003a98:	1141                	addi	sp,sp,-16
    80003a9a:	e406                	sd	ra,8(sp)
    80003a9c:	e022                	sd	s0,0(sp)
    80003a9e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003aa0:	4639                	li	a2,14
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	330080e7          	jalr	816(ra) # 80000dd2 <strncmp>
}
    80003aaa:	60a2                	ld	ra,8(sp)
    80003aac:	6402                	ld	s0,0(sp)
    80003aae:	0141                	addi	sp,sp,16
    80003ab0:	8082                	ret

0000000080003ab2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ab2:	7139                	addi	sp,sp,-64
    80003ab4:	fc06                	sd	ra,56(sp)
    80003ab6:	f822                	sd	s0,48(sp)
    80003ab8:	f426                	sd	s1,40(sp)
    80003aba:	f04a                	sd	s2,32(sp)
    80003abc:	ec4e                	sd	s3,24(sp)
    80003abe:	e852                	sd	s4,16(sp)
    80003ac0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ac2:	04451703          	lh	a4,68(a0)
    80003ac6:	4785                	li	a5,1
    80003ac8:	00f71a63          	bne	a4,a5,80003adc <dirlookup+0x2a>
    80003acc:	892a                	mv	s2,a0
    80003ace:	89ae                	mv	s3,a1
    80003ad0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ad2:	457c                	lw	a5,76(a0)
    80003ad4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ad6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ad8:	e79d                	bnez	a5,80003b06 <dirlookup+0x54>
    80003ada:	a8a5                	j	80003b52 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003adc:	00005517          	auipc	a0,0x5
    80003ae0:	aec50513          	addi	a0,a0,-1300 # 800085c8 <syscalls+0x1a0>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	a5e080e7          	jalr	-1442(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003aec:	00005517          	auipc	a0,0x5
    80003af0:	af450513          	addi	a0,a0,-1292 # 800085e0 <syscalls+0x1b8>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	a4e080e7          	jalr	-1458(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003afc:	24c1                	addiw	s1,s1,16
    80003afe:	04c92783          	lw	a5,76(s2)
    80003b02:	04f4f763          	bgeu	s1,a5,80003b50 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b06:	4741                	li	a4,16
    80003b08:	86a6                	mv	a3,s1
    80003b0a:	fc040613          	addi	a2,s0,-64
    80003b0e:	4581                	li	a1,0
    80003b10:	854a                	mv	a0,s2
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	d76080e7          	jalr	-650(ra) # 80003888 <readi>
    80003b1a:	47c1                	li	a5,16
    80003b1c:	fcf518e3          	bne	a0,a5,80003aec <dirlookup+0x3a>
    if(de.inum == 0)
    80003b20:	fc045783          	lhu	a5,-64(s0)
    80003b24:	dfe1                	beqz	a5,80003afc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b26:	fc240593          	addi	a1,s0,-62
    80003b2a:	854e                	mv	a0,s3
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	f6c080e7          	jalr	-148(ra) # 80003a98 <namecmp>
    80003b34:	f561                	bnez	a0,80003afc <dirlookup+0x4a>
      if(poff)
    80003b36:	000a0463          	beqz	s4,80003b3e <dirlookup+0x8c>
        *poff = off;
    80003b3a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b3e:	fc045583          	lhu	a1,-64(s0)
    80003b42:	00092503          	lw	a0,0(s2)
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	75a080e7          	jalr	1882(ra) # 800032a0 <iget>
    80003b4e:	a011                	j	80003b52 <dirlookup+0xa0>
  return 0;
    80003b50:	4501                	li	a0,0
}
    80003b52:	70e2                	ld	ra,56(sp)
    80003b54:	7442                	ld	s0,48(sp)
    80003b56:	74a2                	ld	s1,40(sp)
    80003b58:	7902                	ld	s2,32(sp)
    80003b5a:	69e2                	ld	s3,24(sp)
    80003b5c:	6a42                	ld	s4,16(sp)
    80003b5e:	6121                	addi	sp,sp,64
    80003b60:	8082                	ret

0000000080003b62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b62:	711d                	addi	sp,sp,-96
    80003b64:	ec86                	sd	ra,88(sp)
    80003b66:	e8a2                	sd	s0,80(sp)
    80003b68:	e4a6                	sd	s1,72(sp)
    80003b6a:	e0ca                	sd	s2,64(sp)
    80003b6c:	fc4e                	sd	s3,56(sp)
    80003b6e:	f852                	sd	s4,48(sp)
    80003b70:	f456                	sd	s5,40(sp)
    80003b72:	f05a                	sd	s6,32(sp)
    80003b74:	ec5e                	sd	s7,24(sp)
    80003b76:	e862                	sd	s8,16(sp)
    80003b78:	e466                	sd	s9,8(sp)
    80003b7a:	1080                	addi	s0,sp,96
    80003b7c:	84aa                	mv	s1,a0
    80003b7e:	8aae                	mv	s5,a1
    80003b80:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b82:	00054703          	lbu	a4,0(a0)
    80003b86:	02f00793          	li	a5,47
    80003b8a:	02f70363          	beq	a4,a5,80003bb0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b8e:	ffffe097          	auipc	ra,0xffffe
    80003b92:	e3c080e7          	jalr	-452(ra) # 800019ca <myproc>
    80003b96:	15053503          	ld	a0,336(a0)
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	9fc080e7          	jalr	-1540(ra) # 80003596 <idup>
    80003ba2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ba4:	02f00913          	li	s2,47
  len = path - s;
    80003ba8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003baa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bac:	4b85                	li	s7,1
    80003bae:	a865                	j	80003c66 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bb0:	4585                	li	a1,1
    80003bb2:	4505                	li	a0,1
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	6ec080e7          	jalr	1772(ra) # 800032a0 <iget>
    80003bbc:	89aa                	mv	s3,a0
    80003bbe:	b7dd                	j	80003ba4 <namex+0x42>
      iunlockput(ip);
    80003bc0:	854e                	mv	a0,s3
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	c74080e7          	jalr	-908(ra) # 80003836 <iunlockput>
      return 0;
    80003bca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bcc:	854e                	mv	a0,s3
    80003bce:	60e6                	ld	ra,88(sp)
    80003bd0:	6446                	ld	s0,80(sp)
    80003bd2:	64a6                	ld	s1,72(sp)
    80003bd4:	6906                	ld	s2,64(sp)
    80003bd6:	79e2                	ld	s3,56(sp)
    80003bd8:	7a42                	ld	s4,48(sp)
    80003bda:	7aa2                	ld	s5,40(sp)
    80003bdc:	7b02                	ld	s6,32(sp)
    80003bde:	6be2                	ld	s7,24(sp)
    80003be0:	6c42                	ld	s8,16(sp)
    80003be2:	6ca2                	ld	s9,8(sp)
    80003be4:	6125                	addi	sp,sp,96
    80003be6:	8082                	ret
      iunlock(ip);
    80003be8:	854e                	mv	a0,s3
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	aac080e7          	jalr	-1364(ra) # 80003696 <iunlock>
      return ip;
    80003bf2:	bfe9                	j	80003bcc <namex+0x6a>
      iunlockput(ip);
    80003bf4:	854e                	mv	a0,s3
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	c40080e7          	jalr	-960(ra) # 80003836 <iunlockput>
      return 0;
    80003bfe:	89e6                	mv	s3,s9
    80003c00:	b7f1                	j	80003bcc <namex+0x6a>
  len = path - s;
    80003c02:	40b48633          	sub	a2,s1,a1
    80003c06:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c0a:	099c5463          	bge	s8,s9,80003c92 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c0e:	4639                	li	a2,14
    80003c10:	8552                	mv	a0,s4
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	144080e7          	jalr	324(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003c1a:	0004c783          	lbu	a5,0(s1)
    80003c1e:	01279763          	bne	a5,s2,80003c2c <namex+0xca>
    path++;
    80003c22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c24:	0004c783          	lbu	a5,0(s1)
    80003c28:	ff278de3          	beq	a5,s2,80003c22 <namex+0xc0>
    ilock(ip);
    80003c2c:	854e                	mv	a0,s3
    80003c2e:	00000097          	auipc	ra,0x0
    80003c32:	9a6080e7          	jalr	-1626(ra) # 800035d4 <ilock>
    if(ip->type != T_DIR){
    80003c36:	04499783          	lh	a5,68(s3)
    80003c3a:	f97793e3          	bne	a5,s7,80003bc0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c3e:	000a8563          	beqz	s5,80003c48 <namex+0xe6>
    80003c42:	0004c783          	lbu	a5,0(s1)
    80003c46:	d3cd                	beqz	a5,80003be8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c48:	865a                	mv	a2,s6
    80003c4a:	85d2                	mv	a1,s4
    80003c4c:	854e                	mv	a0,s3
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	e64080e7          	jalr	-412(ra) # 80003ab2 <dirlookup>
    80003c56:	8caa                	mv	s9,a0
    80003c58:	dd51                	beqz	a0,80003bf4 <namex+0x92>
    iunlockput(ip);
    80003c5a:	854e                	mv	a0,s3
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	bda080e7          	jalr	-1062(ra) # 80003836 <iunlockput>
    ip = next;
    80003c64:	89e6                	mv	s3,s9
  while(*path == '/')
    80003c66:	0004c783          	lbu	a5,0(s1)
    80003c6a:	05279763          	bne	a5,s2,80003cb8 <namex+0x156>
    path++;
    80003c6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c70:	0004c783          	lbu	a5,0(s1)
    80003c74:	ff278de3          	beq	a5,s2,80003c6e <namex+0x10c>
  if(*path == 0)
    80003c78:	c79d                	beqz	a5,80003ca6 <namex+0x144>
    path++;
    80003c7a:	85a6                	mv	a1,s1
  len = path - s;
    80003c7c:	8cda                	mv	s9,s6
    80003c7e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003c80:	01278963          	beq	a5,s2,80003c92 <namex+0x130>
    80003c84:	dfbd                	beqz	a5,80003c02 <namex+0xa0>
    path++;
    80003c86:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003c88:	0004c783          	lbu	a5,0(s1)
    80003c8c:	ff279ce3          	bne	a5,s2,80003c84 <namex+0x122>
    80003c90:	bf8d                	j	80003c02 <namex+0xa0>
    memmove(name, s, len);
    80003c92:	2601                	sext.w	a2,a2
    80003c94:	8552                	mv	a0,s4
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	0c0080e7          	jalr	192(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003c9e:	9cd2                	add	s9,s9,s4
    80003ca0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ca4:	bf9d                	j	80003c1a <namex+0xb8>
  if(nameiparent){
    80003ca6:	f20a83e3          	beqz	s5,80003bcc <namex+0x6a>
    iput(ip);
    80003caa:	854e                	mv	a0,s3
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	ae2080e7          	jalr	-1310(ra) # 8000378e <iput>
    return 0;
    80003cb4:	4981                	li	s3,0
    80003cb6:	bf19                	j	80003bcc <namex+0x6a>
  if(*path == 0)
    80003cb8:	d7fd                	beqz	a5,80003ca6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cba:	0004c783          	lbu	a5,0(s1)
    80003cbe:	85a6                	mv	a1,s1
    80003cc0:	b7d1                	j	80003c84 <namex+0x122>

0000000080003cc2 <dirlink>:
{
    80003cc2:	7139                	addi	sp,sp,-64
    80003cc4:	fc06                	sd	ra,56(sp)
    80003cc6:	f822                	sd	s0,48(sp)
    80003cc8:	f426                	sd	s1,40(sp)
    80003cca:	f04a                	sd	s2,32(sp)
    80003ccc:	ec4e                	sd	s3,24(sp)
    80003cce:	e852                	sd	s4,16(sp)
    80003cd0:	0080                	addi	s0,sp,64
    80003cd2:	892a                	mv	s2,a0
    80003cd4:	8a2e                	mv	s4,a1
    80003cd6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cd8:	4601                	li	a2,0
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	dd8080e7          	jalr	-552(ra) # 80003ab2 <dirlookup>
    80003ce2:	e93d                	bnez	a0,80003d58 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	04c92483          	lw	s1,76(s2)
    80003ce8:	c49d                	beqz	s1,80003d16 <dirlink+0x54>
    80003cea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cec:	4741                	li	a4,16
    80003cee:	86a6                	mv	a3,s1
    80003cf0:	fc040613          	addi	a2,s0,-64
    80003cf4:	4581                	li	a1,0
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	b90080e7          	jalr	-1136(ra) # 80003888 <readi>
    80003d00:	47c1                	li	a5,16
    80003d02:	06f51163          	bne	a0,a5,80003d64 <dirlink+0xa2>
    if(de.inum == 0)
    80003d06:	fc045783          	lhu	a5,-64(s0)
    80003d0a:	c791                	beqz	a5,80003d16 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0c:	24c1                	addiw	s1,s1,16
    80003d0e:	04c92783          	lw	a5,76(s2)
    80003d12:	fcf4ede3          	bltu	s1,a5,80003cec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d16:	4639                	li	a2,14
    80003d18:	85d2                	mv	a1,s4
    80003d1a:	fc240513          	addi	a0,s0,-62
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	0f0080e7          	jalr	240(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80003d26:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2a:	4741                	li	a4,16
    80003d2c:	86a6                	mv	a3,s1
    80003d2e:	fc040613          	addi	a2,s0,-64
    80003d32:	4581                	li	a1,0
    80003d34:	854a                	mv	a0,s2
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	c48080e7          	jalr	-952(ra) # 8000397e <writei>
    80003d3e:	872a                	mv	a4,a0
    80003d40:	47c1                	li	a5,16
  return 0;
    80003d42:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d44:	02f71863          	bne	a4,a5,80003d74 <dirlink+0xb2>
}
    80003d48:	70e2                	ld	ra,56(sp)
    80003d4a:	7442                	ld	s0,48(sp)
    80003d4c:	74a2                	ld	s1,40(sp)
    80003d4e:	7902                	ld	s2,32(sp)
    80003d50:	69e2                	ld	s3,24(sp)
    80003d52:	6a42                	ld	s4,16(sp)
    80003d54:	6121                	addi	sp,sp,64
    80003d56:	8082                	ret
    iput(ip);
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	a36080e7          	jalr	-1482(ra) # 8000378e <iput>
    return -1;
    80003d60:	557d                	li	a0,-1
    80003d62:	b7dd                	j	80003d48 <dirlink+0x86>
      panic("dirlink read");
    80003d64:	00005517          	auipc	a0,0x5
    80003d68:	88c50513          	addi	a0,a0,-1908 # 800085f0 <syscalls+0x1c8>
    80003d6c:	ffffc097          	auipc	ra,0xffffc
    80003d70:	7d6080e7          	jalr	2006(ra) # 80000542 <panic>
    panic("dirlink");
    80003d74:	00005517          	auipc	a0,0x5
    80003d78:	99c50513          	addi	a0,a0,-1636 # 80008710 <syscalls+0x2e8>
    80003d7c:	ffffc097          	auipc	ra,0xffffc
    80003d80:	7c6080e7          	jalr	1990(ra) # 80000542 <panic>

0000000080003d84 <namei>:

struct inode*
namei(char *path)
{
    80003d84:	1101                	addi	sp,sp,-32
    80003d86:	ec06                	sd	ra,24(sp)
    80003d88:	e822                	sd	s0,16(sp)
    80003d8a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d8c:	fe040613          	addi	a2,s0,-32
    80003d90:	4581                	li	a1,0
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	dd0080e7          	jalr	-560(ra) # 80003b62 <namex>
}
    80003d9a:	60e2                	ld	ra,24(sp)
    80003d9c:	6442                	ld	s0,16(sp)
    80003d9e:	6105                	addi	sp,sp,32
    80003da0:	8082                	ret

0000000080003da2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003da2:	1141                	addi	sp,sp,-16
    80003da4:	e406                	sd	ra,8(sp)
    80003da6:	e022                	sd	s0,0(sp)
    80003da8:	0800                	addi	s0,sp,16
    80003daa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dac:	4585                	li	a1,1
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	db4080e7          	jalr	-588(ra) # 80003b62 <namex>
}
    80003db6:	60a2                	ld	ra,8(sp)
    80003db8:	6402                	ld	s0,0(sp)
    80003dba:	0141                	addi	sp,sp,16
    80003dbc:	8082                	ret

0000000080003dbe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dbe:	1101                	addi	sp,sp,-32
    80003dc0:	ec06                	sd	ra,24(sp)
    80003dc2:	e822                	sd	s0,16(sp)
    80003dc4:	e426                	sd	s1,8(sp)
    80003dc6:	e04a                	sd	s2,0(sp)
    80003dc8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dca:	0001e917          	auipc	s2,0x1e
    80003dce:	b3e90913          	addi	s2,s2,-1218 # 80021908 <log>
    80003dd2:	01892583          	lw	a1,24(s2)
    80003dd6:	02892503          	lw	a0,40(s2)
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	ff6080e7          	jalr	-10(ra) # 80002dd0 <bread>
    80003de2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003de4:	02c92683          	lw	a3,44(s2)
    80003de8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003dea:	02d05863          	blez	a3,80003e1a <write_head+0x5c>
    80003dee:	0001e797          	auipc	a5,0x1e
    80003df2:	b4a78793          	addi	a5,a5,-1206 # 80021938 <log+0x30>
    80003df6:	05c50713          	addi	a4,a0,92
    80003dfa:	36fd                	addiw	a3,a3,-1
    80003dfc:	02069613          	slli	a2,a3,0x20
    80003e00:	01e65693          	srli	a3,a2,0x1e
    80003e04:	0001e617          	auipc	a2,0x1e
    80003e08:	b3860613          	addi	a2,a2,-1224 # 8002193c <log+0x34>
    80003e0c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e0e:	4390                	lw	a2,0(a5)
    80003e10:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e12:	0791                	addi	a5,a5,4
    80003e14:	0711                	addi	a4,a4,4
    80003e16:	fed79ce3          	bne	a5,a3,80003e0e <write_head+0x50>
  }
  bwrite(buf);
    80003e1a:	8526                	mv	a0,s1
    80003e1c:	fffff097          	auipc	ra,0xfffff
    80003e20:	0a6080e7          	jalr	166(ra) # 80002ec2 <bwrite>
  brelse(buf);
    80003e24:	8526                	mv	a0,s1
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	0da080e7          	jalr	218(ra) # 80002f00 <brelse>
}
    80003e2e:	60e2                	ld	ra,24(sp)
    80003e30:	6442                	ld	s0,16(sp)
    80003e32:	64a2                	ld	s1,8(sp)
    80003e34:	6902                	ld	s2,0(sp)
    80003e36:	6105                	addi	sp,sp,32
    80003e38:	8082                	ret

0000000080003e3a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e3a:	0001e797          	auipc	a5,0x1e
    80003e3e:	afa7a783          	lw	a5,-1286(a5) # 80021934 <log+0x2c>
    80003e42:	0af05663          	blez	a5,80003eee <install_trans+0xb4>
{
    80003e46:	7139                	addi	sp,sp,-64
    80003e48:	fc06                	sd	ra,56(sp)
    80003e4a:	f822                	sd	s0,48(sp)
    80003e4c:	f426                	sd	s1,40(sp)
    80003e4e:	f04a                	sd	s2,32(sp)
    80003e50:	ec4e                	sd	s3,24(sp)
    80003e52:	e852                	sd	s4,16(sp)
    80003e54:	e456                	sd	s5,8(sp)
    80003e56:	0080                	addi	s0,sp,64
    80003e58:	0001ea97          	auipc	s5,0x1e
    80003e5c:	ae0a8a93          	addi	s5,s5,-1312 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e60:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e62:	0001e997          	auipc	s3,0x1e
    80003e66:	aa698993          	addi	s3,s3,-1370 # 80021908 <log>
    80003e6a:	0189a583          	lw	a1,24(s3)
    80003e6e:	014585bb          	addw	a1,a1,s4
    80003e72:	2585                	addiw	a1,a1,1
    80003e74:	0289a503          	lw	a0,40(s3)
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	f58080e7          	jalr	-168(ra) # 80002dd0 <bread>
    80003e80:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003e82:	000aa583          	lw	a1,0(s5)
    80003e86:	0289a503          	lw	a0,40(s3)
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	f46080e7          	jalr	-186(ra) # 80002dd0 <bread>
    80003e92:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003e94:	40000613          	li	a2,1024
    80003e98:	05890593          	addi	a1,s2,88
    80003e9c:	05850513          	addi	a0,a0,88
    80003ea0:	ffffd097          	auipc	ra,0xffffd
    80003ea4:	eb6080e7          	jalr	-330(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	018080e7          	jalr	24(ra) # 80002ec2 <bwrite>
    bunpin(dbuf);
    80003eb2:	8526                	mv	a0,s1
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	126080e7          	jalr	294(ra) # 80002fda <bunpin>
    brelse(lbuf);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	042080e7          	jalr	66(ra) # 80002f00 <brelse>
    brelse(dbuf);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	038080e7          	jalr	56(ra) # 80002f00 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ed0:	2a05                	addiw	s4,s4,1
    80003ed2:	0a91                	addi	s5,s5,4
    80003ed4:	02c9a783          	lw	a5,44(s3)
    80003ed8:	f8fa49e3          	blt	s4,a5,80003e6a <install_trans+0x30>
}
    80003edc:	70e2                	ld	ra,56(sp)
    80003ede:	7442                	ld	s0,48(sp)
    80003ee0:	74a2                	ld	s1,40(sp)
    80003ee2:	7902                	ld	s2,32(sp)
    80003ee4:	69e2                	ld	s3,24(sp)
    80003ee6:	6a42                	ld	s4,16(sp)
    80003ee8:	6aa2                	ld	s5,8(sp)
    80003eea:	6121                	addi	sp,sp,64
    80003eec:	8082                	ret
    80003eee:	8082                	ret

0000000080003ef0 <initlog>:
{
    80003ef0:	7179                	addi	sp,sp,-48
    80003ef2:	f406                	sd	ra,40(sp)
    80003ef4:	f022                	sd	s0,32(sp)
    80003ef6:	ec26                	sd	s1,24(sp)
    80003ef8:	e84a                	sd	s2,16(sp)
    80003efa:	e44e                	sd	s3,8(sp)
    80003efc:	1800                	addi	s0,sp,48
    80003efe:	892a                	mv	s2,a0
    80003f00:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f02:	0001e497          	auipc	s1,0x1e
    80003f06:	a0648493          	addi	s1,s1,-1530 # 80021908 <log>
    80003f0a:	00004597          	auipc	a1,0x4
    80003f0e:	6f658593          	addi	a1,a1,1782 # 80008600 <syscalls+0x1d8>
    80003f12:	8526                	mv	a0,s1
    80003f14:	ffffd097          	auipc	ra,0xffffd
    80003f18:	c5a080e7          	jalr	-934(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80003f1c:	0149a583          	lw	a1,20(s3)
    80003f20:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f22:	0109a783          	lw	a5,16(s3)
    80003f26:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f28:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f2c:	854a                	mv	a0,s2
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	ea2080e7          	jalr	-350(ra) # 80002dd0 <bread>
  log.lh.n = lh->n;
    80003f36:	4d34                	lw	a3,88(a0)
    80003f38:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f3a:	02d05663          	blez	a3,80003f66 <initlog+0x76>
    80003f3e:	05c50793          	addi	a5,a0,92
    80003f42:	0001e717          	auipc	a4,0x1e
    80003f46:	9f670713          	addi	a4,a4,-1546 # 80021938 <log+0x30>
    80003f4a:	36fd                	addiw	a3,a3,-1
    80003f4c:	02069613          	slli	a2,a3,0x20
    80003f50:	01e65693          	srli	a3,a2,0x1e
    80003f54:	06050613          	addi	a2,a0,96
    80003f58:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f5a:	4390                	lw	a2,0(a5)
    80003f5c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f5e:	0791                	addi	a5,a5,4
    80003f60:	0711                	addi	a4,a4,4
    80003f62:	fed79ce3          	bne	a5,a3,80003f5a <initlog+0x6a>
  brelse(buf);
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	f9a080e7          	jalr	-102(ra) # 80002f00 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	ecc080e7          	jalr	-308(ra) # 80003e3a <install_trans>
  log.lh.n = 0;
    80003f76:	0001e797          	auipc	a5,0x1e
    80003f7a:	9a07af23          	sw	zero,-1602(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	e40080e7          	jalr	-448(ra) # 80003dbe <write_head>
}
    80003f86:	70a2                	ld	ra,40(sp)
    80003f88:	7402                	ld	s0,32(sp)
    80003f8a:	64e2                	ld	s1,24(sp)
    80003f8c:	6942                	ld	s2,16(sp)
    80003f8e:	69a2                	ld	s3,8(sp)
    80003f90:	6145                	addi	sp,sp,48
    80003f92:	8082                	ret

0000000080003f94 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f94:	1101                	addi	sp,sp,-32
    80003f96:	ec06                	sd	ra,24(sp)
    80003f98:	e822                	sd	s0,16(sp)
    80003f9a:	e426                	sd	s1,8(sp)
    80003f9c:	e04a                	sd	s2,0(sp)
    80003f9e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fa0:	0001e517          	auipc	a0,0x1e
    80003fa4:	96850513          	addi	a0,a0,-1688 # 80021908 <log>
    80003fa8:	ffffd097          	auipc	ra,0xffffd
    80003fac:	c56080e7          	jalr	-938(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    80003fb0:	0001e497          	auipc	s1,0x1e
    80003fb4:	95848493          	addi	s1,s1,-1704 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fb8:	4979                	li	s2,30
    80003fba:	a039                	j	80003fc8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fbc:	85a6                	mv	a1,s1
    80003fbe:	8526                	mv	a0,s1
    80003fc0:	ffffe097          	auipc	ra,0xffffe
    80003fc4:	1fa080e7          	jalr	506(ra) # 800021ba <sleep>
    if(log.committing){
    80003fc8:	50dc                	lw	a5,36(s1)
    80003fca:	fbed                	bnez	a5,80003fbc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fcc:	509c                	lw	a5,32(s1)
    80003fce:	0017871b          	addiw	a4,a5,1
    80003fd2:	0007069b          	sext.w	a3,a4
    80003fd6:	0027179b          	slliw	a5,a4,0x2
    80003fda:	9fb9                	addw	a5,a5,a4
    80003fdc:	0017979b          	slliw	a5,a5,0x1
    80003fe0:	54d8                	lw	a4,44(s1)
    80003fe2:	9fb9                	addw	a5,a5,a4
    80003fe4:	00f95963          	bge	s2,a5,80003ff6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003fe8:	85a6                	mv	a1,s1
    80003fea:	8526                	mv	a0,s1
    80003fec:	ffffe097          	auipc	ra,0xffffe
    80003ff0:	1ce080e7          	jalr	462(ra) # 800021ba <sleep>
    80003ff4:	bfd1                	j	80003fc8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80003ff6:	0001e517          	auipc	a0,0x1e
    80003ffa:	91250513          	addi	a0,a0,-1774 # 80021908 <log>
    80003ffe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004000:	ffffd097          	auipc	ra,0xffffd
    80004004:	cb2080e7          	jalr	-846(ra) # 80000cb2 <release>
      break;
    }
  }
}
    80004008:	60e2                	ld	ra,24(sp)
    8000400a:	6442                	ld	s0,16(sp)
    8000400c:	64a2                	ld	s1,8(sp)
    8000400e:	6902                	ld	s2,0(sp)
    80004010:	6105                	addi	sp,sp,32
    80004012:	8082                	ret

0000000080004014 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004014:	7139                	addi	sp,sp,-64
    80004016:	fc06                	sd	ra,56(sp)
    80004018:	f822                	sd	s0,48(sp)
    8000401a:	f426                	sd	s1,40(sp)
    8000401c:	f04a                	sd	s2,32(sp)
    8000401e:	ec4e                	sd	s3,24(sp)
    80004020:	e852                	sd	s4,16(sp)
    80004022:	e456                	sd	s5,8(sp)
    80004024:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004026:	0001e497          	auipc	s1,0x1e
    8000402a:	8e248493          	addi	s1,s1,-1822 # 80021908 <log>
    8000402e:	8526                	mv	a0,s1
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	bce080e7          	jalr	-1074(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    80004038:	509c                	lw	a5,32(s1)
    8000403a:	37fd                	addiw	a5,a5,-1
    8000403c:	0007891b          	sext.w	s2,a5
    80004040:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004042:	50dc                	lw	a5,36(s1)
    80004044:	e7b9                	bnez	a5,80004092 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004046:	04091e63          	bnez	s2,800040a2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000404a:	0001e497          	auipc	s1,0x1e
    8000404e:	8be48493          	addi	s1,s1,-1858 # 80021908 <log>
    80004052:	4785                	li	a5,1
    80004054:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004056:	8526                	mv	a0,s1
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	c5a080e7          	jalr	-934(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004060:	54dc                	lw	a5,44(s1)
    80004062:	06f04763          	bgtz	a5,800040d0 <end_op+0xbc>
    acquire(&log.lock);
    80004066:	0001e497          	auipc	s1,0x1e
    8000406a:	8a248493          	addi	s1,s1,-1886 # 80021908 <log>
    8000406e:	8526                	mv	a0,s1
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	b8e080e7          	jalr	-1138(ra) # 80000bfe <acquire>
    log.committing = 0;
    80004078:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000407c:	8526                	mv	a0,s1
    8000407e:	ffffe097          	auipc	ra,0xffffe
    80004082:	2bc080e7          	jalr	700(ra) # 8000233a <wakeup>
    release(&log.lock);
    80004086:	8526                	mv	a0,s1
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	c2a080e7          	jalr	-982(ra) # 80000cb2 <release>
}
    80004090:	a03d                	j	800040be <end_op+0xaa>
    panic("log.committing");
    80004092:	00004517          	auipc	a0,0x4
    80004096:	57650513          	addi	a0,a0,1398 # 80008608 <syscalls+0x1e0>
    8000409a:	ffffc097          	auipc	ra,0xffffc
    8000409e:	4a8080e7          	jalr	1192(ra) # 80000542 <panic>
    wakeup(&log);
    800040a2:	0001e497          	auipc	s1,0x1e
    800040a6:	86648493          	addi	s1,s1,-1946 # 80021908 <log>
    800040aa:	8526                	mv	a0,s1
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	28e080e7          	jalr	654(ra) # 8000233a <wakeup>
  release(&log.lock);
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	bfc080e7          	jalr	-1028(ra) # 80000cb2 <release>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6121                	addi	sp,sp,64
    800040ce:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d0:	0001ea97          	auipc	s5,0x1e
    800040d4:	868a8a93          	addi	s5,s5,-1944 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040d8:	0001ea17          	auipc	s4,0x1e
    800040dc:	830a0a13          	addi	s4,s4,-2000 # 80021908 <log>
    800040e0:	018a2583          	lw	a1,24(s4)
    800040e4:	012585bb          	addw	a1,a1,s2
    800040e8:	2585                	addiw	a1,a1,1
    800040ea:	028a2503          	lw	a0,40(s4)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	ce2080e7          	jalr	-798(ra) # 80002dd0 <bread>
    800040f6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800040f8:	000aa583          	lw	a1,0(s5)
    800040fc:	028a2503          	lw	a0,40(s4)
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	cd0080e7          	jalr	-816(ra) # 80002dd0 <bread>
    80004108:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000410a:	40000613          	li	a2,1024
    8000410e:	05850593          	addi	a1,a0,88
    80004112:	05848513          	addi	a0,s1,88
    80004116:	ffffd097          	auipc	ra,0xffffd
    8000411a:	c40080e7          	jalr	-960(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    8000411e:	8526                	mv	a0,s1
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	da2080e7          	jalr	-606(ra) # 80002ec2 <bwrite>
    brelse(from);
    80004128:	854e                	mv	a0,s3
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	dd6080e7          	jalr	-554(ra) # 80002f00 <brelse>
    brelse(to);
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	dcc080e7          	jalr	-564(ra) # 80002f00 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413c:	2905                	addiw	s2,s2,1
    8000413e:	0a91                	addi	s5,s5,4
    80004140:	02ca2783          	lw	a5,44(s4)
    80004144:	f8f94ee3          	blt	s2,a5,800040e0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	c76080e7          	jalr	-906(ra) # 80003dbe <write_head>
    install_trans(); // Now install writes to home locations
    80004150:	00000097          	auipc	ra,0x0
    80004154:	cea080e7          	jalr	-790(ra) # 80003e3a <install_trans>
    log.lh.n = 0;
    80004158:	0001d797          	auipc	a5,0x1d
    8000415c:	7c07ae23          	sw	zero,2012(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004160:	00000097          	auipc	ra,0x0
    80004164:	c5e080e7          	jalr	-930(ra) # 80003dbe <write_head>
    80004168:	bdfd                	j	80004066 <end_op+0x52>

000000008000416a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004176:	0001d717          	auipc	a4,0x1d
    8000417a:	7be72703          	lw	a4,1982(a4) # 80021934 <log+0x2c>
    8000417e:	47f5                	li	a5,29
    80004180:	08e7c063          	blt	a5,a4,80004200 <log_write+0x96>
    80004184:	84aa                	mv	s1,a0
    80004186:	0001d797          	auipc	a5,0x1d
    8000418a:	79e7a783          	lw	a5,1950(a5) # 80021924 <log+0x1c>
    8000418e:	37fd                	addiw	a5,a5,-1
    80004190:	06f75863          	bge	a4,a5,80004200 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004194:	0001d797          	auipc	a5,0x1d
    80004198:	7947a783          	lw	a5,1940(a5) # 80021928 <log+0x20>
    8000419c:	06f05a63          	blez	a5,80004210 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800041a0:	0001d917          	auipc	s2,0x1d
    800041a4:	76890913          	addi	s2,s2,1896 # 80021908 <log>
    800041a8:	854a                	mv	a0,s2
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	a54080e7          	jalr	-1452(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800041b2:	02c92603          	lw	a2,44(s2)
    800041b6:	06c05563          	blez	a2,80004220 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041ba:	44cc                	lw	a1,12(s1)
    800041bc:	0001d717          	auipc	a4,0x1d
    800041c0:	77c70713          	addi	a4,a4,1916 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041c4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041c6:	4314                	lw	a3,0(a4)
    800041c8:	04b68d63          	beq	a3,a1,80004222 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800041cc:	2785                	addiw	a5,a5,1
    800041ce:	0711                	addi	a4,a4,4
    800041d0:	fec79be3          	bne	a5,a2,800041c6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041d4:	0621                	addi	a2,a2,8
    800041d6:	060a                	slli	a2,a2,0x2
    800041d8:	0001d797          	auipc	a5,0x1d
    800041dc:	73078793          	addi	a5,a5,1840 # 80021908 <log>
    800041e0:	963e                	add	a2,a2,a5
    800041e2:	44dc                	lw	a5,12(s1)
    800041e4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800041e6:	8526                	mv	a0,s1
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	db6080e7          	jalr	-586(ra) # 80002f9e <bpin>
    log.lh.n++;
    800041f0:	0001d717          	auipc	a4,0x1d
    800041f4:	71870713          	addi	a4,a4,1816 # 80021908 <log>
    800041f8:	575c                	lw	a5,44(a4)
    800041fa:	2785                	addiw	a5,a5,1
    800041fc:	d75c                	sw	a5,44(a4)
    800041fe:	a83d                	j	8000423c <log_write+0xd2>
    panic("too big a transaction");
    80004200:	00004517          	auipc	a0,0x4
    80004204:	41850513          	addi	a0,a0,1048 # 80008618 <syscalls+0x1f0>
    80004208:	ffffc097          	auipc	ra,0xffffc
    8000420c:	33a080e7          	jalr	826(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004210:	00004517          	auipc	a0,0x4
    80004214:	42050513          	addi	a0,a0,1056 # 80008630 <syscalls+0x208>
    80004218:	ffffc097          	auipc	ra,0xffffc
    8000421c:	32a080e7          	jalr	810(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004220:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004222:	00878713          	addi	a4,a5,8
    80004226:	00271693          	slli	a3,a4,0x2
    8000422a:	0001d717          	auipc	a4,0x1d
    8000422e:	6de70713          	addi	a4,a4,1758 # 80021908 <log>
    80004232:	9736                	add	a4,a4,a3
    80004234:	44d4                	lw	a3,12(s1)
    80004236:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004238:	faf607e3          	beq	a2,a5,800041e6 <log_write+0x7c>
  }
  release(&log.lock);
    8000423c:	0001d517          	auipc	a0,0x1d
    80004240:	6cc50513          	addi	a0,a0,1740 # 80021908 <log>
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	a6e080e7          	jalr	-1426(ra) # 80000cb2 <release>
}
    8000424c:	60e2                	ld	ra,24(sp)
    8000424e:	6442                	ld	s0,16(sp)
    80004250:	64a2                	ld	s1,8(sp)
    80004252:	6902                	ld	s2,0(sp)
    80004254:	6105                	addi	sp,sp,32
    80004256:	8082                	ret

0000000080004258 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004258:	1101                	addi	sp,sp,-32
    8000425a:	ec06                	sd	ra,24(sp)
    8000425c:	e822                	sd	s0,16(sp)
    8000425e:	e426                	sd	s1,8(sp)
    80004260:	e04a                	sd	s2,0(sp)
    80004262:	1000                	addi	s0,sp,32
    80004264:	84aa                	mv	s1,a0
    80004266:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004268:	00004597          	auipc	a1,0x4
    8000426c:	3e858593          	addi	a1,a1,1000 # 80008650 <syscalls+0x228>
    80004270:	0521                	addi	a0,a0,8
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	8fc080e7          	jalr	-1796(ra) # 80000b6e <initlock>
  lk->name = name;
    8000427a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000427e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004282:	0204a423          	sw	zero,40(s1)
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004292:	1101                	addi	sp,sp,-32
    80004294:	ec06                	sd	ra,24(sp)
    80004296:	e822                	sd	s0,16(sp)
    80004298:	e426                	sd	s1,8(sp)
    8000429a:	e04a                	sd	s2,0(sp)
    8000429c:	1000                	addi	s0,sp,32
    8000429e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042a0:	00850913          	addi	s2,a0,8
    800042a4:	854a                	mv	a0,s2
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	958080e7          	jalr	-1704(ra) # 80000bfe <acquire>
  while (lk->locked) {
    800042ae:	409c                	lw	a5,0(s1)
    800042b0:	cb89                	beqz	a5,800042c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042b2:	85ca                	mv	a1,s2
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	f04080e7          	jalr	-252(ra) # 800021ba <sleep>
  while (lk->locked) {
    800042be:	409c                	lw	a5,0(s1)
    800042c0:	fbed                	bnez	a5,800042b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042c2:	4785                	li	a5,1
    800042c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	704080e7          	jalr	1796(ra) # 800019ca <myproc>
    800042ce:	5d1c                	lw	a5,56(a0)
    800042d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042d2:	854a                	mv	a0,s2
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9de080e7          	jalr	-1570(ra) # 80000cb2 <release>
}
    800042dc:	60e2                	ld	ra,24(sp)
    800042de:	6442                	ld	s0,16(sp)
    800042e0:	64a2                	ld	s1,8(sp)
    800042e2:	6902                	ld	s2,0(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042e8:	1101                	addi	sp,sp,-32
    800042ea:	ec06                	sd	ra,24(sp)
    800042ec:	e822                	sd	s0,16(sp)
    800042ee:	e426                	sd	s1,8(sp)
    800042f0:	e04a                	sd	s2,0(sp)
    800042f2:	1000                	addi	s0,sp,32
    800042f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042f6:	00850913          	addi	s2,a0,8
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	902080e7          	jalr	-1790(ra) # 80000bfe <acquire>
  lk->locked = 0;
    80004304:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004308:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000430c:	8526                	mv	a0,s1
    8000430e:	ffffe097          	auipc	ra,0xffffe
    80004312:	02c080e7          	jalr	44(ra) # 8000233a <wakeup>
  release(&lk->lk);
    80004316:	854a                	mv	a0,s2
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	99a080e7          	jalr	-1638(ra) # 80000cb2 <release>
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	addi	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000432c:	7179                	addi	sp,sp,-48
    8000432e:	f406                	sd	ra,40(sp)
    80004330:	f022                	sd	s0,32(sp)
    80004332:	ec26                	sd	s1,24(sp)
    80004334:	e84a                	sd	s2,16(sp)
    80004336:	e44e                	sd	s3,8(sp)
    80004338:	1800                	addi	s0,sp,48
    8000433a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000433c:	00850913          	addi	s2,a0,8
    80004340:	854a                	mv	a0,s2
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	8bc080e7          	jalr	-1860(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000434a:	409c                	lw	a5,0(s1)
    8000434c:	ef99                	bnez	a5,8000436a <holdingsleep+0x3e>
    8000434e:	4481                	li	s1,0
  release(&lk->lk);
    80004350:	854a                	mv	a0,s2
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	960080e7          	jalr	-1696(ra) # 80000cb2 <release>
  return r;
}
    8000435a:	8526                	mv	a0,s1
    8000435c:	70a2                	ld	ra,40(sp)
    8000435e:	7402                	ld	s0,32(sp)
    80004360:	64e2                	ld	s1,24(sp)
    80004362:	6942                	ld	s2,16(sp)
    80004364:	69a2                	ld	s3,8(sp)
    80004366:	6145                	addi	sp,sp,48
    80004368:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000436a:	0284a983          	lw	s3,40(s1)
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	65c080e7          	jalr	1628(ra) # 800019ca <myproc>
    80004376:	5d04                	lw	s1,56(a0)
    80004378:	413484b3          	sub	s1,s1,s3
    8000437c:	0014b493          	seqz	s1,s1
    80004380:	bfc1                	j	80004350 <holdingsleep+0x24>

0000000080004382 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004382:	1141                	addi	sp,sp,-16
    80004384:	e406                	sd	ra,8(sp)
    80004386:	e022                	sd	s0,0(sp)
    80004388:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000438a:	00004597          	auipc	a1,0x4
    8000438e:	2d658593          	addi	a1,a1,726 # 80008660 <syscalls+0x238>
    80004392:	0001d517          	auipc	a0,0x1d
    80004396:	6be50513          	addi	a0,a0,1726 # 80021a50 <ftable>
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	7d4080e7          	jalr	2004(ra) # 80000b6e <initlock>
}
    800043a2:	60a2                	ld	ra,8(sp)
    800043a4:	6402                	ld	s0,0(sp)
    800043a6:	0141                	addi	sp,sp,16
    800043a8:	8082                	ret

00000000800043aa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043aa:	1101                	addi	sp,sp,-32
    800043ac:	ec06                	sd	ra,24(sp)
    800043ae:	e822                	sd	s0,16(sp)
    800043b0:	e426                	sd	s1,8(sp)
    800043b2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	69c50513          	addi	a0,a0,1692 # 80021a50 <ftable>
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	842080e7          	jalr	-1982(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043c4:	0001d497          	auipc	s1,0x1d
    800043c8:	6a448493          	addi	s1,s1,1700 # 80021a68 <ftable+0x18>
    800043cc:	0001e717          	auipc	a4,0x1e
    800043d0:	63c70713          	addi	a4,a4,1596 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800043d4:	40dc                	lw	a5,4(s1)
    800043d6:	cf99                	beqz	a5,800043f4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043d8:	02848493          	addi	s1,s1,40
    800043dc:	fee49ce3          	bne	s1,a4,800043d4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043e0:	0001d517          	auipc	a0,0x1d
    800043e4:	67050513          	addi	a0,a0,1648 # 80021a50 <ftable>
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	8ca080e7          	jalr	-1846(ra) # 80000cb2 <release>
  return 0;
    800043f0:	4481                	li	s1,0
    800043f2:	a819                	j	80004408 <filealloc+0x5e>
      f->ref = 1;
    800043f4:	4785                	li	a5,1
    800043f6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800043f8:	0001d517          	auipc	a0,0x1d
    800043fc:	65850513          	addi	a0,a0,1624 # 80021a50 <ftable>
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	8b2080e7          	jalr	-1870(ra) # 80000cb2 <release>
}
    80004408:	8526                	mv	a0,s1
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	64a2                	ld	s1,8(sp)
    80004410:	6105                	addi	sp,sp,32
    80004412:	8082                	ret

0000000080004414 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004414:	1101                	addi	sp,sp,-32
    80004416:	ec06                	sd	ra,24(sp)
    80004418:	e822                	sd	s0,16(sp)
    8000441a:	e426                	sd	s1,8(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004420:	0001d517          	auipc	a0,0x1d
    80004424:	63050513          	addi	a0,a0,1584 # 80021a50 <ftable>
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	7d6080e7          	jalr	2006(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004430:	40dc                	lw	a5,4(s1)
    80004432:	02f05263          	blez	a5,80004456 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004436:	2785                	addiw	a5,a5,1
    80004438:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000443a:	0001d517          	auipc	a0,0x1d
    8000443e:	61650513          	addi	a0,a0,1558 # 80021a50 <ftable>
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	870080e7          	jalr	-1936(ra) # 80000cb2 <release>
  return f;
}
    8000444a:	8526                	mv	a0,s1
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6105                	addi	sp,sp,32
    80004454:	8082                	ret
    panic("filedup");
    80004456:	00004517          	auipc	a0,0x4
    8000445a:	21250513          	addi	a0,a0,530 # 80008668 <syscalls+0x240>
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	0e4080e7          	jalr	228(ra) # 80000542 <panic>

0000000080004466 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004466:	7139                	addi	sp,sp,-64
    80004468:	fc06                	sd	ra,56(sp)
    8000446a:	f822                	sd	s0,48(sp)
    8000446c:	f426                	sd	s1,40(sp)
    8000446e:	f04a                	sd	s2,32(sp)
    80004470:	ec4e                	sd	s3,24(sp)
    80004472:	e852                	sd	s4,16(sp)
    80004474:	e456                	sd	s5,8(sp)
    80004476:	0080                	addi	s0,sp,64
    80004478:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000447a:	0001d517          	auipc	a0,0x1d
    8000447e:	5d650513          	addi	a0,a0,1494 # 80021a50 <ftable>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	77c080e7          	jalr	1916(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    8000448a:	40dc                	lw	a5,4(s1)
    8000448c:	06f05163          	blez	a5,800044ee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004490:	37fd                	addiw	a5,a5,-1
    80004492:	0007871b          	sext.w	a4,a5
    80004496:	c0dc                	sw	a5,4(s1)
    80004498:	06e04363          	bgtz	a4,800044fe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000449c:	0004a903          	lw	s2,0(s1)
    800044a0:	0094ca83          	lbu	s5,9(s1)
    800044a4:	0104ba03          	ld	s4,16(s1)
    800044a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044b4:	0001d517          	auipc	a0,0x1d
    800044b8:	59c50513          	addi	a0,a0,1436 # 80021a50 <ftable>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7f6080e7          	jalr	2038(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    800044c4:	4785                	li	a5,1
    800044c6:	04f90d63          	beq	s2,a5,80004520 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044ca:	3979                	addiw	s2,s2,-2
    800044cc:	4785                	li	a5,1
    800044ce:	0527e063          	bltu	a5,s2,8000450e <fileclose+0xa8>
    begin_op();
    800044d2:	00000097          	auipc	ra,0x0
    800044d6:	ac2080e7          	jalr	-1342(ra) # 80003f94 <begin_op>
    iput(ff.ip);
    800044da:	854e                	mv	a0,s3
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	2b2080e7          	jalr	690(ra) # 8000378e <iput>
    end_op();
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	b30080e7          	jalr	-1232(ra) # 80004014 <end_op>
    800044ec:	a00d                	j	8000450e <fileclose+0xa8>
    panic("fileclose");
    800044ee:	00004517          	auipc	a0,0x4
    800044f2:	18250513          	addi	a0,a0,386 # 80008670 <syscalls+0x248>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	04c080e7          	jalr	76(ra) # 80000542 <panic>
    release(&ftable.lock);
    800044fe:	0001d517          	auipc	a0,0x1d
    80004502:	55250513          	addi	a0,a0,1362 # 80021a50 <ftable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	7ac080e7          	jalr	1964(ra) # 80000cb2 <release>
  }
}
    8000450e:	70e2                	ld	ra,56(sp)
    80004510:	7442                	ld	s0,48(sp)
    80004512:	74a2                	ld	s1,40(sp)
    80004514:	7902                	ld	s2,32(sp)
    80004516:	69e2                	ld	s3,24(sp)
    80004518:	6a42                	ld	s4,16(sp)
    8000451a:	6aa2                	ld	s5,8(sp)
    8000451c:	6121                	addi	sp,sp,64
    8000451e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004520:	85d6                	mv	a1,s5
    80004522:	8552                	mv	a0,s4
    80004524:	00000097          	auipc	ra,0x0
    80004528:	372080e7          	jalr	882(ra) # 80004896 <pipeclose>
    8000452c:	b7cd                	j	8000450e <fileclose+0xa8>

000000008000452e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000452e:	715d                	addi	sp,sp,-80
    80004530:	e486                	sd	ra,72(sp)
    80004532:	e0a2                	sd	s0,64(sp)
    80004534:	fc26                	sd	s1,56(sp)
    80004536:	f84a                	sd	s2,48(sp)
    80004538:	f44e                	sd	s3,40(sp)
    8000453a:	0880                	addi	s0,sp,80
    8000453c:	84aa                	mv	s1,a0
    8000453e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	48a080e7          	jalr	1162(ra) # 800019ca <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004548:	409c                	lw	a5,0(s1)
    8000454a:	37f9                	addiw	a5,a5,-2
    8000454c:	4705                	li	a4,1
    8000454e:	04f76763          	bltu	a4,a5,8000459c <filestat+0x6e>
    80004552:	892a                	mv	s2,a0
    ilock(f->ip);
    80004554:	6c88                	ld	a0,24(s1)
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	07e080e7          	jalr	126(ra) # 800035d4 <ilock>
    stati(f->ip, &st);
    8000455e:	fb840593          	addi	a1,s0,-72
    80004562:	6c88                	ld	a0,24(s1)
    80004564:	fffff097          	auipc	ra,0xfffff
    80004568:	2fa080e7          	jalr	762(ra) # 8000385e <stati>
    iunlock(f->ip);
    8000456c:	6c88                	ld	a0,24(s1)
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	128080e7          	jalr	296(ra) # 80003696 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004576:	46e1                	li	a3,24
    80004578:	fb840613          	addi	a2,s0,-72
    8000457c:	85ce                	mv	a1,s3
    8000457e:	05093503          	ld	a0,80(s2)
    80004582:	ffffd097          	auipc	ra,0xffffd
    80004586:	13a080e7          	jalr	314(ra) # 800016bc <copyout>
    8000458a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000458e:	60a6                	ld	ra,72(sp)
    80004590:	6406                	ld	s0,64(sp)
    80004592:	74e2                	ld	s1,56(sp)
    80004594:	7942                	ld	s2,48(sp)
    80004596:	79a2                	ld	s3,40(sp)
    80004598:	6161                	addi	sp,sp,80
    8000459a:	8082                	ret
  return -1;
    8000459c:	557d                	li	a0,-1
    8000459e:	bfc5                	j	8000458e <filestat+0x60>

00000000800045a0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045a0:	7179                	addi	sp,sp,-48
    800045a2:	f406                	sd	ra,40(sp)
    800045a4:	f022                	sd	s0,32(sp)
    800045a6:	ec26                	sd	s1,24(sp)
    800045a8:	e84a                	sd	s2,16(sp)
    800045aa:	e44e                	sd	s3,8(sp)
    800045ac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045ae:	00854783          	lbu	a5,8(a0)
    800045b2:	c3d5                	beqz	a5,80004656 <fileread+0xb6>
    800045b4:	84aa                	mv	s1,a0
    800045b6:	89ae                	mv	s3,a1
    800045b8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045ba:	411c                	lw	a5,0(a0)
    800045bc:	4705                	li	a4,1
    800045be:	04e78963          	beq	a5,a4,80004610 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045c2:	470d                	li	a4,3
    800045c4:	04e78d63          	beq	a5,a4,8000461e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045c8:	4709                	li	a4,2
    800045ca:	06e79e63          	bne	a5,a4,80004646 <fileread+0xa6>
    ilock(f->ip);
    800045ce:	6d08                	ld	a0,24(a0)
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	004080e7          	jalr	4(ra) # 800035d4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045d8:	874a                	mv	a4,s2
    800045da:	5094                	lw	a3,32(s1)
    800045dc:	864e                	mv	a2,s3
    800045de:	4585                	li	a1,1
    800045e0:	6c88                	ld	a0,24(s1)
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	2a6080e7          	jalr	678(ra) # 80003888 <readi>
    800045ea:	892a                	mv	s2,a0
    800045ec:	00a05563          	blez	a0,800045f6 <fileread+0x56>
      f->off += r;
    800045f0:	509c                	lw	a5,32(s1)
    800045f2:	9fa9                	addw	a5,a5,a0
    800045f4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800045f6:	6c88                	ld	a0,24(s1)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	09e080e7          	jalr	158(ra) # 80003696 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004600:	854a                	mv	a0,s2
    80004602:	70a2                	ld	ra,40(sp)
    80004604:	7402                	ld	s0,32(sp)
    80004606:	64e2                	ld	s1,24(sp)
    80004608:	6942                	ld	s2,16(sp)
    8000460a:	69a2                	ld	s3,8(sp)
    8000460c:	6145                	addi	sp,sp,48
    8000460e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004610:	6908                	ld	a0,16(a0)
    80004612:	00000097          	auipc	ra,0x0
    80004616:	3f4080e7          	jalr	1012(ra) # 80004a06 <piperead>
    8000461a:	892a                	mv	s2,a0
    8000461c:	b7d5                	j	80004600 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000461e:	02451783          	lh	a5,36(a0)
    80004622:	03079693          	slli	a3,a5,0x30
    80004626:	92c1                	srli	a3,a3,0x30
    80004628:	4725                	li	a4,9
    8000462a:	02d76863          	bltu	a4,a3,8000465a <fileread+0xba>
    8000462e:	0792                	slli	a5,a5,0x4
    80004630:	0001d717          	auipc	a4,0x1d
    80004634:	38070713          	addi	a4,a4,896 # 800219b0 <devsw>
    80004638:	97ba                	add	a5,a5,a4
    8000463a:	639c                	ld	a5,0(a5)
    8000463c:	c38d                	beqz	a5,8000465e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000463e:	4505                	li	a0,1
    80004640:	9782                	jalr	a5
    80004642:	892a                	mv	s2,a0
    80004644:	bf75                	j	80004600 <fileread+0x60>
    panic("fileread");
    80004646:	00004517          	auipc	a0,0x4
    8000464a:	03a50513          	addi	a0,a0,58 # 80008680 <syscalls+0x258>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	ef4080e7          	jalr	-268(ra) # 80000542 <panic>
    return -1;
    80004656:	597d                	li	s2,-1
    80004658:	b765                	j	80004600 <fileread+0x60>
      return -1;
    8000465a:	597d                	li	s2,-1
    8000465c:	b755                	j	80004600 <fileread+0x60>
    8000465e:	597d                	li	s2,-1
    80004660:	b745                	j	80004600 <fileread+0x60>

0000000080004662 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004662:	00954783          	lbu	a5,9(a0)
    80004666:	14078563          	beqz	a5,800047b0 <filewrite+0x14e>
{
    8000466a:	715d                	addi	sp,sp,-80
    8000466c:	e486                	sd	ra,72(sp)
    8000466e:	e0a2                	sd	s0,64(sp)
    80004670:	fc26                	sd	s1,56(sp)
    80004672:	f84a                	sd	s2,48(sp)
    80004674:	f44e                	sd	s3,40(sp)
    80004676:	f052                	sd	s4,32(sp)
    80004678:	ec56                	sd	s5,24(sp)
    8000467a:	e85a                	sd	s6,16(sp)
    8000467c:	e45e                	sd	s7,8(sp)
    8000467e:	e062                	sd	s8,0(sp)
    80004680:	0880                	addi	s0,sp,80
    80004682:	892a                	mv	s2,a0
    80004684:	8aae                	mv	s5,a1
    80004686:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004688:	411c                	lw	a5,0(a0)
    8000468a:	4705                	li	a4,1
    8000468c:	02e78263          	beq	a5,a4,800046b0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004690:	470d                	li	a4,3
    80004692:	02e78563          	beq	a5,a4,800046bc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004696:	4709                	li	a4,2
    80004698:	10e79463          	bne	a5,a4,800047a0 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000469c:	0ec05e63          	blez	a2,80004798 <filewrite+0x136>
    int i = 0;
    800046a0:	4981                	li	s3,0
    800046a2:	6b05                	lui	s6,0x1
    800046a4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046a8:	6b85                	lui	s7,0x1
    800046aa:	c00b8b9b          	addiw	s7,s7,-1024
    800046ae:	a851                	j	80004742 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046b0:	6908                	ld	a0,16(a0)
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	254080e7          	jalr	596(ra) # 80004906 <pipewrite>
    800046ba:	a85d                	j	80004770 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046bc:	02451783          	lh	a5,36(a0)
    800046c0:	03079693          	slli	a3,a5,0x30
    800046c4:	92c1                	srli	a3,a3,0x30
    800046c6:	4725                	li	a4,9
    800046c8:	0ed76663          	bltu	a4,a3,800047b4 <filewrite+0x152>
    800046cc:	0792                	slli	a5,a5,0x4
    800046ce:	0001d717          	auipc	a4,0x1d
    800046d2:	2e270713          	addi	a4,a4,738 # 800219b0 <devsw>
    800046d6:	97ba                	add	a5,a5,a4
    800046d8:	679c                	ld	a5,8(a5)
    800046da:	cff9                	beqz	a5,800047b8 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800046dc:	4505                	li	a0,1
    800046de:	9782                	jalr	a5
    800046e0:	a841                	j	80004770 <filewrite+0x10e>
    800046e2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	8ae080e7          	jalr	-1874(ra) # 80003f94 <begin_op>
      ilock(f->ip);
    800046ee:	01893503          	ld	a0,24(s2)
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	ee2080e7          	jalr	-286(ra) # 800035d4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800046fa:	8762                	mv	a4,s8
    800046fc:	02092683          	lw	a3,32(s2)
    80004700:	01598633          	add	a2,s3,s5
    80004704:	4585                	li	a1,1
    80004706:	01893503          	ld	a0,24(s2)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	274080e7          	jalr	628(ra) # 8000397e <writei>
    80004712:	84aa                	mv	s1,a0
    80004714:	02a05f63          	blez	a0,80004752 <filewrite+0xf0>
        f->off += r;
    80004718:	02092783          	lw	a5,32(s2)
    8000471c:	9fa9                	addw	a5,a5,a0
    8000471e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004722:	01893503          	ld	a0,24(s2)
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	f70080e7          	jalr	-144(ra) # 80003696 <iunlock>
      end_op();
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	8e6080e7          	jalr	-1818(ra) # 80004014 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004736:	049c1963          	bne	s8,s1,80004788 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000473a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000473e:	0349d663          	bge	s3,s4,8000476a <filewrite+0x108>
      int n1 = n - i;
    80004742:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004746:	84be                	mv	s1,a5
    80004748:	2781                	sext.w	a5,a5
    8000474a:	f8fb5ce3          	bge	s6,a5,800046e2 <filewrite+0x80>
    8000474e:	84de                	mv	s1,s7
    80004750:	bf49                	j	800046e2 <filewrite+0x80>
      iunlock(f->ip);
    80004752:	01893503          	ld	a0,24(s2)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	f40080e7          	jalr	-192(ra) # 80003696 <iunlock>
      end_op();
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	8b6080e7          	jalr	-1866(ra) # 80004014 <end_op>
      if(r < 0)
    80004766:	fc04d8e3          	bgez	s1,80004736 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000476a:	8552                	mv	a0,s4
    8000476c:	033a1863          	bne	s4,s3,8000479c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004770:	60a6                	ld	ra,72(sp)
    80004772:	6406                	ld	s0,64(sp)
    80004774:	74e2                	ld	s1,56(sp)
    80004776:	7942                	ld	s2,48(sp)
    80004778:	79a2                	ld	s3,40(sp)
    8000477a:	7a02                	ld	s4,32(sp)
    8000477c:	6ae2                	ld	s5,24(sp)
    8000477e:	6b42                	ld	s6,16(sp)
    80004780:	6ba2                	ld	s7,8(sp)
    80004782:	6c02                	ld	s8,0(sp)
    80004784:	6161                	addi	sp,sp,80
    80004786:	8082                	ret
        panic("short filewrite");
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	f0850513          	addi	a0,a0,-248 # 80008690 <syscalls+0x268>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	db2080e7          	jalr	-590(ra) # 80000542 <panic>
    int i = 0;
    80004798:	4981                	li	s3,0
    8000479a:	bfc1                	j	8000476a <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000479c:	557d                	li	a0,-1
    8000479e:	bfc9                	j	80004770 <filewrite+0x10e>
    panic("filewrite");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	f0050513          	addi	a0,a0,-256 # 800086a0 <syscalls+0x278>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	d9a080e7          	jalr	-614(ra) # 80000542 <panic>
    return -1;
    800047b0:	557d                	li	a0,-1
}
    800047b2:	8082                	ret
      return -1;
    800047b4:	557d                	li	a0,-1
    800047b6:	bf6d                	j	80004770 <filewrite+0x10e>
    800047b8:	557d                	li	a0,-1
    800047ba:	bf5d                	j	80004770 <filewrite+0x10e>

00000000800047bc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047bc:	7179                	addi	sp,sp,-48
    800047be:	f406                	sd	ra,40(sp)
    800047c0:	f022                	sd	s0,32(sp)
    800047c2:	ec26                	sd	s1,24(sp)
    800047c4:	e84a                	sd	s2,16(sp)
    800047c6:	e44e                	sd	s3,8(sp)
    800047c8:	e052                	sd	s4,0(sp)
    800047ca:	1800                	addi	s0,sp,48
    800047cc:	84aa                	mv	s1,a0
    800047ce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047d0:	0005b023          	sd	zero,0(a1)
    800047d4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	bd2080e7          	jalr	-1070(ra) # 800043aa <filealloc>
    800047e0:	e088                	sd	a0,0(s1)
    800047e2:	c551                	beqz	a0,8000486e <pipealloc+0xb2>
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	bc6080e7          	jalr	-1082(ra) # 800043aa <filealloc>
    800047ec:	00aa3023          	sd	a0,0(s4)
    800047f0:	c92d                	beqz	a0,80004862 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	31c080e7          	jalr	796(ra) # 80000b0e <kalloc>
    800047fa:	892a                	mv	s2,a0
    800047fc:	c125                	beqz	a0,8000485c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047fe:	4985                	li	s3,1
    80004800:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004804:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004808:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000480c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004810:	00004597          	auipc	a1,0x4
    80004814:	ea058593          	addi	a1,a1,-352 # 800086b0 <syscalls+0x288>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	356080e7          	jalr	854(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004820:	609c                	ld	a5,0(s1)
    80004822:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004826:	609c                	ld	a5,0(s1)
    80004828:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004832:	609c                	ld	a5,0(s1)
    80004834:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004838:	000a3783          	ld	a5,0(s4)
    8000483c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004840:	000a3783          	ld	a5,0(s4)
    80004844:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004848:	000a3783          	ld	a5,0(s4)
    8000484c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004850:	000a3783          	ld	a5,0(s4)
    80004854:	0127b823          	sd	s2,16(a5)
  return 0;
    80004858:	4501                	li	a0,0
    8000485a:	a025                	j	80004882 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000485c:	6088                	ld	a0,0(s1)
    8000485e:	e501                	bnez	a0,80004866 <pipealloc+0xaa>
    80004860:	a039                	j	8000486e <pipealloc+0xb2>
    80004862:	6088                	ld	a0,0(s1)
    80004864:	c51d                	beqz	a0,80004892 <pipealloc+0xd6>
    fileclose(*f0);
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	c00080e7          	jalr	-1024(ra) # 80004466 <fileclose>
  if(*f1)
    8000486e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004872:	557d                	li	a0,-1
  if(*f1)
    80004874:	c799                	beqz	a5,80004882 <pipealloc+0xc6>
    fileclose(*f1);
    80004876:	853e                	mv	a0,a5
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	bee080e7          	jalr	-1042(ra) # 80004466 <fileclose>
  return -1;
    80004880:	557d                	li	a0,-1
}
    80004882:	70a2                	ld	ra,40(sp)
    80004884:	7402                	ld	s0,32(sp)
    80004886:	64e2                	ld	s1,24(sp)
    80004888:	6942                	ld	s2,16(sp)
    8000488a:	69a2                	ld	s3,8(sp)
    8000488c:	6a02                	ld	s4,0(sp)
    8000488e:	6145                	addi	sp,sp,48
    80004890:	8082                	ret
  return -1;
    80004892:	557d                	li	a0,-1
    80004894:	b7fd                	j	80004882 <pipealloc+0xc6>

0000000080004896 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	e04a                	sd	s2,0(sp)
    800048a0:	1000                	addi	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
    800048a4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	358080e7          	jalr	856(ra) # 80000bfe <acquire>
  if(writable){
    800048ae:	02090d63          	beqz	s2,800048e8 <pipeclose+0x52>
    pi->writeopen = 0;
    800048b2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b6:	21848513          	addi	a0,s1,536
    800048ba:	ffffe097          	auipc	ra,0xffffe
    800048be:	a80080e7          	jalr	-1408(ra) # 8000233a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048c2:	2204b783          	ld	a5,544(s1)
    800048c6:	eb95                	bnez	a5,800048fa <pipeclose+0x64>
    release(&pi->lock);
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3e8080e7          	jalr	1000(ra) # 80000cb2 <release>
    kfree((char*)pi);
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	13e080e7          	jalr	318(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800048dc:	60e2                	ld	ra,24(sp)
    800048de:	6442                	ld	s0,16(sp)
    800048e0:	64a2                	ld	s1,8(sp)
    800048e2:	6902                	ld	s2,0(sp)
    800048e4:	6105                	addi	sp,sp,32
    800048e6:	8082                	ret
    pi->readopen = 0;
    800048e8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048ec:	21c48513          	addi	a0,s1,540
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	a4a080e7          	jalr	-1462(ra) # 8000233a <wakeup>
    800048f8:	b7e9                	j	800048c2 <pipeclose+0x2c>
    release(&pi->lock);
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	3b6080e7          	jalr	950(ra) # 80000cb2 <release>
}
    80004904:	bfe1                	j	800048dc <pipeclose+0x46>

0000000080004906 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004906:	711d                	addi	sp,sp,-96
    80004908:	ec86                	sd	ra,88(sp)
    8000490a:	e8a2                	sd	s0,80(sp)
    8000490c:	e4a6                	sd	s1,72(sp)
    8000490e:	e0ca                	sd	s2,64(sp)
    80004910:	fc4e                	sd	s3,56(sp)
    80004912:	f852                	sd	s4,48(sp)
    80004914:	f456                	sd	s5,40(sp)
    80004916:	f05a                	sd	s6,32(sp)
    80004918:	ec5e                	sd	s7,24(sp)
    8000491a:	e862                	sd	s8,16(sp)
    8000491c:	1080                	addi	s0,sp,96
    8000491e:	84aa                	mv	s1,a0
    80004920:	8b2e                	mv	s6,a1
    80004922:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	0a6080e7          	jalr	166(ra) # 800019ca <myproc>
    8000492c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    8000492e:	8526                	mv	a0,s1
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	2ce080e7          	jalr	718(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004938:	09505763          	blez	s5,800049c6 <pipewrite+0xc0>
    8000493c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8000493e:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004942:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004946:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004948:	2184a783          	lw	a5,536(s1)
    8000494c:	21c4a703          	lw	a4,540(s1)
    80004950:	2007879b          	addiw	a5,a5,512
    80004954:	02f71b63          	bne	a4,a5,8000498a <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004958:	2204a783          	lw	a5,544(s1)
    8000495c:	c3d1                	beqz	a5,800049e0 <pipewrite+0xda>
    8000495e:	03092783          	lw	a5,48(s2)
    80004962:	efbd                	bnez	a5,800049e0 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004964:	8552                	mv	a0,s4
    80004966:	ffffe097          	auipc	ra,0xffffe
    8000496a:	9d4080e7          	jalr	-1580(ra) # 8000233a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000496e:	85a6                	mv	a1,s1
    80004970:	854e                	mv	a0,s3
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	848080e7          	jalr	-1976(ra) # 800021ba <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    8000497a:	2184a783          	lw	a5,536(s1)
    8000497e:	21c4a703          	lw	a4,540(s1)
    80004982:	2007879b          	addiw	a5,a5,512
    80004986:	fcf709e3          	beq	a4,a5,80004958 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000498a:	4685                	li	a3,1
    8000498c:	865a                	mv	a2,s6
    8000498e:	faf40593          	addi	a1,s0,-81
    80004992:	05093503          	ld	a0,80(s2)
    80004996:	ffffd097          	auipc	ra,0xffffd
    8000499a:	db2080e7          	jalr	-590(ra) # 80001748 <copyin>
    8000499e:	03850563          	beq	a0,s8,800049c8 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049a2:	21c4a783          	lw	a5,540(s1)
    800049a6:	0017871b          	addiw	a4,a5,1
    800049aa:	20e4ae23          	sw	a4,540(s1)
    800049ae:	1ff7f793          	andi	a5,a5,511
    800049b2:	97a6                	add	a5,a5,s1
    800049b4:	faf44703          	lbu	a4,-81(s0)
    800049b8:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    800049bc:	2b85                	addiw	s7,s7,1
    800049be:	0b05                	addi	s6,s6,1
    800049c0:	f97a94e3          	bne	s5,s7,80004948 <pipewrite+0x42>
    800049c4:	a011                	j	800049c8 <pipewrite+0xc2>
    800049c6:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    800049c8:	21848513          	addi	a0,s1,536
    800049cc:	ffffe097          	auipc	ra,0xffffe
    800049d0:	96e080e7          	jalr	-1682(ra) # 8000233a <wakeup>
  release(&pi->lock);
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	2dc080e7          	jalr	732(ra) # 80000cb2 <release>
  return i;
    800049de:	a039                	j	800049ec <pipewrite+0xe6>
        release(&pi->lock);
    800049e0:	8526                	mv	a0,s1
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2d0080e7          	jalr	720(ra) # 80000cb2 <release>
        return -1;
    800049ea:	5bfd                	li	s7,-1
}
    800049ec:	855e                	mv	a0,s7
    800049ee:	60e6                	ld	ra,88(sp)
    800049f0:	6446                	ld	s0,80(sp)
    800049f2:	64a6                	ld	s1,72(sp)
    800049f4:	6906                	ld	s2,64(sp)
    800049f6:	79e2                	ld	s3,56(sp)
    800049f8:	7a42                	ld	s4,48(sp)
    800049fa:	7aa2                	ld	s5,40(sp)
    800049fc:	7b02                	ld	s6,32(sp)
    800049fe:	6be2                	ld	s7,24(sp)
    80004a00:	6c42                	ld	s8,16(sp)
    80004a02:	6125                	addi	sp,sp,96
    80004a04:	8082                	ret

0000000080004a06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a06:	715d                	addi	sp,sp,-80
    80004a08:	e486                	sd	ra,72(sp)
    80004a0a:	e0a2                	sd	s0,64(sp)
    80004a0c:	fc26                	sd	s1,56(sp)
    80004a0e:	f84a                	sd	s2,48(sp)
    80004a10:	f44e                	sd	s3,40(sp)
    80004a12:	f052                	sd	s4,32(sp)
    80004a14:	ec56                	sd	s5,24(sp)
    80004a16:	e85a                	sd	s6,16(sp)
    80004a18:	0880                	addi	s0,sp,80
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	892e                	mv	s2,a1
    80004a1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a20:	ffffd097          	auipc	ra,0xffffd
    80004a24:	faa080e7          	jalr	-86(ra) # 800019ca <myproc>
    80004a28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1d2080e7          	jalr	466(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a34:	2184a703          	lw	a4,536(s1)
    80004a38:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a40:	02f71463          	bne	a4,a5,80004a68 <piperead+0x62>
    80004a44:	2244a783          	lw	a5,548(s1)
    80004a48:	c385                	beqz	a5,80004a68 <piperead+0x62>
    if(pr->killed){
    80004a4a:	030a2783          	lw	a5,48(s4)
    80004a4e:	ebc1                	bnez	a5,80004ade <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a50:	85a6                	mv	a1,s1
    80004a52:	854e                	mv	a0,s3
    80004a54:	ffffd097          	auipc	ra,0xffffd
    80004a58:	766080e7          	jalr	1894(ra) # 800021ba <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a5c:	2184a703          	lw	a4,536(s1)
    80004a60:	21c4a783          	lw	a5,540(s1)
    80004a64:	fef700e3          	beq	a4,a5,80004a44 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a68:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a6a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a6c:	05505363          	blez	s5,80004ab2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004a70:	2184a783          	lw	a5,536(s1)
    80004a74:	21c4a703          	lw	a4,540(s1)
    80004a78:	02f70d63          	beq	a4,a5,80004ab2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a7c:	0017871b          	addiw	a4,a5,1
    80004a80:	20e4ac23          	sw	a4,536(s1)
    80004a84:	1ff7f793          	andi	a5,a5,511
    80004a88:	97a6                	add	a5,a5,s1
    80004a8a:	0187c783          	lbu	a5,24(a5)
    80004a8e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a92:	4685                	li	a3,1
    80004a94:	fbf40613          	addi	a2,s0,-65
    80004a98:	85ca                	mv	a1,s2
    80004a9a:	050a3503          	ld	a0,80(s4)
    80004a9e:	ffffd097          	auipc	ra,0xffffd
    80004aa2:	c1e080e7          	jalr	-994(ra) # 800016bc <copyout>
    80004aa6:	01650663          	beq	a0,s6,80004ab2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aaa:	2985                	addiw	s3,s3,1
    80004aac:	0905                	addi	s2,s2,1
    80004aae:	fd3a91e3          	bne	s5,s3,80004a70 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ab2:	21c48513          	addi	a0,s1,540
    80004ab6:	ffffe097          	auipc	ra,0xffffe
    80004aba:	884080e7          	jalr	-1916(ra) # 8000233a <wakeup>
  release(&pi->lock);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1f2080e7          	jalr	498(ra) # 80000cb2 <release>
  return i;
}
    80004ac8:	854e                	mv	a0,s3
    80004aca:	60a6                	ld	ra,72(sp)
    80004acc:	6406                	ld	s0,64(sp)
    80004ace:	74e2                	ld	s1,56(sp)
    80004ad0:	7942                	ld	s2,48(sp)
    80004ad2:	79a2                	ld	s3,40(sp)
    80004ad4:	7a02                	ld	s4,32(sp)
    80004ad6:	6ae2                	ld	s5,24(sp)
    80004ad8:	6b42                	ld	s6,16(sp)
    80004ada:	6161                	addi	sp,sp,80
    80004adc:	8082                	ret
      release(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1d2080e7          	jalr	466(ra) # 80000cb2 <release>
      return -1;
    80004ae8:	59fd                	li	s3,-1
    80004aea:	bff9                	j	80004ac8 <piperead+0xc2>

0000000080004aec <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004aec:	de010113          	addi	sp,sp,-544
    80004af0:	20113c23          	sd	ra,536(sp)
    80004af4:	20813823          	sd	s0,528(sp)
    80004af8:	20913423          	sd	s1,520(sp)
    80004afc:	21213023          	sd	s2,512(sp)
    80004b00:	ffce                	sd	s3,504(sp)
    80004b02:	fbd2                	sd	s4,496(sp)
    80004b04:	f7d6                	sd	s5,488(sp)
    80004b06:	f3da                	sd	s6,480(sp)
    80004b08:	efde                	sd	s7,472(sp)
    80004b0a:	ebe2                	sd	s8,464(sp)
    80004b0c:	e7e6                	sd	s9,456(sp)
    80004b0e:	e3ea                	sd	s10,448(sp)
    80004b10:	ff6e                	sd	s11,440(sp)
    80004b12:	1400                	addi	s0,sp,544
    80004b14:	892a                	mv	s2,a0
    80004b16:	dea43423          	sd	a0,-536(s0)
    80004b1a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	eac080e7          	jalr	-340(ra) # 800019ca <myproc>
    80004b26:	84aa                	mv	s1,a0

  begin_op();
    80004b28:	fffff097          	auipc	ra,0xfffff
    80004b2c:	46c080e7          	jalr	1132(ra) # 80003f94 <begin_op>

  if((ip = namei(path)) == 0){
    80004b30:	854a                	mv	a0,s2
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	252080e7          	jalr	594(ra) # 80003d84 <namei>
    80004b3a:	c93d                	beqz	a0,80004bb0 <exec+0xc4>
    80004b3c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	a96080e7          	jalr	-1386(ra) # 800035d4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b46:	04000713          	li	a4,64
    80004b4a:	4681                	li	a3,0
    80004b4c:	e4840613          	addi	a2,s0,-440
    80004b50:	4581                	li	a1,0
    80004b52:	8556                	mv	a0,s5
    80004b54:	fffff097          	auipc	ra,0xfffff
    80004b58:	d34080e7          	jalr	-716(ra) # 80003888 <readi>
    80004b5c:	04000793          	li	a5,64
    80004b60:	00f51a63          	bne	a0,a5,80004b74 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b64:	e4842703          	lw	a4,-440(s0)
    80004b68:	464c47b7          	lui	a5,0x464c4
    80004b6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b70:	04f70663          	beq	a4,a5,80004bbc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b74:	8556                	mv	a0,s5
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	cc0080e7          	jalr	-832(ra) # 80003836 <iunlockput>
    end_op();
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	496080e7          	jalr	1174(ra) # 80004014 <end_op>
  }
  return -1;
    80004b86:	557d                	li	a0,-1
}
    80004b88:	21813083          	ld	ra,536(sp)
    80004b8c:	21013403          	ld	s0,528(sp)
    80004b90:	20813483          	ld	s1,520(sp)
    80004b94:	20013903          	ld	s2,512(sp)
    80004b98:	79fe                	ld	s3,504(sp)
    80004b9a:	7a5e                	ld	s4,496(sp)
    80004b9c:	7abe                	ld	s5,488(sp)
    80004b9e:	7b1e                	ld	s6,480(sp)
    80004ba0:	6bfe                	ld	s7,472(sp)
    80004ba2:	6c5e                	ld	s8,464(sp)
    80004ba4:	6cbe                	ld	s9,456(sp)
    80004ba6:	6d1e                	ld	s10,448(sp)
    80004ba8:	7dfa                	ld	s11,440(sp)
    80004baa:	22010113          	addi	sp,sp,544
    80004bae:	8082                	ret
    end_op();
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	464080e7          	jalr	1124(ra) # 80004014 <end_op>
    return -1;
    80004bb8:	557d                	li	a0,-1
    80004bba:	b7f9                	j	80004b88 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	ed0080e7          	jalr	-304(ra) # 80001a8e <proc_pagetable>
    80004bc6:	8b2a                	mv	s6,a0
    80004bc8:	d555                	beqz	a0,80004b74 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bca:	e6842783          	lw	a5,-408(s0)
    80004bce:	e8045703          	lhu	a4,-384(s0)
    80004bd2:	c735                	beqz	a4,80004c3e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004bd4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004bda:	6a05                	lui	s4,0x1
    80004bdc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004be0:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004be4:	6d85                	lui	s11,0x1
    80004be6:	7d7d                	lui	s10,0xfffff
    80004be8:	ac1d                	j	80004e1e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bea:	00004517          	auipc	a0,0x4
    80004bee:	ace50513          	addi	a0,a0,-1330 # 800086b8 <syscalls+0x290>
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	950080e7          	jalr	-1712(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bfa:	874a                	mv	a4,s2
    80004bfc:	009c86bb          	addw	a3,s9,s1
    80004c00:	4581                	li	a1,0
    80004c02:	8556                	mv	a0,s5
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	c84080e7          	jalr	-892(ra) # 80003888 <readi>
    80004c0c:	2501                	sext.w	a0,a0
    80004c0e:	1aa91863          	bne	s2,a0,80004dbe <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c12:	009d84bb          	addw	s1,s11,s1
    80004c16:	013d09bb          	addw	s3,s10,s3
    80004c1a:	1f74f263          	bgeu	s1,s7,80004dfe <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c1e:	02049593          	slli	a1,s1,0x20
    80004c22:	9181                	srli	a1,a1,0x20
    80004c24:	95e2                	add	a1,a1,s8
    80004c26:	855a                	mv	a0,s6
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	460080e7          	jalr	1120(ra) # 80001088 <walkaddr>
    80004c30:	862a                	mv	a2,a0
    if(pa == 0)
    80004c32:	dd45                	beqz	a0,80004bea <exec+0xfe>
      n = PGSIZE;
    80004c34:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c36:	fd49f2e3          	bgeu	s3,s4,80004bfa <exec+0x10e>
      n = sz - i;
    80004c3a:	894e                	mv	s2,s3
    80004c3c:	bf7d                	j	80004bfa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c3e:	4481                	li	s1,0
  iunlockput(ip);
    80004c40:	8556                	mv	a0,s5
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	bf4080e7          	jalr	-1036(ra) # 80003836 <iunlockput>
  end_op();
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	3ca080e7          	jalr	970(ra) # 80004014 <end_op>
  p = myproc();
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	d78080e7          	jalr	-648(ra) # 800019ca <myproc>
    80004c5a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c5c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c60:	6785                	lui	a5,0x1
    80004c62:	17fd                	addi	a5,a5,-1
    80004c64:	94be                	add	s1,s1,a5
    80004c66:	77fd                	lui	a5,0xfffff
    80004c68:	8fe5                	and	a5,a5,s1
    80004c6a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c6e:	6609                	lui	a2,0x2
    80004c70:	963e                	add	a2,a2,a5
    80004c72:	85be                	mv	a1,a5
    80004c74:	855a                	mv	a0,s6
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	7f6080e7          	jalr	2038(ra) # 8000146c <uvmalloc>
    80004c7e:	8c2a                	mv	s8,a0
  ip = 0;
    80004c80:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c82:	12050e63          	beqz	a0,80004dbe <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c86:	75f9                	lui	a1,0xffffe
    80004c88:	95aa                	add	a1,a1,a0
    80004c8a:	855a                	mv	a0,s6
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	9fe080e7          	jalr	-1538(ra) # 8000168a <uvmclear>
  stackbase = sp - PGSIZE;
    80004c94:	7afd                	lui	s5,0xfffff
    80004c96:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c98:	df043783          	ld	a5,-528(s0)
    80004c9c:	6388                	ld	a0,0(a5)
    80004c9e:	c925                	beqz	a0,80004d0e <exec+0x222>
    80004ca0:	e8840993          	addi	s3,s0,-376
    80004ca4:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ca8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004caa:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	1d2080e7          	jalr	466(ra) # 80000e7e <strlen>
    80004cb4:	0015079b          	addiw	a5,a0,1
    80004cb8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cbc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cc0:	13596363          	bltu	s2,s5,80004de6 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cc4:	df043d83          	ld	s11,-528(s0)
    80004cc8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ccc:	8552                	mv	a0,s4
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	1b0080e7          	jalr	432(ra) # 80000e7e <strlen>
    80004cd6:	0015069b          	addiw	a3,a0,1
    80004cda:	8652                	mv	a2,s4
    80004cdc:	85ca                	mv	a1,s2
    80004cde:	855a                	mv	a0,s6
    80004ce0:	ffffd097          	auipc	ra,0xffffd
    80004ce4:	9dc080e7          	jalr	-1572(ra) # 800016bc <copyout>
    80004ce8:	10054363          	bltz	a0,80004dee <exec+0x302>
    ustack[argc] = sp;
    80004cec:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cf0:	0485                	addi	s1,s1,1
    80004cf2:	008d8793          	addi	a5,s11,8
    80004cf6:	def43823          	sd	a5,-528(s0)
    80004cfa:	008db503          	ld	a0,8(s11)
    80004cfe:	c911                	beqz	a0,80004d12 <exec+0x226>
    if(argc >= MAXARG)
    80004d00:	09a1                	addi	s3,s3,8
    80004d02:	fb3c95e3          	bne	s9,s3,80004cac <exec+0x1c0>
  sz = sz1;
    80004d06:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d0a:	4a81                	li	s5,0
    80004d0c:	a84d                	j	80004dbe <exec+0x2d2>
  sp = sz;
    80004d0e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d10:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d12:	00349793          	slli	a5,s1,0x3
    80004d16:	f9040713          	addi	a4,s0,-112
    80004d1a:	97ba                	add	a5,a5,a4
    80004d1c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004d20:	00148693          	addi	a3,s1,1
    80004d24:	068e                	slli	a3,a3,0x3
    80004d26:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d2a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d2e:	01597663          	bgeu	s2,s5,80004d3a <exec+0x24e>
  sz = sz1;
    80004d32:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d36:	4a81                	li	s5,0
    80004d38:	a059                	j	80004dbe <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d3a:	e8840613          	addi	a2,s0,-376
    80004d3e:	85ca                	mv	a1,s2
    80004d40:	855a                	mv	a0,s6
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	97a080e7          	jalr	-1670(ra) # 800016bc <copyout>
    80004d4a:	0a054663          	bltz	a0,80004df6 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d4e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004d52:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d56:	de843783          	ld	a5,-536(s0)
    80004d5a:	0007c703          	lbu	a4,0(a5)
    80004d5e:	cf11                	beqz	a4,80004d7a <exec+0x28e>
    80004d60:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d62:	02f00693          	li	a3,47
    80004d66:	a039                	j	80004d74 <exec+0x288>
      last = s+1;
    80004d68:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d6c:	0785                	addi	a5,a5,1
    80004d6e:	fff7c703          	lbu	a4,-1(a5)
    80004d72:	c701                	beqz	a4,80004d7a <exec+0x28e>
    if(*s == '/')
    80004d74:	fed71ce3          	bne	a4,a3,80004d6c <exec+0x280>
    80004d78:	bfc5                	j	80004d68 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d7a:	4641                	li	a2,16
    80004d7c:	de843583          	ld	a1,-536(s0)
    80004d80:	158b8513          	addi	a0,s7,344
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	0c8080e7          	jalr	200(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    80004d8c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d90:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004d94:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d98:	058bb783          	ld	a5,88(s7)
    80004d9c:	e6043703          	ld	a4,-416(s0)
    80004da0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004da2:	058bb783          	ld	a5,88(s7)
    80004da6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004daa:	85ea                	mv	a1,s10
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	d7e080e7          	jalr	-642(ra) # 80001b2a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004db4:	0004851b          	sext.w	a0,s1
    80004db8:	bbc1                	j	80004b88 <exec+0x9c>
    80004dba:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004dbe:	df843583          	ld	a1,-520(s0)
    80004dc2:	855a                	mv	a0,s6
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	d66080e7          	jalr	-666(ra) # 80001b2a <proc_freepagetable>
  if(ip){
    80004dcc:	da0a94e3          	bnez	s5,80004b74 <exec+0x88>
  return -1;
    80004dd0:	557d                	li	a0,-1
    80004dd2:	bb5d                	j	80004b88 <exec+0x9c>
    80004dd4:	de943c23          	sd	s1,-520(s0)
    80004dd8:	b7dd                	j	80004dbe <exec+0x2d2>
    80004dda:	de943c23          	sd	s1,-520(s0)
    80004dde:	b7c5                	j	80004dbe <exec+0x2d2>
    80004de0:	de943c23          	sd	s1,-520(s0)
    80004de4:	bfe9                	j	80004dbe <exec+0x2d2>
  sz = sz1;
    80004de6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dea:	4a81                	li	s5,0
    80004dec:	bfc9                	j	80004dbe <exec+0x2d2>
  sz = sz1;
    80004dee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004df2:	4a81                	li	s5,0
    80004df4:	b7e9                	j	80004dbe <exec+0x2d2>
  sz = sz1;
    80004df6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dfa:	4a81                	li	s5,0
    80004dfc:	b7c9                	j	80004dbe <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004dfe:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e02:	e0843783          	ld	a5,-504(s0)
    80004e06:	0017869b          	addiw	a3,a5,1
    80004e0a:	e0d43423          	sd	a3,-504(s0)
    80004e0e:	e0043783          	ld	a5,-512(s0)
    80004e12:	0387879b          	addiw	a5,a5,56
    80004e16:	e8045703          	lhu	a4,-384(s0)
    80004e1a:	e2e6d3e3          	bge	a3,a4,80004c40 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e1e:	2781                	sext.w	a5,a5
    80004e20:	e0f43023          	sd	a5,-512(s0)
    80004e24:	03800713          	li	a4,56
    80004e28:	86be                	mv	a3,a5
    80004e2a:	e1040613          	addi	a2,s0,-496
    80004e2e:	4581                	li	a1,0
    80004e30:	8556                	mv	a0,s5
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	a56080e7          	jalr	-1450(ra) # 80003888 <readi>
    80004e3a:	03800793          	li	a5,56
    80004e3e:	f6f51ee3          	bne	a0,a5,80004dba <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e42:	e1042783          	lw	a5,-496(s0)
    80004e46:	4705                	li	a4,1
    80004e48:	fae79de3          	bne	a5,a4,80004e02 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e4c:	e3843603          	ld	a2,-456(s0)
    80004e50:	e3043783          	ld	a5,-464(s0)
    80004e54:	f8f660e3          	bltu	a2,a5,80004dd4 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e58:	e2043783          	ld	a5,-480(s0)
    80004e5c:	963e                	add	a2,a2,a5
    80004e5e:	f6f66ee3          	bltu	a2,a5,80004dda <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e62:	85a6                	mv	a1,s1
    80004e64:	855a                	mv	a0,s6
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	606080e7          	jalr	1542(ra) # 8000146c <uvmalloc>
    80004e6e:	dea43c23          	sd	a0,-520(s0)
    80004e72:	d53d                	beqz	a0,80004de0 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004e74:	e2043c03          	ld	s8,-480(s0)
    80004e78:	de043783          	ld	a5,-544(s0)
    80004e7c:	00fc77b3          	and	a5,s8,a5
    80004e80:	ff9d                	bnez	a5,80004dbe <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e82:	e1842c83          	lw	s9,-488(s0)
    80004e86:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e8a:	f60b8ae3          	beqz	s7,80004dfe <exec+0x312>
    80004e8e:	89de                	mv	s3,s7
    80004e90:	4481                	li	s1,0
    80004e92:	b371                	j	80004c1e <exec+0x132>

0000000080004e94 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e94:	7179                	addi	sp,sp,-48
    80004e96:	f406                	sd	ra,40(sp)
    80004e98:	f022                	sd	s0,32(sp)
    80004e9a:	ec26                	sd	s1,24(sp)
    80004e9c:	e84a                	sd	s2,16(sp)
    80004e9e:	1800                	addi	s0,sp,48
    80004ea0:	892e                	mv	s2,a1
    80004ea2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ea4:	fdc40593          	addi	a1,s0,-36
    80004ea8:	ffffe097          	auipc	ra,0xffffe
    80004eac:	bba080e7          	jalr	-1094(ra) # 80002a62 <argint>
    80004eb0:	04054063          	bltz	a0,80004ef0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004eb4:	fdc42703          	lw	a4,-36(s0)
    80004eb8:	47bd                	li	a5,15
    80004eba:	02e7ed63          	bltu	a5,a4,80004ef4 <argfd+0x60>
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	b0c080e7          	jalr	-1268(ra) # 800019ca <myproc>
    80004ec6:	fdc42703          	lw	a4,-36(s0)
    80004eca:	01a70793          	addi	a5,a4,26
    80004ece:	078e                	slli	a5,a5,0x3
    80004ed0:	953e                	add	a0,a0,a5
    80004ed2:	611c                	ld	a5,0(a0)
    80004ed4:	c395                	beqz	a5,80004ef8 <argfd+0x64>
    return -1;
  if(pfd)
    80004ed6:	00090463          	beqz	s2,80004ede <argfd+0x4a>
    *pfd = fd;
    80004eda:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ede:	4501                	li	a0,0
  if(pf)
    80004ee0:	c091                	beqz	s1,80004ee4 <argfd+0x50>
    *pf = f;
    80004ee2:	e09c                	sd	a5,0(s1)
}
    80004ee4:	70a2                	ld	ra,40(sp)
    80004ee6:	7402                	ld	s0,32(sp)
    80004ee8:	64e2                	ld	s1,24(sp)
    80004eea:	6942                	ld	s2,16(sp)
    80004eec:	6145                	addi	sp,sp,48
    80004eee:	8082                	ret
    return -1;
    80004ef0:	557d                	li	a0,-1
    80004ef2:	bfcd                	j	80004ee4 <argfd+0x50>
    return -1;
    80004ef4:	557d                	li	a0,-1
    80004ef6:	b7fd                	j	80004ee4 <argfd+0x50>
    80004ef8:	557d                	li	a0,-1
    80004efa:	b7ed                	j	80004ee4 <argfd+0x50>

0000000080004efc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004efc:	1101                	addi	sp,sp,-32
    80004efe:	ec06                	sd	ra,24(sp)
    80004f00:	e822                	sd	s0,16(sp)
    80004f02:	e426                	sd	s1,8(sp)
    80004f04:	1000                	addi	s0,sp,32
    80004f06:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	ac2080e7          	jalr	-1342(ra) # 800019ca <myproc>
    80004f10:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f12:	0d050793          	addi	a5,a0,208
    80004f16:	4501                	li	a0,0
    80004f18:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f1a:	6398                	ld	a4,0(a5)
    80004f1c:	cb19                	beqz	a4,80004f32 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f1e:	2505                	addiw	a0,a0,1
    80004f20:	07a1                	addi	a5,a5,8
    80004f22:	fed51ce3          	bne	a0,a3,80004f1a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f26:	557d                	li	a0,-1
}
    80004f28:	60e2                	ld	ra,24(sp)
    80004f2a:	6442                	ld	s0,16(sp)
    80004f2c:	64a2                	ld	s1,8(sp)
    80004f2e:	6105                	addi	sp,sp,32
    80004f30:	8082                	ret
      p->ofile[fd] = f;
    80004f32:	01a50793          	addi	a5,a0,26
    80004f36:	078e                	slli	a5,a5,0x3
    80004f38:	963e                	add	a2,a2,a5
    80004f3a:	e204                	sd	s1,0(a2)
      return fd;
    80004f3c:	b7f5                	j	80004f28 <fdalloc+0x2c>

0000000080004f3e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f3e:	715d                	addi	sp,sp,-80
    80004f40:	e486                	sd	ra,72(sp)
    80004f42:	e0a2                	sd	s0,64(sp)
    80004f44:	fc26                	sd	s1,56(sp)
    80004f46:	f84a                	sd	s2,48(sp)
    80004f48:	f44e                	sd	s3,40(sp)
    80004f4a:	f052                	sd	s4,32(sp)
    80004f4c:	ec56                	sd	s5,24(sp)
    80004f4e:	0880                	addi	s0,sp,80
    80004f50:	89ae                	mv	s3,a1
    80004f52:	8ab2                	mv	s5,a2
    80004f54:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f56:	fb040593          	addi	a1,s0,-80
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	e48080e7          	jalr	-440(ra) # 80003da2 <nameiparent>
    80004f62:	892a                	mv	s2,a0
    80004f64:	12050e63          	beqz	a0,800050a0 <create+0x162>
    return 0;

  ilock(dp);
    80004f68:	ffffe097          	auipc	ra,0xffffe
    80004f6c:	66c080e7          	jalr	1644(ra) # 800035d4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f70:	4601                	li	a2,0
    80004f72:	fb040593          	addi	a1,s0,-80
    80004f76:	854a                	mv	a0,s2
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	b3a080e7          	jalr	-1222(ra) # 80003ab2 <dirlookup>
    80004f80:	84aa                	mv	s1,a0
    80004f82:	c921                	beqz	a0,80004fd2 <create+0x94>
    iunlockput(dp);
    80004f84:	854a                	mv	a0,s2
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	8b0080e7          	jalr	-1872(ra) # 80003836 <iunlockput>
    ilock(ip);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	ffffe097          	auipc	ra,0xffffe
    80004f94:	644080e7          	jalr	1604(ra) # 800035d4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f98:	2981                	sext.w	s3,s3
    80004f9a:	4789                	li	a5,2
    80004f9c:	02f99463          	bne	s3,a5,80004fc4 <create+0x86>
    80004fa0:	0444d783          	lhu	a5,68(s1)
    80004fa4:	37f9                	addiw	a5,a5,-2
    80004fa6:	17c2                	slli	a5,a5,0x30
    80004fa8:	93c1                	srli	a5,a5,0x30
    80004faa:	4705                	li	a4,1
    80004fac:	00f76c63          	bltu	a4,a5,80004fc4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	60a6                	ld	ra,72(sp)
    80004fb4:	6406                	ld	s0,64(sp)
    80004fb6:	74e2                	ld	s1,56(sp)
    80004fb8:	7942                	ld	s2,48(sp)
    80004fba:	79a2                	ld	s3,40(sp)
    80004fbc:	7a02                	ld	s4,32(sp)
    80004fbe:	6ae2                	ld	s5,24(sp)
    80004fc0:	6161                	addi	sp,sp,80
    80004fc2:	8082                	ret
    iunlockput(ip);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	870080e7          	jalr	-1936(ra) # 80003836 <iunlockput>
    return 0;
    80004fce:	4481                	li	s1,0
    80004fd0:	b7c5                	j	80004fb0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fd2:	85ce                	mv	a1,s3
    80004fd4:	00092503          	lw	a0,0(s2)
    80004fd8:	ffffe097          	auipc	ra,0xffffe
    80004fdc:	464080e7          	jalr	1124(ra) # 8000343c <ialloc>
    80004fe0:	84aa                	mv	s1,a0
    80004fe2:	c521                	beqz	a0,8000502a <create+0xec>
  ilock(ip);
    80004fe4:	ffffe097          	auipc	ra,0xffffe
    80004fe8:	5f0080e7          	jalr	1520(ra) # 800035d4 <ilock>
  ip->major = major;
    80004fec:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004ff0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004ff4:	4a05                	li	s4,1
    80004ff6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	ffffe097          	auipc	ra,0xffffe
    80005000:	50e080e7          	jalr	1294(ra) # 8000350a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005004:	2981                	sext.w	s3,s3
    80005006:	03498a63          	beq	s3,s4,8000503a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000500a:	40d0                	lw	a2,4(s1)
    8000500c:	fb040593          	addi	a1,s0,-80
    80005010:	854a                	mv	a0,s2
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	cb0080e7          	jalr	-848(ra) # 80003cc2 <dirlink>
    8000501a:	06054b63          	bltz	a0,80005090 <create+0x152>
  iunlockput(dp);
    8000501e:	854a                	mv	a0,s2
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	816080e7          	jalr	-2026(ra) # 80003836 <iunlockput>
  return ip;
    80005028:	b761                	j	80004fb0 <create+0x72>
    panic("create: ialloc");
    8000502a:	00003517          	auipc	a0,0x3
    8000502e:	6ae50513          	addi	a0,a0,1710 # 800086d8 <syscalls+0x2b0>
    80005032:	ffffb097          	auipc	ra,0xffffb
    80005036:	510080e7          	jalr	1296(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000503a:	04a95783          	lhu	a5,74(s2)
    8000503e:	2785                	addiw	a5,a5,1
    80005040:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005044:	854a                	mv	a0,s2
    80005046:	ffffe097          	auipc	ra,0xffffe
    8000504a:	4c4080e7          	jalr	1220(ra) # 8000350a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000504e:	40d0                	lw	a2,4(s1)
    80005050:	00003597          	auipc	a1,0x3
    80005054:	69858593          	addi	a1,a1,1688 # 800086e8 <syscalls+0x2c0>
    80005058:	8526                	mv	a0,s1
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	c68080e7          	jalr	-920(ra) # 80003cc2 <dirlink>
    80005062:	00054f63          	bltz	a0,80005080 <create+0x142>
    80005066:	00492603          	lw	a2,4(s2)
    8000506a:	00003597          	auipc	a1,0x3
    8000506e:	68658593          	addi	a1,a1,1670 # 800086f0 <syscalls+0x2c8>
    80005072:	8526                	mv	a0,s1
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	c4e080e7          	jalr	-946(ra) # 80003cc2 <dirlink>
    8000507c:	f80557e3          	bgez	a0,8000500a <create+0xcc>
      panic("create dots");
    80005080:	00003517          	auipc	a0,0x3
    80005084:	67850513          	addi	a0,a0,1656 # 800086f8 <syscalls+0x2d0>
    80005088:	ffffb097          	auipc	ra,0xffffb
    8000508c:	4ba080e7          	jalr	1210(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005090:	00003517          	auipc	a0,0x3
    80005094:	67850513          	addi	a0,a0,1656 # 80008708 <syscalls+0x2e0>
    80005098:	ffffb097          	auipc	ra,0xffffb
    8000509c:	4aa080e7          	jalr	1194(ra) # 80000542 <panic>
    return 0;
    800050a0:	84aa                	mv	s1,a0
    800050a2:	b739                	j	80004fb0 <create+0x72>

00000000800050a4 <sys_dup>:
{
    800050a4:	7179                	addi	sp,sp,-48
    800050a6:	f406                	sd	ra,40(sp)
    800050a8:	f022                	sd	s0,32(sp)
    800050aa:	ec26                	sd	s1,24(sp)
    800050ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050ae:	fd840613          	addi	a2,s0,-40
    800050b2:	4581                	li	a1,0
    800050b4:	4501                	li	a0,0
    800050b6:	00000097          	auipc	ra,0x0
    800050ba:	dde080e7          	jalr	-546(ra) # 80004e94 <argfd>
    return -1;
    800050be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050c0:	02054363          	bltz	a0,800050e6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050c4:	fd843503          	ld	a0,-40(s0)
    800050c8:	00000097          	auipc	ra,0x0
    800050cc:	e34080e7          	jalr	-460(ra) # 80004efc <fdalloc>
    800050d0:	84aa                	mv	s1,a0
    return -1;
    800050d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050d4:	00054963          	bltz	a0,800050e6 <sys_dup+0x42>
  filedup(f);
    800050d8:	fd843503          	ld	a0,-40(s0)
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	338080e7          	jalr	824(ra) # 80004414 <filedup>
  return fd;
    800050e4:	87a6                	mv	a5,s1
}
    800050e6:	853e                	mv	a0,a5
    800050e8:	70a2                	ld	ra,40(sp)
    800050ea:	7402                	ld	s0,32(sp)
    800050ec:	64e2                	ld	s1,24(sp)
    800050ee:	6145                	addi	sp,sp,48
    800050f0:	8082                	ret

00000000800050f2 <sys_read>:
{
    800050f2:	7179                	addi	sp,sp,-48
    800050f4:	f406                	sd	ra,40(sp)
    800050f6:	f022                	sd	s0,32(sp)
    800050f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050fa:	fe840613          	addi	a2,s0,-24
    800050fe:	4581                	li	a1,0
    80005100:	4501                	li	a0,0
    80005102:	00000097          	auipc	ra,0x0
    80005106:	d92080e7          	jalr	-622(ra) # 80004e94 <argfd>
    return -1;
    8000510a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000510c:	04054163          	bltz	a0,8000514e <sys_read+0x5c>
    80005110:	fe440593          	addi	a1,s0,-28
    80005114:	4509                	li	a0,2
    80005116:	ffffe097          	auipc	ra,0xffffe
    8000511a:	94c080e7          	jalr	-1716(ra) # 80002a62 <argint>
    return -1;
    8000511e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005120:	02054763          	bltz	a0,8000514e <sys_read+0x5c>
    80005124:	fd840593          	addi	a1,s0,-40
    80005128:	4505                	li	a0,1
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	95a080e7          	jalr	-1702(ra) # 80002a84 <argaddr>
    return -1;
    80005132:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005134:	00054d63          	bltz	a0,8000514e <sys_read+0x5c>
  return fileread(f, p, n);
    80005138:	fe442603          	lw	a2,-28(s0)
    8000513c:	fd843583          	ld	a1,-40(s0)
    80005140:	fe843503          	ld	a0,-24(s0)
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	45c080e7          	jalr	1116(ra) # 800045a0 <fileread>
    8000514c:	87aa                	mv	a5,a0
}
    8000514e:	853e                	mv	a0,a5
    80005150:	70a2                	ld	ra,40(sp)
    80005152:	7402                	ld	s0,32(sp)
    80005154:	6145                	addi	sp,sp,48
    80005156:	8082                	ret

0000000080005158 <sys_write>:
{
    80005158:	7179                	addi	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005160:	fe840613          	addi	a2,s0,-24
    80005164:	4581                	li	a1,0
    80005166:	4501                	li	a0,0
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	d2c080e7          	jalr	-724(ra) # 80004e94 <argfd>
    return -1;
    80005170:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005172:	04054163          	bltz	a0,800051b4 <sys_write+0x5c>
    80005176:	fe440593          	addi	a1,s0,-28
    8000517a:	4509                	li	a0,2
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	8e6080e7          	jalr	-1818(ra) # 80002a62 <argint>
    return -1;
    80005184:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005186:	02054763          	bltz	a0,800051b4 <sys_write+0x5c>
    8000518a:	fd840593          	addi	a1,s0,-40
    8000518e:	4505                	li	a0,1
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	8f4080e7          	jalr	-1804(ra) # 80002a84 <argaddr>
    return -1;
    80005198:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000519a:	00054d63          	bltz	a0,800051b4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000519e:	fe442603          	lw	a2,-28(s0)
    800051a2:	fd843583          	ld	a1,-40(s0)
    800051a6:	fe843503          	ld	a0,-24(s0)
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	4b8080e7          	jalr	1208(ra) # 80004662 <filewrite>
    800051b2:	87aa                	mv	a5,a0
}
    800051b4:	853e                	mv	a0,a5
    800051b6:	70a2                	ld	ra,40(sp)
    800051b8:	7402                	ld	s0,32(sp)
    800051ba:	6145                	addi	sp,sp,48
    800051bc:	8082                	ret

00000000800051be <sys_close>:
{
    800051be:	1101                	addi	sp,sp,-32
    800051c0:	ec06                	sd	ra,24(sp)
    800051c2:	e822                	sd	s0,16(sp)
    800051c4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051c6:	fe040613          	addi	a2,s0,-32
    800051ca:	fec40593          	addi	a1,s0,-20
    800051ce:	4501                	li	a0,0
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	cc4080e7          	jalr	-828(ra) # 80004e94 <argfd>
    return -1;
    800051d8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051da:	02054463          	bltz	a0,80005202 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	7ec080e7          	jalr	2028(ra) # 800019ca <myproc>
    800051e6:	fec42783          	lw	a5,-20(s0)
    800051ea:	07e9                	addi	a5,a5,26
    800051ec:	078e                	slli	a5,a5,0x3
    800051ee:	97aa                	add	a5,a5,a0
    800051f0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051f4:	fe043503          	ld	a0,-32(s0)
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	26e080e7          	jalr	622(ra) # 80004466 <fileclose>
  return 0;
    80005200:	4781                	li	a5,0
}
    80005202:	853e                	mv	a0,a5
    80005204:	60e2                	ld	ra,24(sp)
    80005206:	6442                	ld	s0,16(sp)
    80005208:	6105                	addi	sp,sp,32
    8000520a:	8082                	ret

000000008000520c <sys_fstat>:
{
    8000520c:	1101                	addi	sp,sp,-32
    8000520e:	ec06                	sd	ra,24(sp)
    80005210:	e822                	sd	s0,16(sp)
    80005212:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005214:	fe840613          	addi	a2,s0,-24
    80005218:	4581                	li	a1,0
    8000521a:	4501                	li	a0,0
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	c78080e7          	jalr	-904(ra) # 80004e94 <argfd>
    return -1;
    80005224:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005226:	02054563          	bltz	a0,80005250 <sys_fstat+0x44>
    8000522a:	fe040593          	addi	a1,s0,-32
    8000522e:	4505                	li	a0,1
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	854080e7          	jalr	-1964(ra) # 80002a84 <argaddr>
    return -1;
    80005238:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000523a:	00054b63          	bltz	a0,80005250 <sys_fstat+0x44>
  return filestat(f, st);
    8000523e:	fe043583          	ld	a1,-32(s0)
    80005242:	fe843503          	ld	a0,-24(s0)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	2e8080e7          	jalr	744(ra) # 8000452e <filestat>
    8000524e:	87aa                	mv	a5,a0
}
    80005250:	853e                	mv	a0,a5
    80005252:	60e2                	ld	ra,24(sp)
    80005254:	6442                	ld	s0,16(sp)
    80005256:	6105                	addi	sp,sp,32
    80005258:	8082                	ret

000000008000525a <sys_link>:
{
    8000525a:	7169                	addi	sp,sp,-304
    8000525c:	f606                	sd	ra,296(sp)
    8000525e:	f222                	sd	s0,288(sp)
    80005260:	ee26                	sd	s1,280(sp)
    80005262:	ea4a                	sd	s2,272(sp)
    80005264:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005266:	08000613          	li	a2,128
    8000526a:	ed040593          	addi	a1,s0,-304
    8000526e:	4501                	li	a0,0
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	836080e7          	jalr	-1994(ra) # 80002aa6 <argstr>
    return -1;
    80005278:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000527a:	10054e63          	bltz	a0,80005396 <sys_link+0x13c>
    8000527e:	08000613          	li	a2,128
    80005282:	f5040593          	addi	a1,s0,-176
    80005286:	4505                	li	a0,1
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	81e080e7          	jalr	-2018(ra) # 80002aa6 <argstr>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005292:	10054263          	bltz	a0,80005396 <sys_link+0x13c>
  begin_op();
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	cfe080e7          	jalr	-770(ra) # 80003f94 <begin_op>
  if((ip = namei(old)) == 0){
    8000529e:	ed040513          	addi	a0,s0,-304
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	ae2080e7          	jalr	-1310(ra) # 80003d84 <namei>
    800052aa:	84aa                	mv	s1,a0
    800052ac:	c551                	beqz	a0,80005338 <sys_link+0xde>
  ilock(ip);
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	326080e7          	jalr	806(ra) # 800035d4 <ilock>
  if(ip->type == T_DIR){
    800052b6:	04449703          	lh	a4,68(s1)
    800052ba:	4785                	li	a5,1
    800052bc:	08f70463          	beq	a4,a5,80005344 <sys_link+0xea>
  ip->nlink++;
    800052c0:	04a4d783          	lhu	a5,74(s1)
    800052c4:	2785                	addiw	a5,a5,1
    800052c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052ca:	8526                	mv	a0,s1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	23e080e7          	jalr	574(ra) # 8000350a <iupdate>
  iunlock(ip);
    800052d4:	8526                	mv	a0,s1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	3c0080e7          	jalr	960(ra) # 80003696 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052de:	fd040593          	addi	a1,s0,-48
    800052e2:	f5040513          	addi	a0,s0,-176
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	abc080e7          	jalr	-1348(ra) # 80003da2 <nameiparent>
    800052ee:	892a                	mv	s2,a0
    800052f0:	c935                	beqz	a0,80005364 <sys_link+0x10a>
  ilock(dp);
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	2e2080e7          	jalr	738(ra) # 800035d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052fa:	00092703          	lw	a4,0(s2)
    800052fe:	409c                	lw	a5,0(s1)
    80005300:	04f71d63          	bne	a4,a5,8000535a <sys_link+0x100>
    80005304:	40d0                	lw	a2,4(s1)
    80005306:	fd040593          	addi	a1,s0,-48
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	9b6080e7          	jalr	-1610(ra) # 80003cc2 <dirlink>
    80005314:	04054363          	bltz	a0,8000535a <sys_link+0x100>
  iunlockput(dp);
    80005318:	854a                	mv	a0,s2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	51c080e7          	jalr	1308(ra) # 80003836 <iunlockput>
  iput(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	46a080e7          	jalr	1130(ra) # 8000378e <iput>
  end_op();
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	ce8080e7          	jalr	-792(ra) # 80004014 <end_op>
  return 0;
    80005334:	4781                	li	a5,0
    80005336:	a085                	j	80005396 <sys_link+0x13c>
    end_op();
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	cdc080e7          	jalr	-804(ra) # 80004014 <end_op>
    return -1;
    80005340:	57fd                	li	a5,-1
    80005342:	a891                	j	80005396 <sys_link+0x13c>
    iunlockput(ip);
    80005344:	8526                	mv	a0,s1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	4f0080e7          	jalr	1264(ra) # 80003836 <iunlockput>
    end_op();
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	cc6080e7          	jalr	-826(ra) # 80004014 <end_op>
    return -1;
    80005356:	57fd                	li	a5,-1
    80005358:	a83d                	j	80005396 <sys_link+0x13c>
    iunlockput(dp);
    8000535a:	854a                	mv	a0,s2
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	4da080e7          	jalr	1242(ra) # 80003836 <iunlockput>
  ilock(ip);
    80005364:	8526                	mv	a0,s1
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	26e080e7          	jalr	622(ra) # 800035d4 <ilock>
  ip->nlink--;
    8000536e:	04a4d783          	lhu	a5,74(s1)
    80005372:	37fd                	addiw	a5,a5,-1
    80005374:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	190080e7          	jalr	400(ra) # 8000350a <iupdate>
  iunlockput(ip);
    80005382:	8526                	mv	a0,s1
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	4b2080e7          	jalr	1202(ra) # 80003836 <iunlockput>
  end_op();
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	c88080e7          	jalr	-888(ra) # 80004014 <end_op>
  return -1;
    80005394:	57fd                	li	a5,-1
}
    80005396:	853e                	mv	a0,a5
    80005398:	70b2                	ld	ra,296(sp)
    8000539a:	7412                	ld	s0,288(sp)
    8000539c:	64f2                	ld	s1,280(sp)
    8000539e:	6952                	ld	s2,272(sp)
    800053a0:	6155                	addi	sp,sp,304
    800053a2:	8082                	ret

00000000800053a4 <sys_unlink>:
{
    800053a4:	7151                	addi	sp,sp,-240
    800053a6:	f586                	sd	ra,232(sp)
    800053a8:	f1a2                	sd	s0,224(sp)
    800053aa:	eda6                	sd	s1,216(sp)
    800053ac:	e9ca                	sd	s2,208(sp)
    800053ae:	e5ce                	sd	s3,200(sp)
    800053b0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b2:	08000613          	li	a2,128
    800053b6:	f3040593          	addi	a1,s0,-208
    800053ba:	4501                	li	a0,0
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	6ea080e7          	jalr	1770(ra) # 80002aa6 <argstr>
    800053c4:	18054163          	bltz	a0,80005546 <sys_unlink+0x1a2>
  begin_op();
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	bcc080e7          	jalr	-1076(ra) # 80003f94 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053d0:	fb040593          	addi	a1,s0,-80
    800053d4:	f3040513          	addi	a0,s0,-208
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	9ca080e7          	jalr	-1590(ra) # 80003da2 <nameiparent>
    800053e0:	84aa                	mv	s1,a0
    800053e2:	c979                	beqz	a0,800054b8 <sys_unlink+0x114>
  ilock(dp);
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	1f0080e7          	jalr	496(ra) # 800035d4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053ec:	00003597          	auipc	a1,0x3
    800053f0:	2fc58593          	addi	a1,a1,764 # 800086e8 <syscalls+0x2c0>
    800053f4:	fb040513          	addi	a0,s0,-80
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	6a0080e7          	jalr	1696(ra) # 80003a98 <namecmp>
    80005400:	14050a63          	beqz	a0,80005554 <sys_unlink+0x1b0>
    80005404:	00003597          	auipc	a1,0x3
    80005408:	2ec58593          	addi	a1,a1,748 # 800086f0 <syscalls+0x2c8>
    8000540c:	fb040513          	addi	a0,s0,-80
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	688080e7          	jalr	1672(ra) # 80003a98 <namecmp>
    80005418:	12050e63          	beqz	a0,80005554 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000541c:	f2c40613          	addi	a2,s0,-212
    80005420:	fb040593          	addi	a1,s0,-80
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	68c080e7          	jalr	1676(ra) # 80003ab2 <dirlookup>
    8000542e:	892a                	mv	s2,a0
    80005430:	12050263          	beqz	a0,80005554 <sys_unlink+0x1b0>
  ilock(ip);
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	1a0080e7          	jalr	416(ra) # 800035d4 <ilock>
  if(ip->nlink < 1)
    8000543c:	04a91783          	lh	a5,74(s2)
    80005440:	08f05263          	blez	a5,800054c4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005444:	04491703          	lh	a4,68(s2)
    80005448:	4785                	li	a5,1
    8000544a:	08f70563          	beq	a4,a5,800054d4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000544e:	4641                	li	a2,16
    80005450:	4581                	li	a1,0
    80005452:	fc040513          	addi	a0,s0,-64
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	8a4080e7          	jalr	-1884(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000545e:	4741                	li	a4,16
    80005460:	f2c42683          	lw	a3,-212(s0)
    80005464:	fc040613          	addi	a2,s0,-64
    80005468:	4581                	li	a1,0
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	512080e7          	jalr	1298(ra) # 8000397e <writei>
    80005474:	47c1                	li	a5,16
    80005476:	0af51563          	bne	a0,a5,80005520 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000547a:	04491703          	lh	a4,68(s2)
    8000547e:	4785                	li	a5,1
    80005480:	0af70863          	beq	a4,a5,80005530 <sys_unlink+0x18c>
  iunlockput(dp);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	3b0080e7          	jalr	944(ra) # 80003836 <iunlockput>
  ip->nlink--;
    8000548e:	04a95783          	lhu	a5,74(s2)
    80005492:	37fd                	addiw	a5,a5,-1
    80005494:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005498:	854a                	mv	a0,s2
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	070080e7          	jalr	112(ra) # 8000350a <iupdate>
  iunlockput(ip);
    800054a2:	854a                	mv	a0,s2
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	392080e7          	jalr	914(ra) # 80003836 <iunlockput>
  end_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	b68080e7          	jalr	-1176(ra) # 80004014 <end_op>
  return 0;
    800054b4:	4501                	li	a0,0
    800054b6:	a84d                	j	80005568 <sys_unlink+0x1c4>
    end_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	b5c080e7          	jalr	-1188(ra) # 80004014 <end_op>
    return -1;
    800054c0:	557d                	li	a0,-1
    800054c2:	a05d                	j	80005568 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054c4:	00003517          	auipc	a0,0x3
    800054c8:	25450513          	addi	a0,a0,596 # 80008718 <syscalls+0x2f0>
    800054cc:	ffffb097          	auipc	ra,0xffffb
    800054d0:	076080e7          	jalr	118(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054d4:	04c92703          	lw	a4,76(s2)
    800054d8:	02000793          	li	a5,32
    800054dc:	f6e7f9e3          	bgeu	a5,a4,8000544e <sys_unlink+0xaa>
    800054e0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054e4:	4741                	li	a4,16
    800054e6:	86ce                	mv	a3,s3
    800054e8:	f1840613          	addi	a2,s0,-232
    800054ec:	4581                	li	a1,0
    800054ee:	854a                	mv	a0,s2
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	398080e7          	jalr	920(ra) # 80003888 <readi>
    800054f8:	47c1                	li	a5,16
    800054fa:	00f51b63          	bne	a0,a5,80005510 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054fe:	f1845783          	lhu	a5,-232(s0)
    80005502:	e7a1                	bnez	a5,8000554a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005504:	29c1                	addiw	s3,s3,16
    80005506:	04c92783          	lw	a5,76(s2)
    8000550a:	fcf9ede3          	bltu	s3,a5,800054e4 <sys_unlink+0x140>
    8000550e:	b781                	j	8000544e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005510:	00003517          	auipc	a0,0x3
    80005514:	22050513          	addi	a0,a0,544 # 80008730 <syscalls+0x308>
    80005518:	ffffb097          	auipc	ra,0xffffb
    8000551c:	02a080e7          	jalr	42(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005520:	00003517          	auipc	a0,0x3
    80005524:	22850513          	addi	a0,a0,552 # 80008748 <syscalls+0x320>
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	01a080e7          	jalr	26(ra) # 80000542 <panic>
    dp->nlink--;
    80005530:	04a4d783          	lhu	a5,74(s1)
    80005534:	37fd                	addiw	a5,a5,-1
    80005536:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	fce080e7          	jalr	-50(ra) # 8000350a <iupdate>
    80005544:	b781                	j	80005484 <sys_unlink+0xe0>
    return -1;
    80005546:	557d                	li	a0,-1
    80005548:	a005                	j	80005568 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000554a:	854a                	mv	a0,s2
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	2ea080e7          	jalr	746(ra) # 80003836 <iunlockput>
  iunlockput(dp);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	2e0080e7          	jalr	736(ra) # 80003836 <iunlockput>
  end_op();
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	ab6080e7          	jalr	-1354(ra) # 80004014 <end_op>
  return -1;
    80005566:	557d                	li	a0,-1
}
    80005568:	70ae                	ld	ra,232(sp)
    8000556a:	740e                	ld	s0,224(sp)
    8000556c:	64ee                	ld	s1,216(sp)
    8000556e:	694e                	ld	s2,208(sp)
    80005570:	69ae                	ld	s3,200(sp)
    80005572:	616d                	addi	sp,sp,240
    80005574:	8082                	ret

0000000080005576 <sys_open>:

uint64
sys_open(void)
{
    80005576:	7131                	addi	sp,sp,-192
    80005578:	fd06                	sd	ra,184(sp)
    8000557a:	f922                	sd	s0,176(sp)
    8000557c:	f526                	sd	s1,168(sp)
    8000557e:	f14a                	sd	s2,160(sp)
    80005580:	ed4e                	sd	s3,152(sp)
    80005582:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005584:	08000613          	li	a2,128
    80005588:	f5040593          	addi	a1,s0,-176
    8000558c:	4501                	li	a0,0
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	518080e7          	jalr	1304(ra) # 80002aa6 <argstr>
    return -1;
    80005596:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005598:	0c054163          	bltz	a0,8000565a <sys_open+0xe4>
    8000559c:	f4c40593          	addi	a1,s0,-180
    800055a0:	4505                	li	a0,1
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	4c0080e7          	jalr	1216(ra) # 80002a62 <argint>
    800055aa:	0a054863          	bltz	a0,8000565a <sys_open+0xe4>

  begin_op();
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	9e6080e7          	jalr	-1562(ra) # 80003f94 <begin_op>

  if(omode & O_CREATE){
    800055b6:	f4c42783          	lw	a5,-180(s0)
    800055ba:	2007f793          	andi	a5,a5,512
    800055be:	cbdd                	beqz	a5,80005674 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055c0:	4681                	li	a3,0
    800055c2:	4601                	li	a2,0
    800055c4:	4589                	li	a1,2
    800055c6:	f5040513          	addi	a0,s0,-176
    800055ca:	00000097          	auipc	ra,0x0
    800055ce:	974080e7          	jalr	-1676(ra) # 80004f3e <create>
    800055d2:	892a                	mv	s2,a0
    if(ip == 0){
    800055d4:	c959                	beqz	a0,8000566a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055d6:	04491703          	lh	a4,68(s2)
    800055da:	478d                	li	a5,3
    800055dc:	00f71763          	bne	a4,a5,800055ea <sys_open+0x74>
    800055e0:	04695703          	lhu	a4,70(s2)
    800055e4:	47a5                	li	a5,9
    800055e6:	0ce7ec63          	bltu	a5,a4,800056be <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	dc0080e7          	jalr	-576(ra) # 800043aa <filealloc>
    800055f2:	89aa                	mv	s3,a0
    800055f4:	10050263          	beqz	a0,800056f8 <sys_open+0x182>
    800055f8:	00000097          	auipc	ra,0x0
    800055fc:	904080e7          	jalr	-1788(ra) # 80004efc <fdalloc>
    80005600:	84aa                	mv	s1,a0
    80005602:	0e054663          	bltz	a0,800056ee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005606:	04491703          	lh	a4,68(s2)
    8000560a:	478d                	li	a5,3
    8000560c:	0cf70463          	beq	a4,a5,800056d4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005610:	4789                	li	a5,2
    80005612:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005616:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000561a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000561e:	f4c42783          	lw	a5,-180(s0)
    80005622:	0017c713          	xori	a4,a5,1
    80005626:	8b05                	andi	a4,a4,1
    80005628:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000562c:	0037f713          	andi	a4,a5,3
    80005630:	00e03733          	snez	a4,a4
    80005634:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005638:	4007f793          	andi	a5,a5,1024
    8000563c:	c791                	beqz	a5,80005648 <sys_open+0xd2>
    8000563e:	04491703          	lh	a4,68(s2)
    80005642:	4789                	li	a5,2
    80005644:	08f70f63          	beq	a4,a5,800056e2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005648:	854a                	mv	a0,s2
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	04c080e7          	jalr	76(ra) # 80003696 <iunlock>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	9c2080e7          	jalr	-1598(ra) # 80004014 <end_op>

  return fd;
}
    8000565a:	8526                	mv	a0,s1
    8000565c:	70ea                	ld	ra,184(sp)
    8000565e:	744a                	ld	s0,176(sp)
    80005660:	74aa                	ld	s1,168(sp)
    80005662:	790a                	ld	s2,160(sp)
    80005664:	69ea                	ld	s3,152(sp)
    80005666:	6129                	addi	sp,sp,192
    80005668:	8082                	ret
      end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	9aa080e7          	jalr	-1622(ra) # 80004014 <end_op>
      return -1;
    80005672:	b7e5                	j	8000565a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005674:	f5040513          	addi	a0,s0,-176
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	70c080e7          	jalr	1804(ra) # 80003d84 <namei>
    80005680:	892a                	mv	s2,a0
    80005682:	c905                	beqz	a0,800056b2 <sys_open+0x13c>
    ilock(ip);
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	f50080e7          	jalr	-176(ra) # 800035d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000568c:	04491703          	lh	a4,68(s2)
    80005690:	4785                	li	a5,1
    80005692:	f4f712e3          	bne	a4,a5,800055d6 <sys_open+0x60>
    80005696:	f4c42783          	lw	a5,-180(s0)
    8000569a:	dba1                	beqz	a5,800055ea <sys_open+0x74>
      iunlockput(ip);
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	198080e7          	jalr	408(ra) # 80003836 <iunlockput>
      end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	96e080e7          	jalr	-1682(ra) # 80004014 <end_op>
      return -1;
    800056ae:	54fd                	li	s1,-1
    800056b0:	b76d                	j	8000565a <sys_open+0xe4>
      end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	962080e7          	jalr	-1694(ra) # 80004014 <end_op>
      return -1;
    800056ba:	54fd                	li	s1,-1
    800056bc:	bf79                	j	8000565a <sys_open+0xe4>
    iunlockput(ip);
    800056be:	854a                	mv	a0,s2
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	176080e7          	jalr	374(ra) # 80003836 <iunlockput>
    end_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	94c080e7          	jalr	-1716(ra) # 80004014 <end_op>
    return -1;
    800056d0:	54fd                	li	s1,-1
    800056d2:	b761                	j	8000565a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056d4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056d8:	04691783          	lh	a5,70(s2)
    800056dc:	02f99223          	sh	a5,36(s3)
    800056e0:	bf2d                	j	8000561a <sys_open+0xa4>
    itrunc(ip);
    800056e2:	854a                	mv	a0,s2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	ffe080e7          	jalr	-2(ra) # 800036e2 <itrunc>
    800056ec:	bfb1                	j	80005648 <sys_open+0xd2>
      fileclose(f);
    800056ee:	854e                	mv	a0,s3
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	d76080e7          	jalr	-650(ra) # 80004466 <fileclose>
    iunlockput(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	13c080e7          	jalr	316(ra) # 80003836 <iunlockput>
    end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	912080e7          	jalr	-1774(ra) # 80004014 <end_op>
    return -1;
    8000570a:	54fd                	li	s1,-1
    8000570c:	b7b9                	j	8000565a <sys_open+0xe4>

000000008000570e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000570e:	7175                	addi	sp,sp,-144
    80005710:	e506                	sd	ra,136(sp)
    80005712:	e122                	sd	s0,128(sp)
    80005714:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	87e080e7          	jalr	-1922(ra) # 80003f94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000571e:	08000613          	li	a2,128
    80005722:	f7040593          	addi	a1,s0,-144
    80005726:	4501                	li	a0,0
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	37e080e7          	jalr	894(ra) # 80002aa6 <argstr>
    80005730:	02054963          	bltz	a0,80005762 <sys_mkdir+0x54>
    80005734:	4681                	li	a3,0
    80005736:	4601                	li	a2,0
    80005738:	4585                	li	a1,1
    8000573a:	f7040513          	addi	a0,s0,-144
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	800080e7          	jalr	-2048(ra) # 80004f3e <create>
    80005746:	cd11                	beqz	a0,80005762 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	0ee080e7          	jalr	238(ra) # 80003836 <iunlockput>
  end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	8c4080e7          	jalr	-1852(ra) # 80004014 <end_op>
  return 0;
    80005758:	4501                	li	a0,0
}
    8000575a:	60aa                	ld	ra,136(sp)
    8000575c:	640a                	ld	s0,128(sp)
    8000575e:	6149                	addi	sp,sp,144
    80005760:	8082                	ret
    end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	8b2080e7          	jalr	-1870(ra) # 80004014 <end_op>
    return -1;
    8000576a:	557d                	li	a0,-1
    8000576c:	b7fd                	j	8000575a <sys_mkdir+0x4c>

000000008000576e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000576e:	7135                	addi	sp,sp,-160
    80005770:	ed06                	sd	ra,152(sp)
    80005772:	e922                	sd	s0,144(sp)
    80005774:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	81e080e7          	jalr	-2018(ra) # 80003f94 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000577e:	08000613          	li	a2,128
    80005782:	f7040593          	addi	a1,s0,-144
    80005786:	4501                	li	a0,0
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	31e080e7          	jalr	798(ra) # 80002aa6 <argstr>
    80005790:	04054a63          	bltz	a0,800057e4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005794:	f6c40593          	addi	a1,s0,-148
    80005798:	4505                	li	a0,1
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	2c8080e7          	jalr	712(ra) # 80002a62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057a2:	04054163          	bltz	a0,800057e4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057a6:	f6840593          	addi	a1,s0,-152
    800057aa:	4509                	li	a0,2
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	2b6080e7          	jalr	694(ra) # 80002a62 <argint>
     argint(1, &major) < 0 ||
    800057b4:	02054863          	bltz	a0,800057e4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057b8:	f6841683          	lh	a3,-152(s0)
    800057bc:	f6c41603          	lh	a2,-148(s0)
    800057c0:	458d                	li	a1,3
    800057c2:	f7040513          	addi	a0,s0,-144
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	778080e7          	jalr	1912(ra) # 80004f3e <create>
     argint(2, &minor) < 0 ||
    800057ce:	c919                	beqz	a0,800057e4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	066080e7          	jalr	102(ra) # 80003836 <iunlockput>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	83c080e7          	jalr	-1988(ra) # 80004014 <end_op>
  return 0;
    800057e0:	4501                	li	a0,0
    800057e2:	a031                	j	800057ee <sys_mknod+0x80>
    end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	830080e7          	jalr	-2000(ra) # 80004014 <end_op>
    return -1;
    800057ec:	557d                	li	a0,-1
}
    800057ee:	60ea                	ld	ra,152(sp)
    800057f0:	644a                	ld	s0,144(sp)
    800057f2:	610d                	addi	sp,sp,160
    800057f4:	8082                	ret

00000000800057f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057f6:	7135                	addi	sp,sp,-160
    800057f8:	ed06                	sd	ra,152(sp)
    800057fa:	e922                	sd	s0,144(sp)
    800057fc:	e526                	sd	s1,136(sp)
    800057fe:	e14a                	sd	s2,128(sp)
    80005800:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005802:	ffffc097          	auipc	ra,0xffffc
    80005806:	1c8080e7          	jalr	456(ra) # 800019ca <myproc>
    8000580a:	892a                	mv	s2,a0
  
  begin_op();
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	788080e7          	jalr	1928(ra) # 80003f94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005814:	08000613          	li	a2,128
    80005818:	f6040593          	addi	a1,s0,-160
    8000581c:	4501                	li	a0,0
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	288080e7          	jalr	648(ra) # 80002aa6 <argstr>
    80005826:	04054b63          	bltz	a0,8000587c <sys_chdir+0x86>
    8000582a:	f6040513          	addi	a0,s0,-160
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	556080e7          	jalr	1366(ra) # 80003d84 <namei>
    80005836:	84aa                	mv	s1,a0
    80005838:	c131                	beqz	a0,8000587c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	d9a080e7          	jalr	-614(ra) # 800035d4 <ilock>
  if(ip->type != T_DIR){
    80005842:	04449703          	lh	a4,68(s1)
    80005846:	4785                	li	a5,1
    80005848:	04f71063          	bne	a4,a5,80005888 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	e48080e7          	jalr	-440(ra) # 80003696 <iunlock>
  iput(p->cwd);
    80005856:	15093503          	ld	a0,336(s2)
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	f34080e7          	jalr	-204(ra) # 8000378e <iput>
  end_op();
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	7b2080e7          	jalr	1970(ra) # 80004014 <end_op>
  p->cwd = ip;
    8000586a:	14993823          	sd	s1,336(s2)
  return 0;
    8000586e:	4501                	li	a0,0
}
    80005870:	60ea                	ld	ra,152(sp)
    80005872:	644a                	ld	s0,144(sp)
    80005874:	64aa                	ld	s1,136(sp)
    80005876:	690a                	ld	s2,128(sp)
    80005878:	610d                	addi	sp,sp,160
    8000587a:	8082                	ret
    end_op();
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	798080e7          	jalr	1944(ra) # 80004014 <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	b7ed                	j	80005870 <sys_chdir+0x7a>
    iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	fac080e7          	jalr	-84(ra) # 80003836 <iunlockput>
    end_op();
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	782080e7          	jalr	1922(ra) # 80004014 <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	bfd1                	j	80005870 <sys_chdir+0x7a>

000000008000589e <sys_exec>:

uint64
sys_exec(void)
{
    8000589e:	7145                	addi	sp,sp,-464
    800058a0:	e786                	sd	ra,456(sp)
    800058a2:	e3a2                	sd	s0,448(sp)
    800058a4:	ff26                	sd	s1,440(sp)
    800058a6:	fb4a                	sd	s2,432(sp)
    800058a8:	f74e                	sd	s3,424(sp)
    800058aa:	f352                	sd	s4,416(sp)
    800058ac:	ef56                	sd	s5,408(sp)
    800058ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058b0:	08000613          	li	a2,128
    800058b4:	f4040593          	addi	a1,s0,-192
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	1ec080e7          	jalr	492(ra) # 80002aa6 <argstr>
    return -1;
    800058c2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058c4:	0c054a63          	bltz	a0,80005998 <sys_exec+0xfa>
    800058c8:	e3840593          	addi	a1,s0,-456
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	1b6080e7          	jalr	438(ra) # 80002a84 <argaddr>
    800058d6:	0c054163          	bltz	a0,80005998 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058da:	10000613          	li	a2,256
    800058de:	4581                	li	a1,0
    800058e0:	e4040513          	addi	a0,s0,-448
    800058e4:	ffffb097          	auipc	ra,0xffffb
    800058e8:	416080e7          	jalr	1046(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058ec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058f0:	89a6                	mv	s3,s1
    800058f2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058f4:	02000a13          	li	s4,32
    800058f8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058fc:	00391793          	slli	a5,s2,0x3
    80005900:	e3040593          	addi	a1,s0,-464
    80005904:	e3843503          	ld	a0,-456(s0)
    80005908:	953e                	add	a0,a0,a5
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	0be080e7          	jalr	190(ra) # 800029c8 <fetchaddr>
    80005912:	02054a63          	bltz	a0,80005946 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005916:	e3043783          	ld	a5,-464(s0)
    8000591a:	c3b9                	beqz	a5,80005960 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000591c:	ffffb097          	auipc	ra,0xffffb
    80005920:	1f2080e7          	jalr	498(ra) # 80000b0e <kalloc>
    80005924:	85aa                	mv	a1,a0
    80005926:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000592a:	cd11                	beqz	a0,80005946 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000592c:	6605                	lui	a2,0x1
    8000592e:	e3043503          	ld	a0,-464(s0)
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	0e8080e7          	jalr	232(ra) # 80002a1a <fetchstr>
    8000593a:	00054663          	bltz	a0,80005946 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000593e:	0905                	addi	s2,s2,1
    80005940:	09a1                	addi	s3,s3,8
    80005942:	fb491be3          	bne	s2,s4,800058f8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005946:	10048913          	addi	s2,s1,256
    8000594a:	6088                	ld	a0,0(s1)
    8000594c:	c529                	beqz	a0,80005996 <sys_exec+0xf8>
    kfree(argv[i]);
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	0c4080e7          	jalr	196(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005956:	04a1                	addi	s1,s1,8
    80005958:	ff2499e3          	bne	s1,s2,8000594a <sys_exec+0xac>
  return -1;
    8000595c:	597d                	li	s2,-1
    8000595e:	a82d                	j	80005998 <sys_exec+0xfa>
      argv[i] = 0;
    80005960:	0a8e                	slli	s5,s5,0x3
    80005962:	fc040793          	addi	a5,s0,-64
    80005966:	9abe                	add	s5,s5,a5
    80005968:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    8000596c:	e4040593          	addi	a1,s0,-448
    80005970:	f4040513          	addi	a0,s0,-192
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	178080e7          	jalr	376(ra) # 80004aec <exec>
    8000597c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000597e:	10048993          	addi	s3,s1,256
    80005982:	6088                	ld	a0,0(s1)
    80005984:	c911                	beqz	a0,80005998 <sys_exec+0xfa>
    kfree(argv[i]);
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	08c080e7          	jalr	140(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000598e:	04a1                	addi	s1,s1,8
    80005990:	ff3499e3          	bne	s1,s3,80005982 <sys_exec+0xe4>
    80005994:	a011                	j	80005998 <sys_exec+0xfa>
  return -1;
    80005996:	597d                	li	s2,-1
}
    80005998:	854a                	mv	a0,s2
    8000599a:	60be                	ld	ra,456(sp)
    8000599c:	641e                	ld	s0,448(sp)
    8000599e:	74fa                	ld	s1,440(sp)
    800059a0:	795a                	ld	s2,432(sp)
    800059a2:	79ba                	ld	s3,424(sp)
    800059a4:	7a1a                	ld	s4,416(sp)
    800059a6:	6afa                	ld	s5,408(sp)
    800059a8:	6179                	addi	sp,sp,464
    800059aa:	8082                	ret

00000000800059ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800059ac:	7139                	addi	sp,sp,-64
    800059ae:	fc06                	sd	ra,56(sp)
    800059b0:	f822                	sd	s0,48(sp)
    800059b2:	f426                	sd	s1,40(sp)
    800059b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059b6:	ffffc097          	auipc	ra,0xffffc
    800059ba:	014080e7          	jalr	20(ra) # 800019ca <myproc>
    800059be:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059c0:	fd840593          	addi	a1,s0,-40
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	0be080e7          	jalr	190(ra) # 80002a84 <argaddr>
    return -1;
    800059ce:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059d0:	0e054063          	bltz	a0,80005ab0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059d4:	fc840593          	addi	a1,s0,-56
    800059d8:	fd040513          	addi	a0,s0,-48
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	de0080e7          	jalr	-544(ra) # 800047bc <pipealloc>
    return -1;
    800059e4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059e6:	0c054563          	bltz	a0,80005ab0 <sys_pipe+0x104>
  fd0 = -1;
    800059ea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059ee:	fd043503          	ld	a0,-48(s0)
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	50a080e7          	jalr	1290(ra) # 80004efc <fdalloc>
    800059fa:	fca42223          	sw	a0,-60(s0)
    800059fe:	08054c63          	bltz	a0,80005a96 <sys_pipe+0xea>
    80005a02:	fc843503          	ld	a0,-56(s0)
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	4f6080e7          	jalr	1270(ra) # 80004efc <fdalloc>
    80005a0e:	fca42023          	sw	a0,-64(s0)
    80005a12:	06054863          	bltz	a0,80005a82 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a16:	4691                	li	a3,4
    80005a18:	fc440613          	addi	a2,s0,-60
    80005a1c:	fd843583          	ld	a1,-40(s0)
    80005a20:	68a8                	ld	a0,80(s1)
    80005a22:	ffffc097          	auipc	ra,0xffffc
    80005a26:	c9a080e7          	jalr	-870(ra) # 800016bc <copyout>
    80005a2a:	02054063          	bltz	a0,80005a4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a2e:	4691                	li	a3,4
    80005a30:	fc040613          	addi	a2,s0,-64
    80005a34:	fd843583          	ld	a1,-40(s0)
    80005a38:	0591                	addi	a1,a1,4
    80005a3a:	68a8                	ld	a0,80(s1)
    80005a3c:	ffffc097          	auipc	ra,0xffffc
    80005a40:	c80080e7          	jalr	-896(ra) # 800016bc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a46:	06055563          	bgez	a0,80005ab0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a4a:	fc442783          	lw	a5,-60(s0)
    80005a4e:	07e9                	addi	a5,a5,26
    80005a50:	078e                	slli	a5,a5,0x3
    80005a52:	97a6                	add	a5,a5,s1
    80005a54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a58:	fc042503          	lw	a0,-64(s0)
    80005a5c:	0569                	addi	a0,a0,26
    80005a5e:	050e                	slli	a0,a0,0x3
    80005a60:	9526                	add	a0,a0,s1
    80005a62:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a66:	fd043503          	ld	a0,-48(s0)
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	9fc080e7          	jalr	-1540(ra) # 80004466 <fileclose>
    fileclose(wf);
    80005a72:	fc843503          	ld	a0,-56(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9f0080e7          	jalr	-1552(ra) # 80004466 <fileclose>
    return -1;
    80005a7e:	57fd                	li	a5,-1
    80005a80:	a805                	j	80005ab0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a82:	fc442783          	lw	a5,-60(s0)
    80005a86:	0007c863          	bltz	a5,80005a96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a8a:	01a78513          	addi	a0,a5,26
    80005a8e:	050e                	slli	a0,a0,0x3
    80005a90:	9526                	add	a0,a0,s1
    80005a92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a96:	fd043503          	ld	a0,-48(s0)
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	9cc080e7          	jalr	-1588(ra) # 80004466 <fileclose>
    fileclose(wf);
    80005aa2:	fc843503          	ld	a0,-56(s0)
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	9c0080e7          	jalr	-1600(ra) # 80004466 <fileclose>
    return -1;
    80005aae:	57fd                	li	a5,-1
}
    80005ab0:	853e                	mv	a0,a5
    80005ab2:	70e2                	ld	ra,56(sp)
    80005ab4:	7442                	ld	s0,48(sp)
    80005ab6:	74a2                	ld	s1,40(sp)
    80005ab8:	6121                	addi	sp,sp,64
    80005aba:	8082                	ret
    80005abc:	0000                	unimp
	...

0000000080005ac0 <kernelvec>:
    80005ac0:	7111                	addi	sp,sp,-256
    80005ac2:	e006                	sd	ra,0(sp)
    80005ac4:	e40a                	sd	sp,8(sp)
    80005ac6:	e80e                	sd	gp,16(sp)
    80005ac8:	ec12                	sd	tp,24(sp)
    80005aca:	f016                	sd	t0,32(sp)
    80005acc:	f41a                	sd	t1,40(sp)
    80005ace:	f81e                	sd	t2,48(sp)
    80005ad0:	fc22                	sd	s0,56(sp)
    80005ad2:	e0a6                	sd	s1,64(sp)
    80005ad4:	e4aa                	sd	a0,72(sp)
    80005ad6:	e8ae                	sd	a1,80(sp)
    80005ad8:	ecb2                	sd	a2,88(sp)
    80005ada:	f0b6                	sd	a3,96(sp)
    80005adc:	f4ba                	sd	a4,104(sp)
    80005ade:	f8be                	sd	a5,112(sp)
    80005ae0:	fcc2                	sd	a6,120(sp)
    80005ae2:	e146                	sd	a7,128(sp)
    80005ae4:	e54a                	sd	s2,136(sp)
    80005ae6:	e94e                	sd	s3,144(sp)
    80005ae8:	ed52                	sd	s4,152(sp)
    80005aea:	f156                	sd	s5,160(sp)
    80005aec:	f55a                	sd	s6,168(sp)
    80005aee:	f95e                	sd	s7,176(sp)
    80005af0:	fd62                	sd	s8,184(sp)
    80005af2:	e1e6                	sd	s9,192(sp)
    80005af4:	e5ea                	sd	s10,200(sp)
    80005af6:	e9ee                	sd	s11,208(sp)
    80005af8:	edf2                	sd	t3,216(sp)
    80005afa:	f1f6                	sd	t4,224(sp)
    80005afc:	f5fa                	sd	t5,232(sp)
    80005afe:	f9fe                	sd	t6,240(sp)
    80005b00:	d95fc0ef          	jal	ra,80002894 <kerneltrap>
    80005b04:	6082                	ld	ra,0(sp)
    80005b06:	6122                	ld	sp,8(sp)
    80005b08:	61c2                	ld	gp,16(sp)
    80005b0a:	7282                	ld	t0,32(sp)
    80005b0c:	7322                	ld	t1,40(sp)
    80005b0e:	73c2                	ld	t2,48(sp)
    80005b10:	7462                	ld	s0,56(sp)
    80005b12:	6486                	ld	s1,64(sp)
    80005b14:	6526                	ld	a0,72(sp)
    80005b16:	65c6                	ld	a1,80(sp)
    80005b18:	6666                	ld	a2,88(sp)
    80005b1a:	7686                	ld	a3,96(sp)
    80005b1c:	7726                	ld	a4,104(sp)
    80005b1e:	77c6                	ld	a5,112(sp)
    80005b20:	7866                	ld	a6,120(sp)
    80005b22:	688a                	ld	a7,128(sp)
    80005b24:	692a                	ld	s2,136(sp)
    80005b26:	69ca                	ld	s3,144(sp)
    80005b28:	6a6a                	ld	s4,152(sp)
    80005b2a:	7a8a                	ld	s5,160(sp)
    80005b2c:	7b2a                	ld	s6,168(sp)
    80005b2e:	7bca                	ld	s7,176(sp)
    80005b30:	7c6a                	ld	s8,184(sp)
    80005b32:	6c8e                	ld	s9,192(sp)
    80005b34:	6d2e                	ld	s10,200(sp)
    80005b36:	6dce                	ld	s11,208(sp)
    80005b38:	6e6e                	ld	t3,216(sp)
    80005b3a:	7e8e                	ld	t4,224(sp)
    80005b3c:	7f2e                	ld	t5,232(sp)
    80005b3e:	7fce                	ld	t6,240(sp)
    80005b40:	6111                	addi	sp,sp,256
    80005b42:	10200073          	sret
    80005b46:	00000013          	nop
    80005b4a:	00000013          	nop
    80005b4e:	0001                	nop

0000000080005b50 <timervec>:
    80005b50:	34051573          	csrrw	a0,mscratch,a0
    80005b54:	e10c                	sd	a1,0(a0)
    80005b56:	e510                	sd	a2,8(a0)
    80005b58:	e914                	sd	a3,16(a0)
    80005b5a:	710c                	ld	a1,32(a0)
    80005b5c:	7510                	ld	a2,40(a0)
    80005b5e:	6194                	ld	a3,0(a1)
    80005b60:	96b2                	add	a3,a3,a2
    80005b62:	e194                	sd	a3,0(a1)
    80005b64:	4589                	li	a1,2
    80005b66:	14459073          	csrw	sip,a1
    80005b6a:	6914                	ld	a3,16(a0)
    80005b6c:	6510                	ld	a2,8(a0)
    80005b6e:	610c                	ld	a1,0(a0)
    80005b70:	34051573          	csrrw	a0,mscratch,a0
    80005b74:	30200073          	mret
	...

0000000080005b7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b7a:	1141                	addi	sp,sp,-16
    80005b7c:	e422                	sd	s0,8(sp)
    80005b7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b80:	0c0007b7          	lui	a5,0xc000
    80005b84:	4705                	li	a4,1
    80005b86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b88:	c3d8                	sw	a4,4(a5)
}
    80005b8a:	6422                	ld	s0,8(sp)
    80005b8c:	0141                	addi	sp,sp,16
    80005b8e:	8082                	ret

0000000080005b90 <plicinithart>:

void
plicinithart(void)
{
    80005b90:	1141                	addi	sp,sp,-16
    80005b92:	e406                	sd	ra,8(sp)
    80005b94:	e022                	sd	s0,0(sp)
    80005b96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	e06080e7          	jalr	-506(ra) # 8000199e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ba0:	0085171b          	slliw	a4,a0,0x8
    80005ba4:	0c0027b7          	lui	a5,0xc002
    80005ba8:	97ba                	add	a5,a5,a4
    80005baa:	40200713          	li	a4,1026
    80005bae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bb2:	00d5151b          	slliw	a0,a0,0xd
    80005bb6:	0c2017b7          	lui	a5,0xc201
    80005bba:	953e                	add	a0,a0,a5
    80005bbc:	00052023          	sw	zero,0(a0)
}
    80005bc0:	60a2                	ld	ra,8(sp)
    80005bc2:	6402                	ld	s0,0(sp)
    80005bc4:	0141                	addi	sp,sp,16
    80005bc6:	8082                	ret

0000000080005bc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bc8:	1141                	addi	sp,sp,-16
    80005bca:	e406                	sd	ra,8(sp)
    80005bcc:	e022                	sd	s0,0(sp)
    80005bce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	dce080e7          	jalr	-562(ra) # 8000199e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bd8:	00d5179b          	slliw	a5,a0,0xd
    80005bdc:	0c201537          	lui	a0,0xc201
    80005be0:	953e                	add	a0,a0,a5
  return irq;
}
    80005be2:	4148                	lw	a0,4(a0)
    80005be4:	60a2                	ld	ra,8(sp)
    80005be6:	6402                	ld	s0,0(sp)
    80005be8:	0141                	addi	sp,sp,16
    80005bea:	8082                	ret

0000000080005bec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bec:	1101                	addi	sp,sp,-32
    80005bee:	ec06                	sd	ra,24(sp)
    80005bf0:	e822                	sd	s0,16(sp)
    80005bf2:	e426                	sd	s1,8(sp)
    80005bf4:	1000                	addi	s0,sp,32
    80005bf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	da6080e7          	jalr	-602(ra) # 8000199e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c00:	00d5151b          	slliw	a0,a0,0xd
    80005c04:	0c2017b7          	lui	a5,0xc201
    80005c08:	97aa                	add	a5,a5,a0
    80005c0a:	c3c4                	sw	s1,4(a5)
}
    80005c0c:	60e2                	ld	ra,24(sp)
    80005c0e:	6442                	ld	s0,16(sp)
    80005c10:	64a2                	ld	s1,8(sp)
    80005c12:	6105                	addi	sp,sp,32
    80005c14:	8082                	ret

0000000080005c16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c16:	1141                	addi	sp,sp,-16
    80005c18:	e406                	sd	ra,8(sp)
    80005c1a:	e022                	sd	s0,0(sp)
    80005c1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c1e:	479d                	li	a5,7
    80005c20:	04a7cc63          	blt	a5,a0,80005c78 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005c24:	0001d797          	auipc	a5,0x1d
    80005c28:	3dc78793          	addi	a5,a5,988 # 80023000 <disk>
    80005c2c:	00a78733          	add	a4,a5,a0
    80005c30:	6789                	lui	a5,0x2
    80005c32:	97ba                	add	a5,a5,a4
    80005c34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c38:	eba1                	bnez	a5,80005c88 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005c3a:	00451713          	slli	a4,a0,0x4
    80005c3e:	0001f797          	auipc	a5,0x1f
    80005c42:	3c27b783          	ld	a5,962(a5) # 80025000 <disk+0x2000>
    80005c46:	97ba                	add	a5,a5,a4
    80005c48:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005c4c:	0001d797          	auipc	a5,0x1d
    80005c50:	3b478793          	addi	a5,a5,948 # 80023000 <disk>
    80005c54:	97aa                	add	a5,a5,a0
    80005c56:	6509                	lui	a0,0x2
    80005c58:	953e                	add	a0,a0,a5
    80005c5a:	4785                	li	a5,1
    80005c5c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c60:	0001f517          	auipc	a0,0x1f
    80005c64:	3b850513          	addi	a0,a0,952 # 80025018 <disk+0x2018>
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	6d2080e7          	jalr	1746(ra) # 8000233a <wakeup>
}
    80005c70:	60a2                	ld	ra,8(sp)
    80005c72:	6402                	ld	s0,0(sp)
    80005c74:	0141                	addi	sp,sp,16
    80005c76:	8082                	ret
    panic("virtio_disk_intr 1");
    80005c78:	00003517          	auipc	a0,0x3
    80005c7c:	ae050513          	addi	a0,a0,-1312 # 80008758 <syscalls+0x330>
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	8c2080e7          	jalr	-1854(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005c88:	00003517          	auipc	a0,0x3
    80005c8c:	ae850513          	addi	a0,a0,-1304 # 80008770 <syscalls+0x348>
    80005c90:	ffffb097          	auipc	ra,0xffffb
    80005c94:	8b2080e7          	jalr	-1870(ra) # 80000542 <panic>

0000000080005c98 <virtio_disk_init>:
{
    80005c98:	1101                	addi	sp,sp,-32
    80005c9a:	ec06                	sd	ra,24(sp)
    80005c9c:	e822                	sd	s0,16(sp)
    80005c9e:	e426                	sd	s1,8(sp)
    80005ca0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ca2:	00003597          	auipc	a1,0x3
    80005ca6:	ae658593          	addi	a1,a1,-1306 # 80008788 <syscalls+0x360>
    80005caa:	0001f517          	auipc	a0,0x1f
    80005cae:	3fe50513          	addi	a0,a0,1022 # 800250a8 <disk+0x20a8>
    80005cb2:	ffffb097          	auipc	ra,0xffffb
    80005cb6:	ebc080e7          	jalr	-324(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cba:	100017b7          	lui	a5,0x10001
    80005cbe:	4398                	lw	a4,0(a5)
    80005cc0:	2701                	sext.w	a4,a4
    80005cc2:	747277b7          	lui	a5,0x74727
    80005cc6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cca:	0ef71163          	bne	a4,a5,80005dac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cce:	100017b7          	lui	a5,0x10001
    80005cd2:	43dc                	lw	a5,4(a5)
    80005cd4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cd6:	4705                	li	a4,1
    80005cd8:	0ce79a63          	bne	a5,a4,80005dac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cdc:	100017b7          	lui	a5,0x10001
    80005ce0:	479c                	lw	a5,8(a5)
    80005ce2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ce4:	4709                	li	a4,2
    80005ce6:	0ce79363          	bne	a5,a4,80005dac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cea:	100017b7          	lui	a5,0x10001
    80005cee:	47d8                	lw	a4,12(a5)
    80005cf0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cf2:	554d47b7          	lui	a5,0x554d4
    80005cf6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cfa:	0af71963          	bne	a4,a5,80005dac <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cfe:	100017b7          	lui	a5,0x10001
    80005d02:	4705                	li	a4,1
    80005d04:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d06:	470d                	li	a4,3
    80005d08:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d0a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d0c:	c7ffe737          	lui	a4,0xc7ffe
    80005d10:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d14:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d16:	2701                	sext.w	a4,a4
    80005d18:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d1a:	472d                	li	a4,11
    80005d1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d1e:	473d                	li	a4,15
    80005d20:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d22:	6705                	lui	a4,0x1
    80005d24:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d26:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d2a:	5bdc                	lw	a5,52(a5)
    80005d2c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d2e:	c7d9                	beqz	a5,80005dbc <virtio_disk_init+0x124>
  if(max < NUM)
    80005d30:	471d                	li	a4,7
    80005d32:	08f77d63          	bgeu	a4,a5,80005dcc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d36:	100014b7          	lui	s1,0x10001
    80005d3a:	47a1                	li	a5,8
    80005d3c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d3e:	6609                	lui	a2,0x2
    80005d40:	4581                	li	a1,0
    80005d42:	0001d517          	auipc	a0,0x1d
    80005d46:	2be50513          	addi	a0,a0,702 # 80023000 <disk>
    80005d4a:	ffffb097          	auipc	ra,0xffffb
    80005d4e:	fb0080e7          	jalr	-80(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d52:	0001d717          	auipc	a4,0x1d
    80005d56:	2ae70713          	addi	a4,a4,686 # 80023000 <disk>
    80005d5a:	00c75793          	srli	a5,a4,0xc
    80005d5e:	2781                	sext.w	a5,a5
    80005d60:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005d62:	0001f797          	auipc	a5,0x1f
    80005d66:	29e78793          	addi	a5,a5,670 # 80025000 <disk+0x2000>
    80005d6a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005d6c:	0001d717          	auipc	a4,0x1d
    80005d70:	31470713          	addi	a4,a4,788 # 80023080 <disk+0x80>
    80005d74:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005d76:	0001e717          	auipc	a4,0x1e
    80005d7a:	28a70713          	addi	a4,a4,650 # 80024000 <disk+0x1000>
    80005d7e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d80:	4705                	li	a4,1
    80005d82:	00e78c23          	sb	a4,24(a5)
    80005d86:	00e78ca3          	sb	a4,25(a5)
    80005d8a:	00e78d23          	sb	a4,26(a5)
    80005d8e:	00e78da3          	sb	a4,27(a5)
    80005d92:	00e78e23          	sb	a4,28(a5)
    80005d96:	00e78ea3          	sb	a4,29(a5)
    80005d9a:	00e78f23          	sb	a4,30(a5)
    80005d9e:	00e78fa3          	sb	a4,31(a5)
}
    80005da2:	60e2                	ld	ra,24(sp)
    80005da4:	6442                	ld	s0,16(sp)
    80005da6:	64a2                	ld	s1,8(sp)
    80005da8:	6105                	addi	sp,sp,32
    80005daa:	8082                	ret
    panic("could not find virtio disk");
    80005dac:	00003517          	auipc	a0,0x3
    80005db0:	9ec50513          	addi	a0,a0,-1556 # 80008798 <syscalls+0x370>
    80005db4:	ffffa097          	auipc	ra,0xffffa
    80005db8:	78e080e7          	jalr	1934(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005dbc:	00003517          	auipc	a0,0x3
    80005dc0:	9fc50513          	addi	a0,a0,-1540 # 800087b8 <syscalls+0x390>
    80005dc4:	ffffa097          	auipc	ra,0xffffa
    80005dc8:	77e080e7          	jalr	1918(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005dcc:	00003517          	auipc	a0,0x3
    80005dd0:	a0c50513          	addi	a0,a0,-1524 # 800087d8 <syscalls+0x3b0>
    80005dd4:	ffffa097          	auipc	ra,0xffffa
    80005dd8:	76e080e7          	jalr	1902(ra) # 80000542 <panic>

0000000080005ddc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ddc:	7175                	addi	sp,sp,-144
    80005dde:	e506                	sd	ra,136(sp)
    80005de0:	e122                	sd	s0,128(sp)
    80005de2:	fca6                	sd	s1,120(sp)
    80005de4:	f8ca                	sd	s2,112(sp)
    80005de6:	f4ce                	sd	s3,104(sp)
    80005de8:	f0d2                	sd	s4,96(sp)
    80005dea:	ecd6                	sd	s5,88(sp)
    80005dec:	e8da                	sd	s6,80(sp)
    80005dee:	e4de                	sd	s7,72(sp)
    80005df0:	e0e2                	sd	s8,64(sp)
    80005df2:	fc66                	sd	s9,56(sp)
    80005df4:	f86a                	sd	s10,48(sp)
    80005df6:	f46e                	sd	s11,40(sp)
    80005df8:	0900                	addi	s0,sp,144
    80005dfa:	8aaa                	mv	s5,a0
    80005dfc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005dfe:	00c52c83          	lw	s9,12(a0)
    80005e02:	001c9c9b          	slliw	s9,s9,0x1
    80005e06:	1c82                	slli	s9,s9,0x20
    80005e08:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e0c:	0001f517          	auipc	a0,0x1f
    80005e10:	29c50513          	addi	a0,a0,668 # 800250a8 <disk+0x20a8>
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	dea080e7          	jalr	-534(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    80005e1c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e1e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e20:	0001dc17          	auipc	s8,0x1d
    80005e24:	1e0c0c13          	addi	s8,s8,480 # 80023000 <disk>
    80005e28:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e2a:	4b0d                	li	s6,3
    80005e2c:	a0ad                	j	80005e96 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e2e:	00fc0733          	add	a4,s8,a5
    80005e32:	975e                	add	a4,a4,s7
    80005e34:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e38:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e3a:	0207c563          	bltz	a5,80005e64 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e3e:	2905                	addiw	s2,s2,1
    80005e40:	0611                	addi	a2,a2,4
    80005e42:	19690d63          	beq	s2,s6,80005fdc <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005e46:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e48:	0001f717          	auipc	a4,0x1f
    80005e4c:	1d070713          	addi	a4,a4,464 # 80025018 <disk+0x2018>
    80005e50:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e52:	00074683          	lbu	a3,0(a4)
    80005e56:	fee1                	bnez	a3,80005e2e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e58:	2785                	addiw	a5,a5,1
    80005e5a:	0705                	addi	a4,a4,1
    80005e5c:	fe979be3          	bne	a5,s1,80005e52 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e60:	57fd                	li	a5,-1
    80005e62:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e64:	01205d63          	blez	s2,80005e7e <virtio_disk_rw+0xa2>
    80005e68:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e6a:	000a2503          	lw	a0,0(s4)
    80005e6e:	00000097          	auipc	ra,0x0
    80005e72:	da8080e7          	jalr	-600(ra) # 80005c16 <free_desc>
      for(int j = 0; j < i; j++)
    80005e76:	2d85                	addiw	s11,s11,1
    80005e78:	0a11                	addi	s4,s4,4
    80005e7a:	ffb918e3          	bne	s2,s11,80005e6a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e7e:	0001f597          	auipc	a1,0x1f
    80005e82:	22a58593          	addi	a1,a1,554 # 800250a8 <disk+0x20a8>
    80005e86:	0001f517          	auipc	a0,0x1f
    80005e8a:	19250513          	addi	a0,a0,402 # 80025018 <disk+0x2018>
    80005e8e:	ffffc097          	auipc	ra,0xffffc
    80005e92:	32c080e7          	jalr	812(ra) # 800021ba <sleep>
  for(int i = 0; i < 3; i++){
    80005e96:	f8040a13          	addi	s4,s0,-128
{
    80005e9a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005e9c:	894e                	mv	s2,s3
    80005e9e:	b765                	j	80005e46 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005ea0:	0001f717          	auipc	a4,0x1f
    80005ea4:	16073703          	ld	a4,352(a4) # 80025000 <disk+0x2000>
    80005ea8:	973e                	add	a4,a4,a5
    80005eaa:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005eae:	0001d517          	auipc	a0,0x1d
    80005eb2:	15250513          	addi	a0,a0,338 # 80023000 <disk>
    80005eb6:	0001f717          	auipc	a4,0x1f
    80005eba:	14a70713          	addi	a4,a4,330 # 80025000 <disk+0x2000>
    80005ebe:	6314                	ld	a3,0(a4)
    80005ec0:	96be                	add	a3,a3,a5
    80005ec2:	00c6d603          	lhu	a2,12(a3)
    80005ec6:	00166613          	ori	a2,a2,1
    80005eca:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005ece:	f8842683          	lw	a3,-120(s0)
    80005ed2:	6310                	ld	a2,0(a4)
    80005ed4:	97b2                	add	a5,a5,a2
    80005ed6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005eda:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005ede:	0612                	slli	a2,a2,0x4
    80005ee0:	962a                	add	a2,a2,a0
    80005ee2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005ee6:	00469793          	slli	a5,a3,0x4
    80005eea:	630c                	ld	a1,0(a4)
    80005eec:	95be                	add	a1,a1,a5
    80005eee:	6689                	lui	a3,0x2
    80005ef0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005ef4:	96ca                	add	a3,a3,s2
    80005ef6:	96aa                	add	a3,a3,a0
    80005ef8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005efa:	6314                	ld	a3,0(a4)
    80005efc:	96be                	add	a3,a3,a5
    80005efe:	4585                	li	a1,1
    80005f00:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f02:	6314                	ld	a3,0(a4)
    80005f04:	96be                	add	a3,a3,a5
    80005f06:	4509                	li	a0,2
    80005f08:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005f0c:	6314                	ld	a3,0(a4)
    80005f0e:	97b6                	add	a5,a5,a3
    80005f10:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f14:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80005f18:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80005f1c:	6714                	ld	a3,8(a4)
    80005f1e:	0026d783          	lhu	a5,2(a3)
    80005f22:	8b9d                	andi	a5,a5,7
    80005f24:	0789                	addi	a5,a5,2
    80005f26:	0786                	slli	a5,a5,0x1
    80005f28:	97b6                	add	a5,a5,a3
    80005f2a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    80005f2e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80005f32:	6718                	ld	a4,8(a4)
    80005f34:	00275783          	lhu	a5,2(a4)
    80005f38:	2785                	addiw	a5,a5,1
    80005f3a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f46:	004aa783          	lw	a5,4(s5)
    80005f4a:	02b79163          	bne	a5,a1,80005f6c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f4e:	0001f917          	auipc	s2,0x1f
    80005f52:	15a90913          	addi	s2,s2,346 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80005f56:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f58:	85ca                	mv	a1,s2
    80005f5a:	8556                	mv	a0,s5
    80005f5c:	ffffc097          	auipc	ra,0xffffc
    80005f60:	25e080e7          	jalr	606(ra) # 800021ba <sleep>
  while(b->disk == 1) {
    80005f64:	004aa783          	lw	a5,4(s5)
    80005f68:	fe9788e3          	beq	a5,s1,80005f58 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f6c:	f8042483          	lw	s1,-128(s0)
    80005f70:	20048793          	addi	a5,s1,512
    80005f74:	00479713          	slli	a4,a5,0x4
    80005f78:	0001d797          	auipc	a5,0x1d
    80005f7c:	08878793          	addi	a5,a5,136 # 80023000 <disk>
    80005f80:	97ba                	add	a5,a5,a4
    80005f82:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005f86:	0001f917          	auipc	s2,0x1f
    80005f8a:	07a90913          	addi	s2,s2,122 # 80025000 <disk+0x2000>
    80005f8e:	a019                	j	80005f94 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80005f90:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80005f94:	8526                	mv	a0,s1
    80005f96:	00000097          	auipc	ra,0x0
    80005f9a:	c80080e7          	jalr	-896(ra) # 80005c16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005f9e:	0492                	slli	s1,s1,0x4
    80005fa0:	00093783          	ld	a5,0(s2)
    80005fa4:	94be                	add	s1,s1,a5
    80005fa6:	00c4d783          	lhu	a5,12(s1)
    80005faa:	8b85                	andi	a5,a5,1
    80005fac:	f3f5                	bnez	a5,80005f90 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fae:	0001f517          	auipc	a0,0x1f
    80005fb2:	0fa50513          	addi	a0,a0,250 # 800250a8 <disk+0x20a8>
    80005fb6:	ffffb097          	auipc	ra,0xffffb
    80005fba:	cfc080e7          	jalr	-772(ra) # 80000cb2 <release>
}
    80005fbe:	60aa                	ld	ra,136(sp)
    80005fc0:	640a                	ld	s0,128(sp)
    80005fc2:	74e6                	ld	s1,120(sp)
    80005fc4:	7946                	ld	s2,112(sp)
    80005fc6:	79a6                	ld	s3,104(sp)
    80005fc8:	7a06                	ld	s4,96(sp)
    80005fca:	6ae6                	ld	s5,88(sp)
    80005fcc:	6b46                	ld	s6,80(sp)
    80005fce:	6ba6                	ld	s7,72(sp)
    80005fd0:	6c06                	ld	s8,64(sp)
    80005fd2:	7ce2                	ld	s9,56(sp)
    80005fd4:	7d42                	ld	s10,48(sp)
    80005fd6:	7da2                	ld	s11,40(sp)
    80005fd8:	6149                	addi	sp,sp,144
    80005fda:	8082                	ret
  if(write)
    80005fdc:	01a037b3          	snez	a5,s10
    80005fe0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80005fe4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80005fe8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005fec:	f8042483          	lw	s1,-128(s0)
    80005ff0:	00449913          	slli	s2,s1,0x4
    80005ff4:	0001f997          	auipc	s3,0x1f
    80005ff8:	00c98993          	addi	s3,s3,12 # 80025000 <disk+0x2000>
    80005ffc:	0009ba03          	ld	s4,0(s3)
    80006000:	9a4a                	add	s4,s4,s2
    80006002:	f7040513          	addi	a0,s0,-144
    80006006:	ffffb097          	auipc	ra,0xffffb
    8000600a:	0c4080e7          	jalr	196(ra) # 800010ca <kvmpa>
    8000600e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006012:	0009b783          	ld	a5,0(s3)
    80006016:	97ca                	add	a5,a5,s2
    80006018:	4741                	li	a4,16
    8000601a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000601c:	0009b783          	ld	a5,0(s3)
    80006020:	97ca                	add	a5,a5,s2
    80006022:	4705                	li	a4,1
    80006024:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006028:	f8442783          	lw	a5,-124(s0)
    8000602c:	0009b703          	ld	a4,0(s3)
    80006030:	974a                	add	a4,a4,s2
    80006032:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006036:	0792                	slli	a5,a5,0x4
    80006038:	0009b703          	ld	a4,0(s3)
    8000603c:	973e                	add	a4,a4,a5
    8000603e:	058a8693          	addi	a3,s5,88
    80006042:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006044:	0009b703          	ld	a4,0(s3)
    80006048:	973e                	add	a4,a4,a5
    8000604a:	40000693          	li	a3,1024
    8000604e:	c714                	sw	a3,8(a4)
  if(write)
    80006050:	e40d18e3          	bnez	s10,80005ea0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006054:	0001f717          	auipc	a4,0x1f
    80006058:	fac73703          	ld	a4,-84(a4) # 80025000 <disk+0x2000>
    8000605c:	973e                	add	a4,a4,a5
    8000605e:	4689                	li	a3,2
    80006060:	00d71623          	sh	a3,12(a4)
    80006064:	b5a9                	j	80005eae <virtio_disk_rw+0xd2>

0000000080006066 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006066:	1101                	addi	sp,sp,-32
    80006068:	ec06                	sd	ra,24(sp)
    8000606a:	e822                	sd	s0,16(sp)
    8000606c:	e426                	sd	s1,8(sp)
    8000606e:	e04a                	sd	s2,0(sp)
    80006070:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006072:	0001f517          	auipc	a0,0x1f
    80006076:	03650513          	addi	a0,a0,54 # 800250a8 <disk+0x20a8>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	b84080e7          	jalr	-1148(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006082:	0001f717          	auipc	a4,0x1f
    80006086:	f7e70713          	addi	a4,a4,-130 # 80025000 <disk+0x2000>
    8000608a:	02075783          	lhu	a5,32(a4)
    8000608e:	6b18                	ld	a4,16(a4)
    80006090:	00275683          	lhu	a3,2(a4)
    80006094:	8ebd                	xor	a3,a3,a5
    80006096:	8a9d                	andi	a3,a3,7
    80006098:	cab9                	beqz	a3,800060ee <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000609a:	0001d917          	auipc	s2,0x1d
    8000609e:	f6690913          	addi	s2,s2,-154 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800060a2:	0001f497          	auipc	s1,0x1f
    800060a6:	f5e48493          	addi	s1,s1,-162 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800060aa:	078e                	slli	a5,a5,0x3
    800060ac:	97ba                	add	a5,a5,a4
    800060ae:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800060b0:	20078713          	addi	a4,a5,512
    800060b4:	0712                	slli	a4,a4,0x4
    800060b6:	974a                	add	a4,a4,s2
    800060b8:	03074703          	lbu	a4,48(a4)
    800060bc:	ef21                	bnez	a4,80006114 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800060be:	20078793          	addi	a5,a5,512
    800060c2:	0792                	slli	a5,a5,0x4
    800060c4:	97ca                	add	a5,a5,s2
    800060c6:	7798                	ld	a4,40(a5)
    800060c8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800060cc:	7788                	ld	a0,40(a5)
    800060ce:	ffffc097          	auipc	ra,0xffffc
    800060d2:	26c080e7          	jalr	620(ra) # 8000233a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800060d6:	0204d783          	lhu	a5,32(s1)
    800060da:	2785                	addiw	a5,a5,1
    800060dc:	8b9d                	andi	a5,a5,7
    800060de:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800060e2:	6898                	ld	a4,16(s1)
    800060e4:	00275683          	lhu	a3,2(a4)
    800060e8:	8a9d                	andi	a3,a3,7
    800060ea:	fcf690e3          	bne	a3,a5,800060aa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060ee:	10001737          	lui	a4,0x10001
    800060f2:	533c                	lw	a5,96(a4)
    800060f4:	8b8d                	andi	a5,a5,3
    800060f6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800060f8:	0001f517          	auipc	a0,0x1f
    800060fc:	fb050513          	addi	a0,a0,-80 # 800250a8 <disk+0x20a8>
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	bb2080e7          	jalr	-1102(ra) # 80000cb2 <release>
}
    80006108:	60e2                	ld	ra,24(sp)
    8000610a:	6442                	ld	s0,16(sp)
    8000610c:	64a2                	ld	s1,8(sp)
    8000610e:	6902                	ld	s2,0(sp)
    80006110:	6105                	addi	sp,sp,32
    80006112:	8082                	ret
      panic("virtio_disk_intr status");
    80006114:	00002517          	auipc	a0,0x2
    80006118:	6e450513          	addi	a0,a0,1764 # 800087f8 <syscalls+0x3d0>
    8000611c:	ffffa097          	auipc	ra,0xffffa
    80006120:	426080e7          	jalr	1062(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
