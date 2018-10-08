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
 
 
.globl main
main:
   lui   $12, 0x1f80    				# $12 = address of LEDs (0xbf800000)
   addiu $13, $12, 4    				# $13 = address of switches
   li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   
readIO: 	
	lw    $10, 0($13)    	# read switches: $10 = switch values   
	and   $11, $10, 0xFFFFF
	sw    $11, 0($12)    	# write switch values to leds
	sw    $11, 0($16)    	# write switch values to lower 7 segment digits 
	li 	  $11, 0x00
	sw	  $11, 0($14)		# Enable all the displays 
	li 	  $11, 0xFF			# Turn off all of the decimal points
	sw	  $11, 0($17)

	beq   $0, $0, readIO 	# repeat
	nop                  	# branch delay slot
