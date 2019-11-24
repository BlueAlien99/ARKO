# TODO: Fixed-point accuracy

.data
filei:	.asciiz	"./bitmap360.bmp"
fileo:	.asciiz	"./output.bmp"

mevy:	.asciiz	"Enter vertical velocity [0, 16):\n"				# (5+27)
mevx:	.asciiz	"Enter horizontal velocity [0, 16):\n"				# (4+28)
meloe:	.asciiz	"Enter part of energy kept after each bounce [0, 1):\n"		# (1+31)

svy:	.space	16
svx:	.space	16
sloe:	.space	16

gconst:	.word	0x9ce809d4	# gravitational acceleration == 9.80665 (4+28)
dt:	.word	0x01000000	# time step == 0.0078125 (1/128) s (1+31)
tau:	.word	0x08000000	# defines how long the ball is touching ground during bounce == 62.5 ms (1+31)

colorR:	.byte	0x19
colorG:	.byte	0x76
colorB:	.byte	0xd2

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
	srl	$s0, $v0, 1
	la	$a0, svx
	jal	convertBegin
	addu	$s1, $v0, $zero
	la	$a0, sloe
	jal	convertBegin
	sll	$s2, $v0, 3
	
	bltu	$s2, 0x80000000, loeGood
	li	$s2, 0x60000000	# 0.75
loeGood:
	li	$s3, 1	# bool freefall
	li	$s4, 0	# h (6+26)
	li	$s5, 0	# s (8+24)
	li	$s6, 0	# i
	addu	$s7, $s0, $zero	# vmax (4+28)
	
	lw	$t0, dt
	lw	$t1, gconst
	multu	$t1, $t0
	mfhi	$t3			# double y = g*dt;
	
	li	$v0, 9
	li	$a0, 8192
	syscall
	addu	$t9, $v0, $zero

# Start of the main loop
loopCnt:				# do{
	sw	$s5, ($t9)
	addiu	$t9, $t9, 4
	sw	$s4, ($t9)
	addiu	$t9, $t9, 4
	
	addiu	$s6, $s6, 1			# ++i;
	beqz	$s3, noFreefall			# if(freefall){
	multu	$t0, $s1
	mfhi	$t2
	srl	$t2, $t2, 3
	addu	$s5, $s5, $t2				# s = s + vx*dt;
	mul	$t2, $t0, $s0
	mfhi	$t2					# double x = vy*dt;
	add	$s4, $s4, $t2				# h = h+x;
	sub	$s0, $s0, $t3				# vy = vy-y;
	bgt	$s4, 0, loopCntIf			# if(h <= 0){
	li	$s3, 0						# freefall = 0;
	li	$s4, 0						# h = 0;
							# }
	b	loopCntIf			# }
noFreefall:					# else{
	lw	$t2, tau
	multu	$s1, $t2
	mfhi	$t2
	srl	$t2, $t2, 3
	addu	$s5, $s5, $t2				# s = s + vx*tau;
	multu	$s7, $s2
	mfhi	$t2
	sll	$s7, $t2, 1				# vmax = vmax*rho;
	addu	$s0, $s7, $zero				# vy = vmax;
	li	$s3, 1					# freefall = true;
loopCntIf:					# }
	blt	$s6, 1024, loopCnt	# } while(i < 1024);


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
	
# Get size of pixel array
	addiu	$a0, $t8, 5
	jal	get4bytes
	subiu	$s2, $v0, 54
	
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
	addiu	$a0, $t8, 21
	jal	get4bytes
	addu	$s4, $v0, $zero

# Get height
# $s5 - height in pixels
	addiu	$a0, $t8, 25
	jal	get4bytes
	addu	$s5, $v0, $zero
	
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

# Get pixels per meter
# $t6 - width ppm (5+27)
# $t7 - height ppm (8+24)
	sll	$t6, $s4, 21
	sll	$t7, $s5, 21


	b	skipPrinting
# ---- ---- Print coordinates ---- ----
	subiu	$t9, $t9, 8192
	li	$t5, 0
cntPrnt:
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
	blt	$t5, 1024, cntPrnt	# while(i < 1024)
# ---- ---- Print coordinates ---- ----
skipPrinting:


# ---- ---- Draw on bitmap ---- ----
	subiu	$t9, $t9, 8192
	li	$t5, 0
	li	$t2, 3
cntDraw:
	addiu	$t5, $t5, 1
	lw	$t0, ($t9)		# $t0 - ball's s
	addiu	$t9, $t9, 4
	lw	$t1, ($t9)		# $t1 - ball's h
	addiu	$t9, $t9, 4
	
	li	$t3, 64			# continue if out of graphing area
	sll	$t3, $t3, 24
	bge	$t0, $t3, cntDrawIf
	li	$t3, 8
	sll	$t3, $t3, 26
	bge	$t1, $t3, cntDrawIf
	
	# $t0 and $t1 are now num of pixels relative to (0, 0)
	multu	$t0, $t6
	mfhi	$t0
	andi	$t3, $t0, 0x00040000
	beqz	$t3, sroX
#	addiu	$t0, $t0, 0x00080000
sroX:	srl	$t0, $t0, 19

	multu	$t1, $t7
	mfhi	$t1
	andi	$t3, $t1, 0x00020000
	beqz	$t3, sroY
#	addiu	$t1, $t1, 0x00040000
sroY:	srl	$t1, $t1, 18
	
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
	lbu	$t4, colorB
	sb	$t4, 0($t3)
	lbu	$t4, colorG
	sb	$t4, 1($t3)
	lbu	$t4, colorR
	sb	$t4, 2($t3)
	
cntDrawIf:
	blt	$t5, 1024, cntDraw	# while(i < 1024)
# ---- ---- Draw on bitmap ---- ----


# TODO: comments and whitespaces

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
	lbu	$t2, ($t0)
	blt	$t2, '0', convertShift
	multu	$t1, $t9
	mflo	$t1
	subiu	$t2, $t2, '0'
	addu	$t1, $t1, $t2
	addiu	$t0, $t0, 1
	b	convertInt
convertShift:
	sll	$t1, $t1, 28
	bne	$t2, '.', convertEnd
convertReadDecimalPart:
	addiu	$t0, $t0, 1
	lbu	$t2, ($t0)
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
	li	$t8, 1000000
	multu	$t3, $t8
	mflo	$t3
	li	$t9, 500000000
	li	$t8, 0x08000000
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


# Converts 4 bytes from LittleEndian to BigEndian
# $a0 - location of last byte
get4bytes:
	li	$v0, 0
	li	$a1, 4
getNextByte:
	sll	$v0, $v0, 8
	lbu	$a2, ($a0)
	addu	$v0, $v0, $a2
	subiu	$a0, $a0, 1
	subiu	$a1, $a1, 1
	bnez	$a1, getNextByte
	jr	$ra
