@
@ tiresias
@ arm is turing-complete without data fetches
@ domas, @xoreaxeaxeax
@

.arch armv6t2
.fpu softvfp

.macro mov32, reg, val
	movw  \reg, #:lower16:\val
	movt  \reg, #:upper16:\val
.endm

.macro simcall target
	mov32 r9, 1f
	b     \target
	1:
.endm

.macro simfetch from, cell
	mov   r0, \cell
	lsl   r0, #3
	mov32 r1, \from
	add   r0, r1
	mov32 r9, 1f
	bx    r0
	1:
.endm

.macro simwrite to, cell
	mov   r4, \cell
	lsl   r4, #3
	mov32 r1, \to
	add   r4, r1
	strb  r0, [r4]
.endm

.text
.align 2

.global _start
_start:
	mov   r6, #0 @ ip
	mov   r8, #0 @ dp
	mov   r3, #0
.read_program:
    simcall read_byte
	simwrite program, r3
	add   r3, #1
	cmp   r0, #'#'
	bne   .read_program

.execute:
	simfetch program, r6

	cmp   r0, #0
	beq   .exit
	cmp   r0, #'>'
	beq   .increment_dp
	cmp   r0, #'<'
	beq   .decrement_dp
	cmp   r0, #'+'
	beq   .increment_data
	cmp   r0, #'-'
	beq   .decrement_data
	cmp   r0, #'.'
	beq   .output
	cmp   r0, #','
	beq   .input
	cmp   r0, #'['
	beq   .forward
	cmp   r0, #']'
	beq   .backward
	b     .done

.increment_dp:
	add   r8, #1
	b     .done

.decrement_dp:
	sub   r8, #1
	b     .done

.increment_data:
	simfetch data, r8
	add   r0, #1
	simwrite data, r8
	b     .done

.decrement_data:
	simfetch data, r8
	sub   r0, #1
	simwrite data, r8
	b     .done

.output:
	simfetch data, r8
	simcall write_byte
	b     .done
	
.input:
	simcall read_byte
	simwrite data, r8
	b     .done

.forward:
	simfetch data, r8
	cmp   r0, #0
	bne   .done
	mov   r4, #1
.forward.seek:
	add   r6, #1
	simfetch program, r6
	cmp   r0, #']'
	beq   .forward.seek.dec
	cmp   r0, #'['
	beq   .forward.seek.inc
	b     .forward.seek
.forward.seek.inc:
	add   r4, #1
	b     .forward.seek
.forward.seek.dec:
	sub   r4, #1
	cmp   r4, #0
	beq   .done
	b     .forward.seek

.backward:
	simfetch data, r8
	cmp   r0, #0
	beq   .done
	mov   r4, #1
.backward.seek:
	sub   r6, #1
	simfetch program, r6
	cmp   r0, #'['
	beq   .backward.seek.dec
	cmp   r0, #']'
	beq   .backward.seek.inc
	b     .backward.seek
.backward.seek.inc:
	add   r4, #1
	b     .backward.seek
.backward.seek.dec:
	sub   r4, #1
	cmp   r4, #0
	beq   .done
	b     .backward.seek

.done:
	add   r6, #1
	b     .execute

.exit:
	mov   r0, #0
	mov   r7, #1
	svc   0 

.section .data
.align 2

read_byte:
	mov   r0, #0
	mov32 r1, io
	mov   r2, #1
	mov   r7, #3
	svc   0 
io: mov   r0, #0
	bx    r9

write_byte:
	strb  r0, io 
	mov   r0, #1
	mov32 r1, io
	mov   r2, #1
	mov   r7, #4
	svc   0 
	bx    r9

data:
	.rept 30000
	.long 0xe3a00000 @ mov r0, xx
	.long 0xe12fff19 @ bx r9
	.endr

program:
	.rept 30000
	.long 0xe3a00000 @ mov r0, xx
	.long 0xe12fff19 @ bx r9
	.endr
