# include "adc.h"

short calc_vdd()
{
    short adcres = 0; // ADC result

    // ADC config
    ADREFbits.ADPREF = 0b00; // select Vdd as positive reference
    ADREFbits.ADNREF = 0b0; // select Vss as negtive reference
    
    ADCLKbits.ADCCS = 0b000000; // Fosc / 2 as ADC clock
    ADPCHbits.ADPCH = 0b111111; // select FVR as sample

    FVRCONbits.FVREN = 0b1; // 大坑！！！！
    FVRCONbits.ADFVR = 0b11; // = ADC FVR Buffer Gain is 4x, (4.096V)(2)
    // ADCON0bits.ADGO; //1 = ADC conversion cycle in progress. Setting this bit starts an ADC conversion cycle. The bit is cleared by hardware as determined by the ADCONT bit; 0 = ADC conversion completed/not in progress
    ADCON0bits.ADON = 0b1; // enable ADC
    ADCON0bits.ADCONT = 0b0; // ADGO is cleared upon completion of each conversion trigger
    ADCON0bits.ADCS = 0b0; // select Fosc as ADC clock
    ADCON0bits.ADFRM0 = 0b1; // ADCRES right justified
    
    ADCON0bits.ADGO = 1; // ADC go!
    while (ADCON0bits.ADGO); // wait for ADC completion

    adcres = (ADRESH << 8) | ADRESL;
    
    return 4096.0 * 1023 / adcres;
}