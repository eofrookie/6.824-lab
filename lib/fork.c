// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	pte_t pte=uvpt[PGNUM(addr)];
	if(!(err&FEC_WR)||(pte&PTE_COW)!=PTE_COW){
		panic("faulting access illegal");
	}
	// LAB 4: Your code here.

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	if((r=sys_page_alloc(0,(void*)PFTEMP,PTE_W|PTE_U|PTE_P))<0){
		panic("page_alloc error:%e",r);
	}
	//map old page to new page
	addr=ROUNDDOWN(addr,PGSIZE);
	memcpy((void*)PFTEMP,(void*)addr,PGSIZE);
	//将addr指向新分配的页
	if((r=sys_page_map(0,PFTEMP,0,addr,PTE_W|PTE_U|PTE_P))<0){
		panic("page_map error:%e",r);
	}
	if((r=sys_page_unmap(0,PFTEMP))<0){
		panic("page_unmap error:%e",r);
	}
	// LAB 4: Your code here.

	// panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uintptr_t addr=pn*PGSIZE;
	int perm=PTE_U|PTE_P;
	if((uvpt[PGNUM(addr)]&(PTE_W|PTE_COW))!=0){
		perm|=PTE_COW;
		if((r=sys_page_map(0,(void*)addr,envid,(void*)addr,perm))<0){
			panic("page_map error:%e",r);
		}
		if((r=sys_page_map(0,(void*)addr,0,(void*)addr,perm))<0){
			panic("page_map error:%e",r);
		}
	}else{
		if((r=sys_page_map(0,(void*)addr,envid,(void*)addr,perm))<0){
			panic("page_map error:%e",r);
		}
	}
	// LAB 4: Your code here.
	// panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//	uvpt用户虚拟地址页表，uvpd用户虚拟地址页目录表
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{	
	extern void _pgfault_upcall(void);
	int r;
	set_pgfault_handler(pgfault);
	envid_t child=sys_exofork();
	uintptr_t addr;
	if(child<0){
		panic("sys_exofork: %e", child);
	}else if(child==0){
		thisenv=&envs[ENVX(child)];
		// set_pgfault_handler(pgfault);
		return 0;
	}
		
	//遍历当前环境的每一页，对于满足条件的页面进行复制的处理
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE){
		if((uvpd[PDX(addr)]&PTE_P)&&(uvpt[PGNUM(addr)]&PTE_P)&&(uvpt[PGNUM(addr)]&PTE_U)){
			duppage(child,PGNUM(addr));
		}
	}
	if((r=sys_page_alloc(child,(void*)(UXSTACKTOP-PGSIZE),PTE_W|PTE_P|PTE_U))<0){
		panic("page_alloc error:%e",r);
	}
	if((r=sys_env_set_pgfault_upcall(child,_pgfault_upcall))<0){
		panic("set_pgfault error:%e",r);
	}
	if ((r = sys_env_set_status(child, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
	return child;
	// LAB 4: Your code here.
	// panic("fork not implemented");
}

static int
sduppage(envid_t envid, unsigned pn){
	int r;
	pte_t pte=uvpt[pn];
	void* addr=(void*)(pn*PGSIZE);
	uint32_t perm=pte&0xFFF;
	if((r=sys_page_map(0,addr,envid,addr,perm&PTE_SYSCALL))<0){
		panic("page_map error;%e",r);
	}
	return 0;
}
// Challenge!
int
sfork(void)
{
	extern void _pgfault_upcall(void);
	int r;
	set_pgfault_handler(pgfault);
	envid_t child=sys_exofork();
	uint8_t *addr;
	if(child<0){
		panic("sys_exofork: %e", child);
	}else if(child==0){
		thisenv=&envs[ENVX(child)];
		// set_pgfault_handler(pgfault);
		return 0;
	}
		
	//除了用户栈区域都为共享的，所以从栈低开始判断，到达栈顶之后，之后的内存还没被映射，所以pte_p不为1
	bool in_stack=true;
	for (addr = (uint8_t*)(USTACKTOP-PGSIZE); addr >= (uint8_t*)UTEXT; addr -= PGSIZE){
		if((uvpd[PDX(addr)]&PTE_P)&&(uvpt[PGNUM(addr)]&PTE_P)){
			if(in_stack){
				duppage(child,PGNUM(addr));
			}else{
				sduppage(child,PGNUM(addr));
			}
		}else{
			in_stack=false;
		}
	}
	if((r=sys_page_alloc(child,(void*)(UXSTACKTOP-PGSIZE),PTE_W|PTE_P|PTE_U))<0){
		panic("page_alloc error:%e",r);
	}
	if((r=sys_env_set_pgfault_upcall(child,_pgfault_upcall))<0){
		panic("set_pgfault error:%e",r);
	}
	if ((r = sys_env_set_status(child, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
	return child;
	// panic("sfork not implemented");
	// return -E_INVAL;
}
