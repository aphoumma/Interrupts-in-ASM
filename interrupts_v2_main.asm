
#include "p12f1572.inc"

; CONFIG1
; __config 0x31E4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_OFF & _CLKOUTEN_ON
; CONFIG2
; __config 0x1EFF
 __CONFIG _CONFIG2, _WRT_OFF & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOREN_OFF & _LVP_OFF

 
 ; Initialize variables
    IDATA
    tick_counter db d'50'
    signal_flag db 0
 
 
RES_VECT  CODE    0x0000     ; processor reset vector
    GOTO  START            ; go to beginning of program


INT_VECT  CODE	  0x0004     ;interrupt vector
    GOTO  ISR
    
    
    
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE

START

    ; Initialize OSCCON register and set Fosc to 4Mhz
    BANKSEL OSCCON
    MOVLW 0x68
    MOVWF OSCCON
    
    
    ; Initialize RA5 pin to be output
    BANKSEL TRISA
    BCF TRISA, RA5
    
    
    ; Initialize global interrupt enable and peripheral interrupt enable
    BANKSEL INTCON
    BSF INTCON, GIE
    BSF INTCON, PEIE
    
    ; Initialize Timer2 interrupt enable bit
    BANKSEL PIE1
    BSF PIE1, TMR2IE
    
    
    ;************************************
    ; Initialize prescaler to 4, postscaler 10, and turn timer2 on in T2CON register
    ; Initialize PR2 so mainscale divides by 250
    ; Interval between interrupts = 1us * 4 * 250 * 10 = 10ms
    ; Need to wait for 50 of these intervals to pass before we get half a second
    ;************************************
    MOVLW d'249'
    BANKSEL PR2
    MOVWF PR2
    MOVLW 0x4D
    BANKSEL T2CON
    MOVWF T2CON
   
    
    BANKSEL tick_counter
    MOVLW d'50' 
    MOVWF tick_counter 
    
FOREGROUND_LOOP
    
    BANKSEL signal_flag
    BTFSS signal_flag, 0
    GOTO FOREGROUND_LOOP
    
    

    BCF signal_flag, 0	;when tick_counter is 0, we will not skip this instruction. We need to set signal_flag.    
    ; toggle RA5
    BANKSEL PORTA
    MOVLW 0x20
    XORWF PORTA, f
    GOTO FOREGROUND_LOOP

    
    
    
ISR
    ;first need to clear interrupt flag
    BANKSEL PIR1
    BCF PIR1, TMR2IF	;clears timer2 interrupt flag 
    BANKSEL tick_counter
    DECFSZ tick_counter, f
    RETFIE 
    
    ;set signal_flag bit if tick_counter is 0 (which means above instruction was skipped)
    BANKSEL signal_flag
    BSF signal_flag, 0
    ;reset tick counter back to 50
    BANKSEL tick_counter
    MOVLW d'50'
    MOVWF tick_counter
    RETFIE
    
    END