# include "scan_botton.h"
# include "seg_display.h"

void scan_func()
{
    polling_func();
    if (curr_key == 0) // released
    {
        if (rcnt == SINGLE_CLICK_DELAY)
        {
            single_click_func();
        }
        if (rcnt > 3)
        {
            pcnt = 0;
        }
        if (rcnt == 255)
        {
            return;
        }
        ++rcnt;
    }else // pressed
    {
        if (pcnt == LONG_CLICK_DELAY)
        {
            long_click_func();
            rcnt = SINGLE_CLICK_DELAY+1;
        }
        if (pcnt == 2)
        {
            key_buffer = (unsigned char)(key_buffer <<  4);
            key_buffer = key_buffer ^ curr_key;
            if (rcnt < SINGLE_CLICK_DELAY)
            {
                double_click_func();
                rcnt = SINGLE_CLICK_DELAY+1;
                pcnt = LONG_CLICK_DELAY+1;
                return;
            }
            rcnt = 0;
        }
        if (pcnt == 255)
        {
            return;
        }
        ++pcnt;
    }
}

void polling_func()
{
    unsigned char w_tmp;
    unsigned char mask = 0x08;
    
    curr_key = 10;
    KEY_INPUT_CLTR_PORT = 0x0f;
    KEY_INPUT_PORT = 0x00;

    while (mask)
    {
        w_tmp = mask;
        while (w_tmp)
        {
            if ((w_tmp & KEY_INPUT_PORT) == 0)
            {
                return;
            }
            --curr_key;
            w_tmp = w_tmp >> 1;
        }
        KEY_INPUT_CLTR_PORT = KEY_INPUT_CLTR_PORT >> 1;
        mask = mask >> 1;
    }
    return;
}

void single_click_func()
{
    seg_buffer[3] = _table_encoded[CODE_IDX_S];
    seg_buffer[0] = _table_encoded[key_buffer&CURR_KEY_MASK];
    return;
}

void double_click_func()
{
    unsigned char pre_key = (key_buffer&PRE_KEY_MASK) >> 4;
    if (pre_key != (key_buffer&CURR_KEY_MASK))
    {
        single_click_func();
        return;
    }

    seg_buffer[3] = _table_encoded[CODE_IDX_D];
    seg_buffer[2] = _table_encoded[key_buffer&CURR_KEY_MASK];

    return;
}

void long_click_func()
{
    seg_buffer[3] = _table_encoded[CODE_IDX_L];
    seg_buffer[1] = _table_encoded[key_buffer&CURR_KEY_MASK];
    return;
}

int scan_touch_key_func()
{
    short adcres = 0; // ADC result
    int key = -1;
    // recieve analog input
    TRISA = 0b01110000; // A4-A6:T3-T1
    ANSELA = 0b01110000;

    // ADPCHbits.ADPCH = 0b000100; // select ANA6 as sample

    for (unsigned char port = 4; port <= 6; ++port)
    {
        adcres = 0;
        ADPCHbits.ADPCH = port;
        for (int i = 0; i < 8; ++i){
            ADCON0bits.ADGO = 1; // ADC go!
            while (ADCON0bits.ADGO); // wait for ADC completion
            adcres += ((ADRESH << 8) | ADRESL);
        }
        adcres = adcres >> 3;
        if (adcres > TOUCH_SCAN_THREDHOLD)
        {
            return key;
        }
        ++key;
    }
    key = 2; // scan nothing
    return key;
}

short get_voltige_func()
{
    short adcres = 0; // ADC result
    // recieve analog input
    TRISA = 0b01110000; // A4-A6:T3-T1
    ANSELA = 0b01110000;

    ADPCHbits.ADPCH = 0b000100; // select ANA6 as sample

    ADCON0bits.ADGO = 1; // ADC go!
    while (ADCON0bits.ADGO); // wait for ADC completion
    adcres = ((ADRESH << 8) | ADRESL);
    return adcres;
}

void scan_key_func()
{
    polling_func();
    if (curr_key != 0)
    {
        return;
    }
    scan_touch_key_func();
}