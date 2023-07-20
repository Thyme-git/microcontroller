
# 1 "timer0.s"
global _main
_main:
;TODO
;PORTA config
banksel PORTA
clrf PORTA
banksel LATA
clrf LATA
banksel ANSELA
clrf ANSELA
banksel TRISA
movlw 00000000B
movwf TRISA

;TIMER0 config
banksel T0CON0
movlw 10000000B
movwf T0CON0
banksel T0CON1
movlw 10010110B
movwf T0CON1

loop:
banksel PIR0
btfss PIR0, 5 ; if PIR0[5] == 1, jump next line
goto loop
bcf PIR0, 5 ; set overflow flag 0

banksel PORTA
MOVLW 01H
XORWF PORTA,f
goto loop

;END
end reset_vec
