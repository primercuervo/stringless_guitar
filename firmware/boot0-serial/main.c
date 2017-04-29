/**
 * Primitive first stage bootloader 
 */
#include "soc-hw.h"

/* prototypes */

int main()
{
	volatile unsigned int  *p;
	*p = gpion0->in;
	sintesis0->data = *p; //se pasa las 13 teclas de gpio a síntesis
	sintesis0->cs= 0x02; //start=1
	gpion0->out = 0x0B;
	gpion0->cs = 0x01; //activar interrupcion	
	lcd_inicializa();
	return 0;
}






/*
#include "soc-hw.h"
void irq_handler(uint32_t irq) {	
      volatile unsigned int     *data_irq;
      volatile unsigned int     irqc;
// La rutina de interrupción simplemente hace una escritura del vector de interrupciones en la direccion especificada, 
// se lee el vector de interrupciones y se hace una escritura si coincice con la que enmascaramos, si no se escribe otro
// dato
	irqc=0;
	irqc=(char)irq;
	if(irqc == 0x00000008) {	//intr_n={28'hFFFFFFF,~timer0_intr[1],~gpio0_intr,~timer0_intr[0],~uart0_intr };
					//se evalúa si el timer interrumpió
	data_irq = (unsigned int   *)(0x20000700);  //dirección arbitraria
        //*data_irq = irqc;}
	*data_irq = 0x00000003;}
	else 
	{        
	*data_irq = 0xFFFFFFFF;
	}
}
int main() {
	volatile unsigned int     *data_test;
	volatile unsigned int     test;
    	data_test = (unsigned int   *)(0x20000900);

	// Initialize TIC timer interrupt controller 
//   Activación y enmascaramiento para habilitar la interrupción del timer 
	irq_set_mask( 0x00000008 ); //0010
	irq_enable();// Definida en crt0ram.S
// Escrituras Necesarias para la activación de la interrupción en el modulo timer
	timer0->counter0 = 0x000000AA;
	timer0->compare0 = 0x000000BB;
	timer0->tcr0 = 0x0000000C;
	
*data_test=0xAAAAAAAA;
test=*data_test;
 return 0;
}
*/
