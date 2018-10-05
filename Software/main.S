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
BUTTONS_ADDR 		= 0x1f800008        # (o) Input Buttons Address
LEDS_ADDR			= 0xbf800000        # (o) LEDS Address
 
 
.globl main
main:
   li    $20, 0							# $20 = address of the 1hz counter
   li	 $21, 0							# $21 = address of the 5hz counter
   li	 $22, 0							# $22 = address of the 10 hz counter
   li	 $23, 0                         # $23 = address of the hundreds place counter
   li	 $24, 0							# $24 = address of the tens place counter
   li	 $25, 0                         # $25 = address of the ones place counter
   lui   $12, LEDS_ADDR #0xbf80    	    # $12 = address of LEDs (0xbf800000)
   addiu $13, $12, 4    				# $13 = address of switches
   li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   li	 $18, BUTTONS_ADDR				# $18 = address of the button inputs (last 4 bits are UPLR)
   li	 $26, MOTIONSTATE               # $26 = motion state address
   
readIO:
	lw    $10, 0($13)    	# read switches: $10 = switch values
	lw	  $19, 0($18)       # read buttons: $19 = button values
	andi  $19, $19, 0xf     # load only the lowest 4 bits ($19 stores values of UDLR Buttons)
	
	sw    $11, 0($12)    	# write switch values to leds
	### sw    $11, 0($16)   # write switch values to lower 7 segment digits 
	li 	  $11, 0x00
	sw	  $11, 0($14)		# Enable all the displays 
	li 	  $11, 0xFF			# Turn off all of the decimal points
	sw	  $11, 0($17)
	
	
	#motion state machine code (outputs only)
	
	branch $26 0 labelidle //start pseudo code for motion state machine, if branch state == goto label
	branch $26 1 labela
	branch $26 2 labelb
	branch $26 3 labelc
	branch $26 4 labeld
	branch $26 5 labele
	branch $26 6 labelf
	branch $26 7 labelg
	goto labelclock
	
	labelidle:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labela:
	  #write correct digit code to digit data
	  goto labelclock
	
	labelb:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labelc:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labeld:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labele:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labelf:
	  #write correct digit code to digit data
	  goto labelclock
	  
	labelg:
	  #write correct digit code to digit data
	  goto labelclock
	
	labelclock:
	
	#write correct digit codes to compass digits based on counters
	#write the digit data to the digit address
	
	#branch statement is checking if equal, if true then goes to label (equivalent to if statement)
	#figure out the clock speed (loop speed), if the state should go to next state based on clock counter(pseudocode)
	branch $19 cwf labelfast #19 is the button address (check if counter clockwise, clockwise, idle, reverse, or forward, also if fast)
	branch $19 ccf labelfast
	
	branch $19 forward labelslow
	branch $19 reverse labelslow
	branch $19 idle labelslow

	branch $19 cc labelnorm
	branch $19 cw labelnorm
	
	goto label labelskipnextstate
	
	labelfast:
		branch $22 5 labelfastcheck #has the 10hz counter reached the period
		# else
		goto label labelskipnextstate
		
	labelfastcheck:
		branch $19 ccf labelcompassdecrement
		branch $19 cwf labelcompassincrement
		goto statemachinenext
		
	labelslow:
		branch $20 50 labelslowcheck
		$else
		goto label labelskipnextstate
		
	labelslowcheck:
		goto statemachinenext
		
	labelnorm:
		branch $21 10 labelnormcheck
		$else
		goto label labelskipnextstate
		
	labelnormcheck:
		branch $19 cc labelcompassdecrement
		branch $19 cw labelcompassincrement
		goto statemachinenext
		
	labelcompassdecrement:
		#decrement the compass counter
		goto statemachinenext
		
	labelcompassincrement:
		#increment the compass counter
		goto statemachinenext
	
	statemachinenext: #motion state machine (next state only)
	
	#resets all the clock counters it goes to next state
	li	 $20, 0 
	li	 $21, 0
	li	 $22, 0
	
	#states should written like anext not label (rewrite)
	
	branch $26 0 labelidlenext //start pseudo code for motion state machine, if branch state == goto label
	branch $26 1 labelanext
	branch $26 2 labelbnext
	branch $26 3 labelcnext
	branch $26 4 labeldnext
	branch $26 5 labelenext
	branch $26 6 labelfnext
	branch $26 7 labelgnext
	goto label labelskipnextstate
	
	labelidlenext:
	  branch $19 (forward) anext
	  branch $19 (reverse) dnext
	  branch $19 (cc) dnext
	  branch $19 (ccf) dnext
	  branch $19 (cw) anext
	  branch $19 (cwf) anext
	  branch $19 (idle) gnext
	  goto label labelskipnextstate
	  #write the other state like this
	  
	labelanext:
	  branch $19 (forward) labelidle
	  branch $19 (reverse) labeld
	  branch $19 (cc) labeld
	  branch $19 (ccf) labeld
	  branch $19 (cw) labelb
	  branch $19 (cwf) labelb
	  branch $19 (idle) labelg
	  goto label labelskipnextstate
	
	labelbnext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labela
	  branch $19 (ccf) labela
	  branch $19 (cw) labelc
	  branch $19 (cwf) labelc
	  branch $19 (idle) labelg
	  goto labelskipnextstate
	  
	labelcnext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labelb
	  branch $19 (ccf) labelb
	  branch $19 (cw) labeld
	  branch $19 (cwf) labeld
	  branch $19 (idle) labelg
	  goto labelskipnextstate
	  
	labeldnext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labelc
	  branch $19 (ccf) labelc
	  branch $19 (cw) labele
	  branch $19 (cwf) labele
	  branch $19 (idle) labelg
	  goto labelskipnextstate
	  
	labelenext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labeld
	  branch $19 (ccf) labeld
	  branch $19 (cw) labelf
	  branch $19 (cwf) labelf
	  branch $19 (idle) labelg
	  goto labelskipnextstate
	  
	labelfnext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labele
	  branch $19 (ccf) labele
	  branch $19 (cw) labela
	  branch $19 (cwf) labela
	  branch $19 (idle) labelg
	  goto labelskipnextstate
	  
	labelgnext:
	  branch $19 (forward) labela
	  branch $19 (reverse) labeld
	  branch $19 (cc) labela
	  branch $19 (ccf) labela
	  branch $19 (cw) labela
	  branch $19 (cwf) labela
	  branch $19 (idle) labelidle
	  goto labelskipnextstate
	
	#set next state
	idlenext:
	  li $19 0
	  goto labelskipnextstate
	anext:
	  li $19 1
	  goto labelskipnextstates
	bnext:
	  li $19 2
	  goto labelskipnextstate
	cnext:
	  li $19 3
	  goto labelskipnextstate
	dnext:
      li $19 4
	  goto labelskipnextstate
	enext:
	  li $19 5
	  goto labelskipnextstate
	fnext:
	  li $19 6
	  goto labelskipnextstate
	gnext:
	  li $19 7
	  goto labelskipnextstate
	  
	labelskipnextstate:
	  
	  #increment all the counters
	  addiu $20, $20, 1      
	  addiu $21, $21, 1
	  addiu $22, $22, 1
	  addiu $23, $23, 1
	  addiu $24, $24, 1
	  addiu $25, $25, 1

	beq   $0, $0, readIO 	# repeat
	nop                  	# branch delay slot
