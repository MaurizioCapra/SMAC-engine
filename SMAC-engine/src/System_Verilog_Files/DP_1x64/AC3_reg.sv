`timescale 1ns/1ns

module ac3_reg
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 4,
	parameter MNO = 288)  //Max Number Operands: 3x3xN_filter_max/16
  (input clk, rst_n, cl_en, valid, w_en, //asynchronous reset
   input [$clog2(M)+Pa+Pw+$clog2(MNO):0] inr,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO):0] outr);
	

	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (~rst_n) begin
		outr <= 0;
	end else if (cl_en) begin
		outr <= 0;
	end else if (w_en == 1 & valid == 1) begin
		outr <= inr;
	end
end


endmodule 