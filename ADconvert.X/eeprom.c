# include "eeprom.h"

void store_eeprom_func(char data, short addr)
{
    // NVMDATL = seg_buffer[0];
    NVMDATL = data;

    NVMCON1bits.NVMREGS = 0b1;
    NVMCON1bits.WREN = 0b1;
    // NVMADRH = 0xf0;
    // NVMADRL = 0x00;
    NVMADRH = (char)(addr>>8);
    NVMADRL = (char)addr;

    INTCONbits.GIE = 0b0;
    NVMCON1bits.WREN = 0b1;
    
    NVMCON2 = 0x55;
    NVMCON2 = 0xaa;
    NVMCON1bits.WR = 0b1;
    INTCONbits.GIE = 0b1;

    while (NVMCON1bits.WR); // Software must poll the WR bit to determine when writing is complete
}

char load_from_eeprom_func(short addr)
{
    NVMCON1bits.NVMREGS = 0b1; // r set NMVREGS if the user intends to access User ID, Configuration, or EEPROM locations

    // NVMADRH = 0xf0;
    // NVMADRL = 0x00; // Write the desired address into the NVMADRH:NVMADRL register pair

    NVMADRH = (char)(addr>>8);
    NVMADRL = (char)addr;

    NVMCON1bits.RD = 0b1; // Set the RD bit of the NVMCON1 register to initiate the read

    return NVMDATL;
}

void store_seg_buffer()
{
    store_eeprom_func(seg_buffer[0], (short)0xf000);
    store_eeprom_func(seg_buffer[1], (short)0xf001);
    store_eeprom_func(seg_buffer[2], (short)0xf002);
    store_eeprom_func(seg_buffer[3], (short)0xf003);
}

void load_seg_buffer()
{
    seg_buffer[0] = load_from_eeprom_func((short)0xf000);
    seg_buffer[1] = load_from_eeprom_func((short)0xf001);
    seg_buffer[2] = load_from_eeprom_func((short)0xf002);
    seg_buffer[3] = load_from_eeprom_func((short)0xf003);
}