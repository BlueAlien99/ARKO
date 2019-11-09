# Fixed-point convention: 22+10 -> accuracy of 0.001 (1/1024)

.data
mevy:	.asciiz	"Enter vertical velocity:\n"
mevx:	.asciiz	"Enter horizontal velocity:\n"
meloe:	.asciiz	"Enter percentage of energy kept after each bounce:\n"

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
	li	$a1, 0
	jal	convertBegin
	addu	$s0, $v0, $zero
	la	$a0, svx
	li	$a1, 0
	jal	convertBegin
	addu	$s1, $v0, $zero
	la	$a0, sloe
	li	$a1, 1
	jal	convertBegin
	addu	$s2, $v0, $zero
	
	li	$v0, 10
	syscall
	
	
# Converts string to fixed-point number, max 3 digits after comma
# $a0 - address of a string
# $a1 - 1 if string is a decimal part of a number, else 0
convertBegin:
	addu	$t0, $a0, $zero
	li	$t1, 0		# integral part
	li	$t9, 10
	li	$t3, 0		# decimal part
	li	$t4, 0		# count for reading decimal part (max 3 digits)
	bnez	$a1, convertReadDecimalPart
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