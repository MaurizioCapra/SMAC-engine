`timescale 1ns/1ns

//This register samples the output of the Bit_Adder

//18/02/2019 reduced parallelism and removed useless stuff

module bit_register 
  #(parameter M = 16) // dimension of the register
  (input clk, rst_n, w_en, cl_en, //asynchronous reset
   input [$clog2(M):0] inr,
   output reg [$clog2(M):0] outr);
	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (!rst_n) begin
		outr <= 0;
	end else if (cl_en) begin
		outr <= 0;
	end else if	(w_en) begin
		outr <= inr;
	end	
end


endmodule 