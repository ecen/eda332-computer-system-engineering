### Text segment
		.text
start:
		la	$a0, matrix_4x4		# a0 = A (base address of matrix)
		li	$a1, 4    		# a1 = N (number of elements per row)
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
		# If necessary, create stack frame, and save return address from ra
		addiu	$sp, $sp, -4		# allocate stack frame
		sw	$ra, 0($sp)		# done saving registers
		
		###### ELIMINATE IMPLEMENTATION
		
		# Constants
		subiu	$t5, $a1, 1
		sll	$t5, $t5, 2		# t5 = (N - 1) * 4
		addiu	$t8, $t5, 4		# t8 = N * 4
		addiu	$t3, $a1, 1		# t3 = N + 1
		sll	$t3, $t3, 2		# t3 = (N + 1) * 4
		
		lwc1	$f3, one		# f3 = 1
		mul	$t1, $a1, $a1		# t1: total nr of elements in matrix
		sll	$t4, $t1, 2		# Convert t1 to pointer offset by multiply by 4
		addu	$t9, $a0, $t4		# t9: pointer to element N * N
		addiu	$t2, $t9, -4		# t2: pointer to element (N * N) - 1
		subu	$t2, $t9, $t5		# t2: pointer to element (N * (N - 1)) - 1
		subu	$t2, $t2, $t5		# t2: pointer to element (N * (N - 2)) - 1
		
		# Pivot Loop Setup
		addiu	$t0, $a0, 0		# t0: pointer to current pivot
		addu	$t6, $zero, $a0		# t6: pointer to first element in current row
		# Pivot Loop: Loops over all pivot elements
pivot_loop:	lwc1	$f0, 0($t0)		# f0 = current pivot element
		## Right Loop Setup
		addiu	$t4, $t0, 4		# t4: pointer to current element on row
		addu	$t7, $t6, $t5		# t7: Pointer to last element of row.
		## Right Loop: Loops over all elements on pivot row to the right of pivot element
right_loop:	lwc1	$f1, 0($t4)		# f1: current element on row
		div.s	$f1, $f1, $f0		# f1 = f1/f0
		swc1	$f1, 0($t4)
		bne	$t7, $t4, right_loop
		addiu	$t4, $t4, 4
		## Right Loop End
		
		swc1	$f3, 0($t0)		# pivot = 1
		
		## Down Loop Setup
		## Down Loop End
		
		addu	$t6, $t6, $t8		# t6 += N * 4. Point t6 to first element on next row.
		bne	$t0, $t2, pivot_loop	# Loop if current pivot was not the last element
		addu	$t0, $t0, $t3		# t0 += (N + 1) * 4. Point t0 to next pivot element.
		# Pivot Loop End
		
		swc1	$f3, 0($t0)		# Pivot loop is only run N-1 times. This sets pivot element N to 1.
		
		
		###### ELIMINATE IMPLEMENTATION END

		lw	$ra, 0($sp)		# done restoring registers
		addiu	$sp, $sp, 4		# remove stack frame

		jr	$ra			# return from subroutine
		nop				# this is the delay slot associated with all types of jumps

################################################################################
# getelem - Get address and content of matrix element A[a][b].
#
# Argument registers $a0..$a3 are preserved across calls
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)
#			$a2  - row number (a)
#			$a3  - column number (b)
#						
# Returns:	$v0  - Address to A[a][b]
#		$f0  - Contents of A[a][b] (single precision)
getelem:
		addiu	$sp, $sp, -12			# allocate stack frame
		sw	$s2, 8($sp)
		sw	$s1, 4($sp)
		sw	$s0, 0($sp)			# done saving registers
		
		sll	$s2, $a1, 2			# s2 = 4*N (number of bytes per row)
		multu	$a2, $s2			# result will be 32-bit unless the matrix is huge
		mflo	$s1				# s1 = a*s2
		addu	$s1, $s1, $a0			# Now s1 contains address to row a
		sll	$s0, $a3, 2			# s0 = 4*b (byte offset of column b)
		addu	$v0, $s1, $s0			# Now we have address to A[a][b] in v0...
		l.s	$f0, 0($v0)			# ... and contents of A[a][b] in f0.
		
		lw	$s2, 8($sp)
		lw	$s1, 4($sp)
		lw	$s0, 0($sp)			# done restoring registers
		addiu	$sp, $sp, 12			# remove stack frame
		
		jr	$ra				# return from subroutine
		nop					# this is the delay slot associated with all types of jumps

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
