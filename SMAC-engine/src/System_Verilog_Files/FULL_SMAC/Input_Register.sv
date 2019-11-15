`timescale 1ns/1ns

//Input_Register is a simple register which size can be varied with M, 
//used at the interface of the DP and for the SMAC boundaries

//18/02/2019 removed useless stuff, addeed synchronous clear

module input_register 
  #(parameter M = 16) // dimension of the register
  (input clk, rst_n, w_en, cl_en, //asynchronous reset
   input [M-1:0] inr,
   output reg [M-1:0] outr);
	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (!rst_n) begin
		outr <= 0;
	end else if (cl_en) begin
		outr <= 0;
	end else if (w_en) begin
		outr <= inr;
	end	
end


endmodule 