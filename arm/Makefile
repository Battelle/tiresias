tiresias: tiresias.o
	arm-linux-gnueabi-ld $< -o $@
	
tiresias.o: tiresias.s
	arm-linux-gnueabi-as $< -o $@

clean:
	rm tiresias tiresias.o
