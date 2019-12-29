extern printf

section .data
gconst	dq 9.80665		; gravitational acceleration
tstep	dq 0.001953125	; 1/512 s -- time step
tau		dq 0.0625		; 1/16 s -- defines how long the ball is touching ground during bounce

colorR	db 0x19
colorG	db 0x76
colorB	db 0xd2

msg		db "%lld", 9, "%lf", 9, "%lf", 10, 0
msg2	db "x = %lld -> vx = %.2lf", 10, "y = %lld -> vy = %.2lf", 10, 10, 0

section .text
global fun

fun:
	push rbp
	mov rbp, rsp

	mov r10, rdi		; pointer to pixels
	mov r11, rcx		; bytes per row
	mov r12, rsi		; width
	mov r13, rdx		; height

	; r8 - mouse y
	; r9 - mouse x

	mov rax, r12
	shr rax, 4			; get 1/16 of width
	sub r9, rax			; mouse x relative to x = 0
	sub r12, rax
	sub r12, 1			; width = (1/16)*width - 1 --> width of graphing area
	mov rcx, 3
	mul rcx				; each pixel has 3 bytes
	add r10, rax		; move ptr to pixels from (0,0) to (x,0)

	mov rax, r13
	shr rax, 4			; get 1/16 of height
	mov r15, r13
	sub r15, r8
	mov r8, r15
	sub r8, rax			; mouse y relative to y = 0
	sub r13, rax
	sub r13, 1			; height = (1/16)*height - 1 --> height of graphing area
	mul r11				; each horizontal line of pixels has r11 bytes
	add r10, rax		; move ptr to pixels from (x,0) to (x,y)

	cmp r8, 0			; check if mouse y was outside graphing area
	jg posmy
	mov r8, 0
posmy:
	mov r14, r13
	shr r14, 1			; max vy is in the middle of graphing area
	cmp r8, r14			; check if mouse y was greater than max vy
	jl nofmy
	mov r8, r14
nofmy:

	cmp r9, 0			; check if mouse x was outside graphing area
	jg posmx
	mov r9, 0
posmx:
	mov r15, r12
	shr r15, 1			; max vx is in the middle of graphing area
	cmp r9, r15			; check if mouse x was greater than max vx
	jl nofmx
	mov r9, r15
nofmx:

	mov rax, 64				; max vy = 64
	cvtsi2sd xmm13, rax
	cvtsi2sd xmm8, r14
	divsd xmm13, xmm8		; get vy per pixel (linear scale)
	cvtsi2sd xmm8, r8
	mulsd xmm13, xmm8		; vpp * pixels = vy

	mov rax, 128			; max vx = 128
	cvtsi2sd xmm14, rax
	cvtsi2sd xmm8, r15
	divsd xmm14, xmm8		; get vx per pixel (linear scale)
	cvtsi2sd xmm8, r9
	mulsd xmm14, xmm8		; vpp * pixels = vx

	movsd xmm15, xmm0		; K

	sub rsp, 48
	movdqa [rbp-16], xmm13
	movdqa [rbp-32], xmm14
	movdqa [rbp-48], xmm15
	push r10
	push r11
	push r12
	push r13

	movsd xmm0, xmm14
	movsd xmm1, xmm13
	mov rsi, r9
	mov rdx, r8
	mov rax, 2
	mov rdi, msg2
	call printf				; print info about calculated velocity

	pop r13
	pop r12
	pop r11
	pop r10
	movdqa xmm13, [rbp-16]
	movdqa xmm14, [rbp-32]
	movdqa xmm15, [rbp-48]
	add rsp, 48

	movsd xmm8, [gconst]
	movsd xmm9, [tstep]
	movsd xmm10, [tau]
	xorps xmm11, xmm11		; s = 0
	xorps xmm12, xmm12		; h = 0
							; vy -> xmm13
							; vx -> xmm14
							; K  -> xmm15
	mov r14, 1			; freefall
	mov r15, 0			; loop counter

	mov rax, 64
	cvtsi2sd xmm0, rax
	cvtsi2sd xmm1, r12		; divide width by 64 (scale)
	divsd xmm1, xmm0		; width ppm (pixels per meter)

	mov rax, 8
	cvtsi2sd xmm0, rax
	cvtsi2sd xmm2, r13		; divide height by 8 (scale)
	divsd xmm2, xmm0		; height ppm

	sub rsp, 160
mainloop:				; do{
	mov rax, 64
	cvtsi2sd xmm0, rax
	comisd xmm0, xmm11
	jbe end					; exit loop if s >= 64

	mov rax, 8
	cvtsi2sd xmm0, rax
	comisd xmm0, xmm12
	jbe skipDrawing			; skip drawing if h >= 8

	mov r8, r10				; pixel to color (base address)

	movsd xmm0, xmm11
	mulsd xmm0, xmm1		; get pixel offset (width) --> ppm * s
	roundsd xmm0, xmm0, 0
	cvtsd2si rax, xmm0		; round and convert to integer
	mov rcx, 3
	mul rcx					; get byte offset --> pixel offset * 3 bytes
	add r8, rax				; add byte offset to base address

	movsd xmm0, xmm12
	mulsd xmm0, xmm2		; get pixel offset (height) --> ppm * h
	roundsd xmm0, xmm0, 0
	cvtsd2si rax, xmm0		; round and convert to integer
	mul r11					; get byte offset --> pixel offset * bytes per row
	add r8, rax				; add byte offset to (base address + width offset)

	mov al, [colorB]
	mov [r8], al
	mov al, [colorG]
	mov [1+r8], al
	mov al, [colorR]
	mov [2+r8], al

skipDrawing:
	jmp skipPrintf
	movdqa [rbp-16], xmm8
	movdqa [rbp-32], xmm9
	movdqa [rbp-48], xmm10
	movdqa [rbp-64], xmm11
	movdqa [rbp-80], xmm12
	movdqa [rbp-96], xmm13
	movdqa [rbp-112], xmm14
	movdqa [rbp-128], xmm15
	movdqa [rbp-144], xmm1
	movdqa [rbp-160], xmm2
	push r10
	push r11

	movsd xmm0, xmm11
	movsd xmm1, xmm12
	mov rsi, r15
	mov rax, 2
	mov rdi, msg
	call printf				; cout<<i<<'\t'<<s<<'\t'<<h<<'\n';

	pop r11
	pop r10
	movdqa xmm8, [rbp-16]
	movdqa xmm9, [rbp-32]
	movdqa xmm10, [rbp-48]
	movdqa xmm11, [rbp-64]
	movdqa xmm12, [rbp-80]
	movdqa xmm13, [rbp-96]
	movdqa xmm14, [rbp-112]
	movdqa xmm15, [rbp-128]
	movdqa xmm1, [rbp-144]
	movdqa xmm2, [rbp-160]
skipPrintf:
	cmp r14, 0
	jz nofreefall			; if(freefall){
	movsd xmm0, xmm14
	mulsd xmm0, xmm9
	addsd xmm11, xmm0			; s = s + vx*dt;
	movsd xmm7, xmm8
	mulsd xmm7, xmm9			; y = g*dt
	movsd xmm6, xmm13
	mulsd xmm6, xmm9			; x = vy*dt;
	movsd xmm5, xmm15
	mulsd xmm5, xmm9			; K*dt
	movsd xmm4, xmm14
	mulsd xmm4, xmm4
	mulsd xmm4, xmm5			; vxt = K*vx*vx*dt;
	movsd xmm3, xmm13
	mulsd xmm3, xmm3
	mulsd xmm3, xmm5			; vyt = K*vy*vy*dt;
	addsd xmm12, xmm6			; h = h+x;
	subsd xmm14, xmm4			; vx = vx-vxt;
	xorps xmm0, xmm0
	comisd xmm0, xmm12
	jae negh					; if(h > 0){
	subsd xmm13, xmm7				; vy = vy-y;
	xorps xmm0, xmm0
	comisd xmm0, xmm13
	jb posvy						; if(vy <= 0){
	addsd xmm13, xmm3					; vy = vy+vyt;
	jmp whilecond					; }
posvy:								; else{
	subsd xmm13, xmm3					; vy = vy-vyt;
	jmp whilecond					; }
negh:							; else{
	mov r14, 0						; freefall = 0;
	xorps xmm12, xmm12				; h = 0;
								; }
	jmp whilecond			; }
nofreefall:					; else{
	movsd xmm0, xmm14
	mulsd xmm0, xmm10
	addsd xmm11, xmm0			; s = s + vx*tau;
	mov rax, -1
	cvtsi2sd xmm0, rax
	mulsd xmm13, xmm0			; vy = vy * (-1);
	mov r14, 1					; freefall = true;
whilecond:					; }
	inc r15					; ++i;
	cmp r15, 16384
	jnz mainloop		; } while(i < 1024);
end:
	mov rsp, rbp
	pop rbp
	ret
