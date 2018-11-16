/*
 * main.S - #Project 1 Simple Bot Code
 * running on Nexys4 DDR FPGA target board
 *
 * Copyright Srivatsa Yogendra, 2017
 * 
 * Created By:		Srivatsa Yogendra
 * Modified By:     Michael Bourquin, Jean Shirimpaka
 * Last Modified:	12-Oct-2018
 *
 * Description:
 * Reads the switches on the FPGA board and writes 
 * the values to the LEDs
 * Reads the Buttons on the FPGA board and outputs a compass (3 Digit Display) based on relative turning position of Robot
 * Displays a robot motion in the 4th display based on button input
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

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
BUTTONS_ADDR 		= 0xbf800008        # (o) Input Buttons Address
LEDS_ADDR			= 0xbf800000        # (o) LEDS Address
PORT_BOTCTRL		= 0xbf800014		# (o) Bot Control port
PORT_BOTINFO 		= 0xbf80000C		# (i) Bot Info Port
PORT_BOTUPDATE		= 0xbf800010		# (i) Bot Update Port
PORT_BOTACK			= 0xbf800018		# (o) Bot Acknowledge Port

#MASKS
BLACKLINE_MSK		= 0x700 			#mask out for sensor bits only in botinfo
ORIENT_MSK			= 0x7        		#mask out for orientation bits only in botinfo
LOC_X_MSK			= 0xff000000		#mask out for robot x location bits
LOC_Y_MSK			= 0x00ff0000		#mask out for robot y location bits

#bot control defines
#forward: 00110011 = x33
#reverse: 00100010 = x22
#left: 00000011 = x3
#right: 00110000 = x30
#idle: 0 = x0
#fastleft: 00100011 = x23
#fastright: 00110010 = x32
FORWARD_CNT			= 0x33
REVERSE_CNT			= 0x22
LEFT_CNT			= 0x3
RIGHT_CNT			= 0x30
IDLE_CNT			= 0x0
FAST_LEFT_CNT		= 0x23
FAST_RIGHT_CNT		= 0x32

//use these two lines for debugging
#li $22, IDLE_CNT					#read in the idle control value
#sw $22, 0($9)						#write out idle to bot control
 
 
.globl main
main:
	li $4, 0					#stateregister (0: forward, 1: rightturn, 2: reverse, 3: forwardnot180)
	li $5, 90					#forward orientation register, initialize at 90 degrees
	li $6, PORT_SEVENSEG_EN	    #keep the sevensegenable address here
	li $7, PORT_SEVENSEG_LOW	#keep the sevenseglow digits address here
	li $8, BUTTONS_ADDR			#keep the buttons address here
	li $9, PORT_BOTCTRL			#keep the botcontrol port here
	li $10, PORT_BOTINFO		#keep the botinfo port here
	li $11, PORT_BOTUPDATE		#keep the botupdate port here
	li $12, PORT_BOTACK			#keep the ack port here
	li $13, 0					#keep the lower digit data here (7 seg display)
	li $14, 90					#initialize the lastforward angle
	li $15, 0					#initialize the current orientation register
	li $23, 0					#initialize botinfodata
	li $24, 0					#initialize the forward180 start position

	#							temp registers 2, 3 and 22
	#							function returns in 16 - 19
	#							function inputs reserved for 20 - 21

	li $25, 0					#initialize saved $ra address

	li 	  $22, 0xf8				# set display enable to only enable lowest 3 displays (b'11111000)
	sw	  $22, 0($6)			# set display enables

	li $22, IDLE_CNT			#read in the idle control value
	sw $22, 0($9)				#write out idle to bot control

	jal	getBotInfoandDisplay    #read in botinfo and display orient immediately
	j statemachineoutput		#start with statemachineoutput logic


updatelooplogic:
	lw $22, 0($11)				#load update sync into $22


	beq $22, 0, updatelooplogic	#no update, keep looping
	nop                  		# branch delay slot

	#update was 1 so update controller
	li $22, 1					#load 1 into 22 for ACK signal
	sw $22, 0($12)				#write to acknowledge signal

	#stop the robot temporarily to give time for controller logic
	#li $22, IDLE_CNT			#read in the idle control value
	#sw $22, 0($9)				#write out idle to bot control

	jal getBotInfoandDisplay	#update botinfo and display orient

	j nextstatelogic			#there was an update, continue to statemachinnext


nextstatelogic:

	beq	  $4, 0, forwardnextlabel		#if state is 0(forward), goto forward next logic
	beq   $4, 1, rightturnnextlabel		#if state is 1(rightturn), goto right turn next logic
	beq	  $4, 2, reversenextlabel		#if state is 2(reverse), goto reverse next logic
	beq   $4, 3, forwardnot180nextlabel	#if state is 3(forwardnot180), goto forwardnot180 next logic
	beq	  $4, 4, forwardnot180nextset 	#if state is 4(forwardnot180set), goto forwardnot180set logic
	j forwardnextlabel                  #else goto default

forwardnextlabel:

	#read in the black line value from bot info
	andi $22, $23, BLACKLINE_MSK		#get only the black line bits from bot info
	srl $22, $22, 8						#shift data right 8 to get in least sig
	#black line means $22 equals zero

	bne $22, $0, nextstatereverse		#if not black line, next state is reverse
										#1else stay in forward state
	j statemachineoutput

rightturnnextlabel:

	#read in the black line value from bot info
	andi $22, $23, BLACKLINE_MSK		#get only the black line bits from bot info
	srl $22, $22, 8						#shift data right 8 to get in least sig
	#black line means $22 equals zero

	#1if difference from forward orientation is not 180 then continue onto forwardnot180
	sub $22, $16, $5					    #current orientation - forward orientation

	bne $22, 180, checkorientdiff0			#if not 180 and not 0 and not -180 (has turned from starting straight forward) and orient has changed since last 180forward goto forwardnot180
											#1else state in right turn state
	j statemachineoutput

checkorientdiff0:

	bne $22, 0, checkorientdiffneg180		#1and if not 0

	j statemachineoutput					#else stay in rightturn

checkorientdiffneg180:

	bne $22, -180, checkorientdifflastforward180	#1and if not -180 continue to next check

	j statemachineoutput	#else stay in right turn

checkorientdifflastforward180:

	bne $16, $14, nextstateforwardnot180set			#1and angle since last forward is not equal

	j statemachineoutput	#else stay in right turn

reversenextlabel:
	#read in the black line value from bot info
	andi $22, $23, BLACKLINE_MSK		#get only the black line bits from bot info
	srl $22, $22, 8						#shift data right 8 to get in least sig
	#black line means $22 equals zero

	beq $22, $0, rightturnnext          #if black line next is right turn

	j statemachineoutput                #else stay in reverse


forwardnot180nextset:

	j nextstateforwardnot180			#always continue to forwardnot180from here


forwardnot180nextlabel:
	#read in the black line value from bot info
	andi $22, $23, BLACKLINE_MSK		#get only the black line bits from bot info
	srl $22, $22, 8						#shift data right 8 to get in least sig
	#black line means $22 equals zero

	beq $22, $0, checkpostionchange  					#if black line found then we must also check that the pos has changed from last before moving to straightaway forward (starting orientation is reset)
	j nextstatereverse                         			#else reverse to find the black line again


checkpostionchange: 									#if there is a change of x or y (24) goto forward set orientation, otherwise stay in this state

	li $2, LOC_X_MSK
	and $22, $23, $2					#get the current location x bits from botinfo
	srl $22, $22, 24					#shift 24 to put in first byte
	andi $3, $24, 0xff00				#mask out e/b x reg in the start pos reg (24)
	srl $3, $3, 8						#shift 8 to put in first byte

	bne $3, $22, nextstateforward		#if position changed(not equal) goto forward set

	j checkpositionchange2				#else do the or logic too

checkpositionchange2:

	li $2, LOC_Y_MSK
	and $22, $23, $2					#get the current location y bits from botinfo
	srl $22, $22, 16					#shift 16 to put in first byte
	andi $3, $24, 0xff					#mask out e/b the y reg in the start pos reg (24)
										#no need to shift here
	bne $3, $22, nextstateforward		#1if position changed(not equal) goto forward set

	j statemachineoutput				#1else stay in forward 180 state (position did not change and black line was found, not time for next state yet)

nextstateforward:

	li $4, 0
	j statemachineoutput

rightturnnext:

	li $4, 1
	j statemachineoutput

nextstatereverse:

	li $4, 2
	j statemachineoutput

nextstateforwardnot180:

	li $4, 3
	j statemachineoutput

nextstateforwardnot180set:

	li $4, 4
	j statemachineoutput

   
statemachineoutput:
	beq	  $4, 0, forwardoutlabel		#if state is 0(forward), goto forward output logic
	beq   $4, 1, rightturnoutlabel		#if state is 1(rightturn), goto right turn output logic
	beq	  $4, 2, reverseoutlabel		#if state is 2(reverse), goto reverse output logic
	beq   $4, 3, forwardnot180outlabel	#if state is 3(forwardnot180), goto forwardnot180 out logic
	beq	  $4, 4, forwardnot180outsetlabel #if state is 4(forward180 set), goto logic
	j forwardoutlabel 					#else goto forwardout (default)


forwardoutlabel:

	li $22, FORWARD_CNT					#read in the forward control value
	sw $22, 0($9)						#write out forward to bot control
	add $5, $0, $16						#set the forward orientation register

	j statemachineoutputdone
rightturnoutlabel:

	li $22, RIGHT_CNT					#read in the right turn control value
	sw $22, 0($9)						#write out right turn to bot control

	j statemachineoutputdone
reverseoutlabel:

	li $22, REVERSE_CNT					#read in the reverse control value
	sw $22, 0($9)						#write out reverse to bot control

	j statemachineoutputdone
forwardnot180outlabel:

	li $22, FORWARD_CNT					#read in the forward control value
	sw $22, 0($9)						#write out forward to bot control

	j statemachineoutputdone

forwardnot180outsetlabel:
	add $14, $0, $16					#set the last orientation (last forward)

	#set the start position reg (24)
	li $2, LOC_X_MSK
	and $22, $23, $2					#get the location x bits from botinfo
	srl $22, $22, 16					#shift 16 to put in 2nd byte
	add $24, $22, $0					#reset and add to the forward 180 pos reg (24)
	li $2, LOC_Y_MSK
	and $22, $23, $2					#get the location y bits from botinfo
	srl $22, $22, 16					#shift 16 to put in 1st byte
	add $24, $22, $24					#add to the forward 180 pos reg

	li $22, FORWARD_CNT					#read in the forward control value
	sw $22, 0($9)						#write out forward to bot control

	j statemachineoutputdone

statemachineoutputdone:
	li $22, 0							#load zero into temp 22 for write to ACK
	sw $22, 0($12)						#reset the ACK signal when done updating controller

	j 	updatelooplogic					#returns to update logic loop after done



#start getOrientation Function:

getOrientation:
	#returns in 16 - 19 (16: stores full, 17 stores hundreds, 18 stores tens, 19 stores ones)
	beq $20, 0, setorient0
	beq $20, 1, setorient45
	beq $20, 2, setorient90
	beq $20, 3, setorient135
	beq $20, 4, setorient180
	beq $20, 5, setorient225
	beq $20, 6, setorient270
	beq $20, 7, setorient315
	j setorient0            #else set to 0

setorient0:
	addi $16, $0, 0
	addi $17, $0, 0
	addi $18, $0, 0
	addi $19, $0, 0
	j endgetOrientation

setorient45:
	addi $16, $0, 45
	addi $17, $0, 0
	addi $18, $0, 4
	addi $19, $0, 5
	j endgetOrientation

setorient90:
	addi $16, $0, 90
	addi $17, $0, 0
	addi $18, $0, 9
	addi $19, $0, 0
	j endgetOrientation

setorient135:
	add $16, $0, 135
	add $17, $0, 1
	add $18, $0, 3
	add $19, $0, 5
	j endgetOrientation

setorient180:
	addi $16, $0, 180
	addi $17, $0, 1
	addi $18, $0, 8
	addi $19, $0, 0
	j endgetOrientation

setorient225:
	addi $16, $0, 225
	addi $17, $0, 2
	addi $18, $0, 2
	addi $19, $0, 5
	j endgetOrientation

setorient270:
	addi $16, $0, 270
	addi $17, $0, 2
	addi $18, $0, 7
	addi $19, $0, 0
	j endgetOrientation

setorient315:
	addi $16, $0, 315
	addi $17, $0, 3
	addi $18, $0, 1
	addi $19, $0, 5
	j endgetOrientation

endgetOrientation:
	jr $ra                  #return to the caller

#end get orientation

#start display orientation function:
displayOrientation:

	add $22, $17, $0		#load the hundreds into temp
	sll	 $22, $22, 16		#shift the bits by 24 for digit 2
	add $13, $0, $22		#reset and add this digit to the digits register

	add $22, $18, $0		#load the tens into temp
	sll	 $22, $22, 8		#shift the bits by 16 for digit 1
	add $13, $13, $22		#add this digit to the digits register

	add $22, $19, $0		#load the ones into temp
							#no need to shift for digit 0
	add $13, $13, $22		#add this digit to the digits register

	sw $13, 0($7)			#write to the lower digits address

	jr $ra

#end the display orientation function


#start the botinfoRead and display orient
getBotInfoandDisplay:
	add $25, $0, $ra			#save the ra register for return

	lw $23, 0($10)				#load botinfo data into 23 for update

	andi $20, $23, ORIENT_MSK	#get only the orientation bits and load into function input
	jal	getOrientation			#call get orientation, returns in $16 - $19
	jal displayOrientation		#display the current orientation on the 7segdisplay
	
	add $ra, $0, $25			#restore ra from before intial call in main
	jr $ra

#end the botinfoRead and display orient function


