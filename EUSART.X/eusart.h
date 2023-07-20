# ifndef _EUSART_H
# define _EUSART_H

# include <xc.h>

char eusart_receive_buffer;

void init_eusart_func(void);
void eusart_tx_func(char data);
void eusart_rx_func(void);
void print_red_start(void);
void print_green_start(void);
void print_blue_start(void);
void print_yellow_start(void);
void print_white_start(void);
void mov_cursor(short pos);

# endif