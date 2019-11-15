`timescale 1ns/1ns

//4 of these registers are used for the outputs of AC3. This behaves as 
//a normal register but when the operation is done, it shifts the saved value
//of a preprogrammed quantity to apply quantization

//18/02/2019 reduced parallelism, modifications to allow shifting: added s_en signal
//21/08/2019 changed parallelism of Pw from 4 to 8

module ac3_reg
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 8,
	parameter MNO = 288)  
  (input clk, rst_n, cl_en, w_en, s_en,
   input [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] inr,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] outr);
	
always_ff @(posedge clk or negedge rst_n)
	begin 
		if (~rst_n) begin
			outr <= 0; //erease
		end else if (cl_en) begin
			outr <= 0; //erease
		end else if (w_en == 1 & cl_en==0 & s_en == 0) begin
			outr <= inr; //writing
		end else if (w_en == 0 & cl_en==0 & s_en == 1) begin
			outr <= {outr[$clog2(M)+Pa+Pw+$clog2(MNO)-1],outr[$clog2(M)+Pa+Pw+$clog2(MNO)-1:1]}; //shifting
		end
	end

endmodule 
