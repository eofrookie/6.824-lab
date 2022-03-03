// Called from entry.S to get us going.
// entry.S already took care of defining envs, pages, uvpd, and uvpt.

#include <inc/lib.h>

extern void umain(int argc, char **argv);

// const volatile struct Env *thisenv;
const volatile struct Env *envs_ptr[NENV];
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	int i;
	for(i=0;i<NENV;++i){
		envs_ptr[i]=&envs[i];
	}
	// thisenv = 0;
	// cprintf("index of id is %d\n", ENVX(id));
	thisenv=&envs[ENVX(sys_getenvid())];
	// cprintf("thisenv->env_tf.tf_cs: %08x\n", thisenv->env_tf.tf_cs);
	//id==2 why?
	// cprintf("id am environment %08x\n",id);
	// save the name of the program so that panic() can use it
	if (argc > 0)
		binaryname = argv[0];

	// call user main routine
	umain(argc, argv);

	// exit gracefully
	exit();
}

