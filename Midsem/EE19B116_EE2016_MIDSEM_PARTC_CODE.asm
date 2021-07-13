/*
 * EE19B116_Part-C.asm
 *
 *  Created: 04-11-2020 11:06:23
 *   Author: Lenovo
 */ 

 ;Setting the number of taps : Make changes below if need to change the taps
 ldi r18,0x20; Number of taps
 mov r14,r18;  Making a copy of the number of taps

 ;Loading the input values and coefficients and initial setup
 ;The coefficients are loaded from the flash memory and stored in the SRAM starting from the locations 0x0060
 ;following that the input values are just loaded into the flash memory.
 ;-----------------------------------
 ;Loading coefficients correctly based on the number of taps as defined at the last
 ;Make changes below if need to change the input after looking at the end
 ldi zl,low(num2<<1);
 ldi zh,high(num2<<1);
 ldi xl,0x60; x-pointer being set to location 0x0060
 ldi xh,0x00;
 mov r2,r26; making note of the loacation where the coefficients are stored 
 mov r3,r27;
 again1: lpm r16,z+; loading from flash
 st x+,r16; storing in the SRAM
 dec r18;
 brne again1;

 ; loading the input values into the flash memory as per the required input (sine/white noise) as described at the last
 ldi zl,low(num4<<1);
 ldi zh,high(num4<<1);

 ldi r21,0x00; a refernced zero register, used when required for addition or subracttion
 ldi r22,0x01; a refernced one register, used when required for addition or subracttion
 mov r15,r22; a copy of one registers again

 ; r12 has the value of two, used when needed to add any register by 2
 clr r12;
 inc r12;
 inc r12;
 ;------------------------------------

 ;The registers and their usage depicted below:
 ; x-pointer for the address of the coefficients
 ; z-pointer for the address of the input
 ; y-pointer for storing the output
 ; the outputs are stored from the location 0x0400
 
 ;Computation of the output starts here
 ;------------------------------------
 ; r3:r2 is used to denote the address of the coefficient to accessed
 ; r5:r4 is used to denote the address of the input to be accessed 
 ; r18 is loaded with the coefficient
 ; r19 is loaded with the input
 ; r17:r16 is loaded with the start point at which the output has to be calculated i.e the value of 'n'
 ; r6 is loaded with the number of taps
 ; r11 is storing the number of negative multiplications that are added to sort out the overflow by performing the bit manipulations.
 ; r10,r9,r8 is being used as a accumulator here. (we need a min of 18 bits for 5-tap and 23-bits for 32-tap)
 
 ; r25 contains the number of values to be computed
 ldi r25,0xfa; calculating the output for 250 values 
 
 ; load the address from where we need to store the output (i.e the y-pointer is set to the location 0x0090) 
 ldi r28,0x90;
 ldi r29,0x00;

 ; need to calculate output starting from n=101, so r16 holds that
 ldi r16,0x65; 
 ldi r17,0x00;

 ; pointing the z-pointer to exact location from where the input should be accessed.
 ; we just add the value of 'n' to the z-pointer
 add r30,r16;
 adc r31,r17;

 ; storing it in r17:r16 for looping purpose
 mov r16,r30;
 mov r17,r31;

 ; The outer loop, that runs the number of times we need to calculate the output
 start:
 ;Clearing the accumulator initially for each output we calculate
 clr r11;
 clr r10;
 clr r9;
 clr r8;

 ; load the address of the coefficients into the x-pointer
 mov r26,r2;
 mov r27,r3;
  
 ; load the address of the inputs into the z-pointer
 mov r30,r16;
 mov r31,r17;

 mov r6,r14; setting the number of taps for iterating the inner loop

 again: ld r18,x+; loading the coefficients from the SRAM using the x-pointer
 ; Comment the below line while calculating the output for sine and white noise,
 ; also while calculating for the DC signal uncomment below line and comment the following two lines 
 ldi r19,0x7f; For the case of DC signal we just always have the same input as 127(or 0x7f)
 ;lpm r19,z; For the case of sine and wgn we load the input from the flash memory
 ;sbiw zh:zl,1; Decrementing the pointer to get the correct value in the next iteration

 ; Performing the multiply and accumulate operation
 fmuls r18,r19; multiplying the operands
 add r8,r0; adding the lsb of multiplication result to the lsb of accumulator
 adc r9,r1; adding the msb of multiplication result to the msb of accumulator with the carry generated while adding the lsb's
 brcc nocarry; checking if any carry while adding the msb's 
 inc r10; incrementing the final byte if there is a carry
 nocarry: 
 sbrc r1,7; checking whether the result is negative, and if it is negative increment the r11 by 2.
 add r11,r12
 nonegative:
 dec r6; decrementing the number of taps, so as to perform the inner loop
 brne again;
 
 ; performing the manipulation to get correct output after including the carry and overflow
 ; r10:r9:r8 has the 24-bit accumulated value.
 mov r13,r10; moving the msb and middle byte to other registers for manipulation
 mov r24,r9; moving the r9 to r24 for using cbr and sbr operations

 ; here we just take integer part of the result (i.e the third byte and msb of the second byte and subtract the r11, so as to accompany the overflow generated while adding negative numbers)
 clc; setting the carry based on the msb of the second byte 
 sbrc r24,7; 
 sec;
 rol r13;  pushing in the high bit for subtraction
 sub r13,r11; performing the subtraction  
 cbr r24,$80; again setting the msb of second byte after we do the subtraction 
 ror r13; pushing out the high bit after subtraction
 brcc carryclear;
 sbr r24,$80;
 carryclear: mov r10,r13; Moving the mainpulated values again to the accumualtor.
 mov r9,r24;

 ; Storing the final accumulated result of 24-bits
 st y+,r10;
 st y+,r9;
 st y+,r8;

 ; incrementing the address of the initial coefficient so as calculate the outpt for the next n-value
 add r16,r15;
 adc r17,r21;

 dec r25; decrementing the no.of count for iterating the outer loop
 brne start;

here: rjmp here; the end operation, to see the memory locations after performing the calculations

 ; for dc signal put directly while loading the input 0x7f

 ; num1 holds the 5tap coefficients after scaling
 num1: .db 0xce,0x0d,0x59,0x0d,0xce,0x00;
 ; num2 holds the 32tap coefficients after scaling
 num2: .db 0xf3,0xf7,0x7,0xf0,0x01,0x00,0x6,0xd,0x2,0x1,0x0,0xf0,0x0,0xed,0xe1,0x35,0x35,0xe1,0xed,0x0,0xf0,0x0,0x1,0x2,0xd,0x6,0x00,0x01,0xf0,0x7,0xf7,0xf3;
 ; num3 holds sine signal after scaling
 num3: .db 0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122,0,-122,-75,75,122;
 ; num4 holds wgn signal after scaling
 num4: .db 37,14,-57,65,-26,-30,-60,-5,-4,-14,-35,-70,127,63,-15,-5,15,-1,-24,39,-48,83,-74,-14,37,5,-63,39,7,-34,17,32,92,-4,-12,-21,-81,22,-87,-11,-12,36,-117,39,-22,-55,-0,10,-18,-62,51,8,-30,51,16,-54,26,-76,-45,6,17,3,-82,35,53,49,-24,-17,-43,11,11,-33,39,36,28,-32,-57,28,61,-54,-93,61,-3,50,42,-51,-18,-35,8,49,2,-89,52,0,-19,-89,16,10,14,-46,-31,-39,76,-35,-8,-38,38,-1,3,40,29,33,-90,9,41,15,38,90,53,-47,-35,-5,-27,-3,52,-22,-12,-10,28,44,-6,-13,39,31,21,0,1,14,-4,26,-22,43,77,4,-3,-24,-20,-72,-2,-37,53,7,2,59,-75,14,-45,-27,11,38,-35,23,62,-36,-42,-0,26,0,-34,5,9,-19,-47,18,1,-15,-27,-21,-37,-44,53,-10,-73,-21,45,-23,75,-33,-32,-44,49,-25,18,-70,-24,28,-54,2,23,75,27,40,-15,-24,2,-38,47,33,41,53,-5,-24,22,49,36,40,64,12,51,-1,33,-59,65,-75,9,-15,-49,14,14,60,6,24,10,62,48,0,5,75,-10,36,-37,-32,36,27,45,-27,43,7,-2,71,61,-95,15,-36,-13,-27,69,52,23,30,19,29,11,-8,21,-13,-17,-11,-4,0,107,-52,-45,10,-2,-31,14,32,-49,-17,-54,4,7,29,-46,13,-6,59,13,-23,-10,-23,61,-22,-68,-9,48,28,7,75,-25,11,-37,-33,-15,27,87,34,-45,-9,-23,-12,50,16,42,25,-33,39,-57,34,25,46,-60,-9,1,4,37,30,28,8,71,-14,4,-24,-3,31,-52,8,-31,33,-83,-83,69,-6,-83,-71,-4,13,14,45,14,-3,44,87,1,-10,44,-21,-63,-4,10,6,-47,-25,-29,40,-6,27,25,-8,-84,15,30,-32,-1,-19,72,-1,9,-44,-31,-57,31,26,-35,122,39,17,81,-104,-4,-1,8,-44,22,-94,5,19,-2,15,-32,23,-16,-70,-13,-26,-43,21,2,-11,-23,71,50,-8,4,64,76,47,-14,-25,32,-36,-45,-15,40,7,10,48,10,-48,36,20,-4,-17,-23,-1,-34,-22,-63,-22,-29,24,61,44,44,29,23,32,-31,35,-51,26,-35,-41,-19,-55,1,47,-11,21,7,51,-7,12,104,48,-39,47,-39,0,12,37,-17,23,75,-80,-45,50,-12,-2,39,94,-55,-38,-3,0,5,-13,52,-38,9,42,16,-26,5,-13,-25,57,-8,-24,-32,5,-63,-70,8,-54,-17,33,39,65,-43,36,14,53,9,34,48,-17,-19,-56,-4,15,-31,3,-15,-18,33,34,49,-46,-6,28,-55,81,10,-23,44,16,5,-29,-75,-41,-27,19,26,-33,35,28,-5,-40,38,-5,-43,11,22,-62,79,-91,-69,52,14,-18,0,31,-37,39,29,-2,8,-27,-36,-16,43,-10,-19,-41,-48,1,44,52,24,-13,-16,15,40,41,-90,-2,-41,-20,73,-33,-71,7,-5,-18,37,24,16,-12,15,-12,8,24,14,-28,-23,-44,42,-1,-28,29,-22,19,64,40,-7,-5,82,-7,13,14,39,9,15,14,114,37,-37,-51,-68,78,-35,42,23,-64,85,23,77,14,8,-43,2,6,-64,-1,7,-30,17,-51,-24,4,-26,18,-15,-37,39,25,24,29,43,42,1,-19,-5,52,-51,-24,44,36,-21,-9,-7,-12,-103,-18,13,104,-62,-27,-16,-40,-28,-81,-5,-22,23,2,45,68,5,-52,10,59,-4,16,-41,64,17,-18,-71,-29,-43,-21,15,35,7,4,16,112,14,6,67,4,-28,39,-15,9,37,34,-68,-100,-30,70,10,-6,-7,44,14,20,-88,-7,1,-36,-1,-25,37,-24,55,-2,38,97,3,63,-45,77,-51,-3,-14,-49,-55,27,-59,-57,48,0,16,-38,-8,13,7,76,-26,-6,35,40,-83,-17,-29,-1,22,19,48,19,13,40,18,-56,5,-70,47,-89,-23,4,-2,80,2,-26,25,-51,23,11,-17,-26,-50,-79,-18,33,-30,67,-38,90,-29,4,61,52,-32,31,-47,-72,28,-73,-90,-3,59,51,-63,2,34,41,66,67,36,-60,2,-58,52,74,-85,35,-14,-20,-38,53,16,-5,18,43,-37,-34,29,67,53,-5,-56,-99,-39,48,-23,12,9,-93,53,86,-2,42,-32,25,90,55,-30,-43,2,-10,-3,54,9,70,-2,-6,34,18,-9,-67,-47,26,23,-62,5,22,-50,-42,50,-74,19,41,-76,-5,-50,4,-18,-70,26,25,-26,22,-57,-52,-49,-5,-22,81,-3,24,24,16,8,53,-49,69,29,-49,47,50,72,-18,69,11,-62,-33,39,76,-50,-5,-28,79,-38,56,-26,33,-56,63,-93,14,18,-35,-41,26,-44,-1,-119,-88,-2,47,-70,29,21,-25,-1,93,-59,20,9,14,-0,12,-11,-72,-25,10,11,25,94,-70,29,6,-2,-29,-5,29,18,-68,38,11,80,-47,-30,-74,0,42,-20,-22,-12,-7,43,1,-20,27,-58,25,-9,90,-27,18,5,-46,37,-94,-82,-55;