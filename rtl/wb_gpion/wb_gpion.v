/*
module debouncer(
		input clk,
		input key,
		output deb_key
    );
reg [15:0] cont=0; 
reg key_status=0;
reg key_pressed0;
reg key_pressed1;

always @(posedge clk)begin              //se pasa la señal por dos always para sincronizar la señla de entrada con clk
	key_pressed0<=key;
end
always @(posedge clk)begin
	key_pressed1<=key_pressed0;
end
always @(posedge clk)begin            //se verifica el estado de la tecla
	case(key_status)
	1'b0: begin
		if (key_pressed1==1)begin //si pulso una tecla la salida es 1 no importa el ruido no cambia el estado pues status se pone en 1
		cont<=0;
		key_status<=1;end
	end	
	1'b1:begin	
		cont<=cont+1;
	if (cont== 14'd16383)                  //hasta que termine el contador no se deshabilita la salida, valor maximo para 14 bits 
		key_status<=0;				
	end
	endcase
end
assign deb_key=key_status;
endmodule
*/

//---------------------------------------------------------------------------
// Wishbone General Pupose IO Component	
//     0x00     gpio_in    (read-only)
//     0x04     gpio_out   (read/write)
//---------------------------------------------------------------------------

module wb_gpion (
	input              clk,
	input              reset,
	// Wishbone interface
	input              wb_stb_i,
	input              wb_cyc_i,
	output             wb_ack_o,
	input              wb_we_i,
	input       [31:0] wb_adr_i,
	input        [3:0] wb_sel_i,
	input       [31:0] wb_dat_i,
	output reg  [31:0] wb_dat_o,
	//
	output           intr,
	// IO Wires
	input       [12:0] gpio_entrada,
	output reg  [6:0] gpio_salida
);

//---------------------------------------------------------------------------
//llamado módulo debouncer
wire [12:0] gpio_en_deb;
debouncer db0 (.clk(clk), .key(gpio_entrada[0]), .deb_key(gpio_en_deb[0]));
debouncer db1 (.clk(clk), .key(gpio_entrada[1]), .deb_key(gpio_en_deb[1]));
debouncer db2 (.clk(clk), .key(gpio_entrada[2]), .deb_key(gpio_en_deb[2]));
debouncer db3 (.clk(clk), .key(gpio_entrada[3]), .deb_key(gpio_en_deb[3]));
debouncer db4 (.clk(clk), .key(gpio_entrada[4]), .deb_key(gpio_en_deb[4]));
debouncer db5 (.clk(clk), .key(gpio_entrada[5]), .deb_key(gpio_en_deb[5]));
debouncer db6 (.clk(clk), .key(gpio_entrada[6]), .deb_key(gpio_en_deb[6]));
debouncer db7 (.clk(clk), .key(gpio_entrada[7]), .deb_key(gpio_en_deb[7]));
debouncer db8 (.clk(clk), .key(gpio_entrada[8]), .deb_key(gpio_en_deb[8]));
debouncer db9 (.clk(clk), .key(gpio_entrada[9]), .deb_key(gpio_en_deb[9]));
debouncer db10 (.clk(clk), .key(gpio_entrada[10]), .deb_key(gpio_en_deb[10]));
debouncer db11 (.clk(clk), .key(gpio_entrada[11]), .deb_key(gpio_en_deb[11]));
debouncer db12 (.clk(clk), .key(gpio_entrada[12]), .deb_key(gpio_en_deb[12]));

//---------------------------------------------------------------------------
// Wishbone
reg intr0=0;
assign intr = intr0;
//registros
wire [31:0] in={19'b0, gpio_en_deb};
wire [31:0] out={25'b0, gpio_salida};
wire [31:0] cs={31'b0, intr0};

reg  ack;
assign wb_ack_o = wb_stb_i & wb_cyc_i & ack;

wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i;
wire wb_wr = wb_stb_i & wb_cyc_i &  wb_we_i;

always @(posedge clk)
begin
	if (~reset) begin
		ack      <= 0;
		gpio_salida <= 'b0;
	end else begin
		// Handle WISHBONE access
		ack    <= 0;
		if (wb_rd & ~ack) begin           // read cycle
			ack <= 1;
			case (wb_adr_i[3:2])
			'h00: wb_dat_o <= in;
			'h01: wb_dat_o <= out;
			default: wb_dat_o <= 32'b0;
			endcase
		end else if (wb_wr & ~ack ) begin // write cycle
			ack <= 1;
			case (wb_adr_i[3:2])
			'h01: gpio_salida <= wb_dat_i[6:0];
			'h02: intr0 <= wb_dat_i[0];
			endcase
		end
	end
end

endmodule
