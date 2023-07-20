# ifndef _SCAN_BOTTON_H
# define _SCAN_BOTTON_H

# include <xc.h>

# define KEY_NUM		10
# define KEY_INPUT_PORT		PORTA
# define KEY_INPUT_ANSEL	ANSELA
# define KEY_INPUT_CLTR_PORT	TRISA
# define KEY_INPUT_WPU		WPUA
# define SINGLE_CLICK_DELAY	128
# define LONG_CLICK_DELAY	200
# define PRE_KEY_MASK		0xf0
# define CURR_KEY_MASK		0x0f
# define TOUCH_SCAN_THREDHOLD   300

unsigned char curr_key;
// unsigned char mask;
unsigned char pcnt;
unsigned char rcnt;
unsigned char key_buffer;
unsigned char touch_key_buffer;

void scan_func(void);
void polling_func(void);
void single_click_func(void);
void double_click_func(void);
void long_click_func(void);
short scan_touch_key_func(void);
void scan_key_func(void);
short get_voltige_func(void);


# endif