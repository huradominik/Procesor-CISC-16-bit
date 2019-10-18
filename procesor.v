 // procesor//  
 
module razem(input clock, input reset, output [7:0]acc, output [11:0]pc, output [7:0]R0, output [7:0]R1, output [7:0]R2, output [7:0]R3, output cy_flag, output zero_flag);
	
	
	
	wire [11:0]address;
	wire we;
	wire [7:0]datain;
	wire [7:0]dataout;
	
	
	
	
	s_ram ram
	(
	address,
	we,
	~clock,
	dataout,
	datain
	);
	
 	procesor procesor1
	 (
	 clock,
	 reset,
	 we,
	 i_bar,
	 datain,
	 dataout,
	 address,
	 acc,
	 pc,
	 R0,
	 R1,
	 R2,
	 R3,
	 cy_flag,
	 zero_flag
	 
	 );
 
 
 
endmodule 
 
 
module procesor(clock, reset, we, i_bar, datain, dataout, address, acc, pc, R0, R1, R2, R3, cy_flag, zero_flag);
	
	parameter DATAWIDTH  = 8;
	parameter ADRESSWIDTH  = 12;
	
	parameter SAVE = 4'b0111;
	parameter JZ = 4'b0011;	 	
	parameter JC = 4'b0100;
	parameter LOAD = 4'b0110;	 
	parameter LOADI = 8'hE3;
	parameter MVA  = 6'b100000;	 //rr
	parameter ADCI = 8'hD0;
	parameter ADCR = 6'b101100;	 //rr
	parameter MVI0 = 8'h8C;		 
	parameter MVI1 = 8'h8D;
	parameter MVI2 = 8'h8E;
	parameter MVI3 = 8'h8F;
	parameter NOTA = 8'hC2;
	parameter NOTR = 6'b100100; //rr
	parameter SBBI = 8'hD8;
	parameter ANDI = 8'hC4;
	parameter RC = 8'hDA;
	parameter SC = 8'hD2;
	parameter GET = 8'hFA;
	parameter PUT = 8'hFE;
	
	input clock;
	input reset;
	output reg we;	  //(write enable) aktywny w stanie 0
	output reg i_bar; //zapis do peryferi�w w stanie 0			       /// ciekawe czemu ma byc output reg zamiast samego output
	
	input [DATAWIDTH-1:0] datain;
	output reg [DATAWIDTH-1:0] dataout;
	output reg [ADRESSWIDTH-1:0] address;
	
	output reg [ADRESSWIDTH-1:0] pc; //licznik rozkazow
	reg [DATAWIDTH-1:0] ireg;  //rejestr instrukcji
	//reg [DATAWIDTH-1:0] dreg; //rejestr danych adresow
	output reg [DATAWIDTH-1:0] acc;  //akumlator
	// rejestry u�ytkownika //
	output reg [DATAWIDTH-1:0] R0;
	output reg [DATAWIDTH-1:0] R1;
	output reg [DATAWIDTH-1:0] R2;
	output reg [DATAWIDTH-1:0] R3;
	// rejestry robocze // 
	//reg [DATAWIDTH-1:0] R1_temp;
	
	typedef enum {FETCH, EXEC1, EXEC2, EXEC3} pr_state; 
	
//	pr_state state_r; // zmiana stanu automatu steruj�cego
	pr_state next_state; // funkcja wzbudzen automatu
	
//	reg [7:0] instr; 	 
	
	output reg zero_flag;
	output reg cy_flag;	
//////////////////////////////////////////////////////////////////////////////////////////// 
////////////////////////////////////////////////////////////////////////////////////////////
always@(posedge clock or posedge reset)
	begin
		if(reset)
			begin
				R0 <=0;
				R1 <=0;
				R2 <=0;
				R3 <=0;
				acc <=0;
				zero_flag <=0;
				cy_flag <=0;
				pc <=0;
				address <=0;
				dataout <=0;
				we <=0;
				i_bar <=0;
				//state_r <=FETCH;
				next_state <= FETCH;
			end
		else
			begin						
				case(next_state)
						FETCH:
						begin
							ireg <= datain;
							//instr <= datain;
							pc <= pc+1;
							address <= pc+1;
							i_bar <= 0;
							we <= 0;
							//dataout <=0;
				
							
							if(datain == SC || datain == RC || datain == NOTA || datain[7:2] == MVA || datain[7:2] == NOTR || datain[7:2] == ADCR)
								begin
									next_state <= FETCH;
								end
							if(datain[7:4] == JZ || datain[7:4] == JC || datain[7:4] == LOAD || datain[7:4] == SAVE || datain == MVI0 || datain == MVI1 || datain == MVI2 || datain == MVI3 || datain == ANDI || datain == ADCI || datain == SBBI || datain == LOADI || datain == GET || datain == PUT)
								begin
									next_state <= EXEC1;
								end
							
								case(datain)
									SC:
									begin
										cy_flag <= 1;
									end
									RC:
									begin
										cy_flag <= 0;
									end
									NOTA:
									begin
										acc <= ~acc;	
										zero_flag <= ~|acc;
									end	
								endcase
								
								case(datain[7:2])											 
									MVA:
									begin
										if(datain[1:0] == 2'b00)
											begin
												acc <= R0;		   
												zero_flag <= ~|R0;
											end
										else if(datain[1:0] == 2'b01)
											begin
												acc <= R1;
												zero_flag <= ~|R1;
											end
										else if (datain[1:0] == 2'b10)
											begin
												acc <= R2;
												zero_flag <= ~|R2;
											end
										else if (datain[1:0] == 2'b11)
											begin
												acc <= R3;
												zero_flag <= ~|R3;
											end
									end
									NOTR:
									begin
										if(datain[1:0] == 2'b00)
											begin
												R0 <= ~R0;
											end
										else if(datain[1:0] == 2'b01)
											begin
												R1 <= ~R1;
											end
										else if(datain[1:0] == 2'b10)
											begin
												R2 <= ~R2;
											end
										else if(datain[1:0] == 2'b11)
											begin
												R3 <= ~R3;
											end
									end
									ADCR:
									begin
										if(datain[1:0] == 2'b00)
											begin
												{cy_flag,acc} <= acc + R0 + cy_flag;			
												zero_flag <= ~|(acc + R0 + cy_flag);
											end
										else if(datain[1:0] == 2'b01)
											begin
												{cy_flag,acc} <= acc + R1 + cy_flag;		
												zero_flag <= ~|(acc + R1 + cy_flag);
											end
										else if(datain[1:0] == 2'b10)
											begin
												{cy_flag,acc} <= acc + R2 + cy_flag;	
												zero_flag <= ~|(acc + R2 + cy_flag);
											end
										else if(datain[1:0] == 2'b11)
											begin
												{cy_flag,acc} <= acc + R3 + cy_flag;
												zero_flag <= ~|(acc + R3 + cy_flag);
											end
									end
								endcase
							end
						EXEC1:
						begin
							if(ireg[7:4] == JZ || ireg[7:4] == JC || ireg == MVI0 || ireg == MVI1 || ireg == MVI2 || ireg == MVI3 || ireg == ANDI ||
								ireg == ADCI || ireg == SBBI || ireg == LOADI)
								begin
									next_state <= FETCH;
								end
							if(ireg[7:4] == LOAD || ireg[7:4] == SAVE || ireg == GET || ireg == PUT)
								begin
									next_state <= EXEC2;
								end
								
							case(ireg[7:4])
								JZ:
								begin
									if(zero_flag)
										begin
											pc[11:0] <= {ireg[3:0],datain[7:0]};
											address[11:0] <= {ireg[3:0],datain[7:0]}; 
										end
									else
										begin
											pc <= pc+1;
											address <= pc+1;
										end
								end
								JC:
								begin
									if(cy_flag)
										begin
											pc[11:0] <= {ireg[3:0],datain[7:0]};
											address[11:0] <= {ireg[3:0],datain[7:0]};
										end
									else
										begin
											pc <= pc+1;
											address <= pc+1;
										end
								end	
								SAVE:
								begin
									address <= {ireg[3:0],datain[7:0]};	 
									dataout <= acc;
									pc <= pc+1;
									we <= 1;
								end
								LOAD:
								begin
								address <= {ireg[3:0],datain[7:0]};			
								pc <= pc+1;
								end
															
							endcase
							case(ireg)
								MVI0:
								begin
									R0 <= datain;
									pc <= pc+1;
									address <= pc+1;
								end
								MVI1:
								begin
									R1 <= datain;
									pc <= pc+1;
									address <= pc+1;
								end
								MVI2:
								begin
									R2 <= datain;
									pc <= pc+1;
									address <= pc+1;
								end
								MVI3:
								begin
									R3 <= datain;
									pc <= pc+1;
									address <= pc+1;
								end
								ANDI:
								begin
									acc <= acc & datain;
									zero_flag <= ~|(acc & datain);
									pc <= pc+1;
									address <= pc+1;
								end
								ADCI:
								begin
									{cy_flag,acc} <= acc + datain + cy_flag;
									zero_flag <= ~|(acc + datain + cy_flag);
									pc <= pc+1;
									address <= pc+1;
								end
								SBBI:
								begin
									acc <= acc - datain - cy_flag;
									zero_flag <= ~|(acc - datain - cy_flag);
									pc <= pc+1;
									address <= pc+1;
								end
								LOADI:
								begin
									acc <= datain;
									pc <= pc+1;
									address <= pc+1;
								end
								PUT:
								begin
									address[7:0] <= datain;
									dataout <= acc;
									pc <= pc+1;
									i_bar <= 1;
								end
								GET:
								begin
									address[7:0] <= datain;
									pc <= pc+1;
									i_bar <= 1;
												 // czy tu trzeba sterowac i_bar ??
								end
								
							endcase		
						end
					EXEC2:
					begin
						if(ireg[7:4] == LOAD || ireg[7:4] == SAVE || ireg == GET || ireg == PUT)
							begin
								next_state <= FETCH;
							end
						case(ireg[7:4])
							LOAD:
							begin
								address <= pc;
								acc <= datain;
							end
							SAVE:
							begin
								we <= 0;
								address <= pc;		
							end
						endcase
						
						case(ireg)
							GET:
							begin
								acc <= datain;
								address <= pc;
								i_bar <= 0;
							end
							PUT:
							begin
								i_bar <=0;
								address <= pc;
							end
						endcase				
					end
				
			endcase	
			
		end
				
	end
			

	
endmodule

	
				
				
				