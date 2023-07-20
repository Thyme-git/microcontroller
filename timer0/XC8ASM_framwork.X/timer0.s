#include <xc.inc>

    psect   init, class=CODE, delta=2
    psect   end_init, class=CODE, delta=2
    psect   powerup, class=CODE, delta=2
    psect   cinit,class=CODE,delta=2
    psect   functab,class=ENTRY,delta=2
    psect   idloc,class=IDLOC,delta=2,noexec
    psect   eeprom_data,class=EEDATA,delta=2,space=3,noexec
    psect   intentry, class=CODE, delta=2
    psect   reset_vec, class=CODE, delta=2

    global _main, reset_vec, start_initialization

psect config, class=CONFIG, delta=2
    dw	0xDFEC
    dw	0xF7FF
    dw	0xFFBF
    dw	0xEFFE
    dw	0xFFFF
    
    psect	reset_vec
reset_vec:
    ljmp	_main
    
    psect cinit
start_initialization:
   
    psect	CommonVar, class=COMMON, space=1, delta=1
charcase: ds 1h

    psect intentry
intentry:
    retfie
    
psect   main,class=CODE,delta=2 ; PIC10/12/16
    
global _main
_main:
    banksel TRISA   
    bcf TRISA, 0 ;PORTA[0] as output
    
    ;TIMER0 config
    banksel T0CON0
    movlw   10010000B ;16-bit mode
    movwf   T0CON0
    
    banksel T0CON1
    movlw   01010011B ;
    movwf   T0CON1

    HIGHBYTE equ 0x0b
    LOWBYTE equ 0xde
    
 start:
    banksel LATA
    comf LATA, 0 
    
    ; 2**16 - 2**14 = 0xc0 00
    banksel TMR0H
    movlw HIGHBYTE
    movwf TMR0H
    banksel TMR0L
    movlw LOWBYTE
    movwf TMR0L
    banksel PIR0
    nop

loop:
    btfss PIR0, 5
    goto loop
    nop
    bcf PIR0, 5
    nop
    goto start
 
end reset_vec
