module clkg(
	input clk,
	input [14:0] factor,
	output clkp		
	);
	reg clkpr=1'b0;
	reg [14:0] cont=15'b0;
	always @ (posedge clk) begin
		if(cont==factor) begin
			cont<=1;
			clkpr=~clkpr;
		end
		else cont<=cont+1;
	end
	assign clkp=clkpr;
endmodule

module seleccion (
	input clk,  //frecuencia de muestreo
	input tecla,
	input start,
	output [13:0] cont,
	output reg en,
	output busyf
	);
	reg [13:0] cont0 = 14'b0;
	reg busy1 = 1'b0;
	reg busy2 = 1'b0;
	wire busyr;
	assign busyr = busy1 ^ busy2;
	always @ (posedge clk) begin
		if (start) begin
			if (busyr == 1'b0) begin
				en <= tecla;
				if (en)	busy1 <= ~busy1;
			end
			else begin
				if (cont0<14'd15625)     //1s
					cont0<=cont+1;
				else begin
					cont0<=14'b0;
					busy2<=~busy2;
				end
			end
		end
	end
	assign cont = cont0;
	assign busyf = busyr;
endmodule

module oscilador(
	input en,
	input clk,  //fmuestreo=15625Hz, T=64us
	input [5:0] nmuestras,
	input [8:0] factor,
        output [5:0] amp1,
	output reg done_osc	
    	);
	 //resolución de 6 bits 0-63
	 //nmuestras=fmuestreo/frec;
	 //para do, m=64/60=1.06 , se toma 106, fac*nmuestras/128=64, fac=136
	 reg [5:0] amp;
	 reg [5:0] cont=0;
	 always @ (posedge clk) begin
		if (en==1) begin
			amp<=factor*cont/128;   //se calcula la amplitud para cada muestra
			cont<=cont+1;
			done_osc <= 1;
			if (cont==nmuestras)
				cont<=0;
		end
		else begin
			amp<=0;
			done_osc <= 0;
		end
	 end
	 assign amp1=amp;
endmodule

module attack (
	input [13:0] tiempo, //hasta 15625
	input en,
	output reg [5:0] amp_env
	);
	
	always @ (tiempo,en) begin
		if (en)
			amp_env <= (tiempo*5)/256;
		else
			amp_env <= 6'b0;
	end
endmodule

module decay(
	input [13:0] tiempo, 
	input en,
	output reg [5:0] amp_env
	);
	
	always @ (tiempo,en) begin
		if (en)
			amp_env <= 78 - (5*tiempo)/1024;
		else
			amp_env <= 6'b0;
	end
endmodule

module sustain(
	input en,
	output reg [5:0] amp_env
	);
	
	always @ (en) begin
		if (en)
			amp_env <= 6'd32;
		else
			amp_env <= 6'b0;
	end
endmodule

module releasee(
	input [13:0] tiempo,
	input en,
	output reg [5:0] amp_env
	);
	
	always @ (tiempo,en) begin
		if (en)
			amp_env <= 153 - (10*tiempo)/1024;
		else
			amp_env <= 6'b0;
	end
endmodule

module control_envolvente(
	input [13:0] tiempo,
	input start,
	input clk,
	input reset,
	output reg done,
	output reg en_a,
	output reg en_d,
	output reg en_s,
	output reg en_r
	);
	parameter S0 = 3'h0;
	parameter S1 = 3'h1;
	parameter S2 = 3'h2;
	parameter S3 = 3'h3;
	parameter S4 = 3'h4;
	reg [2:0] state = S0;
	reg [2:0] nextstate = S0;

	always @ (posedge clk) begin
		if (reset) state <= S0;
		else state <= nextstate;
	end
	always @ (*) begin
		case (state)
			S0: if (start) nextstate <= S1;
			    else nextstate <= S0;
			S1: if (tiempo <= 14'd3125) nextstate <= S1;
			    else nextstate <= S2;
			S2: if (tiempo <= 14'd9375) nextstate <= S2;
			    else nextstate <= S3;
			S3: if (tiempo <= 14'd12500) nextstate <= S3;
			    else nextstate <= S4;
			S4: if (tiempo <= 14'd15625) nextstate <= S4;
			    else nextstate <= S0;
		endcase
	end
	always @ (*) begin
		case (state)
			S0: begin
				en_a <= 1'b0;
				en_d <= 1'b0;
				en_s <= 1'b0;
				en_r <= 1'b0;
				done <= 1'b0;
			end
			S1: begin
				en_a <= 1'b1;
				en_d <= 1'b0;
				en_s <= 1'b0;
				en_r <= 1'b0;
				done <= 1'b1;
			end
			S2: begin
				en_a <= 1'b0;
				en_d <= 1'b1;
				en_s <= 1'b0;
				en_r <= 1'b0;
				done <= 1'b1;
			end
			S3: begin
				en_a <= 1'b0;
				en_d <= 1'b0;
				en_s <= 1'b1;
				en_r <= 1'b0;
				done <= 1'b1;
			end
			S4: begin
				en_a <= 1'b0;
				en_d <= 1'b0;
				en_s <= 1'b0;
				en_r <= 1'b1;
				done <= 1'b1;
			end
		endcase
	end
endmodule

module envolvente(
	input [13:0] tiempo,
	input clk,
	input start,
	input reset,
	input [5:0] amp,  //amplitud de la onda
	output done,				
	output [5:0] amp_res //amplitud de la onda después de la envolvente  
	);
	wire en_a, en_d, en_s, en_r;
	wire [5:0] amp_a, amp_d, amp_s, amp_r;
	control_envolvente control_env0 (tiempo,start,clk,reset,done,en_a,en_d,en_s,en_r);
	attack attack0 (tiempo,en_a,amp_a);
	decay decay0 (tiempo,en_d,amp_d);
	sustain sustain0 (en_s,amp_s);
	releasee releasee0 (tiempo,en_r,amp_r); 
	assign amp_res = ((amp_a + amp_d + amp_s + amp_r)*amp)/64;
endmodule

module suma_amp(
	input clk,
	input start,   //habilitador de la división
	input [9:0] a,  //max valor 756
	input [11:0] en, //b max divisor 12 teclas
	output done,
	output reg [5:0] result //max es 63 
	);
	reg [5:0] rp = 6'b0; //resultado parcial
	reg [9:0] c,d;
	reg load = 1'b1;
	reg done1 = 1'b1;
	reg loaden;
	wire [3:0] b,num_teclas;
	
	assign num_teclas = en[0]+en[1]+en[2]+en[3]+en[4]+en[5]+en[5]+en[6]+en[7]+en[8]+en[9]+en[10]+en[11];
	assign b = num_teclas;

	always @ (posedge clk) begin
		loaden <= load & start;	
		if(loaden) begin
			//if (a!=0) begin
			c<=a;
			d<=a;
			load<=1'b0;
			rp<=1'b0;
			//end
		end
		else 	if (c>=b) begin
				c<=c-b;
				rp<=rp+1;
				done1<=0;			
			end
			else begin
				done1<=1;
				result<=rp;
				if (a!=d)
				load<=1;
			end
	end
	assign done = done1;
endmodule


module pwm(
    input [5:0] sint_data,
    input en,
    input clk,
    output pulse_data,
    output busy_pwm
    );
	 reg pulse_reg;
	 reg [5:0] cont=6'd63;	
	 reg [5:0] pwm_in=0;
	 always @ (posedge clk) begin
		if	(cont==6'd63) begin
			pwm_in<=sint_data;
			cont=0;
		end
		else cont=cont+1;
		if (cont<sint_data)
			pulse_reg=1;
		else pulse_reg=0;
	 end
	 assign pulse_data=pulse_reg;
	assign busy_pwm = en;
endmodule

module sintesis(
    input sel, //botón de escape
    input [11:0] teclas,
    input clk,
    input start,
    output pulse_data,
    output busy_pwm
    );
	wire clk_fm; //con la frecuencia de muestreo
	clkg clk_fm0 (clk,1600,clk_fm); //frecuencia de muestreo de 15625Hz, factor=1600
	wire clk_1u; //con la perido de 1us para la modulación
	clkg clk_1u0 (clk,25,clk_1u); //factor=25
	wire [11:0] en_osc;
	wire [11:0] done_osc;
	wire [11:0] start_env;
	wire [11:0] busyf;
	wire [11:0] done_env;
	wire reset; 		//----
	assign reset=sel; //reset!
	wire [5:0] amp_final;
	wire [5:0] amp0,amp1,amp2,amp3,amp4,amp5,amp6,amp7,amp8,amp9,amp10,amp11;
	wire [5:0] aenv0,aenv1,aenv2,aenv3,aenv4,aenv5,aenv6,aenv7,aenv8,aenv9,aenv10,aenv11;
	wire [13:0] tiempo0,tiempo1,tiempo2,tiempo3,tiempo4,tiempo5,tiempo6,tiempo7,tiempo8,tiempo9,tiempo10,tiempo11;
	wire [9:0] amp_env_total;
	wire done_suma, start_suma;
	assign start_env = done_osc;
	//selección de cada tecla
	seleccion s0 (clk_fm, teclas[0], start, tiempo0, en_osc[0], busyf[0]);
	seleccion s1 (clk_fm, teclas[1], start, tiempo1, en_osc[1], busyf[1]);	
	seleccion s2 (clk_fm, teclas[2], start, tiempo2, en_osc[2], busyf[2]);
	seleccion s3 (clk_fm, teclas[3], start, tiempo3, en_osc[3], busyf[3]);
	seleccion s4 (clk_fm, teclas[4], start, tiempo4, en_osc[4], busyf[4]);
	seleccion s5 (clk_fm, teclas[5], start, tiempo5, en_osc[5], busyf[5]);
	seleccion s6 (clk_fm, teclas[6], start, tiempo6, en_osc[6], busyf[6]);
	seleccion s7 (clk_fm, teclas[7], start, tiempo7, en_osc[7], busyf[7]);
	seleccion s8 (clk_fm, teclas[8], start, tiempo8, en_osc[8], busyf[8]);
	seleccion s9 (clk_fm, teclas[9], start, tiempo9, en_osc[9], busyf[9]);
	seleccion s10 (clk_fm, teclas[10], start, tiempo10, en_osc[10], busyf[10]);
	seleccion s11 (clk_fm, teclas[11], start, tiempo11, en_osc[11], busyf[11]);	
	//osciladores 0 a 11
	oscilador o0 (en_osc[0],clk_fm, 59, 138, amp0,done_osc[0]);
	oscilador o1 (en_osc[1],clk_fm, 55, 148, amp1,done_osc[1]);
	oscilador o2 (en_osc[2],clk_fm, 52, 157, amp2,done_osc[2]);
	oscilador o3 (en_osc[3],clk_fm, 49, 167, amp3,done_osc[3]);
	oscilador o4 (en_osc[4],clk_fm, 46, 178, amp4,done_osc[4]);
	oscilador o5 (en_osc[5],clk_fm, 44, 186, amp5,done_osc[5]);
	oscilador o6 (en_osc[6],clk_fm, 41, 199, amp6,done_osc[6]);
	oscilador o7 (en_osc[7],clk_fm, 39, 210, amp7,done_osc[7]); 
	oscilador o8 (en_osc[8],clk_fm, 37, 221, amp8,done_osc[8]);
	oscilador o9 (en_osc[9],clk_fm, 35, 234, amp9,done_osc[9]);  
	oscilador o10 (en_osc[10],clk_fm, 33, 248, amp10,done_osc[10]); 
	oscilador o11 (en_osc[11],clk_fm, 31, 264, amp11,done_osc[11]);
	//envolvente para cada tecla
	envolvente env0 (tiempo0,clk_fm,start_env[0],reset,amp0,done_env[0],aenv0);
	envolvente env1 (tiempo1,clk_fm,start_env[1],reset,amp1,done_env[1],aenv1);
	envolvente env2 (tiempo2,clk_fm,start_env[2],reset,amp0,done_env[2],aenv2);
	envolvente env3 (tiempo3,clk_fm,start_env[3],reset,amp3,done_env[3],aenv3);
	envolvente env4 (tiempo4,clk_fm,start_env[4],reset,amp4,done_env[4],aenv4);
	envolvente env5 (tiempo5,clk_fm,start_env[5],reset,amp5,done_env[5],aenv5);
	envolvente env6 (tiempo6,clk_fm,start_env[6],reset,amp6,done_env[6],aenv6);
	envolvente env7 (tiempo7,clk_fm,start_env[7],reset,amp7,done_env[7],aenv7);
	envolvente env8 (tiempo8,clk_fm,start_env[8],reset,amp8,done_env[8],aenv8);
	envolvente env9 (tiempo9,clk_fm,start_env[9],reset,amp9,done_env[9],aenv9);
	envolvente env10 (tiempo10,clk_fm,start_env[10],reset,amp10,done_env[10],aenv10);
	envolvente env11 (tiempo11,clk_fm,start_env[11],reset,amp11,done_env[11],aenv11);
	assign amp_env_total = aenv0+aenv1+aenv2+aenv3+aenv4+aenv5+aenv6+aenv7+aenv8+aenv9+aenv10+aenv11; 	

	//sumatoria de amplitudes
	assign start_suma = | done_env;        //revisar.............
	suma_amp suma1 (clk,start_suma,amp_env_total,en_osc,done_suma,amp_final);

	//modulación PWM
	pwm pwm0 (amp_final,done_suma,clk_1u,pulse_data,busy_pwm);

endmodule

//---------------------------------------------------------------------------
// Wishbone Sintesis 
//
// Register Description:
//
//    0x00 DATA	    [ 0 | 0 | pulse_data | sel | teclas(11:0) ]       (RO)		//16bits
//    0x02 CTRL/STAT cs [0 | 0 | 0 | 0 | 0 | 0 | busy_pwm | start]   (RW)		//8bits

//(antes un registro de entrada y uno de salida) //0x02 DATA_OUT[0 | 0 | 0 | 0 | 0 | 0 | 0 | pulse_data ] (WO)	//8bits
//
//---------------------------------------------------------------------------

module wb_sintesis  (
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
	input 	    [12:0] teclado,
	output		pulse_data
);

//---------------------------------------------------------------------------
//instanciación del módulo síntesis
wire sel;
wire [11:0] teclas;
//wire pulse_data;
wire busy_pwm;
reg start;

sintesis sint0 (
	.sel(sel),
	.teclas(teclas),
	.clk(clk),
	.start(start), // señal desde gpio
	.pulse_data(pulse_data),
	.busy_pwm(busy_busy)
);
assign teclas = teclado[11:0];
assign sel = teclado[12];

//---------------------------------------------------------------------------
//declaracion registros
wire [31:0] teclasw = {20'b0, teclas};
wire [31:0] data = { 30'b0, pulse_data, sel};
wire [31:0] cs = { 30'b0, busy_pwm, start};


wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i; //stb un ciclo de transferencia de datos válido, cyc ciclo en proceso, lectura (lo que se lee del periférico)
wire wb_wr = wb_stb_i & wb_cyc_i &  wb_we_i; // & wb_sel_i[0]; //ciclo escritura (lo que se escribe en el periferico)

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

			case (wb_adr_i[3:0])  //wb_adr_i[1:0] no se utilizan, solo de 3:2 porque son 2 registros
			'h00: wb_dat_o <= 32'b0;   //señal de busy
			'h04: wb_dat_o[0] <= data[1];  //pulso modulado 
			'h08: wb_dat_o[0] <= cs[1];		
			default: wb_dat_o <= 32'b0;
			endcase
		end else if (wb_wr & ~ack ) begin  //ciclo de escritura
			ack <= 1;

			case (wb_adr_i[3:2])
			//'h00: teclas <= wb_dat_i[11:0];
			//'h01: sel <= wb_dat_i[0];	
			'h02: start <= wb_dat_i[0];
			endcase
		end
	end
end

endmodule


//... registros de 32 bits
