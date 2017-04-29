#include "soc-hw.h"

int main()
{
	//volatile unsigned int  *p;
	//*p = gpion0->in;
	//sintesis0->data = *p; //se pasa las 13 teclas de gpio a síntesis
	irq_set_mask( 0x00000001 ); //   Activación y enmascaramiento
	irq_enable(); //para habilitar la interrupción del timer
	sintesis0->cs= 0x02; //start=1
	//gpion0->out = 0x0B;	
	lcd_inicializa();
	//if (gpion0->in != 0x00)	{
	//irq_set_mask( 0x00000001 ); //   Activación y enmascaramiento
	//irq_enable(); //para habilitar la interrupción del timer  
	//gpion0->cs  = 0x01; //flag de interrupción int=1;
	//}
	//gpion0->out = 0X0E;
 return 0;
}

