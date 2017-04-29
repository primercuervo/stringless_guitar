//----------------------------------------------------------------------------
//
//----------------------------------------------------------------------------
//`timescale 1 ns / 100 ps
`timescale 1 ns / 1 ns

module system_tb;

//----------------------------------------------------------------------------
// Parameter (may differ for physical synthesis)
//----------------------------------------------------------------------------
parameter tck              = 20;       // clock period in ns
parameter uart_baud_rate   = 1152000;  // uart baud rate for simulation 

parameter clk_freq = 1000000000 / tck; // Frequenzy in HZ
//----------------------------------------------------------------------------
//
//----------------------------------------------------------------------------
reg        clk;
reg        rst;
wire       led;

//----------------------------------------------------------------------------
// UART STUFF (testbench uart, simulating a comm. partner)
//----------------------------------------------------------------------------
wire         uart_rxd;
wire         uart_txd;
//Teclado
reg [12:0] gpio_entrada;
wire [6:0] gpio_salida;
//----------------------------------------------------------------------------
// Device Under Test 
//----------------------------------------------------------------------------
system #(
	.clk_freq(           clk_freq         ),
	.uart_baud_rate(     uart_baud_rate   )
) dut  (
	.clk(          clk    ),
	// Debug
	.rst(          rst    ),
	.led(          led    ),
	// Uart
	.uart_rxd(  uart_rxd  ),
	.uart_txd(  uart_txd  ),
	.gpio_entrada (gpio_entrada),
	.gpio_salida (gpio_salida)
);

/* Clocking device */
initial         clk <= 0;
always #(tck/2) clk <= ~clk;

/* Simulation setup */
initial begin



	$dumpfile("system_tb.vcd");
	//$monitor("%b,%b,%b,%b",clk,rst,uart_txd,uart_rxd);
	$dumpvars(-1, dut);
	//$dumpvars(-1,clk,rst,uart_txd,uart_rxd);
	// reset
	#0  rst <= 0;
	#80 rst <= 1;				
	#10 gpio_entrada <= 13'b1;	//+++..
	#100000 gpio_entrada <= 13'b0;
	#100000 gpio_entrada <= 13'b101;
	#100000 gpio_entrada <= 13'b0;
	#(tck*50000) $finish;
end



endmodule
