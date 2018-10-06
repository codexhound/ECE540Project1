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

PORT_SEVENSEG_EN 	= 0x1f700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0x1f700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0x1f700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0x1f70000C		# (o) 7 segment Decimal Point Display
BUTTONS_ADDR 		= 0x1f800008        	# (o) Input Buttons Address
LEDS_ADDR		= 0xbf800000        	# (o) LEDS Address
 
 
.globl main
main:
   	li    $20, 0					# $20 = 1hz counter register
   	li	 $21, 0					# $21 = 5hz counter register
   	li	 $22, 0					# $22 = 10hz counter register
   	li	 $23, 0                         	# $23 = hundreds place counter register
   	li	 $24, 0					# $24 = tens place counter register
   	li	 $25, 0                         	# $25 = ones place counter register
   	lui   $12, LEDS_ADDR #0xbf80    	    	# $12 = address of LEDs (0xbf800000)
   	addiu $13, $12, 4    				# $13 = address of switches
   	li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   	li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   	li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   	li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   	li	 $18, BUTTONS_ADDR			# $18 = address of the button inputs (last 4 bits are UPLR)
   	li	 $26, 0                         	# $26 = motion state register, default to 0(idle)
   
readIO:
	li    $3   0						# lower digit data, reset to 0 every write
	lw    $10, 0($13)    				# read switches: $10 = switch values
	lw	  $19, 0($18)       			# read buttons: $19 = button values
	andi  $19, $19, 0xf     			# load only the lowest 4 bits ($19 stores values of UDLR Buttons)	(don't care what the others are)
	sw    $11, 0($12)    				# write switch values to leds
	### sw    $11, 0($16)   			# write switch values to lower 7 segment digits 
	li 	  $11, 0x00
	sw	  $11, 0($14)				# Enable all the displays 
	li 	  $11, 0xFF				# Turn off all of the decimal points
	sw	  $11, 0($17)
	
	#write out the current compass digits
	li $11 $23  #write hundreds value
	sll $11 $11 16 #shift the data 16 bits left for digit 2 data (hundreds)
	add $3 $11 $3 #add this to lower digit data for later write out

	li $11 $24  #write tens value
	sll $11 $11 8 #shift the data 16 bits left for digit 1 data (tens)
	add $3 $11 $3 #add this to lower digit data for later write out

	li $11 $23  #write ones value
	add $3 $11 $3 #add this to lower digit data for later write out
	
	#motion state machine code (outputs only)
	
	bre $26 0 labelidle //start pseudo code for motion state machine, if branch state == goto label
	bre $26 1 labela
	bre $26 2 labelb
	bre $26 3 labelc
	bre $26 4 labeld
	bre $26 5 labele
	bre $26 6 labelf
	bre $26 7 labelg
	j labelclock
	
	#16 = a, 17= b, 18 = c, 19 = d, 20 = e, 21 = f, 22 = g, 28 = blank
	labelidle:
	  	#write correct digit code to digit data
	  	li $11 28  #write blank value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	labela:
	  	#write correct digit code to digit data
	  	li $11 16  #write a value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	
	labelb:
	  	#write correct digit code to digit data
	  	li $11 17  #write b value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelc:
	  	#write correct digit code to digit data
	  	li $11 18  #write c value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labeld:
	  	#write correct digit code to digit data
	  	li $11 19  #write d value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labele:
	  	#write correct digit code to digit data
	  	li $11 20  #write e value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelf:
	  	#write correct digit code to digit data
	  	li $11 21  #write f value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
	  	j labelclock
	  
	labelg:
	  	#write correct digit code to digit data
	  	li $11 22  #write g value
		sll $11 $11 24 #shift the data 24 bits left for digit 3 data
		add $3 $11 $3 #add this to lower digit data for later write out
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
	#clockwise -> 0010 (d2) or 0111 (d7) (reverseright motor, right motor and left motor on)
	#counterclockwise -> 0001 (d1) or 1011 (d11) (reverse left motor, left motor and right on)
	#clockwise fast -> 0110 (d6) (reverse right and left)
	#counter clockwise fast -> 1001 (d9) (reverse left and right motors)

	bre $19 6 labelfast #clockwise fast
	bre $19 9 labelfast #counterclockwise fast
	
	bre $19 3 labelslow #forward
	bre $19 12 labelslow #reverse
	bre $19 0 labelslow #idle
	bre $19 15 labelslow #idle

	bre $19 2 labelnorm #clockwise
	bre $19 7 labelnorm #clockwise
	bre $19 1 labelnorm #counter clockwise
	bre $19 11 labelnorm #counter clockwise
	
	j label labelskipnextstate
	
	labelfast:
		bre $22 5 labelfastcheck #has the 10hz counter reached the period
		# else
		j label labelskipnextstate
		
	labelfastcheck:
		bre $19 9 labelcompassdecrement
		bre $19 6 labelcompassincrement
		j statemachinenext
		
	labelslow:
		bre $20 50 statemachinenext
		$else
		j label labelskipnextstate
		
	labelnorm:
		bre $21 10 labelnormcheck
		$else
		j label labelskipnextstate
		
	labelnormcheck:
		bre $19 1 labelcompassdecrement
		bre $19 2 labelcompassincrement
		bre $19 11 labelcompassdecrement
		bre $19 7 labelcompassincrement
		j statemachinenext
		
	labelcompassdecrement:
		#decrement the compass counter
		subi $25 $25 1
		bre $25 -1 decrementtens
		j statemachinenext

	decrementtens:
		li $25 9
		subi $24 $24 1
		bre $24 -1 decrementhundreds
		j statemachinenext

	decrementhundreds:
		li $24 9
		subi $23 $23 1
		bre $23 -1 resetcompasscountersdecrement
		j statemachinenext

	resetcompasscountersdecrement:
		li $23 3
		li $24 5
		li $25 9
		#set counters to 359
		j statemachinenext

	resetcompasscounters:
		li $23 0
		li $24 0 
		li $25 0
		j statemachinenext

	labelcompassincrement:
		#increment the compass counter
		addi $25 $25 1
		bre $25 10 incrementtens
		j statemachinenext

	incrementtens:
		li $25 0
		addi $24 $24 1
		bre $23 3 incrementtenslast #if hundreds is 3
		bre $24 10 incrementhundreds #else if tens is 10
		j statemachinenext

	incrementtenslast:
		bre $24 6 resetcompasscounters #if hundreds is 3 and tens is 6 that means counter needs to be reset
		j statemachinenext

	incrementhundreds:
		li $24 0
		addi $23 $23 1
		j statemachinenext
	
	statemachinenext: #motion state machine (next state only)
	
	#resets all the clock counters before going to next state
	li	 $20, 0 
	li	 $21, 0
	li	 $22, 0

	#forward -> 0011 (3)
	#reverse -> 1100 (12)
	#idle -> 0000 (0) or 1111 (15)
	#clockwise -> 0001 (d1) or 0111 (d7) (reverseright motor, right motor and left motor on)
	#counterclockwise -> 0010 (d2) or 1011 (d11) (reverse left motor, left motor and right on)
	#clockwise fast -> 0101 (d5) (reverse right and left)
	#counter clockwise fast -> 1010 (d10) (reverse left and right motors)
	
	bre $26 0 labelidlenext
	bre $26 1 labelanext
	bre $26 2 labelbnext
	bre $26 3 labelcnext
	bre $26 4 labeldnext
	bre $26 5 labelenext
	bre $26 6 labelfnext
	bre $26 7 labelgnext
	j labelskipnextstate

	labelidlenext:
	  bre $19 3 anext   #forward
	  bre $19 12 dnext   #reverse
	  bre $19 1 anext 		#cc
	  bre $19 11 anext 		#cc
	  bre $19 9 anext 		#ccf
	  bre $19 2 anext		#cw
	  bre $19 7 anext		#cw
	  bre $19 6 anext		#cwf
	  bre $19 0 gnext		#idle
	  bre $19 15 gnext		#idle
	  j labelskipnextstate
	  #write the other state like this
	  
	labelanext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 fnext
	  bre $19 11 fnext
	  bre $19 9 fnext
	  bre $19 2 bnext
	  bre $19 7 bnext
	  bre $19 6 bnext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	
	labelbnext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 anext
	  bre $19 11 anext
	  bre $19 9 anext
	  bre $19 2 cnext
	  bre $19 7 cnext
	  bre $19 6 cnext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	  
	labelcnext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 bnext
	  bre $19 11 bnext
	  bre $19 9 bnext
	  bre $19 2 dnext
	  bre $19 7 dnext
	  bre $19 6 dnext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	  
	dnextnext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 cnext
	  bre $19 11 cnext
	  bre $19 9 cnext
	  bre $19 2 enext
	  bre $19 7 enext
	  bre $19 6 enext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	  
	labelenext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 dnext
	  bre $19 11 dnext
	  bre $19 9 dnext
	  bre $19 2 fnext
	  bre $19 7 fnext
	  bre $19 6 fnext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	  
	labelfnext:
	  bre $19 3 idlenext
	  bre $19 12 idlenext
	  bre $19 1 enext
	  bre $19 11 enext
	  bre $19 9 enext
	  bre $19 2 anext
	  bre $19 7 anext
	  bre $19 6 anext
	  bre $19 0 idlenext
	  bre $19 15 idlenext
	  j labelskipnextstate
	  
	labelgnext:
	  j idlenext #next state from g is always idle
	
	#set next state register
	idlenext:
	  li $26 0
	  j labelskipnextstate
	anext:
	  li $26 1
	  j labelskipnextstates
	bnext:
	  li $26 2
	  j labelskipnextstate
	cnext:
	  li $26 3
	  j labelskipnextstate
	dnext:
      li $26 4
	  j labelskipnextstate
	enext:
	  li $26 5
	  j labelskipnextstate
	fnext:
	  li $26 6
	  j labelskipnextstate
	gnext:
	  li $26 7
	  j labelskipnextstate
	  
	labelskipnextstate:
	  
	  #increment all the clock counters
	  addiu $20, $20, 1      
	  addiu $21, $21, 1
	  addiu $22, $22, 1

	beq   $0, $0, readIO 	# repeat
	nop                  	# branch delay slot
