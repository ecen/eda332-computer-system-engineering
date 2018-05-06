### Text segment

		.text

start:

		la		$a0, matrix_4x4		# a0 = A (base address of matrix)

		li		$a1, 4    		    # a1 = N (number of elements per row)

									# <debug>

		jal 	print_matrix	    # print matrix before elimination

		nop							# </debug>

		jal 	eliminate			# triangularize matrix!

		nop							# <debug>

		jal 	print_matrix		# print matrix after elimination

		nop							# </debug>

		jal 	exit



exit:

		li   	$v0, 10          	# specify exit system call

      	syscall						# exit program



################################################################################

# eliminate - Triangularize matrix.

#




eliminate:

		# If necessary, create stack frame, and save return address from ra
		
		addiu	$sp, $sp, -4		# allocate stack frame

		sw		$ra, 0($sp)			# done saving registers
		
		####Eliminate implementation
		## Args
		## Imortant M*B must be equal to N
		# $a0 - base address of matrix (A)
		# $a1 - Number of elements per row/column (N)
		# $a2 - Number of blocks per row/column (B)   /   (N+1)*4
		# $a3 - Number of element per block row/column (M)
		#----------------------------------------
		#s0 - I
		#s1 - N*N*4	/J
		#s2 - last element pointer
		#s3 - ((N+1)*(M-1))*4	Length from top corner of block to bottom corner of block.
		#s4 - last block pointer
		#s5 - M*4
		#s6 - (N-M)*4	Length from first block to last in row.
		#s7 - Last row first block, pointer
		#-----------------------------------------
		#t0 - current block-row pointer
		#t1 - last block in row
		#t2 - pivot pointer
		#t3 - current block-col pointer
		#t4 - last block in row
		#t5 - min((I+1)*M-1, (J+1)*M-1)
		#t6 - tmp
		#t7 - tmp
		#t8 - (I+1)*M-1 	/tmp
		#t9 - M*N*4
		#-----------------------------------------
		#v0 - tmp
		#v1 - tmp
		#-----------------------------------------
		#k0 - k
		#k1 - j
		#sp - i
		#gp - N*4
		
		#Constants:
		addiu $a2, $a1, 1
		sll $a2, $a2, 2		#a2 = (N+1)*4
		
		sll $gp, $a1, 2		#N*4
		
		mulu $s1, $gp, $a1	#N*N*4
		
		mulu $t2, $s0, $a3	#M*N*4
		
		addu $s2, $a0, $s1
		subiu $s2, $s2, 4	#Last element pointer
		
		addiu $s3, $a1, 1
		subiu $t2, $a3, 1
		mul $s3, $s3, $t2
		sll $s3, $s3, 2		#((N+1)*(M-1))*4
		
		subiu $s4, $s2, $s3	#Last block pointer = Last element pointer - ((N+1)*(M-1))*4
		
		sll $s5, $a3, 2		#M*4
		
		subu $s6, $a1, $a3	#M-N
		sll $s6, $s6, 2		#(N-M)*4
		
		subu $s7, $s4, $s6	#Last block first column
		
		#Program
		
		#Set up the row_loop
		addiu $t0, $a0, 0	#Current block-row pointer
		addu $s0, $zero, $zero	#s0 = 0 /I /Row probably necessary due to prev usage of s0
		
		
row_loop:	#Set up the col_loop
		addiu $t3, $t0, 0	#t3 = t0
		addu $t4, $t0, $s6	#t4 = pointer to the last  block in row 
		addu $s1, $zero, $zero	#s1 = 0 probably necessary due to prev usage of s1
		
col_loop:	#row_loop loops over t0->,s0 (=I) to $s7-> (Last row first block, pointer)
		#col_loop loops over $t3->,s1 (=J) to $t4-> (Last block in row, pointer)
		
		
		#s0 = I
		#s1 = J
		
		#Set up pivot loop
		slt $t6, $s1, $s0	# t6 = J<I
		addiu $t8, $s0, 1	# t8 = (I+1)
		mulu $t8, $t8, $a3	# t8 = (I+1) * M
		subiu $t8, $t8, 1	# t8 = (I+1) * M - 1
		mulu $t8, $t6, $t8	# v0 = t6*t8 = (J>I)*((I+1)*M - 1)
		
		sle $t7, $s0, $s1	# t7 = I<=J
		addiu $t5, $s1, 1	#t5 = (J+1)
		mulu $t5, $t5, $a3	#t5 = (J+1)* M
		subiu $v1, $t5, 1	#v1 = (J+1)* M - 1
		mulu $t5, $t7, $v1	#t5 = t7*v1 = (I<=J)*((J+1)* M - 1)
		
		addu $t5, $v1, $v0	#t5 = t6*t0 + t7*t3 = ((J>I) * (I+1)*M-1) + ((I<=J) * (J+1)*M-1) = min((I+1)*M-1, (J+1)*M-1)
		#t5 = min((I+1)*M-1, (J+1)*M-1)
		#v1 = (J+1) * M - 1
		#t8 = (I+1) * M - 1
		
		addu $k0, $zero, $zero	#k0=0 (Might not be necessary)
		addu $t2, $a0, $zero	#Set t2 to the current pivot-pointer
pivot_loop:	#loop over k0 (=k) to t5 (with pointer t2)
		
		#tmpreg: t6,t7,xt8x,v0,xv1x
		#if(k>=I*M && k<=(I+1)*M-1)
		mulu $t6, $a3, $s0
		sge $t6, $k0, $t6
		sle $t7, $k0, $t8
		bne $t6, $t7 done_if	# If t6 = t7 then they are both 1, since they can't be zero at the same time.
		
		#Begin if
		#tmpreg: t6,t7,t8,v0,xv1x
		
		
		
		
		#pivcalc loop setup
		jal maxkj		#max($k0+1,$s0*$a3) -> $k1 (uses t6,t7,t8)
		
		
		
		
		#pointer to A[k][j]
		mulu $t2, $a1, $gp
		sll $t6, $k1, 2
		addu $t2, $t2, $t6
		
pivcalc_loop:	#loop over k1 to v1
		
		
		#End pivcalc loop
		addiu $t2, $t2, 4
		bne $k1, $v1, pivcalc_loop
		addiu $k1,$k1,1
done_if:	
		
		#End pivot loop
		addu $t2, $t2, $a2
		bne $k0, $t5, pivot_loop
		addiu $k0, $k0, 1
		
		#End col loop
		addiu $s0, $s1, 1
		bne $t3, $t4, col_loop
		addu $t3, $t3, $s5
		
		#End row loop
		addiu $s0, $s0, 1
		bne $t0, $s7, row_loop
		addu $t0, $t0, $t7
		
		
		
		
		
		
		lw	$ra, 0($sp)			# done restoring registers

		addiu	$sp, $sp, 4			# remove stack frame



		jr		$ra					# return from subroutine

		nop							# this is the delay slot associated with all types of jumps



################################################################################
#maxkj - Max(k+1, J*M) = Max($k0+1,$s0*$a3) -> $k1 /Uses t6, t7, t8,k1
maxkj:		
		
		addiu $t6, $k0, 1	#t6 = k0+1 = k+1
		mulu $t7, $s0, $a3	#v0 = s0*a3 = J*M
		
		slt $t8, $t7, $t6	#t8 = s0<t6 = s0*a3 < k0+1 = J*M < k+1
		sle $k1, $t6, $s0	#v0 = t6<=s0 = k0+1 <= s0*a3 = k+1 <= J*M
		
		mulu $t6, $t6, $t8	#t6 = (k0+1)*(s0*a3 < k0+1) = (k+1) * (J*M < k+1)
		mulu $t7, $t7, $k1	#t7 = (s0*a3)*(k0+1 <= s0*a3) = (J*M) * (k+1 <= J*M)
		
		addu $k1, $t6, $t7	#v0 = Max($k0+1,$s0*$a3) = Max(k+1, I*M)
		jr $ra




#maxki - Max(k+1, I*M) = Max($k0+1,$s0*$a3) -> $k1 /Uses t6, t7, $t8, k1
#Almost the same as maxkj, could just use one...
maxki:		
		
		addiu $t6, $k0, 1	#t6 = k0+1 = k+1
		mulu $t7, $s1, $a3	#v0 = s0*a3 = J*M
		
		slt $t8, $t7, $t6	#t8 = t7<t6 = s0*a3 < k0+1 = J*M < k+1
		sle $k1, $t6, $t7	#v0 = t6<=t7 = k0+1 <= s0*a3 = k+1 <= J*M
		
		mulu $t6, $t6, $t8	#t6 = (k0+1)*(s1*a3 < k0+1) = (k+1) * (J*M < k+1)
		mulu $t7, $t7, $k1	#t7 = (s1*a3)*(k0+1 <= s1*a3) = (J*M) * (k+1 <= J*M)
		
		addu $k1, $t6, $t7	#v0 = Max($k0+1,$s1*$a3) = Max(k+1, I*M)
		jr $ra

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

#			$a1  - number of elements per row (N) 

print_matrix:

		addiu	$sp,  $sp, -20		# allocate stack frame

		sw		$ra,  16($sp)

		sw      $s2,  12($sp)

		sw		$s1,  8($sp)

		sw		$s0,  4($sp) 

		sw		$a0,  0($sp)		# done saving registers



		move	$s2,  $a0			# s2 = a0 (array pointer)

		move	$s1,  $zero			# s1 = 0  (row index)

loop_s1:

		move	$s0,  $zero			# s0 = 0  (column index)

loop_s0:

		l.s		$f12, 0($s2)        # $f12 = A[s1][s0]

		li		$v0,  2				# specify print float system call

 		syscall						# print A[s1][s0]

		la		$a0,  spaces

		li		$v0,  4				# specify print string system call

		syscall						# print spaces



		addiu	$s2,  $s2, 4		# increment pointer by 4



		addiu	$s0,  $s0, 1        # increment s0

		blt		$s0,  $a1, loop_s0  # loop while s0 < a1

		nop

		la		$a0,  newline

		syscall						# print newline

		addiu	$s1,  $s1, 1		# increment s1

		blt		$s1,  $a1, loop_s1  # loop while s1 < a1

		nop

		la		$a0,  newline

		syscall						# print newline



		lw		$ra,  16($sp)

		lw		$s2,  12($sp)

		lw		$s1,  8($sp)

		lw		$s0,  4($sp)

		lw		$a0,  0($sp)		# done restoring registers

		addiu	$sp,  $sp, 20		# remove stack frame



		jr		$ra					# return from subroutine

		nop							# this is the delay slot associated with all types of jumps



### End of text segment



### Data segment 

		.data

		

### String constants

spaces:

		.asciiz "   "   			# spaces to insert between numbers

newline:

		.asciiz "\n"  				# newline



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
