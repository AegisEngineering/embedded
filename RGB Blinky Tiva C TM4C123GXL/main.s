; 22-Jul-2020
; Written by Nathan Fittler-Willis, using ARM keil uVision5
; Target: Tiva C - TM4C123GXL
; A Simple program that cycles through the Tiva C onboard RGB LED colours with a 1 second delay.
; 
; LED pins 
; LED_R PF1		LED_B PF2		LED_G PF3

; Procedure
; 1. Activate clock to LED GPIO ports using RCGCGPIO registers (p340)
; 2. Set direction of pin in DIR register (p663)
; 3. Enable pin in DEN register (p682)
; 4. Toggle LED's using GPIODATA register, setting the corresponding pin to HIGH (p654) 

; Register information from datasheet
; PORT_F RCGCGPIO			Base: 0x 400F E000	Offset: 0x608	type: RW	reset: 0x 0000 0000
; PORT_F GPIODIR (APB)		Base: 0x 4002 5000	Offset: 0x400	type: RW	reset: 0x 0000 0000
; PORT_F GPIODEN (APB)		Base: 0x 4002 5000	Offset: 0x51C	type: RW	reset: -
; PORT_F GPIODATA(APB)		Base: 0x 4002 5000	Offset: 0x000	type: RW	reset: 0x 0000 0000

;Symbolic register names
SYSCTL_RCGCGPIO_R EQU 0x400FE608 ;Clock gating control register
GPIO_PORTF_DIR_R EQU 0x40025400  ;GPIO port f direction register
GPIO_PORTF_DEN_R EQU 0x4002551C  ;GPIO Digital Enable register
GPIO_PORTF_DATA_R EQU 0x400253FC ;GPIO data register, bit masking is used -> ADDR[9:2] 
								 ;So add 3FC to base address for conventional read, modify, write.

DELAY_CONST EQU 8333333 ; reload constant for pseudo delay function
						; Currently set for ~1s delay @ 16Mhz clock speed

;Declare directives, allow other programs to access this code
				AREA	|.text|,CODE,READONLY,ALIGN=2
				THUMB ;using thumb instruction set
				EXPORT __main

__main
		BL		GPIOF_Init ;Initialize GPIOF pins for LED control

;Infinite loop
loop	
		BL		state_machine
		LDR R0, =DELAY_CONST 
		BL		pseudo_delay
		B		loop

;Subroutine to initialize GPIO pins for RGB LED output
GPIOF_Init
		;Enable clock access to GPIO port f
		LDR R1, =SYSCTL_RCGCGPIO_R 
		LDR R0, [R1]
		ORR R0, R0, #0x20 
		STR R0, [R1]
		
		;Set port f pins 1,2,3 as output pins
		LDR R1, =GPIO_PORTF_DIR_R
		MOV R0, #0x0E
		STR R0, [R1]
		
		;Enables digital pins 1,2,3 on GPIO port f (LED pins)
		LDR R1, =GPIO_PORTF_DEN_R
		MOV R0, #0x0E
		STR R0, [R1]
		
		BX LR ; Return to caller

;State machine to cycle through RGB LED colours
;State = 0 -> Turn on Red
;State = 1 -> Turn on Green
;State = 2 -> Turn on Blue
state_machine	
		CMP R3, #0x01
		BEQ green_on
		
		CMP R3, #0x02
		BEQ blue_on
		
		BNE red_on
		
		BX LR

;A delay routine that stalls the execution of code for ~1s @16Mhz (confirmed with logic analyzer)
pseudo_delay
		SUBS R0, R0, #1 ;
		BNE pseudo_delay
		BX LR

;Routine to turn red LED on
red_on
		LDR R1, =GPIO_PORTF_DATA_R
		MOV R0, #0x02 ; Value to set Bit 1 HIGH in GPIO port f
		STR R0, [R1]  ; Write to GPIO port f register, turning on the red LED
		MOV R3, #0x01 ; Set state machine state to 1
		BX LR

;Routine to turn green LED on
green_on 
		LDR R1, =GPIO_PORTF_DATA_R
		MOV R0, #0x08 ;Value to set Bit 3 HIGH in GPIO port f
		STR R0, [R1]  ; Write to GPIO port f register, turning on the green LED
		MOV R3, #0x02 ; Set state machine state to 2
		BX LR

;Routine to turn blue LED on
blue_on 
		LDR R1, =GPIO_PORTF_DATA_R
		MOV R0, #0x04 ; Value to set Bit 2 HIGH in GPIO port f 
		STR R0, [R1]  ; Write to GPIO port f register, turning on the blue LED
		MOV R3, #0x00 ; Set state machine state to 0
		BX LR
		
		
		ALIGN
		END
