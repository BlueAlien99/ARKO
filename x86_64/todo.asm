colorR:	.byte	0x19
colorG:	.byte	0x76
colorB:	.byte	0xd2

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
	bgeu	$t0, $t3, endEnd
	li	$t3, 8
	sll	$t3, $t3, 26
	bgeu	$t1, $t3, cntDrawIf

	# $t0 and $t1 are now num of pixels relative to (0, 0)
	multu	$t0, $t6
	mfhi	$t0
	andi	$t3, $t0, 0x00040000
	beqz	$t3, sroX
	addiu	$t0, $t0, 0x00080000
sroX:	srl	$t0, $t0, 19

	multu	$t1, $t7
	mfhi	$t1
	andi	$t3, $t1, 0x00020000
	beqz	$t3, sroY
	addiu	$t1, $t1, 0x00040000
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
