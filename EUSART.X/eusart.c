# include "eusart.h"

void init_eusart_func()
{
    TRISBbits.TRISB6 = 0;
    
    // receive mode for portB7
    TRISBbits.TRISB7 = 1;
    ANSELBbits.ANSB7 = 0;

    // baud rate 9600
    SPBRGH = 0;
    SPBRGL = 25;
    // high speed mode
    TX1STAbits.BRGH = 1;
    // 1 = 16-bit Baud Rate Generator is used
    BAUD1CONbits.BRG16 = 1;
    // Asynchronous Transmissions
    TX1STAbits.SYNC = 0;
    // Serial port enabled
    RC1STAbits.SPEN = 1; 

    RB6PPS = 0x10; // RB6 -> TX/CK
    // Transmit enabled
    TX1STAbits.TXEN = 1;
    // enable transmit interrupt
    // PIE3bits.TXIE = 1;


    RXPPS = 0x0f; // RX -> RB7 大坑
    // receive enable
    RC1STAbits.CREN = 1;
    // enable receive interrupt
    PIE3bits.RCIE = 1;
    // The RCIF interrupt flag bit will be set when a
    // character is transferred from the RSR to the
    // receive buffer. An interrupt will be generated if
    // the RCIE interrupt enable bit was also set.
}

void eusart_tx_func(char data)
{
    // wait transmit complete
    while (!TX1STAbits.TRMT);

    // write data
    TXREG = data;
}

void eusart_rx_func()
{
    // read data
    // eusart_receive_buffer = RCREG;
    eusart_receive_buffer = RC1REGbits.RC1REG; // 大坑
}

void print_red_start()
{
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func('3');
    eusart_tx_func('1');
    eusart_tx_func('m');
}

void print_green_start()
{
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func('3');
    eusart_tx_func('2');
    eusart_tx_func('m');
}

void print_blue_start()
{
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func('3');
    eusart_tx_func('4');
    eusart_tx_func('m');
}

void print_white_start()
{
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func('0');
    eusart_tx_func('m');
}

void print_yellow_start()
{
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func('3');
    eusart_tx_func('3');
    eusart_tx_func('m');
}

void mov_cursor(short pos)
{
    char pos_buffer[3];
    pos_buffer[0] = pos / 100 + '0';
    pos_buffer[1] = (pos % 100) / 10 + '0';
    pos_buffer[2] = pos % 10 + '0';
    eusart_tx_func('\033');
    eusart_tx_func('[');
    eusart_tx_func(pos_buffer[0]);
    eusart_tx_func(pos_buffer[1]);
    eusart_tx_func(pos_buffer[2]);
    eusart_tx_func('G');
}