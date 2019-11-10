# Fixed-point convention: 22+10 -> accuracy of 0.001 (1/1024)

.data
#filenm	.asciiz	"./mips_data.txt"
mevy:	.asciiz	"Enter vertical velocity:\n"
mevx:	.asciiz	"Enter horizontal velocity:\n"
meloe:	.asciiz	"Enter part of energy kept after each bounce [0,1):\n"

svy:	.space	16
svx:	.space	16
sloe:	.space	16

gconst:	.word	0x00002740	# gravitational acceleration == 9.8125
dt:	.word	0x00000001	# time step
tau:	.word	0x00000080	# defines how long the ball is touching ground during bounce == 125 ms
hstop:	.word	0x00000020	# program will stop if max height of the ball is less than ~~ 3 cm

.text
.globl main

# Handle input of 3 variables
main:	li	$v0, 4
	la	$a0, mevy
	syscall
	li	$v0, 8
	la	$a0, svy
	li	$a1, 16
	syscall
	li	$v0, 4
	la	$a0, mevx
	syscall
	li	$v0, 8
	la	$a0, svx
	li	$a1, 16
	syscall
	li	$v0, 4
	la	$a0, meloe
	syscall
	li	$v0, 8
	la	$a0, sloe
	li	$a1, 16
	syscall
	
# Convert variables to fixed-point representation
	la	$a0, svy
	jal	convertBegin
	addu	$s0, $v0, $zero
	la	$a0, svx
	jal	convertBegin
	addu	$s1, $v0, $zero
	la	$a0, sloe
	jal	convertBegin
	addu	$s2, $v0, $zero
	
	blt	$s2, 0x00000400, loeGood
	li	$s2, 0x00000300	# 0.75
loeGood:
#	li	$v0, 13
#	la	$a0, filenm
#	li	$a1, 1
#	li	$a2, 0
#	syscall
#	addu	$s0, $v0, $zero
	
	li	$s3, 1	# bool freefall
	li	$s4, 0	# h
	li	$s5, 0	# s
	li	$s6, 0	# hmax, calculated below
	addu	$s7, $s0, $zero	# vmax
	li	$t8, 0	# bool negvy
	
# Calculate hmax = pow(vmax, 2)/(2*g)
	lw	$t0, gconst
	sll	$t0, $t0, 11
	addu	$t1, $s7, $zero
	sll	$t1, $t1, 10
	divu	$t1, $t1, $t0
	multu	$t1, $s7
	mflo	$s6
	
# Start of the main loop
loopStart:
	lw	$t0, hstop
	ble	$s6, $t0, loopEnd	# while(hmax > hstop){
	beqz	$s3, noFreefall			# if(freefall){
	lw	$t0, dt
	multu	$t0, $s1
	mflo	$t1
	addu	$s5, $s5, $t1				# s = s + vx*dt;
	lw	$t1, gconst
	multu	$t0, $s0
	mflo	$t2					# double x = vy*dt;
	multu	$t1, $t0
	mflo	$t3					# double y = g*dt;
	beqz	$t8, posVY				# if(negvy){
	blt	$t2, $s4, stillFreefall				# if(x >= h){
	li	$s3, 0							# freefall = 0;
	li	$s4, 0							# h = 0;
	b	newNegVY					# }
stillFreefall:							# else{
	subu	$s4, $s4, $t2						# h = h-x;
newNegVY:							# }
	addu	$s0, $s0, $t3					# vy = vy+y;
	b	printCoordinates			# }
posVY:							# else{
	addu	$s4, $s4, $t2					# h = h+x;
	bge	$t3, $s0, chgVYsgn				# if(y < vy){
	subu	$s0, $s0, $t3						# vy = vy-y;
	b	printCoordinates				# }
chgVYsgn:							# else{
	li	$s0, 0							# vy = 0;
	li	$t8, 1							# negvy = true;
	b	printCoordinates				# }
							# }
						# }
noFreefall:					# else{
	lw	$t0, tau
	multu	$s1, $t0
	mflo	$t0
	srl	$t0, $t0, 10
	addu	$s5, $s5, $t0				# s = s + vx*tau;
	multu	$s7, $s2
	mflo	$t0
	srl	$s7, $t0, 10				# vmax = vmax*rho;
	addu	$s0, $s7, $zero				# vy = vmax;
	li	$t8, 0					# negvy = false;
	li	$s3, 1					# freefall = true;
	lw	$t0, gconst
	sll	$t0, $t0, 11
	addu	$t1, $s7, $zero
	sll	$t1, $t1, 10
	divu	$t1, $t1, $t0
	multu	$t1, $s7
	mflo	$s6					# hmax = pow(vmax, 2)/(2*g);
printCoordinates:				# }
	li	$v0, 1
	addu	$a0, $s4, $zero
	syscall					# cout<<h;
	li	$v0, 11
	addiu	$a0, ' ', $zero
	syscall					# cout<<' ';
	li	$v0, 1
	addu	$a0, $s5, $zero
	syscall					# cout<<s;
	li	$v0, 11
	addiu	$a0, '\n', $zero
	syscall					# cout<<'\n';
	b	loopStart		# }



loopEnd:
#	li	$v0, 16
#	addu	$a0, $s0
#	syscall
	li	$v0, 10
	syscall
	
	
# Converts string to fixed-point number, max 3 digits after comma
# $a0 - address of a string
convertBegin:
	addu	$t0, $a0, $zero
	li	$t1, 0		# integral part
	li	$t9, 10
	li	$t3, 0		# decimal part
	li	$t4, 0		# count for reading decimal part (max 3 digits)
convertInt:
	lb	$t2, ($t0)
	beq	$t2, '.', convertShift
	blt	$t2, '0', convertShift
	multu	$t1, $t9
	mflo	$t1
	subiu	$t2, $t2, '0'
	addu	$t1, $t1, $t2
	addiu	$t0, $t0, 1
	b	convertInt
convertShift:
	sll	$t1, $t1, 10
	bne	$t2, '.', convertEnd
convertReadDecimalPart:
	addiu	$t4, $t4, 1
	addiu	$t0, $t0, 1
	lb	$t2, ($t0)
	blt	$t2, '0', convertDecimalPartMultu
	bgt	$t4, 3, convertDecimalPartMultu
	multu	$t3, $t9
	mflo	$t3
	subiu	$t2, $t2, '0'
	addu	$t3, $t3, $t2
	b	convertReadDecimalPart
convertDecimalPartMultu:
	li	$t8, 1000
	multu	$t3, $t8
	mflo	$t3
	li	$t9, 500000
	li	$t8, 0x00000200
convertDecimalPart:
	blt	$t3, $t9, convertDecimalPartSkip
	addu	$t1, $t1, $t8
	subu	$t3, $t3, $t9
convertDecimalPartSkip:
	srl	$t9, $t9, 1
	srl	$t8, $t8, 1
	bnez	$t8, convertDecimalPart
convertEnd:
	addu	$v0, $t1, $zero
	jr	$ra
