extern printf

section .data
gconst	dq 9.80665		; gravitational acceleration
tstep	dq 0.0078125	; 1/128 s -- time step
tau		dq 0.0625		; 1/16 s -- defines how long the ball is touching ground during bounce

;msg		db "%lld", 9, "%lf", 9, "%lf", 9, "%lf", 9, "%lf", 10, 0
msg		db "%lld", 9, "%lf", 9, "%lf", 10, 0

section .text
global fun

fun:
	push rbp
	mov rbp, rsp

	movsd xmm8, [gconst]
	movsd xmm9, [tstep]
	movsd xmm10, [tau]
	xorps xmm11, xmm11		; s = 0
	xorps xmm12, xmm12		; h = 0
	movsd xmm13, xmm0		; vy
	movsd xmm14, xmm1		; vx
	movsd xmm15, xmm2		; K
	mov r14, 1			; freefall
	mov r15, 0			; loop counter

	sub rsp, 128
mainloop:				; do{
	movdqa [rbp-16], xmm8
	movdqa [rbp-32], xmm9
	movdqa [rbp-48], xmm10
	movdqa [rbp-64], xmm11
	movdqa [rbp-80], xmm12
	movdqa [rbp-96], xmm13
	movdqa [rbp-112], xmm14
	movdqa [rbp-128], xmm15

	movsd xmm0, xmm11
	movsd xmm1, xmm12
	;movsd xmm2, xmm14
	;movsd xmm3, xmm13
	mov rsi, r15
	mov rax, 2
	mov rdi, msg
	call printf				; cout<<i<<'\t'<<s<<'\t'<<h<<'\n';

	movdqa xmm8, [rbp-16]
	movdqa xmm9, [rbp-32]
	movdqa xmm10, [rbp-48]
	movdqa xmm11, [rbp-64]
	movdqa xmm12, [rbp-80]
	movdqa xmm13, [rbp-96]
	movdqa xmm14, [rbp-112]
	movdqa xmm15, [rbp-128]

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
	mulsd xmm4, xmm5			; vxt = rho*vx*vx*dt;
	movsd xmm3, xmm13
	mulsd xmm3, xmm3
	mulsd xmm3, xmm5			; vyt = rho*vy*vy*dt;
	addsd xmm12, xmm6			; h = h+x;
	subsd xmm14, xmm4			; vx = vx-vxt;
	subsd xmm13, xmm7			; vy = vy-y;
	xorps xmm0, xmm0
	comisd xmm0, xmm13
	jb posvy					; if(vy <= 0){
	addsd xmm13, xmm3				; vy = vy+vyt;
	jmp negh					; }
posvy:							; else{
	subsd xmm13, xmm3				; vy = vy-vyt;
negh:							; }
	xorps xmm0, xmm0
	comisd xmm0, xmm12
	jb whilecond				; if(h <= 0){
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
	cmp r15, 2048
	jnz mainloop		; } while(i < 1024);

	mov rsp, rbp
	pop rbp
	ret
