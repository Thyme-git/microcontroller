# ifndef _EEPROM_H
# define _EEPROM_H

# include <xc.h>
# include "seg_display.h"

// unsigned long* eeprom_ptr = (unsigned long*)0xf000;

void store_eeprom_func(char data, short addr);

char load_from_eeprom_func(short addr);

void store_seg_buffer(void);

void load_seg_buffer(void);

# endif