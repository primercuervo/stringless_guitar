module lcd(	
	input clk,
	input sig,
	input rsin,
	//input reset,
	input [7:0] data_out1, //de c, para  inicializar
	input donec,
	input start,
	output donep,
    	output [3:0] output_lcd,
    	output reg en_lcd,
	output rw_lcd,
	output rs_lcd,
	output busylcd,
	output reg donelcd
    );
	wire clk_lcd;
	clkg clk_lcd0 (clk, 100000, clk_lcd);    //250000              ///////// cambiar factor, frecuencia admitida lcd
	wire modo_lcd = 0;
	reg modo_change = 0;
	reg [255:0] mensaje = 0;
	reg [2:0] cont1 = 0;
	reg [7:0] cont = 8'd255;
	wire [7:0] data_out;
	reg [7:0] data_out2=0; //del periférico, para escribir los caracteres
	wire next_char;
	reg busylcd0=0;
	reg donep0 = 1;
	wire done;
	reg [3:0] output_lcd0 = 0;

	assign donep = donep0;
	assign output_lcd = output_lcd0;
	assign busylcd = busylcd0;

	assign next_char=sig&(~busylcd0);

	assign data_out = sig ? data_out2 : data_out1 ;
	assign rs_lcd = sig ? 1 : 0;
	assign done = sig ? donep : donec;
	assign rw_lcd = 0;

	always @ (modo_lcd) begin
		modo_change <= ~ modo_change;
		case (modo_lcd)
			0: mensaje = "mensaje modo 0 mensaje modo 0 AB";
		endcase	
		//donelcd <= 1;	
		donelcd <= 0;
	end

	always @ (posedge next_char) begin
		if (sig==1) begin
			
		if(cont>=7) begin
			data_out2[7] <= mensaje[cont];
			data_out2[6] <= mensaje[cont-1];
			data_out2[5] <= mensaje[cont-2];
			data_out2[4] <= mensaje[cont-3];
			data_out2[3] <= mensaje[cont-4];
			data_out2[2] <= mensaje[cont-5];
			data_out2[1] <= mensaje[cont-6];
			data_out2[0] <= mensaje[cont-7];
			if (cont>7)
				cont <= cont - 8;
			else
				cont <= 0;			
		end
		else begin
			data_out2 <= 0;
			cont <= 0;
			donelcd <= 0;
		end
		end
	end

	always @ (posedge clk_lcd) begin
		if (start) begin
		case (cont1)
			0: begin 
				donep0 = 1;
				//if (donec) begin
				busylcd0 = 1;
				//rs_lcd <= rsin;
				output_lcd0 <= data_out[7:4];
				cont1 = cont1 + 1;
				//end
			   end
			1:begin
				en_lcd <= 1;
				cont1 = cont1+ 1;
			  end
			2:begin
				en_lcd <= 0;
				cont1 = cont1+ 1;
			  end
			3: begin 
				//rs_lcd <= rsin;
				output_lcd0 <= data_out[3:0];
				cont1 = cont1 + 1;
			   end
			4:begin
				en_lcd <= 1;
				cont1 = cont1+ 1;
			  end
			5:begin
				en_lcd <= 0;
				if (cont!=0) begin
					cont1 = 0;
				end
				busylcd0 = 0;
				donep0 = 0;
			  end
		endcase	
		end
	end
endmodule	



//---------------------------------------------------------------------------
// Wishbone LCD 
// Register Description:
//    0x00 MENSAJE	    [ mens]       (WO)		
//    0x04 DATA_OUT 	[24'b0, data_out]   (RW)	
//    0X08 CTRL STA CS	[31'b0, sig] 
//---------------------------------------------------------------------------

module wb_lcd  (
	input              clk,
	input		   reset,
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
	output [5:0] bus_salida
);

//---------------------------------------------------------------------------
//instanciación del módulo 
reg sig;
reg rsin;
reg [7:0] data_out1;
reg donec;
reg start;
wire donep;
wire [3:0] output_lcd;
wire en_lcd;
wire rs_lcd;
wire busylcd;
wire donelcd;

lcd lcd0 (
	.clk(clk),
	.sig(sig),
	.rsin(rsin),
	.data_out1(data_out1),
	.donec(donec),
	.start(start),
	.donep(donep),
	.output_lcd(output_lcd),
	.en_lcd(en_lcd),
	.rw_lcd(rw_lcd),
	.rs_lcd(rs_lcd),
	.busylcd(busylcd),
	.donelcd(donelcd)
);

assign bus_salida = {en_lcd, rs_lcd, rw_lcd, output_lcd};
//en 24 - dig 22 - 33
//rs 22 - dig 20 - 35
//d3 20 - dig 18 - 40
//d2 18 - dig 16 - 47
//d1 16 - dig 14 - 49
//d0 14 - dig 1  - 54

//---------------------------------------------------------------------------
//declaracion registros
wire [31:0] data_out = {24'b0,data_out1};
wire [31:0] cs = { 26'b0, start, donelcd, busylcd,donec, rsin, sig}; //donelcd=0 para iniciar envío de comandos
wire [31:0] donepwb = {31'b0, donep};


wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i; // lectura (lo que se lee del periférico)
wire wb_wr = wb_stb_i & wb_cyc_i &  wb_we_i; // ciclo escritura (lo que se escribe en el periferico)

reg  ack;
assign wb_ack_o       = wb_stb_i & wb_cyc_i & ack; //terminación del ciclo, salida del esclavo

always @(posedge clk)
begin
	if (~reset) begin
		wb_dat_o[31:0] <= 32'b0;
		ack    <= 0;
	end else begin
		wb_dat_o[31:0] <= 32'b0;
		ack    <= 0;

		if (wb_rd & ~ack) begin //ciclo de lectura
			ack <= 1;

			case (wb_adr_i[3:2])    
			'h00: wb_dat_o[7:0] <= data_out; 
			'h01: begin				
				wb_dat_o[2] <= cs[3];	//lee busylcd	
				wb_dat_o[3] <= cs[4];	//lee donelcd
			      end
			'h02: wb_dat_o[7:0] <= donepwb [0]; 
			default: wb_dat_o <= 32'b0;
			endcase
		end else if (wb_wr & ~ack ) begin  //ciclo de escritura
			ack <= 1;

			case (wb_adr_i[3:2])
			'h00: data_out1 <= wb_dat_i;	
			'h01: begin 
				sig <= wb_dat_i[0];
				rsin <= wb_dat_i[1];
				donec <= wb_dat_i[2];
				start <= wb_dat_i[5];
			      end
			endcase
		end
	end
end

endmodule
