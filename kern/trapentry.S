/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
 /* Use ec = 1 for traps where the CPU automatically push an error code and ec = 0 for not.
 * Use user = 1 for a syscall; user = 0 for a normal trap.
 user 表示特权级数
 */
#define TRAPHANDLER(name,num,ec,user)						\
.text;													\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	.if ec==0;  									\
		pushl $0;									\
	.endif;											\
	pushl $(num);									\
	jmp _alltraps;									\
.data;												\
	.long name,num,user 

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
; #define TRAPHANDLER_NOEC(name, num)					\
; 	.globl name;							\
; 	.type name, @function;						\
; 	.align 2;							\
; 	name:								\
; 	pushl $0;							\
; 	pushl $(num);							\
; 	jmp _alltraps

; .text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

.data
	.globl entry_data
entry_data:
.text;
TRAPHANDLER(divide_entry,T_DIVIDE,0,0);
TRAPHANDLER(debug_entry,T_DEBUG,0,0);
TRAPHANDLER(non_maskable_entry,T_NMI,0,0);
TRAPHANDLER(breakpoint_entry,T_BRKPT,0,1);
TRAPHANDLER(overflow_entry,T_OFLOW,0,0);
TRAPHANDLER(bounds_check_entry,T_BOUND,0,0);
TRAPHANDLER(invalid_opcode_entry,T_ILLOP,0,0);
TRAPHANDLER(device_entry,T_DEVICE,0,0);
TRAPHANDLER(double_fault_entry,T_DBLFLT,1,0);
TRAPHANDLER(invalid_TSS_entry,T_TSS,1,0);
TRAPHANDLER(segment_not_present_entry,T_SEGNP,1,0);
TRAPHANDLER(stack_exception_entry,T_STACK,1,0);
TRAPHANDLER(gplft_entry,T_GPFLT,1,0);
TRAPHANDLER(pgflt_entry,T_PGFLT,1,0);
TRAPHANDLER(FPERR_entry,T_FPERR,0,0);
TRAPHANDLER(align_entry,T_ALIGN,1,0);
TRAPHANDLER(mchk_entry,T_MCHK,0,0);
TRAPHANDLER(SIMDerr_entry,T_SIMDERR,0,0);
TRAPHANDLER(syscall_entry,T_SYSCALL,0,1);
TRAPHANDLER(irq_entry1,32,0,0);
TRAPHANDLER(irq_entry2,33,0,0);
TRAPHANDLER(irq_entry3,34,0,0);
TRAPHANDLER(irq_entry4,35,0,0);
TRAPHANDLER(irq_entry5,36,0,0);
TRAPHANDLER(irq_entry6,37,0,0);
TRAPHANDLER(irq_entry7,38,0,0);
TRAPHANDLER(irq_entry8,39,0,0);
TRAPHANDLER(irq_entry9,40,0,0);
TRAPHANDLER(irq_entry10,41,0,0);
TRAPHANDLER(irq_entry11,42,0,0);
TRAPHANDLER(irq_entry12,43,0,0);
TRAPHANDLER(irq_entry13,44,0,0);
TRAPHANDLER(irq_entry14,45,0,0);
TRAPHANDLER(irq_entry15,46,0,0);
TRAPHANDLER(irq_entry16,47,0,0);
.data
	.long 0,0,0




/*
 * Lab 3: Your code here for _alltraps
 将用户的数据段和扩展数据段寄存器推入内核栈中，保证内核可以访问用户的内存
 pushal将trapframe的地址作为参数推入栈中，作为trap.c的参数。
 pushal将常规寄存器入栈
 */

_alltraps:
	pushl %ds
	pushl %es
	pushal

	movl $GD_KD,%eax
	movl %eax,%ds
	movl %eax,%es

	push %esp
	call trap


