# include "main.h"
# include "scan_botton.h"
# include "seg_display.h"
# include "adc.h"
# include "eeprom.h"
# include "eusart.h"

unsigned char w_tmp         = 0;

void __interrupt() irs_routine(void)
{
   if (PIR0bits.TMR0IF){
       seg_display_func();
       scan_func();
       PIR0bits.TMR0IF = 0; // clear timer0 interupt bit
       // reset counter
       TMR0H = HIGHBYTE;
       TMR0L = LOWBYTE;
   }
   if (PIR3bits.RCIF){
        PIR3bits.RCIF = 0;
        eusart_rx_func();
        seg_buffer[3] = _table_encoded[(eusart_receive_buffer)%11];
        // seg_buffer[3] = _table_encoded[eusart_receive_buffer-'0'];
   }
}

void main(void)
{    
    // weak pull up for portA
    KEY_INPUT_WPU = 0x0f;
    KEY_INPUT_ANSEL = 0x00;

    // segment config
    OUTPUT_ENABLE_REG = 0x00; // port b as output
    NEG_POLE_ENABLE_REG = 0x00; // ort c as negtive pole

    // interupt config
    INTCONbits.GIE = 1; // enable general interupt
    PIE0bits.TMR0IE = 1; // enable Timer0 interupt
    INTCONbits.PEIE = 1; // Enable all active peripheral interrupts

    // TIMER0 config
    T0CON0 = 0x90; // 10010000B 16-bit mode
    T0CON1 = 0x50; // 01010000B use FOSC/4 as input: prescale 1:1


    // conter initialize
    rcnt = 0xff; 
    pcnt = 0x00;

    // ADC config
    ADREFbits.ADPREF = 0b00; // select Vdd as positive reference
    ADREFbits.ADNREF = 0b0; // select Vss as negtive reference

    ADCLKbits.ADCCS = 0b000000; // Fosc / 2 as ADC clock

    ADCON0bits.ADON = 0b1; // enable ADC
    ADCON0bits.ADCONT = 0b0; // ADGO is cleared upon completion of each conversion trigger
    ADCON0bits.ADCS = 0b0; // select Fosc as ADC clock
    ADCON0bits.ADFRM0 = 0b1; // ADCRES right justified

    ADCON1 = 0x80; // Precharge Polarity bit
    ADPRE = 0x0f; // Precharge time is 0xff clocks of the selected ADC clock
    ADACQ = 0x0f; // aquisition time(采样时间)
 
    // startup anime
    seg_startup_anime(2);
    
    // init eusart
    init_eusart_func();

    // default display
    seg_buffer[0] = _table_encoded[0];
    seg_buffer[1] = _table_encoded[0];
    seg_buffer[2] = _table_encoded[0];
    seg_buffer[3] = _table_encoded[0];


    seg_flash = 0b00001000; // 00001000B;
    
    int buffer3num = 0;
    short adcres = 0;
    short pos = 0;
    while (1){
        adcres = scan_touch_key_func();
        // adcres = get_voltige_func();
        pos = (adcres) >> 4;
        // for (short i = 0; i < pos; ++i)
        // {
        //     eusart_tx_func(' ');
        // }

        mov_cursor(pos);

        if (touch_key_buffer == 11)
        {
            print_red_start();
        }
        if (touch_key_buffer == 12)
        {
            print_yellow_start();
        }
        if (touch_key_buffer == 13)
        {
            print_green_start();
        }
        eusart_tx_func('#');
        eusart_tx_func('\r');
        eusart_tx_func('\n');
        print_white_start();
        // _delay(2000);
    }

    // int key = 0;
    // while (1){
    //     key = scan_touch_key_func();
    //     if (touch_key_buffer == 13){
    //         load_seg_buffer();
    //         seg_buffer[3] = _table_encoded[CODE_IDX_L]; // load from eeprom
    //     }
    //     if (touch_key_buffer == 12)
    //     {
    //         seg_flash ^= 0b00001000;
    //     }
    //     if (touch_key_buffer == 11)
    //     {
    //         store_seg_buffer();
    //         seg_buffer[3] = _table_encoded[CODE_IDX_S]; // store to eeprom
    //     }
    //      _delay(4000);
    // }
    
    // calculate Vdd
    // short Vdd = 0;
    // while (1){
    //     Vdd = scan_touch_key_func();
    //     seg_buffer[0] = _table_encoded[Vdd/1000];
    //     seg_buffer[1] = _table_encoded[(Vdd%1000)/100];
    //     seg_buffer[2] = _table_encoded[(Vdd%100)/10];
    //     seg_buffer[3] = _table_encoded[Vdd%10];
    //     _delay(2000);
    // }


    // transmit to PC
    // while(1){
    //     for (char chr = '0'; chr <= '9'; ++chr)
    //     {
    //         eusart_tx_func(chr);
    //     }
    //     eusart_tx_func('\r'); // 大坑
    //     eusart_tx_func('\n');
    // }

    while (1);

    return;
}