;
; tiresias
; x86 is turing-complete without data fetches
; domas, @xoreaxeaxeax
;

USE32

global _start

section .text

%macro simcall 1
	mov  esi, %%retsim
	jmp  %1
%%retsim:
%endmacro
	
%macro simfetch 2
	mov  edi, %2
	shl  edi, 3
	add  edi, %1
	mov  esi, %%retsim
	jmp  edi
%%retsim:
%endmacro

%macro simwrite 2
	mov  edi, %2
	shl  edi, 3
	add  edi, %1+1
	mov  [edi], eax
%%retsim:
%endmacro

_start:
	mov  ebp, 0
.read_program:
    simcall read_byte
	simwrite program, ebp
	inc  ebp
	cmp  al, '#'
	jnz  .read_program

.execute:
	simcall fetch_ip
	simfetch program, eax

	cmp  al, 0
	je   .exit
	cmp  al, '>'
	je   .increment_dp
	cmp  al, '<'
	je   .decrement_dp
	cmp  al, '+'
	je   .increment_data
	cmp  al, '-'
	je   .decrement_data
	cmp  al, '.'
	je   .output
	cmp  al, ','
	je   .input
	cmp  al, '['
	je   .forward
	cmp  al, ']'
	je   .backward
	jmp  .done

.increment_dp:
	simcall fetch_dp
	inc  eax
	mov  [dp], eax
	jmp  .done

.decrement_dp:
	simcall fetch_dp
	dec  eax
	mov  [dp], eax
	jmp  .done

.increment_data:
	simcall fetch_dp
	mov edx, eax
	simfetch data, edx
	inc  eax
	simwrite data, edx
	jmp  .done

.decrement_data:
	simcall fetch_dp
	mov edx, eax
	simfetch data, edx
	dec  eax
	simwrite data, edx
	jmp  .done

.output:
	simcall fetch_dp
	simfetch data, eax
	simcall write_byte
	jmp  .done
	
.input:
	simcall read_byte
	mov  edx, eax
	simcall fetch_dp
	mov  ecx, eax
	mov  eax, edx
	simwrite data, ecx
	jmp  .done

.forward:
	simcall fetch_dp
	simfetch data, eax
	cmp  al, 0
	jne  .done
	mov  ecx, 1
.forward.seek:
	simcall fetch_ip
	inc  eax
	mov  [ip], eax
	simfetch program, eax
	cmp  al, ']'
	je   .forward.seek.dec
	cmp  al, '['
	je   .forward.seek.inc
	jmp  .forward.seek
.forward.seek.inc:
	inc  ecx
	jmp  .forward.seek
.forward.seek.dec:
	dec  ecx
	cmp  ecx, 0
	je   .done
	jmp  .forward.seek

.backward:
	simcall fetch_dp
	simfetch data, eax
	cmp  al, 0
	je  .done
	mov  ecx, 1
.backward.seek:
	simcall fetch_ip
	dec  eax
	mov  [ip], eax
	simfetch program, eax
	cmp  al, '['
	je   .backward.seek.dec
	cmp  al, ']'
	je   .backward.seek.inc
	jmp  .backward.seek
.backward.seek.inc:
	inc  ecx
	jmp  .backward.seek
.backward.seek.dec:
	dec  ecx
	cmp  ecx, 0
	je   .done
	jmp  .backward.seek

.done:
	simcall fetch_ip
	inc  eax
	mov  [ip], eax
	jmp  .execute

.exit:
	mov  eax, 1
	mov  ebx, 0
	int  0x80

section .data

read_byte:
	mov  ebx, 0
	mov  ecx, io
	mov  edx, 1
	mov  eax, 3
	int  0x80
	db 0xb8
io: dd 0
	jmp esi

write_byte:
	mov  ebx, 1
	mov  [io], eax
	mov  ecx, io
	mov  edx, 1
	mov  eax, 4
	int  0x80
	jmp  esi

fetch_ip:    db 0xb8 ; mov eax, xxxxxxxx
ip:          dd 0
             jmp esi
fetch_dp:    db 0xb8 ; mov eax, xxxxxxxx
dp:          dd 0
             jmp esi
data:        times 30000 db 0xb8, 0, 0, 0, 0, 0xff, 0xe6, 0x90 ; mov eax, xxxxxxxx, jmp esi, nop
program:     times 30000 db 0xb8, 0, 0, 0, 0, 0xff, 0xe6, 0x90 ; mov eax, xxxxxxxx, jmp esi, nop
