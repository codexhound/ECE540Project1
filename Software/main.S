/*
 * main.S - ECE 540 project #1 starter code for microAptiv_UP MIPS core
 * running on Nexys4 DDR FPGA target board
 *
 * Copyright Srivatsa Yogendra, 2017
 * 
 * Created By:		Srivatsa Yogendra
 * Last Modified:	01-Oct-2017 (RK)
 *
 * Description:
 * Reads the switches on the FPGA board and writes 
 * the values to the LEDs and the seven segment display
 *
 * Assumes the existance of an AHB-Lite peripheral for the 8 digit
 * 7-segment display on the Nexys4 DDR.  The peripheral has 4 memory
 * mapped I/O registers:
 *	PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 *									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 *									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 *	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit7 = bits[31:24], Digit6 = bits[23:16],
 *									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 *	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit3 = bits[31:24], Digit2 = bits[23:16],
 *									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 *	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 *									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 *									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 */


/* FOR PROJECT 1 , Change the below addresses to 
 * the addresses of your peripherals 
 */

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
BUTTONS_ADDR 		= 0xbf800008        	# (o) Input Buttons Address
LEDS_ADDR		= 0xbf800000        	# (o) LEDS Address
 
 
.globl main
main:
	li   $20, 0                    #1hz counter
	li   $21, 0                    #5hz counter
	li   $22, 0                    #10hz counter
   	li	 $23, 0                         	# $23 = hundreds place counter register
   	li	 $24, 0					# $24 = tens place counter register
   	li	 $25, 0                         	# $25 = ones place counter register
   	li   $12, LEDS_ADDR #0xbf80    	    	# $12 = address of LEDs (0xbf800000)
   	addiu $13, $12, 4    				# $13 = address of switches
   	li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   	li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   	li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   	li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   	li	 $18, BUTTONS_ADDR			# $18 = address of the button inputs (last 4 bits are UPLR)
   	li	 $26, 0                         	# $26 = motion state register, default to 0(idle)
   	li 	  $11, 0xf0					# set display enable to only enable lowest 4 displays (b'11110000)
	sw	  $11, 0($14)				# set display enables
	li 	  $11, 0xFF					# Turn off all of the decimal points
	sw	  $11, 0($17)

	li $4, 0xf4240 					#slow period
	li $5, 0x30d40 					#norm period
	li $6, 0x186a0 					#fast period

	#li    $v0, 30					#load time sys call code into v0($2)
	#syscall
	#add   $6, $0, $a0                #low bit starting time (from a0)
   
readIO:
	li    $3,  0						# lower digit data, reset to 0 every write
	lw    $11, 0($13)    				# read switches: $10 = switch values
	lw	  $19, 0($18)       			# read buttons: $19 = button values
	andi  $19, $19, 0xf     			# load only the lowest 4 bits ($19 stores values of UDLR Buttons)	(don't care what the others are)
	sw    $11, 0($12)    				# write switch values to leds
	# sw    $11, 0($16)   			# write switch values to lower 7 segment digits

	#get time passed in milliseconds
	#li    $v0, 30					#load time sys call code into v0($2)
	#syscall
	#add   $8, $0, $a0                #low bit check time (from a0)

	#subu $10, $8, $6 # low order difference = $8 - $6 //only need lower part of the difference, $10 holds the time difference in milliseconds
	
	#write out the current compass digits
	add $11, $0, $23  #write hundreds value
	sll $11, $11, 16 #shift the data 16 bits left for digit 2 data (hundreds)
	add $3, $11, $3 #add this to lower digit data for later write out

	add $11, $0, $24  #write tens value
	sll $11, $11, 8 #shift the data 8 bits left for digit 1 data (tens)
	add $3, $11, $3 #add this to lower digit data for later write out

	add $11, $0, $25  #write ones value
	add $3, $11, $3 #add this to lower digit data for later write out
	
	#motion state machine code (outputs only)
	
	beq $26, 0, labelidle //start pseudo code for motion state machine, if branch state == goto label
	beq $26, 1, labela
	beq $26, 2, labelb
	beq $26, 3, labelc
	beq $26, 4, labeld
	beq $26, 5, labele
	beq $26, 6, labelf
	beq $26, 7, labelg
	j labelclock
	
	#16 = a, 17= b, 18 = c, 19 = d, 20 = e, 21 = f, 22 = g, 28 = blank
	labelidle:
	  	#write correct digit code to digit data
	  	li $11, 28  #write blank value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	labela:
	  	#write correct digit code to digit data
	  	li $11, 16  #write a value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	
	labelb:
	  	#write correct digit code to digit data
	  	li $11, 17  #write b value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelc:
	  	#write correct digit code to digit data
	  	li $11, 18  #write c value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labeld:
	  	#write correct digit code to digit data
	  	li $11, 19  #write d value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labele:
	  	#write correct digit code to digit data
	  	li $11, 20  #write e value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelf:
	  	#write correct digit code to digit data
	  	li $11, 21  #write f value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelg:
	  	#write correct digit code to digit data
	  	li $11, 22  #write g value
		sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
		add $3, $11, $3 #add this to lower digit data for later write out
	  	j labelclock
	
	labelclock:
	
	#write the digit data to the digit address
	sw	  $3, 0($16) 
	
	#branch statement is checking if equal, if true then goes to label (equivalent to if statement)
	#figure out the clock speed (loop speed), if the state should go to next state based on clock counter(pseudocode)

	#input from button data comes in bits like so -> UDLR
	#forward -> 0011 (3)
	#reverse -> 1100 (12)
	#idle -> 0000 (0) or 1111 (15)
	#clockwise -> 0010 (d2) or 0111 (d7) or 0100(4) or 1110(14)
	#counterclockwise -> 0001 (d1) or 1011 (d11) or 1000(8) or 1101(13)
	#clockwise fast -> 0110 (d6) (reverse right and left)
	#counter clockwise fast -> 1001 (d9) (reverse left and right motors)

	#0100 reverse right = clockwise
	#1000 reverse left = counter clockwise

	beq $19, 6, labelfast #clockwise fast
	beq $19, 9, labelfast #counterclockwise fast
	
	beq $19, 3, labelslow #forward
	beq $19, 12, labelslow #reverse
	beq $19, 0, labelslow #idle
	beq $19, 15, labelslow #idle
	beq $19, 10, labelslow #idle
	beq $19, 5, labelslow #idle

	beq $19, 2, labelnorm #clockwise
	beq $19, 7, labelnorm #clockwise
	beq $19, 4, labelnorm #clockwise
	beq $19, 14, labelnorm #clockwise
	beq $19, 1, labelnorm #counter clockwise
	beq $19, 11, labelnorm #counter clockwise
	beq $19, 8, labelnorm #counter clockwise
	beq $19, 13, labelnorm #counter clockwise
	
	j labelskipnextstate



	labelfast:
		#has the timer reached the 10 hz period (P = .1 seconds)
		slt $11, $22, $6 #(set $11 to 1 if time difference is less than 100)
		bne $11, 1, labelfastcheck #goto if not equal to 1, (greater than or equal)
		#beq $22, 100000, labelfastcheck
		#ifnot
		j labelskipnextstate #skip all the next state stuff, not time yet
		
	labelfastcheck:
		beq $19, 9, labelcompassdecrement #decrement in any case that robot is turning cc, increment otherwise
		beq $19, 6, labelcompassincrement
		j statemachinenext
		
	labelslow:
		#check 1hz counter (P = 1 seconds)
		slt $11, $20, $4 #(set $11 to 1 if time difference is less than 1000)
		bne $11, 1, statemachinenext #goto if not equal to 1, (greater than or equal)
		#beq $20, 750000, statemachinenext
		#an else
		j labelskipnextstate
		
	labelnorm:
		#check 5 hz counter (P = .2 seconds)
		slt $11, $21, $5 #(set $11 to 1 if time difference is less than 200)
		bne $11, 1, labelnormcheck #goto if not equal to 1, (greater than or equal)
		#beq $21, 100000, labelnormcheck
		#an else
		j labelskipnextstate
		
	labelnormcheck:
		beq $19, 1, labelcompassdecrement #decrement in any case that robot is turning cc, increment otherwise
		beq $19, 2, labelcompassincrement
		beq $19, 11, labelcompassdecrement
		beq $19, 7, labelcompassincrement
		beq $19, 4, labelcompassincrement #clockwise
		beq $19, 14, labelcompassincrement #clockwise
		beq $19, 8, labelcompassdecrement #counter clockwise
		beq $19, 13, labelcompassdecrement #counter clockwise
		j statemachinenext
		
	labelcompassdecrement:
		#decrement the compass counter
		addi $25, $25, -1
		beq $25, -1, decrementtens
		j statemachinenext

	decrementtens:
		li $25, 9
		addi $24, $24, -1
		beq $24, -1, decrementhundreds
		j statemachinenext

	decrementhundreds:
		li $24, 9
		addi $23, $23, -1
		beq $23, -1, resetcompasscountersdecrement
		j statemachinenext

	resetcompasscountersdecrement:
		li $23, 3
		li $24, 5
		li $25, 9
		#set counters to 359
		j statemachinenext

	resetcompasscounters:
		li $23, 0
		li $24, 0 
		li $25, 0
		j statemachinenext

	labelcompassincrement:
		#increment the compass counter
		addi $25, $25, 1
		beq $25, 10, incrementtens
		j statemachinenext

	incrementtens:
		li $25, 0
		addi $24, $24, 1
		beq $23, 3, incrementtenslast #if hundreds is 3
		beq $24, 10, incrementhundreds #else if tens is 10
		j statemachinenext

	incrementtenslast:
		beq $24, 6, resetcompasscounters #if hundreds is 3 and tens is 6 that means counter needs to be reset
		j statemachinenext

	incrementhundreds:
		li $24, 0
		addi $23, $23, 1
		j statemachinenext
	
	statemachinenext: #motion state machine (next state only)
	
	#resets the clock timer (gets the starting time from syscall)
	#li    $v0, 30					#load time sys call code into v0($2)
	#syscall
	#add   $6, $0, $a0                #low bit check time (from a0)

	#reset the timers
	li $20, 0
	li $21, 0
	li $22, 0

	#forward -> 0011 (3)
	#reverse -> 1100 (12)
	#idle -> 0000 (0) or 1111 (15)
	#clockwise -> 0001 (d1) or 0111 (d7) (reverseright motor, right motor and left motor on)
	#counterclockwise -> 0010 (d2) or 1011 (d11) (reverse left motor, left motor and right on)
	#clockwise fast -> 0101 (d5) (reverse right and left)
	#counter clockwise fast -> 1010 (d10) (reverse left and right motors)
	
	beq $26, 0, labelidlenext
	beq $26, 1, labelanext
	beq $26, 2, labelbnext
	beq $26, 3, labelcnext
	beq $26, 4, labeldnext
	beq $26, 5, labelenext
	beq $26, 6, labelfnext
	beq $26, 7, labelgnext
	j labelskipnextstate


	labelidlenext:
	  beq $19, 3, anext   		#forward
	  beq $19, 12, dnext   		#reverse
	  beq $19, 1, anext 			#cc
	  beq $19, 11, anext 			#cc
	  beq $19, 4, anext 			#cc
	  beq $19, 14, anext 			#cc

	  beq $19, 9, anext 			#ccf
	  beq $19, 2, anext			#cw
	  beq $19, 7, anext			#cw
	  beq $19, 8, anext			#cw
	  beq $19, 13, anext			#cw
	  beq $19, 6, anext			#cwf
	  beq $19, 0, gnext			#idle
	  beq $19, 15, gnext			#idle
	  beq $19, 10, gnext #idle
	  beq $19, 5, gnext #idle
	  j idlenext
	  
	labelanext:
	  beq $19, 3, idlenext		#forward		
	  beq $19, 12, idlenext	 	#reverse		
	  beq $19, 1, fnext			#cc
	  beq $19, 11, fnext			#cc	
	  beq $19, 4, bnext 			#cw
	  beq $19, 14, fnext 			#cc
	  beq $19, 9, fnext			#ccf	
	  beq $19, 2, bnext			#cw	
	  beq $19, 7, bnext			#cw	
	  beq $19, 8, fnext			#cw
	  beq $19, 13, bnext			#cw
	  beq $19, 6, bnext			#cwf	
	  beq $19, 0, idlenext		#idle		
	  beq $19, 15, idlenext		#idle		
	  j idlenext
	
	labelbnext:
	  beq $19, 3, idlenext		#forward					
	  beq $19, 12, idlenext		#reverse					
	  beq $19, 1, anext			#cc
	  beq $19, 11, anext			#cc
	  beq $19, 4, cnext 			#cw
	  beq $19, 14, anext 			#cc
	  beq $19, 9, anext			#ccf			
	  beq $19, 2, cnext			#cw			
	  beq $19, 7, cnext			#cw
	  beq $19, 8, anext			#cw
	  beq $19, 13, cnext			#cw
	  beq $19, 6, cnext			#cwf			
	  beq $19, 0, idlenext		#idle					
	  beq $19, 15, idlenext		#idle					
	  j idlenext
	  
	labelcnext:
	  beq $19, 3, idlenext		#forward				
	  beq $19, 12, idlenext		#reverse				
	  beq $19, 1, bnext			#cw
	  beq $19, 11, bnext			#cc		
	  beq $19, 4, dnext 			#cw
	  beq $19, 14, bnext 			#cc
	  beq $19, 9, bnext			#ccf		
	  beq $19, 2, dnext			#cw		
	  beq $19, 7, dnext			#cw		
	  beq $19, 8, bnext			#cc
	  beq $19, 13, dnext			#cw
	  beq $19, 6, dnext			#cwf		
	  beq $19, 0, idlenext		#idle				
	  beq $19, 15, idlenext		#idle				
	  j idlenext
	  
	labeldnext:
	  beq $19, 3, idlenext		#forward				
	  beq $19, 12, idlenext		#reverse				
	  beq $19, 1, cnext			#cc
	  beq $19, 11, cnext			#cc
	  beq $19, 4, enext 			#cw
	  beq $19, 14, cnext 			#cc
	  beq $19, 9, cnext			#ccf		
	  beq $19, 2, enext			#cw		
	  beq $19, 7, enext			#cw		
	  beq $19, 8, cnext			#cc
	  beq $19, 13, enext			#cw
	  beq $19, 6, enext			#cwf		
	  beq $19, 0, idlenext		#idle				
	  beq $19, 15, idlenext		#idle				
	  j idlenext
	  
	labelenext:
	  beq $19, 3, idlenext		#forward			
	  beq $19, 12, idlenext		#reverse			
	  beq $19, 1, dnext			#cc
	  beq $19, 11, dnext			#cc	
	  beq $19, 4, fnext 			#cw
	  beq $19, 14, dnext 			#cc
	  beq $19, 9, dnext			#ccf	
	  beq $19, 2, fnext			#cw	
	  beq $19, 7, fnext			#cw	
	  beq $19, 8, dnext			#cc
	  beq $19, 13, fnext			#cw
	  beq $19, 6, fnext			#cwf	
	  beq $19, 0, idlenext		#idle			
	  beq $19, 15, idlenext		#idle			
	  j idlenext
	  
	labelfnext:
	  beq $19, 3, idlenext		#forward			
	  beq $19, 12, idlenext		#reverse			
	  beq $19, 1, enext			#cc
	  beq $19, 11, enext			#cc	
	  beq $19, 4, anext 			#cw
	  beq $19, 14, enext 			#cc
	  beq $19, 9, enext			#ccf	
	  beq $19, 2, anext			#cw	
	  beq $19, 7, anext			#cw	
	  beq $19, 8, enext			#cc
	  beq $19, 13, anext			#cw
	  beq $19, 6, anext			#cwf	
	  beq $19, 0, idlenext		#idle			
	  beq $19, 15, idlenext		#idle			
	  j idlenext
	  
	labelgnext:
	  j idlenext #next state from g is always idle
	
	#set next state register
	idlenext:
	  li $26, 0
	  j labelskipnextstate
	anext:
	  li $26, 1
	  j labelskipnextstate
	bnext:
	  li $26, 2
	  j labelskipnextstate
	cnext:
	  li $26, 3
	  j labelskipnextstate
	dnext:
      li $26, 4
	  j labelskipnextstate
	enext:
	  li $26, 5
	  j labelskipnextstate
	fnext:
	  li $26, 6
	  j labelskipnextstate
	gnext:
	  li $26, 7
	  j labelskipnextstate
	  
	labelskipnextstate:
	#increment the clock timers
	add $20, 1
	add $21, 1
	add $22, 1

	beq   $0, $0, readIO 	# repeat
	nop                  	# branch delay slot
