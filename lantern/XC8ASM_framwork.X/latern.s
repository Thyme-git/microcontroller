#include <xc.inc>

# define OUTPUT_ENABLE_REG	TRISB
# define NEG_POLE_ENABLE_REG	TRISC
# define POS_POLE		LATB
# define NEG_POLE		LATC
# define SEG_CNT		4
# define HIGHBYTE		0xfb
# define LOWBYTE		0xff
# define NUMBER_CNT		10
# define SEG0_SELECT_VALUE 11111101B
# define SEG1_SELECT_VALUE 11111011B
# define SEG2_SELECT_VALUE 11110111B
# define SEG3_SELECT_VALUE 11101111B
    
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
seg_buffer  : ds 4h; encoded number for display at 0xf0
seg_idx     : ds 1h; index for seg_buffer at 0xf4
seg_select: ds 4h; at 0xf5 TODO constant value can be put into a table
number: ds 4h; at 0xfa
cnt: ds 1h; for test
w_tmp:ds 1h; for test
seg_flash: ds 1h; 0000 0001 means that flash seg0

    psect intentry
intentry:
    ; (index+1)
    call seg_display_func

    banksel PIR0
    bcf PIR0, 5; clear timer0 interupt bit

    ; reset counter
    banksel TMR0H
    movlw HIGHBYTE
    movwf TMR0H
    banksel TMR0L
    movlw LOWBYTE
    movwf TMR0L
    retfie
    
psect   main,class=CODE,delta=2 ; PIC10/12/16
    
 global _main
_main:
;write code here
    ; initialize
    banksel OUTPUT_ENABLE_REG
    clrf    OUTPUT_ENABLE_REG; port b as output
    
    banksel NEG_POLE_ENABLE_REG
    clrf    NEG_POLE_ENABLE_REG; port c as negtive pole
  
    ; interupt config
    banksel INTCON
    bsf GIE ;enable general interupt
    
    banksel PIE0
    bsf TMR0IE; enable Timer0 interupt
    
    ;TIMER0 config
    banksel T0CON0
    movlw   10010000B ;16-bit mode
    movwf   T0CON0
    banksel T0CON1
    movlw   01010000B ;use FOSC/4 as input: prescale 1:1
    movwf   T0CON1
    
    banksel LATC
    clrf LATC
    comf LATC
    
    movlw 1
    movwf number
    movlw 2
    movwf number+1
    movlw 3
    movwf number+2
    movlw 4
    movwf number+3
   
    movlw SEG0_SELECT_VALUE
    movwf seg_select
    movlw SEG1_SELECT_VALUE
    movwf seg_select+1
    movlw SEG2_SELECT_VALUE
    movwf seg_select+2
    movlw SEG3_SELECT_VALUE
    movwf seg_select+3
    
    movlw 10
    movwf seg_flash
    
main_loop:
    movlw number; store base address of numbers to w
    addwf cnt, w
    movwf FSR0L; store real address of number[cnt] to w

    ; INDF0 = FSR0->content
    incf INDF0, f; number[cnt]++
    movf INDF0, w
    call mod_10_func;w = w % 10
    movwf INDF0 ; number[cnt] = (number[cnt])%10
    call _table_encoded  ; encode(number[cnt]) -> w
    movwf w_tmp;  encode(number[cnt]) -> w_tmp

    movlw seg_buffer; store base address of seg_buffers to w
    addwf cnt, w
    movwf FSR0L  ;addr(seg_buffer[cnt]) -> FSR0L
    movf w_tmp, w;
    movwf INDF0 ;encode(number0[cnt]) -> seg_buffer[cnt]
    
    incf cnt, f
    movlw SEG_CNT-1
    andwf cnt, f; cnt = cnt % 4
    
    btfsc STATUS, 2; skip if cnt == 0
    call delay
    goto main_loop

#     movlw 4
#     call _table_encoded
#     movwf seg_buffer
#     movlw 2
#     call _table_encoded
#     movwf seg_buffer+1
#     movlw 1
#     call _table_encoded
#     movwf seg_buffer+2
#     movlw 3
#     call _table_encoded
#     movwf seg_buffer+3
#     
# #     movlw 3
# #     movwf seg_idx
# 
# main_loop:
#     goto main_loop
    
    goto _exit
    
delay:
    movlw 0x8F
    movwf w_tmp
delay_loop:
    movlw 0xFF
loop_delay:
    decfsz WREG, w
    goto loop_delay
    decfsz w_tmp, f
    goto delay_loop
    return

seg_display_func:;display seg_buffer[seg_idx%4] in segment
    decf seg_idx, f
    
    ; disable negtive pole before write postive pole,
    ; ortherwise there will be blurry light leaving in segment
    banksel NEG_POLE
    clrf NEG_POLE
    comf NEG_POLE
    
    ; write postive pole
    movf seg_idx, w	; w <- seg_idx (range from 0 to 255)
    andlw SEG_CNT-1	; w <- seg_idx % 4
    addlw seg_buffer	; w <- seg_buffer + seg_idx % 4
    movwf FSR0L		; FSR0L <- seg_buffer + seg_idx % 4
    banksel POS_POLE
    movf INDF0, w	; w <- seg_buffer[seg_idx%4]
    movwf POS_POLE	; w -> POS_POLE

    ; write negtive pole
    movf seg_idx, w	; w <- seg_idx (range from 0 to 255)
    andlw SEG_CNT-1	; w <- seg_idx % 4
    addlw seg_select	;w <- seg_select + seg_idx % 4
    movwf FSR0L		; FSR0L <- seg_select + seg_idx % 4
    banksel NEG_POLE
    movf INDF0, w	; w <- seg_select[seg_idx%4]
    movwf NEG_POLE	; NEG_POLE <- seg_select[seg_idx%4]
    
    movf seg_flash, w	
    btfsc seg_idx, 7
    iorwf NEG_POLE, f	; flash, if seg_flash[i] == 1, then NEG_POLE[i] will be set as 1
    
    return

_dim_all:
;    clrf NEG_POLE
    movf seg_flash, w
;    comf NEG_POLE, f
    iorwf NEG_POLE, f
    return
    
 _table_encoded:
    addwf PCL,f ;add offset to pc to 
		;generate a computed goto
    retlw 11101011B ; 0
    retlw 00101000B ; 1
    retlw 10110011B ; 2
    retlw 10111010B ; 3
    retlw 01111000B ; 4
    retlw 11011010B ; 5
    retlw 11011011B ; 6
    retlw 10101000B ; 7
    retlw 11111011B ; 8
    retlw 11111010B ; 9

mod_10_func:; input value in wreg, return value is in wreg
    movwf w_tmp
    movlw 10
mod_loop:
    subwf   w_tmp, f
    btfsc   STATUS, 0	    
    goto    mod_loop	    
    addwf   w_tmp, w
    return

_exit:
end reset_vec