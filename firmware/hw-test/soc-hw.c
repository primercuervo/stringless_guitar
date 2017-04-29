#include "soc-hw.h"

uart_t   *uart0  = (uart_t *)   0xF0000000;
timer_t  *timer0 = (timer_t *)  0xF0010000;
gpion_t   *gpion0  = (gpion_t *)   0xF0020000;
lcd_t   *lcd0  = (lcd_t *)   0xF0030000;
sintesis_t   *sintesis0  = (sintesis_t *)   0xF0040000;    //++

isr_ptr_t    isr_table[32];  // Tipo de Puntero encargado de las interrupciones no tiene direccion

void tic_isr();
/***************************************************************************
 * IRQ handling
 */
void isr_null()
{
}

void isr_init()
{
	int i;
	for(i=0; i<32; i++)
		isr_table[i] = &isr_null;
}

void isr_register(int irq, isr_ptr_t isr)
{
	isr_table[irq] = isr;
}

void isr_unregister(int irq)
{
	isr_table[irq] = &isr_null;
}

/***************************************************************************
 * TIMER Functions
 */
void msleep(uint32_t msec)
{
	uint32_t tcr;

	// Use timer0.1
	timer0->compare1 = (FCPU/1000)*msec;
	timer0->counter1 = 0;
	timer0->tcr1 = TIMER_EN;

	do {
		//halt();
 		tcr = timer0->tcr1;
 	} while ( ! (tcr & TIMER_TRIG) );
}

void nsleep(uint32_t nsec)
{
	uint32_t tcr;

	// Use timer0.1
	timer0->compare1 = (FCPU/1000000)*nsec;
	timer0->counter1 = 0;
	timer0->tcr1 = TIMER_EN;

	do {
		//halt();
 		tcr = timer0->tcr1;
 	} while ( ! (tcr & TIMER_TRIG) );
}


uint32_t tic_msec;

void tic_isr()
{
	tic_msec++;
	timer0->tcr0     = TIMER_EN | TIMER_AR | TIMER_IRQEN;
}

void tic_init() //inicializacion del control de interrupciones del timer 
{
	tic_msec = 0;

	// Setup timer0.0
	timer0->compare0 = (FCPU/10000);
	timer0->counter0 = 0;
	timer0->tcr0     = TIMER_EN | TIMER_AR | TIMER_IRQEN; // Almacena en un vector de control y estado los registros de HW correspondientes, a enable IRQ -autoreload

	isr_register(1, &tic_isr);
}


/***************************************************************************
 * UART Functions
 */
void uart_init()
{
	//uart0->ier = 0x00;  // Interrupt Enable Register
	//uart0->lcr = 0x03;  // Line Control Register:    8N1
	//uart0->mcr = 0x00;  // Modem Control Register

	// Setup Divisor register (Fclk / Baud)
	//uart0->div = (FCPU/(57600*16));
}

char uart_getchar()
{   
	while (! (uart0->ucr & UART_DR)) ;
	return uart0->rxtx;
}

void uart_putchar(char c)
{
	while (uart0->ucr & UART_BUSY) ;
	uart0->rxtx = c;
}

void uart_putstr(char *str)
{
	char *c = str;
	while(*c) {
		uart_putchar(*c);
		c++;
	}
}

//***************************************************************************
//Rutina de interrupción - del gpio
void irq_handler(uint32_t irq)
{	
        volatile unsigned int     irqc;  
 	irqc=0;
	irqc=(char)irq;
	if(irqc == 0x00000001){   //se lee vector de interrupciones, se hace una escritura si coincice con la enmascarada
		timer0->counter1 = 'work';
		gpion0->cs  = 0x00; //flag de interrupción int=0;
	}
}


// LCD Funciones
void wait_lcd (unsigned int a) {
	while (a == 0x01){ //donep=1; 
		a = lcd0->donepwb;
	}
	while (a == 0x00){ //donep=0;
		a = lcd0->donepwb;
	}
}
void lcd_inicializa () { //unsigned char  uint8_t 8 Bit 
	volatile unsigned int  a;
	lcd0->cs = 0x20;// sig=0, rsin=0, donec=0; start=1
	a = lcd0->donepwb;
	lcd0->cs = 0x24; //donec=1;
	lcd0->data_out = 0x02; //4 bit mode ON, 1 line, 5*8 font
	wait_lcd(a);
	lcd0->data_out = 0x0C; //Display ON/OFF control: display ON, cursor OFF, blink OFF
	wait_lcd(a);
	lcd0->data_out = 0x03; //Cursor home
	wait_lcd(a);
	lcd0->data_out = 0x01; //Clear display
	wait_lcd(a);
	lcd0->data_out = 0x80; //Set DDRAM address to 0
	wait_lcd(a);
	lcd0->cs = 0x21; // sig=1, start=1
}
