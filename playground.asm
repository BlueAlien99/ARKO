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
main:	
	

	li	$v0, 1
	li	$a0, 0x00000011
	syscall
	li	$v0, 1
	li	$a0, 0x00000011
	syscall



loopEnd:
#	li	$v0, 16
#	addu	$a0, $s0
#	syscall
	li	$v0, 10
	syscall
	
	

