# ifndef _SEG_DISPLAY_H
# define _SEG_DISPLAY_H

# include <xc.h>

# define OUTPUT_ENABLE_REG	    TRISC
# define NEG_POLE_ENABLE_REG	TRISB
# define POS_POLE		        LATC
# define NEG_POLE		        LATB
# define SEG_CNT		        4
# define SEG0_SELECT_VALUE	    0b11111110
# define SEG1_SELECT_VALUE	    0b11111101
# define SEG2_SELECT_VALUE	    0b11111011
# define SEG3_SELECT_VALUE	    0b11110111
# define SEG_DOT_MASK           0b00000100
# define CODE_IDX_S		        14
# define CODE_IDX_L		        15
# define CODE_IDX_D		        16
# define CODE_NUM               17
# define STARTUP_STATE_NUM      11
# define STARTUP_ANIME_DELAY    6000

unsigned char seg_buffer[SEG_CNT];
unsigned char seg_idx;
unsigned char seg_flash;
const unsigned char _table_encoded[CODE_NUM] = {
    0xeb // 11101011B
,   0x28 // 00101000B
,   0xb3 // 10110011B
,   0xba // 10111010B
,   0x78 // 01111000B
,   0xda // 11011010B
,   0xdb // 11011011B
,   0xa8 // 10101000B
,   0xfb // 11111011B
,   0xfa // 11111010B
,   0xf9 // 11111001B
,   0x5b // 01011011B b
,   0xc3 // 11000011B c
,   0x3b // 00111011B d
,   0xde // 11011110B S.
,   0x47 // 01000111B L.
,   0x3f // 00111111B D.
};

const unsigned char _table_seg_select[SEG_CNT] = {
    SEG0_SELECT_VALUE
,   SEG1_SELECT_VALUE
,   SEG2_SELECT_VALUE
,   SEG3_SELECT_VALUE
};

const unsigned long startup_anime_code[STARTUP_STATE_NUM] = {
    0x28000000
,   0x80800000
,   0x00808000
,   0x00008080
,   0x000000c0
,   0x00000041
,   0x00000003
,   0x00000202
,   0x00020200
,   0x02020000
,   0x0a000000
}; // 注意小端存储


void seg_display_func(void);
void seg_startup_anime(int times);

# endif