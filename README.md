## tiresias
: arm and x86 are turing-complete without data fetches // domas, @xoreaxeaxeax

Tiresias is a brief proof of concept that ARM and x86 (and most other Von
Neumann architectures) are Turing-complete without actually reading data.

The project began as a thought experiment on circumventions to an arbitrary
'execute-only' memory protection.  Looking at x86 for succinctness, the
(somewhat uninspiring) observation is that a data fetch:

```
data: 0xdeadc0de
mov eax, [data]
```

can be simulated by an instruction fetch instead:

```
mov eax, 0xdeadc0de
```

A data write, then, simply modifies the immediate used in the instruction.
Memory can then be modeled as an array of 'fetch cells':

```
cell_0:
	mov eax, 0xdeadc0de
	jmp esi
cell_1:
	mov eax, 0xfeedface
	jmp esi
cell_2:
	mov eax, 0xcafed00d
	jmp esi
```

To read a memory cell, without a data fetch, we then:

```
mov esi, mret
jmp cell_2 ; load cell 2
mret:
```

And writing a data cell is simply modifying the immediate used:

```
mov [cell_1+1], 0xc0ffee ; set cell 1
```

Of course, for a proof of concept, we should actually _compute_ something,
without reading data.  As is typical in this situation, the BrainF#$! language
is an ideal candidate for implementation - our fetch cells can be easily adapted
to fit the BF memory model.  Reads from the BF memory space are performed
through a jmp to the BF data cell, which loads an immediate, and jmps back;
writes to the BF memory space are executed as self modifying code, overwriting
the immediate value loaded by the data cell.  To satisfy our 'no data fetch'
requirement, we implement a BrainF#$! interpreter without a stack.  The I/O BF
instructions (. and ,), which use an int 0x80, will, at some point, use data
reads of course, but this is merely a result of the Linux implementation of I/O.

The result is functioning Turing-machines on [ARM](arm/tiresias.s) and
[x86](x86/tiresias.asm) capable of execution without ever touching the data
read pipeline.  Practical applications are nonexistent.

```
# build:
$ make

# verify there are no ARM data fetches:
$ objdump -d tiresias | grep -e ldr -e ldm

# or for x86:
$ objdump -d tiresias | grep '),'
$ objdump -d tiresias | grep -v mov | grep ',('

# execute a program without reading data:
$ cat hello_world.by | ./tiresias
  Hello World!
```

### Acknowledgements

This work is inspired by the blog post 'x86 is Turing-complete with no
registers'.
http://mainisusuallyafunction.blogspot.com/2014/02/x86-is-turing-complete-with-no-registers.html

### Author

Tiresias is a proof-of-concept from Christopher Domas
([@xoreaxeaxeax](https://twitter.com/xoreaxeaxeax)).
