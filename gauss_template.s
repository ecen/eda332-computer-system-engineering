### Text segment
		.text
start:
		la	$a0, matrix_24x24		# a0 = A (base address of matrix)
		li	$a1, 24    		# a1 = N (number of elements per row)
						# <debug>
		jal 	print_matrix	    	# print matrix before elimination
		nop				# </debug>
		jal 	eliminate		# triangularize matrix!
		nop				# <debug>
		jal 	print_matrix		# print matrix after elimination
		nop				# </debug>
		jal 	exit

exit:
		li   	$v0, 10          	# specify exit system call
   	   	syscall				# exit program

################################################################################
# eliminate - Triangularize matrix.
#
# Args:		$a0  - base address of matrix (A)
#		$a1  - number of elements per row (N)

eliminate:
		
		
		###### ELIMINATE IMPLEMENTATION
		
		# PERFORMANCE RECORD
		# 214K Cycles, Performance: 2012
		# I Cache: Direct, 4 blocks, block size 4
		# D-Cache: 2-Way, 8 blocks, block size 4
		# Memory 30/6, write buffer 8
		
		# REGISTER USAGE TABLE
		#
		#     Keep up to date!
		#
		#     Not including temp registers that store value immediately after use.
		#     Try to use t9 as temp register whenever possible, then t8, t7...
		#     Always check for register use immediately surrounding code area.
		#	
		#     t: primarily pointers/variables/things that move
		#     s: primarily constants or constant pointers
		#
		# -------------------------------------------------------------------------
		# Nr: Description					Name Space (Approx)
		# -------------------------------------------------------------------------
		# t0: Pointer to current pivot.				Pivot Loop
		# t1: Pointer to current element on row.		Right Loop
		# t2: Pointer to current col element.			Pivot Loop
		# t3: Pointer offset from col elem to cur row elem.	Column Loop
		# t4: Pointer to current element on current row.	Row Loop
		# t5: Pointer to current element on pivot row.		Row Loop
		# t6: Last element of pivot row				Column Loop
		# t7: 
		# t8: 
		# t9: Reserved for use as temp register.		TEMP
		# -------------------------------------------------------------------------
		# s0 = (N - 1) * 4					CONST
		# s1 = N * 4						CONST
		# s2 = (N + 1) * 4					CONST
		# s3: Pointer to second last pivot element.		Pivot Loop
		# s4: Pointer to last elem of current row.		Pivot Loop
		# s5: Pointer to last column elem in curr pivot col.	Pivot Loop
		# s6: Pointer to first element in current row.		Pivot Loop
		# s7: Pointer to last element of row.			Pivot Loop
		# -------------------------------------------------------------------------
		# f0: Current pivot element.				Pivot Loop
		# f1: Current element on row.				Right Loop
		# f2: Current column element.				Column Loop
		# f3: A[i][j] - A[i][k] * A[k][j]			Row Loop
		# f4: A[i][k] * A[k][j]					Row Loop
		# f5 = 0						CONST
		# f6 = 1						CONST
		# f7: 
		# f8 - f30: Pivot row elements
		# f31:
		# -------------------------------------------------------------------------
		
		# Constants
		sll	$s1, $a1, 2		# s1 = N * 4
		subiu	$s0, $s1, 4		# s0 = (N - 1) * 4
		addiu	$s2, $s1, 4		# s2 = (N + 1) * 4
		
		#sub.s	$f5, $f5, $f5		# f5 = 0	#Probably not necessary. Gonna leave it as a comment anyway.
		lwc1	$f6, one		# f6 = 1
		
		mul	$t1, $a1, $a1		# total nr of elements in matrix
		
		sll	$s3, $t1, 2		# Convert t1 to pointer offset by multiplying by 4
		addu	$s3, $a0, $s3		# Pointer to element N * N (Outside matrix)
		subu	$s3, $s3, $s1		# Pointer to element N * N - N
		subiu	$s3, $s3, 8		# s3: Pointer to element N * N - N - 2 (Second last pivot element)
		
		# Pivot Loop Setup
		addiu	$t0, $a0, 0		# t0: pointer to current pivot
		addiu	$s6, $a0, 0		# s6: pointer to first element in current row
		mulu	$s5, $a1, $s0		# N * (N - 1) * 4
		addu	$s5, $t0, $s5		# s5 = t0 + N * (N - 1) * 4: Pointer to the last column element in current pivot column.
		# Pivot Loop: Loops over all pivot elements
pivot_loop:	
		## Right Loop Setup
		addiu	$t1, $t0, 4		# t1: pointer to current element on row
		addu	$s7, $s6, $s0		# s7: Pointer to last element of row.
		lwc1	$f0, 0($t0)		# f0 = current pivot element
		## Right Loop: Loops over all elements on pivot row to the right of pivot element
right_loop:	lwc1	$f1, 0($t1)		# f1: current element on row
		div.s	$f1, $f1, $f0		# f1 = f1/f0
		swc1	$f1, 0($t1)		# Store
		bne	$s7, $t1, right_loop
		addiu	$t1, $t1, 4
		## Right Loop End
		
		swc1	$f6, 0($t0)		# pivot = 1
		
		## Column Loop Setup
		# s5: Pointer to the last element in the column
		addiu	$s4, $t0, 4		# s4 = first element of pivot row: Pointer to the first element of current row_loop row.
		addu	$t2, $t0, $s1		# t2 = t0 + N * 4: Pointer to current col element
		addiu	$t6, $s7, 0		# t6: Last element of pivot row
		lwc1	$f30,   0($t6)		#Load all pivot row elements to registers, starting from the right
		lwc1	$f29,  -4($t6)
		lwc1	$f28,  -8($t6)
		lwc1	$f27, -12($t6)
		lwc1	$f26, -16($t6)
		lwc1	$f25, -20($t6)
		lwc1	$f24, -24($t6)
		lwc1	$f23, -28($t6)
		lwc1	$f22, -32($t6)
		lwc1	$f21, -36($t6)		# 10
		lwc1	$f20, -40($t6)
		lwc1	$f19, -44($t6)
		lwc1	$f18, -48($t6)
		lwc1	$f17, -52($t6)
		lwc1	$f16, -56($t6)
		lwc1	$f15, -60($t6)
		lwc1	$f14, -64($t6)
		lwc1	$f13, -68($t6)
		lwc1	$f12, -72($t6)
		lwc1	$f11, -76($t6)		# 20
		lwc1	$f10, -80($t6)
		lwc1	$f9,  -84($t6)
		lwc1	$f8,  -88($t6)		# 23
		## Column Loop: Iterate over each element C in pivot column below pivot element
column_loop:	lwc1	$f2, 0($t2)		# f2: current col element	# TODO Column loop is getting about 11 D-Cache misses each iteration
		### Row Loop Setup
		li	$t3, 92			# t3: Pointer offset from column element to current row element (starting from the right)
		addu	$s4, $s4, $s1		# Point s4 to first element of next row
		### Row Loop: Iterate over each element in the row to the the right of C
row_loop:	addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		#addu	$t5, $t0, $t3		# t5: Pointer to current element on pivot row
		#lwc1	$f4, 0($t5)		# f4: current pivot row element
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f30, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		#bne	$t4, $s4, row_loop
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f29, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f28, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f27, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f26, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f25, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f24, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f23, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f22, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f21, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f20, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f19, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f18, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f17, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f16, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f15, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f14, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f13, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f12, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f11, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f10, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f9, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
		
		addu	$t4, $t2, $t3		# t4: Pointer to current element on current row 
		lwc1	$f3, 0($t4)		# f3 = A[i][j]
		mfc1	$t9, $f3		
		beqz	$t9, row_loop_end
		mul.s	$f4, $f8, $f2		# f4 = A[i][k] * A[k][j]
		sub.s	$f3, $f3, $f4		# f3 -= f4
		swc1	$f3, 0($t4)		# Store
		addiu	$t3, $t3, -4		# Decrease row element offset to point to next row element
row_loop_end:
		

		### Row Loop End
		swc1	$f5, 0($t2)		# A[i][k] = 0. (Set current col element = 0.)
		bne	$t2, $s5, column_loop
		addu	$t2, $t2, $s1		# Point t2 to next col element
		## Column Loop End
		
		addiu	$s5, $s5, 4		# Point last column element pointer to the next element on the last row.
		addu	$s6, $s6, $s1		# s6 += N * 4. Point s6 to first element on next row.
		bne	$t0, $s3, pivot_loop	# Loop if current pivot was not the last element
		addu	$t0, $t0, $s2		# t0 += (N + 1) * 4. Point t0 to next pivot element.
		# Pivot Loop End
		
		swc1	$f6, 0($t0)		# Pivot loop is only run N-1 times. This sets pivot element N to 1.
		
		
		###### ELIMINATE IMPLEMENTATION END

		

		jr	$ra			# return from subroutine
		nop				# this is the delay slot associated with all types of jumps

################################################################################
# print_matrix
#
# This routine is for debugging purposes only. 
# Do not call this routine when timing your code!
#
# print_matrix uses floating point register $f12.
# the value of $f12 is _not_ preserved across calls.
#
# Args:		$a0  - base address of matrix (A)
#		$a1  - number of elements per row (N) 
print_matrix:
		addiu	$sp,  $sp, -20		# allocate stack frame
		sw	$ra,  16($sp)
		sw      $s2,  12($sp)
		sw	$s1,  8($sp)
		sw	$s0,  4($sp) 
		sw	$a0,  0($sp)		# done saving registers

		move	$s2,  $a0		# s2 = a0 (array pointer)
		move	$s1,  $zero		# s1 = 0  (row index)
loop_s1:
		move	$s0,  $zero		# s0 = 0  (column index)
loop_s0:
		l.s	$f12, 0($s2)        	# $f12 = A[s1][s0]
		li	$v0,  2			# specify print float system call
 		syscall				# print A[s1][s0]
		la	$a0,  spaces
		li	$v0,  4			# specify print string system call
		syscall				# print spaces

		addiu	$s2,  $s2, 4		# increment pointer by 4

		addiu	$s0,  $s0, 1       	# increment s0
		blt	$s0,  $a1, loop_s0  	# loop while s0 < a1
		nop
		la	$a0,  newline
		syscall				# print newline
		addiu	$s1,  $s1, 1		# increment s1
		blt	$s1,  $a1, loop_s1  	# loop while s1 < a1
		nop
		la	$a0,  newline
		syscall				# print newline

		lw	$ra,  16($sp)
		lw	$s2,  12($sp)
		lw	$s1,  8($sp)
		lw	$s0,  4($sp)
		lw	$a0,  0($sp)		# done restoring registers
		addiu	$sp,  $sp, 20		# remove stack frame

		jr	$ra			# return from subroutine
		nop				# this is the delay slot associated with all types of jumps

### End of text segment

### Data segment 
		.data
		
### String constants
spaces:
		.asciiz "   "   		# spaces to insert between numbers
newline:
		.asciiz "\n"  			# newline
one:
		.float 1.0
## Input matrix: (4x4) ##
matrix_4x4:	
		.float 57.0
		.float 20.0
		.float 34.0
		.float 59.0
		
		.float 104.0
		.float 19.0
		.float 77.0
		.float 25.0
		
		.float 55.0
		.float 14.0
		.float 10.0
		.float 43.0
		
		.float 31.0
		.float 41.0
		.float 108.0
		.float 59.0
		
		# These make it easy to check if 
		# data outside the matrix is overwritten
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef

## Input matrix: (24x24) ##
matrix_24x24:
		.float	 92.00 
		.float	 43.00 
		.float	 86.00 
		.float	 87.00 
		.float	100.00 
		.float	 21.00 
		.float	 36.00 
		.float	 84.00 
		.float	 30.00 
		.float	 60.00 
		.float	 52.00 
		.float	 69.00 
		.float	 40.00 
		.float	 56.00 
		.float	104.00 
		.float	100.00 
		.float	 69.00 
		.float	 78.00 
		.float	 15.00 
		.float	 66.00 
		.float	  1.00 
		.float	 26.00 
		.float	 15.00 
		.float	 88.00 

		.float	 17.00 
		.float	 44.00 
		.float	 14.00 
		.float	 11.00 
		.float	109.00 
		.float	 24.00 
		.float	 56.00 
		.float	 92.00 
		.float	 67.00 
		.float	 32.00 
		.float	 70.00 
		.float	 57.00 
		.float	 54.00 
		.float	107.00 
		.float	 32.00 
		.float	 84.00 
		.float	 57.00 
		.float	 84.00 
		.float	 44.00 
		.float	 98.00 
		.float	 31.00 
		.float	 38.00 
		.float	 88.00 
		.float	101.00 

		.float	  7.00 
		.float	104.00 
		.float	 57.00 
		.float	  9.00 
		.float	 21.00 
		.float	 72.00 
		.float	 97.00 
		.float	 38.00 
		.float	  7.00 
		.float	  2.00 
		.float	 50.00 
		.float	  6.00 
		.float	 26.00 
		.float	106.00 
		.float	 99.00 
		.float	 93.00 
		.float	 29.00 
		.float	 59.00 
		.float	 41.00 
		.float	 83.00 
		.float	 56.00 
		.float	 73.00 
		.float	 58.00 
		.float	  4.00 

		.float	 48.00 
		.float	102.00 
		.float	102.00 
		.float	 79.00 
		.float	 31.00 
		.float	 81.00 
		.float	 70.00 
		.float	 38.00 
		.float	 75.00 
		.float	 18.00 
		.float	 48.00 
		.float	 96.00 
		.float	 91.00 
		.float	 36.00 
		.float	 25.00 
		.float	 98.00 
		.float	 38.00 
		.float	 75.00 
		.float	105.00 
		.float	 64.00 
		.float	 72.00 
		.float	 94.00 
		.float	 48.00 
		.float	101.00 

		.float	 43.00 
		.float	 89.00 
		.float	 75.00 
		.float	100.00 
		.float	 53.00 
		.float	 23.00 
		.float	104.00 
		.float	101.00 
		.float	 16.00 
		.float	 96.00 
		.float	 70.00 
		.float	 47.00 
		.float	 68.00 
		.float	 30.00 
		.float	 86.00 
		.float	 33.00 
		.float	 49.00 
		.float	 24.00 
		.float	 20.00 
		.float	 30.00 
		.float	 61.00 
		.float	 45.00 
		.float	 18.00 
		.float	 99.00 

		.float	 11.00 
		.float	 13.00 
		.float	 54.00 
		.float	 83.00 
		.float	108.00 
		.float	102.00 
		.float	 75.00 
		.float	 42.00 
		.float	 82.00 
		.float	 40.00 
		.float	 32.00 
		.float	 25.00 
		.float	 64.00 
		.float	 26.00 
		.float	 16.00 
		.float	 80.00 
		.float	 13.00 
		.float	 87.00 
		.float	 18.00 
		.float	 81.00 
		.float	  8.00 
		.float	104.00 
		.float	  5.00 
		.float	 57.00 

		.float	 19.00 
		.float	 26.00 
		.float	 87.00 
		.float	 80.00 
		.float	 72.00 
		.float	106.00 
		.float	 70.00 
		.float	 83.00 
		.float	 10.00 
		.float	 14.00 
		.float	 57.00 
		.float	  8.00 
		.float	  7.00 
		.float	 22.00 
		.float	 50.00 
		.float	 90.00 
		.float	 63.00 
		.float	 83.00 
		.float	  5.00 
		.float	 17.00 
		.float	109.00 
		.float	 22.00 
		.float	 97.00 
		.float	 13.00 

		.float	109.00 
		.float	  5.00 
		.float	 95.00 
		.float	  7.00 
		.float	  0.00 
		.float	101.00 
		.float	 65.00 
		.float	 19.00 
		.float	 17.00 
		.float	 43.00 
		.float	100.00 
		.float	 90.00 
		.float	 39.00 
		.float	 60.00 
		.float	 63.00 
		.float	 49.00 
		.float	 75.00 
		.float	 10.00 
		.float	 58.00 
		.float	 83.00 
		.float	 33.00 
		.float	109.00 
		.float	 63.00 
		.float	 96.00 

		.float	 82.00 
		.float	 69.00 
		.float	  3.00 
		.float	 82.00 
		.float	 91.00 
		.float	101.00 
		.float	 96.00 
		.float	 91.00 
		.float	107.00 
		.float	 81.00 
		.float	 99.00 
		.float	108.00 
		.float	 73.00 
		.float	 54.00 
		.float	 18.00 
		.float	 91.00 
		.float	 97.00 
		.float	  8.00 
		.float	 71.00 
		.float	 27.00 
		.float	 69.00 
		.float	 25.00 
		.float	 77.00 
		.float	 34.00 

		.float	 36.00 
		.float	 25.00 
		.float	  8.00 
		.float	 69.00 
		.float	 24.00 
		.float	 71.00 
		.float	 56.00 
		.float	106.00 
		.float	 30.00 
		.float	 60.00 
		.float	 79.00 
		.float	 12.00 
		.float	 51.00 
		.float	 65.00 
		.float	103.00 
		.float	 49.00 
		.float	 36.00 
		.float	 93.00 
		.float	 47.00 
		.float	  0.00 
		.float	 37.00 
		.float	 65.00 
		.float	 91.00 
		.float	 25.00 

		.float	 74.00 
		.float	 53.00 
		.float	 53.00 
		.float	 33.00 
		.float	 78.00 
		.float	 20.00 
		.float	 68.00 
		.float	  4.00 
		.float	 45.00 
		.float	 76.00 
		.float	 74.00 
		.float	 70.00 
		.float	 38.00 
		.float	 20.00 
		.float	 67.00 
		.float	 68.00 
		.float	 80.00 
		.float	 36.00 
		.float	 81.00 
		.float	 22.00 
		.float	101.00 
		.float	 75.00 
		.float	 71.00 
		.float	 28.00 

		.float	 58.00 
		.float	  9.00 
		.float	 28.00 
		.float	 96.00 
		.float	 75.00 
		.float	 10.00 
		.float	 12.00 
		.float	 39.00 
		.float	 63.00 
		.float	 65.00 
		.float	 73.00 
		.float	 31.00 
		.float	 85.00 
		.float	 31.00 
		.float	 36.00 
		.float	 20.00 
		.float	108.00 
		.float	  0.00 
		.float	 91.00 
		.float	 36.00 
		.float	 20.00 
		.float	 48.00 
		.float	105.00 
		.float	101.00 

		.float	 84.00 
		.float	 76.00 
		.float	 13.00 
		.float	 75.00 
		.float	 42.00 
		.float	 85.00 
		.float	103.00 
		.float	100.00 
		.float	 94.00 
		.float	 22.00 
		.float	 87.00 
		.float	 60.00 
		.float	 32.00 
		.float	 99.00 
		.float	100.00 
		.float	 96.00 
		.float	 54.00 
		.float	 63.00 
		.float	 17.00 
		.float	 30.00 
		.float	 95.00 
		.float	 54.00 
		.float	 51.00 
		.float	 93.00 

		.float	 54.00 
		.float	 32.00 
		.float	 19.00 
		.float	 75.00 
		.float	 80.00 
		.float	 15.00 
		.float	 66.00 
		.float	 54.00 
		.float	 92.00 
		.float	 79.00 
		.float	 19.00 
		.float	 24.00 
		.float	 54.00 
		.float	 13.00 
		.float	 15.00 
		.float	 39.00 
		.float	 35.00 
		.float	102.00 
		.float	 99.00 
		.float	 68.00 
		.float	 92.00 
		.float	 89.00 
		.float	 54.00 
		.float	 36.00 

		.float	 43.00 
		.float	 72.00 
		.float	 66.00 
		.float	 28.00 
		.float	 16.00 
		.float	  7.00 
		.float	 11.00 
		.float	 71.00 
		.float	 39.00 
		.float	 31.00 
		.float	 36.00 
		.float	 10.00 
		.float	 47.00 
		.float	102.00 
		.float	 64.00 
		.float	 29.00 
		.float	 72.00 
		.float	 83.00 
		.float	 53.00 
		.float	 17.00 
		.float	 97.00 
		.float	 68.00 
		.float	 56.00 
		.float	 22.00 

		.float	 61.00 
		.float	 46.00 
		.float	 91.00 
		.float	 43.00 
		.float	 26.00 
		.float	 35.00 
		.float	 80.00 
		.float	 70.00 
		.float	108.00 
		.float	 37.00 
		.float	 98.00 
		.float	 14.00 
		.float	 45.00 
		.float	  0.00 
		.float	 86.00 
		.float	 85.00 
		.float	 32.00 
		.float	 12.00 
		.float	 95.00 
		.float	 79.00 
		.float	  5.00 
		.float	 49.00 
		.float	108.00 
		.float	 77.00 

		.float	 23.00 
		.float	 52.00 
		.float	 95.00 
		.float	 10.00 
		.float	 10.00 
		.float	 42.00 
		.float	 33.00 
		.float	 72.00 
		.float	 89.00 
		.float	 14.00 
		.float	  5.00 
		.float	  5.00 
		.float	 50.00 
		.float	 85.00 
		.float	 76.00 
		.float	 48.00 
		.float	 13.00 
		.float	 64.00 
		.float	 63.00 
		.float	 58.00 
		.float	 65.00 
		.float	 39.00 
		.float	 33.00 
		.float	 97.00 

		.float	 52.00 
		.float	 18.00 
		.float	 67.00 
		.float	 57.00 
		.float	 68.00 
		.float	 65.00 
		.float	 25.00 
		.float	 91.00 
		.float	  7.00 
		.float	 10.00 
		.float	101.00 
		.float	 18.00 
		.float	 52.00 
		.float	 24.00 
		.float	 90.00 
		.float	 31.00 
		.float	 39.00 
		.float	 96.00 
		.float	 37.00 
		.float	 89.00 
		.float	 72.00 
		.float	  3.00 
		.float	 28.00 
		.float	 85.00 

		.float	 68.00 
		.float	 91.00 
		.float	 33.00 
		.float	 24.00 
		.float	 21.00 
		.float	 67.00 
		.float	 12.00 
		.float	 74.00 
		.float	 86.00 
		.float	 79.00 
		.float	 22.00 
		.float	 44.00 
		.float	 34.00 
		.float	 47.00 
		.float	 25.00 
		.float	 42.00 
		.float	 58.00 
		.float	 17.00 
		.float	 61.00 
		.float	  1.00 
		.float	 41.00 
		.float	 42.00 
		.float	 33.00 
		.float	 81.00 

		.float	 28.00 
		.float	 71.00 
		.float	 60.00 
		.float	101.00 
		.float	 75.00 
		.float	 89.00 
		.float	 76.00 
		.float	 34.00 
		.float	 71.00 
		.float	  0.00 
		.float	 58.00 
		.float	 92.00 
		.float	 68.00 
		.float	 70.00 
		.float	 57.00 
		.float	 44.00 
		.float	 39.00 
		.float	 79.00 
		.float	 88.00 
		.float	 74.00 
		.float	 16.00 
		.float	  3.00 
		.float	  6.00 
		.float	 75.00 

		.float	 20.00 
		.float	 68.00 
		.float	 77.00 
		.float	 62.00 
		.float	  0.00 
		.float	  0.00 
		.float	 33.00 
		.float	 28.00 
		.float	 72.00 
		.float	 94.00 
		.float	 19.00 
		.float	 37.00 
		.float	 73.00 
		.float	 96.00 
		.float	 71.00 
		.float	 34.00 
		.float	 97.00 
		.float	 20.00 
		.float	 17.00 
		.float	 55.00 
		.float	 91.00 
		.float	 74.00 
		.float	 99.00 
		.float	 21.00 

		.float	 43.00 
		.float	 77.00 
		.float	 95.00 
		.float	 60.00 
		.float	 81.00 
		.float	102.00 
		.float	 25.00 
		.float	101.00 
		.float	 60.00 
		.float	102.00 
		.float	 54.00 
		.float	 60.00 
		.float	103.00 
		.float	 87.00 
		.float	 89.00 
		.float	 65.00 
		.float	 72.00 
		.float	109.00 
		.float	102.00 
		.float	 35.00 
		.float	 96.00 
		.float	 64.00 
		.float	 70.00 
		.float	 83.00 

		.float	 85.00 
		.float	 87.00 
		.float	 28.00 
		.float	 66.00 
		.float	 51.00 
		.float	 18.00 
		.float	 87.00 
		.float	 95.00 
		.float	 96.00 
		.float	 73.00 
		.float	 45.00 
		.float	 67.00 
		.float	 65.00 
		.float	 71.00 
		.float	 59.00 
		.float	 16.00 
		.float	 63.00 
		.float	  3.00 
		.float	 77.00 
		.float	 56.00 
		.float	 91.00 
		.float	 56.00 
		.float	 12.00 
		.float	 53.00 

		.float	 56.00 
		.float	  5.00 
		.float	 89.00 
		.float	 42.00 
		.float	 70.00 
		.float	 49.00 
		.float	 15.00 
		.float	 45.00 
		.float	 27.00 
		.float	 44.00 
		.float	  1.00 
		.float	 78.00 
		.float	 63.00 
		.float	 89.00 
		.float	 64.00 
		.float	 49.00 
		.float	 52.00 
		.float	109.00 
		.float	  6.00 
		.float	  8.00 
		.float	 70.00 
		.float	 65.00 
		.float	 24.00 
		.float	 24.00 

### End of data segment
