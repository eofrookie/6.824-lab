/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



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
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide_entry,T_DIVIDE);
TRAPHANDLER_NOEC(debug_entry,T_DEBUG);
TRAPHANDLER_NOEC(non_maskable_entry,T_NMI);
TRAPHANDLER_NOEC(breakpoint_entry,T_BRKPT);
TRAPHANDLER_NOEC(overflow_entry,T_OFLOW);
TRAPHANDLER_NOEC(bounds_check_entry,T_BOUND);
TRAPHANDLER_NOEC(invalid_opcode_entry,T_ILLOP);
TRAPHANDLER_NOEC(divice_not_avail,T_DEVICE);
TRAPHANDLER(double_fault_entry,T_DBLFLT);
TRAPHANDLER(invalid_TSS_entry,T_TSS);
TRAPHANDLER(segment_not_present_entry,T_SEGNP);
TRAPHANDLER(stack_exception_entry,T_STACK);
TRAPHANDLER(gplft_entry,T_GPFLT);
TRAPHANDLER(pgflt_entry,T_PGFLT);
TRAPHANDLER_NOEC(FPERR_entry,T_FPERR);
TRAPHANDLER(align_entry,T_ALIGN);
TRAPHANDLER_NOEC(mchk_entry,T_MCHK);
TRAPHANDLER_NOEC(SIMDerr_entry,T_SIMDERR);
TRAPHANDLER_NOEC(syscall_entry,T_SYSCALL);




/*
 * Lab 3: Your code here for _alltraps
 将用户的数据段和扩展数据段寄存器推入内核栈中，保证内核可以访问用户的内存
 pushal将trapframe的地址作为参数推入栈中，作为trap.c的参数。
 */

_alltraps:
	pushl %ds
	pushl %es
	pushal

	movl $GD_KD %eax
	movl %eax %ds
	movl %eax %es

	push %esp
	call trap


