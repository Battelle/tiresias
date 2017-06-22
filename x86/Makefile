tiresias: tiresias.o
	ld -melf_i386 $< -o $@

tiresias.o: tiresias.asm
	nasm -felf $< -o $@

clean:
	rm tiresias tiresias.o
