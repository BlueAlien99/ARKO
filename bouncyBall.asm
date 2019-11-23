# TODO: U2 representation
# TODO: Fixed-point accuracy

# Fixed-point convention: 20+12 -> accuracy of 0.000244 (1/4096)

.data
filei:	.asciiz	"./bitmap360.bmp"
fileo:	.asciiz	"./output.bmp"

mevy:	.asciiz	"Enter vertical velocity:\n"
mevx:	.asciiz	"Enter horizontal velocity:\n"
meloe:	.asciiz	"Enter part of energy kept after each bounce [0,1):\n"

svy:	.space	16
svx:	.space	16
sloe:	.space	16

gconst:	.word	0x00009d00	# gravitational acceleration == 9.8125
dt:	.word	0x00000020	# time step == 0.0078125 (1/128) s
tau:	.word	0x00000100	# defines how long the ball is touching ground during bounce == 62.5 ms

colorB:	.byte	0xd2
colorG:	.byte	0x76
colorR:	.byte	0x19

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
	
	blt	$s2, 0x00001000, loeGood
	li	$s2, 0x00000c00	# 0.75
loeGood:
	li	$s3, 1	# bool freefall
	li	$s4, 0	# h
	li	$s5, 0	# s
	li	$s6, 0	# i
	addu	$s7, $s0, $zero	# vmax
	li	$t8, 0	# bool negvy
	
	li	$v0, 9
	li	$a0, 8192
	syscall
	addu	$t9, $v0, $zero

# Start of the main loop
loopStart:
	bge	$s6, 1024, loopEnd	# while(i < 1024){
	
	sw	$s5, ($t9)
	addiu	$t9, $t9, 4
	sw	$s4, ($t9)
	addiu	$t9, $t9, 4
	
	addiu	$s6, $s6, 1			# ++i;
	beqz	$s3, noFreefall			# if(freefall){
	lw	$t0, dt
	multu	$t0, $s1
	mflo	$t1
	srl	$t1, $t1, 12
	addu	$s5, $s5, $t1				# s = s + vx*dt;
	lw	$t1, gconst
	multu	$t0, $s0
	mflo	$t2
	srl	$t2, $t2, 12				# double x = vy*dt;
	multu	$t1, $t0
	mflo	$t3
	srl	$t3, $t3, 12				# double y = g*dt;
	beqz	$t8, posVY				# if(negvy){
	blt	$t2, $s4, stillFreefall				# if(x >= h){
	li	$s3, 0							# freefall = 0;
	li	$s4, 0							# h = 0;
	b	newNegVY					# }
stillFreefall:							# else{
	subu	$s4, $s4, $t2						# h = h-x;
newNegVY:							# }
	addu	$s0, $s0, $t3					# vy = vy+y;
	b	loopContinue				# }
posVY:							# else{
	addu	$s4, $s4, $t2					# h = h+x;
	bge	$t3, $s0, chgVYsgn				# if(y < vy){
	subu	$s0, $s0, $t3						# vy = vy-y;
	b	loopContinue					# }
chgVYsgn:							# else{
	li	$s0, 0							# vy = 0;
	li	$t8, 1							# negvy = true;
	b	loopContinue					# }
							# }
						# }
noFreefall:					# else{
	lw	$t0, tau
	multu	$s1, $t0
	mflo	$t0
	srl	$t0, $t0, 12
	addu	$s5, $s5, $t0				# s = s + vx*tau;
	multu	$s7, $s2
	mflo	$t0
	srl	$s7, $t0, 12				# vmax = vmax*rho;
	addu	$s0, $s7, $zero				# vy = vmax;
	li	$t8, 0					# negvy = false;
	li	$s3, 1					# freefall = true;
loopContinue:					# }
	b	loopStart		# }
# TODO: branch after jump
loopEnd:

# Open input bitmap
	li	$v0, 13
	la	$a0, filei
	li	$a1, 0
	li	$a2, 0
	syscall
	addu	$s0, $v0, $zero
	
# Open output bitmap
	li	$v0, 13
	la	$a0, fileo
	li	$a1, 1
	li	$a2, 0
	syscall
	addu	$s1, $v0, $zero

# Allocate heap for bmp header
	li	$v0, 9
	li	$a0, 54
	syscall
	addu	$t8, $v0, $zero
	
# Load bmp header
	li	$v0, 14
	addu	$a0, $s0, $zero
	addu	$a1, $t8, $zero
	li	$a2, 54
	syscall
	
# Write bmp header
	li	$v0, 15
	addu	$a0, $s1, $zero
	addu	$a1, $t8, $zero
	li	$a2, 54
	syscall
	
# Get size of bmp
	li	$t0, 5
	li	$s2, 0
getSize:
	blt	$t0, 2, knownSize
	sll	$s2, $s2, 8
	addu	$t2, $t8, $t0
	lbu	$t1, ($t2)
	addu	$s2, $s2, $t1
	subiu	$t0, $t0, 1
	b	getSize
knownSize:
	subiu	$s2, $s2, 54
	
# Allocate heap for pixel array
	li	$v0, 9
	addu	$a0, $s2, $zero
	syscall
	addu	$s3, $v0, $zero
	
# Load pixel array
	li	$v0, 14
	addu	$a0, $s0, $zero
	addu	$a1, $s3, $zero
	addu	$a2, $s2, $zero
	syscall
	
# Get width
# $s4 - width in pixels
	li	$t0, 21
	li	$s4, 0
getWidth:
	blt	$t0, 18, knownWidth
	sll	$s4, $s4, 8
	addu	$t2, $t8, $t0
	lbu	$t1, ($t2)
	addu	$s4, $s4, $t1
	subiu	$t0, $t0, 1
	b	getWidth
knownWidth:

# Get height
# $s5 - height in pixels
	li	$t0, 25
	li	$s5, 0
getHeight:
	blt	$t0, 22, knownHeight
	sll	$s5, $s5, 8
	addu	$t2, $t8, $t0
	lbu	$t1, ($t2)
	addu	$s5, $s5, $t1
	subiu	$t0, $t0, 1
	b	getHeight
knownHeight:

# Get (0, 0) address
	srl	$t0, $s4, 4
	srl	$t1, $s5, 4
	addu	$s6, $s3, $zero
	divu	$s7, $s2, $s5
	# $s4 and $s5 - width and height of graphing area
	subu	$s4, $s4, $t0
	subu	$s5, $s5, $t1
	# 
	li	$t2, 3
	multu	$t0, $t2
	mflo	$t2
	addu	$s6, $s6, $t2
	multu	$t1, $s7
	mflo	$t2
	addu	$s6, $s6, $t2
	
	# color (0, 0) in red
	#li	$t0, 0
	##addiu	$t1, $s6, 1
	##addiu	$t2, $s6, 2
	#sb	$t0, 0($s6)
	#sb	$t0, 1($s6)
	
# TODO: branches at the end of each loop
# TODO: load byte unsigned
# TODO: Get size, width and height - similar
	
# $s0 - input bmp descriptor
# $s1 - output bmp descriptor
# $s2 - size of pixel array
# $s3 - heap address of pixel array
# $s4 - width of graphing area in pixels
# $s5 - height of graphing area in pixels
# $s6 - (0, 0) point
# $s7 - bytes per row
# $t8 - heap address of bmp header
# $t9 - heap address of ball data

# Get pixels per meter -> 26+6
# $t6 - width ppm
# $t7 - height ppm
	addu	$t6, $s4, $zero
	sll	$t7, $s5, 3
	#srl	$t6, $s4, 6
	#srl	$t7, $s5, 3

# TODO: printing not needed in release
# ---- ---- Print coordinates ---- ----
	subiu	$t9, $t9, 8192
	li	$t5, 0
cntPrnt:
	bge	$t5, 1024, draw		# while(i < 1024)
	addiu	$t5, $t5, 1
	li	$v0, 1
	lw	$a0, ($t9)
	addiu	$t9, $t9, 4
	syscall					# cout<<s;
	li	$v0, 11
	addiu	$a0, $zero, ' '
	syscall					# cout<<' ';
	li	$v0, 1
	lw	$a0, ($t9)
	addiu	$t9, $t9, 4
	syscall					# cout<<h;
	li	$v0, 11
	addiu	$a0, $zero, '\n'
	syscall					# cout<<'\n';
	b	cntPrnt
# ---- ---- Print coordinates ---- ----



draw:

# ---- ---- Draw on bitmap ---- ----
	subiu	$t9, $t9, 8192
	li	$t5, 0
	li	$t2, 3
cntDraw:
	bge	$t5, 1024, endEnd	# while(i < 1024)
	addiu	$t5, $t5, 1
	lw	$t0, ($t9)		# $t0 - ball's s
	addiu	$t9, $t9, 4
	lw	$t1, ($t9)		# $t1 - ball's h
	addiu	$t9, $t9, 4
	
	li	$t3, 64			# continue if out of graphing area
	sll	$t3, $t3, 12
	bgt	$t0, $t3, cntDraw
	li	$t3, 8
	sll	$t3, $t3, 12
	bgt	$t1, $t3, cntDraw
	
	# $t0 and $t1 are now num of pixels relative to (0, 0)
	multu	$t0, $t6
	mflo	$t0
	srl	$t0, $t0, 18
	multu	$t1, $t7
	mflo	$t1
	srl	$t1, $t1, 18
	
	# $t0 - num of bytes from (0, 0) - width
	multu	$t0, $t2
	mflo	$t0
	
	# $t1 - num of bytes from (0, 0) - height
	multu	$t1, $s7
	mflo	$t1
	
	# $t3 - pixel to color
	addu	$t3, $s6, $t0
	addu	$t3, $t3, $t1
	
	# Draw
	lb	$t4, colorB
	sb	$t4, 0($t3)
	lb	$t4, colorG
	sb	$t4, 1($t3)
	lb	$t4, colorR
	sb	$t4, 2($t3)
	
	b	cntDraw
# ---- ---- Draw on bitmap ---- ----
# TODO: x pixels and a half


# TODO: comments and whitespaces
endEnd:

# Write pixel array
	li	$v0, 15
	addu	$a0, $s1, $zero
	addu	$a1, $s3, $zero
	addu	$a2, $s2, $zero
	syscall

# Close files and exit
	li	$v0, 16
	addu	$a0, $s0, $zero
	syscall
	li	$v0, 16
	addu	$a0, $s1, $zero
	syscall
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
	sll	$t1, $t1, 12
	bne	$t2, '.', convertEnd
convertReadDecimalPart:
	addiu	$t0, $t0, 1
	lb	$t2, ($t0)
	blt	$t2, '0', convertDecimalPartMultu
	multu	$t3, $t9
	mflo	$t3
	subiu	$t2, $t2, '0'
	addu	$t3, $t3, $t2
	addiu	$t4, $t4, 1
	blt	$t4, 3, convertReadDecimalPart
convertDecimalPartMultu:
	bge	$t4, 3, convertSkipMultu
	multu	$t3, $t9
	mflo	$t3
	bge	$t4, 2, convertSkipMultu
	multu	$t3, $t9
	mflo	$t3
convertSkipMultu:
	li	$t8, 1000
	multu	$t3, $t8
	mflo	$t3
	li	$t9, 500000
	li	$t8, 0x00000800
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
