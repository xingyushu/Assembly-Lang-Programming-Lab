		.data
prToken:	.word	0:3			# space to copy one token at a time
tableHead:	.asciiz "TOKEN    TYPE\n"
symbolHead:	.asciiz "SYMBOL\tVAL\tFLAG\n"
tabToken:	.word 	0:60
tabSym:		.word	0:32
inBuf: 		.space 		80 # input line
outBuf: 	.space 		80 # char types for the input line
prompt: 	.asciiz 	"\nEnter a new input line. \n�
saveReg: 	.word 0:3
LOC:		0x0400

	.text
li	$s3, 0
nextLine:
	jal	main	# Read input string, save token & type in tabToken [HW 5]
	li 	$s0, 0 	# i = 0
	li	$s1, 0 	# init paramStart = false
	lb	$t0, tabToken+12 # t0 = tabToken[1][0]
	bne	$t0, ':', instruction # if (tabToken[1][0] != ':') goto instruction

labelDef:
	la	$s2, tabToken # curToken = &tabToken
	lw 	$t0, ($s2) # store curToken in tabSym
	sw	$t0, tabSym($s3) 
	addi 	$s3, $s3, 4 # iterate
	lw 	$t0, 4($s2) # store curToken in tabSym
	sw	$t0, tabSym($s3) 
	addi 	$s3, $s3, 4 # iterate
	lw	$t0, LOC #store loc in tabSym
	sw	$t0, tabSym($s3)
	addi	$s3, $s3, 4 # iterate
	li	$t0, 1 # store 1 flag into table
	sw	$t0, tabSym($s3)
	addi 	$s3, $s3, 4
	li	$s0, 24 # i = 2

instruction:
	li	$s0, 12 # i = 1
	li 	$s1, 1	# paramStart = true
	
chkForVar:
	lb	$t0, tabToken($s0) # t0 = tabToken[i][0]
	beq	$t0, '#', dump # if (tabToken[i][0] == '#') goto dump
	beqz	$s1, chkForComma # if (param != 1) goto chkForComma
	lw	$t0, tabToken+8($s0) # t0 = tabToken[i][0]
	bne	$t0, 2, chkForComma # if (tabToken[i][1] != 2) goto chkForComma
	la	$s2, tabToken($s0) # curToken = &tabToken[i];
	
	lw 	$t0, ($s2) # store curToken in tabSym
	sw	$t0, tabSym($s3) 
	addi 	$s3, $s3, 4 # iterate
	lw 	$t0, 4($s2) # store curToken in tabSym
	sw	$t0, tabSym($s3) 
	addi 	$s3, $s3, 4 # iterate
	lw	$t0, LOC #store loc in tabSym
	sw	$t0, tabSym($s3)
	addi	$s3, $s3, 4 # iterate
	li	$t0, 0 # store 0 flag into table
	sw	$t0, tabSym($s3)
	addi 	$s3, $s3, 4
	
	j 	nextToken # jump nextToken

chkForComma:
	li 	$t0, ',' # t0 = ','
	lb	$t1, tabToken($s0) # t0 = tabToken[i][0]
	bne	$t0, $t1, commaNotFound
	li	$s1, 1 # paramStart = 1
	j	nextToken
	commaNotFound:
		li	$s1, 0 # paramStart = 0
		j 	nextToken # goto nextToken
	# paramStart = �,� == tabToken[i][0];
	
nextToken:
	addi	$s0, $s0, 12 # i++
	j 	chkForVar # goto chkForVar
	
dump:
	addi	$sp, $sp, -4 # store ra so it doesn't get messed up through jal
	sw	$ra, ($sp)
	jal	symPrint # print tabSym
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	# clear inBuf;
	la	$a0, inBuf
	li	$a1, 80
	jal	clear
	# clear tabToken;
	la	$a0, tabToken
	li	$a0, 240
	jal	clear
	lw	$t0, LOC # t0 = LOC
	addi	$t0, $t0, 4 # LOC +=4;
	sw	$t0, LOC # LOC = t0
	j	nextLine # goto nextLine;
	
symPrint:
  # print the header 
	li	$t0, 0 # t0 = 0  # this is for the index to iterate the symbol table  Symtable[0]...
	li	$v0, 4 # print string syscall    
	la	$a0, symbolHead # print the header  
	syscall  #then it will print header 

	# This loop for iterating all the elements of the table
	printLoop:
		bge	$t0, 64, loopDone # if (t0 >= 64) goto loopDone  , it is a function to judge the index(range) 
		li	$v0, 4  
		la	$a0, tabSym($t0) # print tab token     # input token  "ssssss" from the token to the table 
		syscall
		li	$v0, 11
		li	$a0, '\t' # table spacing/formatting  ,address fcuntion to handle the special character
		syscall
		
		lw	$a0, tabSym+8($t0) # print tab value  , index of table by address
		addi	$sp, $sp, -4   # store ra so it doesn't get messed up through jal
		sw	$ra, ($sp)
		jal	hex2char  # use hex2char to transfer it into the char
		lw	$ra, ($sp)   # save the transfer result into the return address/registers
		addi	$sp, $sp, 4  
		sw	$v0, saveReg  
		sw	$0, saveReg+4
		la	$a0, saveReg
		li	$v0, 4
		syscall
		li	$v0, 11
		li	$a0, '\t'
		syscall
		
		li	$v0, 1 # print tab status
		lw	$a0, tabSym+12($t0)  
		syscall
		li	$v0, 11
		li	$a0, '\n'  # move to the next line 
		syscall
		
		addi	$t0, $t0, 16 # iterate t0   16 is the size of each symbol table entry
		j	printLoop
	loopDone:
		jr	$ra     # return
	

hex2char:
	# save registers
	sw $t0, saveReg($0) # hex digit to process
	sw $t1, saveReg+4($0) # 4-bit mask
	sw $t9, saveReg+8($0)	
	# initialize registers
	li $t1, 0x0000000f # $t1: mask of 4 bits
	li $t9, 3 # $t9: counter limit
	
nibble2char:
	and $t0, $a0, $t1 # $t0 = least significant 4 bits of $a0
	# convert 4-bit number to hex char
	bgt $t0, 9, hex_alpha # if ($t0 > 9) goto alpha
	# hex char '0' to '9'
	addi $t0, $t0, 0x30 # convert to hex digit
	b collect
	
hex_alpha:
	addi $t0, $t0, -10 # subtract hex # "A"
	addi $t0, $t0, 0x61 # convert to hex char, a..f
	# save converted hex char to $v0

collect:
	sll $v0, $v0, 8 # make a room for a new hex char
	or $v0, $v0, $t0 # collect the new hex char
	# loop counter bookkeeping
	srl $a0, $a0, 4 # right shift $a0 for the next digit
	addi $t9, $t9, -1 # $t9--
	bgez $t9, nibble2char
	# restore registers
	lw $t0, saveReg($0)
	lw $t1, saveReg+4($0)
	lw $t9, saveReg+8($0)
	jr $ra

# ----- OLD STUFF ------
main:
	addi	$sp, $sp, -4 # store ra so it doesn't get messed up through jal
	sw	$ra, ($sp)
	jal	getline
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	la	$s1, Q0		# Initial state = Q0
	li	$s0, 1		# Initial T = 1
	li	$k0, 0
	li	$t6, 0
	li 	$s5, 0
	li	$a3, 96
	nextState:	
		lw	$s2, 0($s1)		# Load this state�s ACT
		jalr	$v1, $s2		# Call ACT, save return addr in $v1

		sll	$s0, $s0, 2		# Multiply T by 4 for word boundary
		add	$s1, $s1, $s0	# Add T to current state index
		sra	$s0, $s0, 2		# Divide by 4 to restore original T
		lw	$s1, 0($s1)		# Transition to next state
		b	nextState

# read next char from inBuf
# Set T = charType
ACT1:
	lb 	$a0, inBuf($k0) # reads current char from inbuf
	addi	$k0, $k0, 1 #increment
	
	addi	$sp, $sp, -4 # store ra so it doesn't get messed up through jal
	sw	$ra, ($sp)
	jal	search
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	move	$s0, $v0 # T = charType
	move	$a2, $a0 # save char
	jr 	$v1
	
# [TOKEN is empty now]
# TOKEN = curChar, TokSpace = 7
ACT2:
	sb	$a2, prToken # token = curChar
	sb	$s0, prToken+8 #set token to type
	li	$s7, 7 #tokenSpace = 7
	jr	$v1
	
# TOKEN = TOKEN + curChar
# TokSpace = TokSpace - 1
ACT3:
	li	$t9, 8
	sub	$s6, $t9, $s7 # token location = 8 - tokenSpace
	sb	$a2, prToken($s6) # token = nextChar
	addi 	$s7, $s7, -1 #decrement
	jr	$v1

# Save TOKEN into TabToken
# Clear TOKEN
# TokSpace = 8
ACT4:
	lw	$t9, prToken+0 #t9 = token
	sw	$t9, tabToken($s5) #tabToken[s5] = token
	addi	$s5, $s5, 4 #increment
	lw	$t9, prToken+4 
	sw	$t9, tabToken($s5) 
	addi	$s5, $s5, 4 
	lw	$t9, prToken+8
	sw	$t9, tabToken($s5)
	addi	$s5, $s5, 4	
	# clear token
	la	$a0, prToken
	li	$a1, 12
	addi	$sp, $sp, -4 # store ra so it doesn't get messed up through jal
	sw	$ra, ($sp)
	jal	clear
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	li	$s7, 8 #tokSpace = 8
	jr	$v1
	
RETURN:
	addi	$sp, $sp, -4 # store ra so it doesn't get messed up through jal
	sw	$ra, ($sp)
	jal	printToken
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
ERROR:
	li	$v0, 17
	syscall
	jr	$v1

# GIVEN IN DOC 5
printToken:
		la	$a0, tableHead	# print table heading
		li	$v0, 4
		syscall

		# copy 2-word token from tabToken into prToken
		#  run through prToken, and replace 0 (Null) by ' ' (0x20)
		#  so that printing does not terminate prematurely
		li	$t0, 0
loopTok:	bge	$t0, $a3, donePrTok	# if ($t0 <= $a3)
	
		lw	$t1, tabToken($t0)	#   copy tabTok[] into prTok
		sw	$t1, prToken
		lw	$t1, tabToken+4($t0)
		sw	$t1, prToken+4
	
		li	$t7, 0x20		# blank in $t7
		li	$t9, -1		# for each char in prTok
loopChar:	addi	$t9, $t9, 1
		bge	$t9, 8, tokType		
		lb	$t8, prToken($t9)	#   if char == Null
		bne	$t8, $zero, loopChar	
		sb	$t7, prToken($t9)	#       replace it by ' ' (0x20)
		b	loopChar

		# to print type, use four bytes: ' ', char(type), '\n', and Null
		#  in order to print the ASCII type and newline
tokType:
		li	$t6, '\n'		# newline in $t6
		sb	$t7, prToken+8
		#sb	$t7, prToken+9
		lb	$t1, tabToken+8($t0)
		addi	$t1, $t1, 0x30	# ASCII(token type)
		sb	$t1, prToken+9
		sb	$t6, prToken+10	# terminate with '\n'
		sb	$0, prToken+11
		
		la	$a0, prToken		# print token and its type
		li	$v0, 4
		syscall
	
		addi	$t0, $t0, 12
		sw	$0, prToken		# clear prToken
		sw	$0, prToken+4
		b	loopTok

donePrTok:
		jr	$ra

# Functions from hw 4
getline:
	la 	$a0, prompt # Prompt to enter a new line
	li 	$v0, 4 # Command code to write to the screen
	syscall
	la 	$a0, inBuf # Store the user input in inBuf
	li 	$a1, 80 # inBuf has space for 80 character
	li 	$v0, 8 # Command code to read a new line
	syscall
	jr 	$ra # Return

# clears buffer
clear:
	blez	$a1, end # if size = 0, leave
	subi	$a1, $a1, 1 # size--
	add	$t0, $a0, $a1 #t0 = a0 + a1
	sb	$zero, ($t0)
	j	clear # loop clear function 
	
	end:
		jr 	$ra

# searches through table
search:
	li	$t9, 0 # t9 = 0
	
	searchLoop:
		lw	$v0, tabChar($t9)
		beq	$v0, '\\', endTable # if \ then it has reached the end of the table
		beq	$v0, $a0, found
		addi 	$t9, $t9, 8 # t9++
		j	searchLoop
	
	found:
		addi	$t9, $t9, 4 # t9 = keyType
		lw	$v0, tabChar($t9) # v0 = tabChar(t2)
		jr	$ra
		
	endTable:
		li	$v0, 0
		jr	$ra

		.data
tabState:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q4   # T5
        .word  Q0   # T6
        .word  Q11  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q11  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q11  # T7

Q4:     .word  ACT4
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q11  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q11  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q11  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q11 # T7

Q10:    .word	  RETURN
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q11:    .word  ERROR 
	 .word  Q4  # T1
	 .word  Q4  # T2
	 .word  Q4  # T3
	 .word  Q4  # T4
	 .word  Q4  # T5
	 .word  Q4  # T6
	 .word  Q4  # T7

tabChar:
	.word 	0x09, 6 # tab
	.word 	0x0a, 6 # line feed
	.word 	0x0d, 6 # carraige return
	.word ' ', 6
	.word '#', 5
	.word '$', 4
	.word '(', 4
	.word ')', 4
	.word '*', 3
	.word '+', 3
	.word ',', 4
	.word '-', 3
	.word '.', 4
	.word '/', 3
	.word '0', 1
	.word '1', 1
	.word '2', 1
	.word '3', 1
	.word '4', 1
	.word '5', 1
	.word '6', 1
	.word '7', 1
	.word '8', 1
	.word '9', 1
	.word ':', 4
	.word 'A', 2
	.word 'B', 2
	.word 'C', 2
	.word 'D', 2
	.word 'E', 2
	.word 'F', 2
	.word 'G', 2
	.word 'H', 2
	.word 'I', 2
	.word 'J', 2
	.word 'K', 2
	.word 'L', 2
	.word 'M', 2
	.word 'N', 2
	.word 'O', 2
	.word 'P', 2
	.word 'Q', 2
	.word 'R', 2
	.word 'S', 2
	.word 'T', 2
	.word 'U', 2
	.word 'V', 2
	.word 'W', 2
	.word 'X', 2
	.word 'Y', 2
	.word 'Z', 2
	.word 'a', 2
	.word 'b', 2
	.word 'c', 2
	.word 'd', 2
	.word 'e', 2
	.word 'f', 2
	.word 'g', 2
	.word 'h', 2
	.word 'i', 2
	.word 'j', 2
	.word 'k', 2
	.word 'l', 2
	.word 'm', 2
	.word 'n', 2
	.word 'o', 2
	.word 'p', 2
	.word 'q', 2
	.word 'r', 2
	.word 's', 2
	.word 't', 2
	.word 'u', 2
	.word 'v', 2
	.word 'w', 2
	.word 'x', 2
	.word 'y', 2
	.word 'z', 2
	.word 0x5c, -1 # �\� used as the end-of-table symbol
