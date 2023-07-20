# include <xc.inc>
# define KEY_NUM		10
# define KEY_INPUT_PORT		PORTA
# define KEY_INPUT_ANSEL	ANSELA
# define KEY_INPUT_CLTR_PORT	TRISA
# define KEY_INPUT_WPU		WPUA
# define OUTPUT_ENABLE_REG	TRISB
# define NEG_POLE_ENABLE_REG	TRISC
# define POS_POLE		LATB
# define NEG_POLE		LATC
# define SEG_CNT		4
# define HIGHBYTE		0xfe
# define LOWBYTE		0xaf
# define NUMBER_CNT		10
# define SEG0_SELECT_VALUE	11111101B
# define SEG1_SELECT_VALUE	11111011B
# define SEG2_SELECT_VALUE	11110111B
# define SEG3_SELECT_VALUE	11101111B
# define SINGLE_CLICK_DELAY	128
# define LONG_CLICK_DELAY	200
# define CODE_IDX_S		11
# define CODE_IDX_L		12
# define CODE_IDX_D		13
# define PRE_KEY_MASK		11110000B
# define CURR_KEY_MASK		00001111B

    
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


;========================CommonVar===========================================
    psect	CommonVar, class=COMMON, space=1, delta=1
seg_buffer: ds 4h; encoded number for display at 0xf0
seg_idx: ds 1h; index for seg_buffer at 0xf4

w_tmp:ds 1h; temperary variable for storing value of WREG
seg_flash: ds 1h; 0000 0001 means that flash seg0

; for polling
curr_key: ds 1h; current key input from keyboard 0xfa
mask: ds 1h; mask for polling

;for key scanning
pcnt: ds 1h; pressed time counter at 0xfc
rcnt: ds 1h; released time counter at 0xfd
key_buffer: ds 1h; store curr-key in bit<3:0>, pre-key in bit<7:4>

delay_tmp: ds 2h;
;========================CommonVar===========================================
    
    
;========================intentry============================================
    psect intentry
intentry:
    ; (index+1)
    call seg_display_func

    call scan_func

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
;========================intentry============================================


;========================_main==============================================
psect   main,class=CODE,delta=2 ; PIC10/12/16
 global _main
_main:
    ;weak pull up for portA
    banksel KEY_INPUT_WPU
    clrf KEY_INPUT_WPU
    comf KEY_INPUT_WPU; WPUA <- 0xff
    banksel KEY_INPUT_ANSEL
    clrf KEY_INPUT_ANSEL; ANSELA <- 0x00
    
    ;segment config
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
    
    ; conter initialize
    clrf rcnt
    comf rcnt, f; rcnt <- 255
    clrf pcnt; pcnt <- 0

    ; startup anime
    movlw 8
    call _table_encoded
    movwf seg_buffer
    clrf seg_buffer+1
    clrf seg_buffer+2
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+1
    clrf seg_buffer
    clrf seg_buffer+2
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+2
    clrf seg_buffer+1
    clrf seg_buffer
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+3
    clrf seg_buffer+1
    clrf seg_buffer+2
    clrf seg_buffer
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer
    clrf seg_buffer+1
    clrf seg_buffer+2
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+1
    clrf seg_buffer
    clrf seg_buffer+2
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+2
    clrf seg_buffer+1
    clrf seg_buffer
    clrf seg_buffer+3
    call delay
    movlw 8
    call _table_encoded
    movwf seg_buffer+3
    clrf seg_buffer+1
    clrf seg_buffer+2
    clrf seg_buffer
    call delay
    
    movlw 0
    call _table_encoded
    movwf seg_buffer
    movlw 0
    call _table_encoded
    movwf seg_buffer+1
    movlw 0
    call _table_encoded
    movwf seg_buffer+2
    movlw 0
    call _table_encoded
    movwf seg_buffer+3

    movlw 00010000B
    movwf seg_flash; 
    
main_loop:
    goto main_loop

    goto _exit
;========================_main==============================================

delay:
    decfsz delay_tmp, f
    goto delay
    decfsz (delay_tmp + 1), f
    goto delay
    movlw 0x0F
    movwf (delay_tmp + 1)
    return
    
;========================scan_func==========================================
scan_func:
    call polling_func; store current key in curr_key, store 0 if no key
    
    movf curr_key, w;
    btfss STATUS, 2; if curr_key == 0, skip
    goto pressed; if curr_key != 0

released:
    ; if (r == 64) call single_click_func
    movlw SINGLE_CLICK_DELAY;
    subwf rcnt, w;
    btfsc STATUS, 2; if rcnt != SINGLE_CLICK_DELAY, skip
    call single_click_func;
    ; goto released_end

    ; if (r > 3) p = 0
    movlw 255-3
    andwf rcnt, w;
    btfss STATUS, 2; if rcnt <= 3, skip
    clrf pcnt; if (rcnt > 2) pcnt = 0

released_end:
    ; if (r != 255) r++
    movlw 255
    xorwf rcnt, w;w <- rcnt ^ 255
    btfss STATUS, 2; if rcnt == 255, skip
    incf rcnt, f;
    return

pressed:
    ; if p == 200 then call long_click_func, r = 64
    movlw LONG_CLICK_DELAY
    xorwf pcnt, w; w <- 200 ^ pcnt
    btfss STATUS, 2; if pcnt == 200, skip
    goto scan_func_L1;if pcnt != 200
    
    ;if pcnt == 200
    call long_click_func
    movlw SINGLE_CLICK_DELAY+1
    movwf rcnt; r = 65
    goto pressed_end

scan_func_L1:
    movlw 2
    xorwf pcnt, w; w <- 2 ^ pcnt
    btfss STATUS, 2; if pcnt == 2, skip
    goto pressed_end; if pcnt != 2

    ; if pcnt == 2
    ; curr_key -> key_buffer, press comfirmed
    swapf key_buffer, f; swap curr-key and pre-key
    movlw PRE_KEY_MASK; w <- 11110000B
    andwf key_buffer, f; clear to store curr-key
    movf curr_key, w;
    xorwf key_buffer; curr_key<3:0> -> key_buffer<3:0>
        ; if r < 64:
        movlw 255-(SINGLE_CLICK_DELAY-1)
        andwf rcnt, w; w <- ~63 & rcnt
        btfsc STATUS, 2; if rcnt > 63, skip
        goto scan_func_L2; if (rcnt <= 63)
    clrf rcnt; rcnt = 0

pressed_end:
    ; if (p != 255) p++
    movlw 255
    xorwf pcnt, w;w <- pcnt ^ 255
    btfss STATUS, 2; if pcnt == 255, skip
    incf pcnt, f;
    return

scan_func_L2:
    call double_click_func;
    movlw SINGLE_CLICK_DELAY+1;
    movwf rcnt; r = 65
    movlw LONG_CLICK_DELAY+1;
    movwf pcnt; p = 201
    return
;========================scan_func==========================================

;========================single_click_func==================================
single_click_func:
    movlw CODE_IDX_S
    call _table_encoded
    movwf seg_buffer+3
    
    movf key_buffer, w;
    andlw CURR_KEY_MASK; w <- key_buffer & 00001111B
    call _table_encoded; w <- encode(w)
    movwf seg_buffer; seg_buffer[0] <- w
    return
;========================single_click_func==================================

;========================long_click_func====================================
long_click_func:
    movlw CODE_IDX_L
    call _table_encoded
    movwf seg_buffer+3
    
    movf key_buffer, w;
    andlw CURR_KEY_MASK; w <- key_buffer & 00001111B
    call _table_encoded; w <- encode(w)
    movwf seg_buffer+1; seg_buffer[1] <- w
    return
;========================long_click_func====================================

;========================double_click_func==================================
double_click_func:
    swapf key_buffer, w;
    xorwf key_buffer, w; w <- key_buffer<7:4, 3:0> ^ key_buffer<3:0, 7:4>
    btfss STATUS, 2; if z!=0(key_buffer<7:4, 3:0> == key_buffer<3:0, 7:4>), skip
    goto single_click_func; if (key_buffer<7:4, 3:0> == key_buffer<3:0, 7:4>)
    
    movlw CODE_IDX_D
    call _table_encoded
    movwf seg_buffer+3
    
    movf key_buffer, w;
    andlw CURR_KEY_MASK; w <- key_buffer & 00001111B
    call _table_encoded; w <- encode(w)
    movwf seg_buffer+2; seg_buffer[2] <- w
    return
;========================double_click_func==================================

;========================polling_func=======================================
polling_func: ;return pressed key in curr_key, curr_key is zero if no key is pressed
    movlw 10
    movwf curr_key; curr_key <- 10
    banksel KEY_INPUT_CLTR_PORT
    movlw 0x0f
    movwf KEY_INPUT_CLTR_PORT; TRISA <- 0x0f
    clrf KEY_INPUT_PORT; PORTA <- 0x00; set output low 
    movlw 0x08
    movwf mask; mask <- 0x08
  ; check if curr_key is pressed
POLLING_L1:
    movf mask, w; w <- mask
POLLING_L2:
    movwf w_tmp; w_tmp <- w
    andwf KEY_INPUT_PORT, w; w <- w & PORTA
    btfsc STATUS, 2; if w != 0 then skip
    return
    decf curr_key, f; curr_key <- curr_key-1
    
    lsrf w_tmp, w; w <- w_tmp >> 1
    btfss STATUS, 2; if w == 0 then skip
    goto POLLING_L2
    banksel KEY_INPUT_CLTR_PORT
    lsrf KEY_INPUT_CLTR_PORT, f; TRISA <- TRISA >> 1
    
    lsrf mask, f; mask <- mask >> 1
    btfss STATUS, 2; if mask == 0 then skip
    goto POLLING_L1
    return
;========================polling_func=======================================



;========================seg_display_func===================================    
seg_display_func:;display seg_buffer[seg_idx%4] in segment
    decf seg_idx, f
    
    ; disable negtive pole before write postive pole,
    ; ortherwise there will be blurry light leaving in segment
    banksel NEG_POLE
    clrf NEG_POLE
    comf NEG_POLE, f
    
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

    call _table_seg_select; w < _table_select[seg_idx%4]
    movwf NEG_POLE	; NEG_POLE <- seg_select[seg_idx%4]
    
    movf seg_flash, w	
    btfsc seg_idx, 7
    iorwf NEG_POLE, f	; flash, if seg_flash[i] == 1, then NEG_POLE[i] will be set as 1
    return
;========================seg_display_func===================================
    
    
;========================_table_seg_select==================================
_table_seg_select:
    addwf PCL,f ;add offset to pc to 
		;generate a computed goto
    retlw SEG0_SELECT_VALUE
    retlw SEG1_SELECT_VALUE
    retlw SEG2_SELECT_VALUE
    retlw SEG3_SELECT_VALUE
;========================_table_seg_select==================================

    
;========================_table_encoded=====================================
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
    retlw 11111001B ; A
    retlw 11011110B ; s
    retlw 01000011B ; l
    retlw 00111011B ; d
;========================_table_encoded====================================

_exit:
end reset_vec