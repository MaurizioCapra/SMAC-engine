`timescale 1ns/1ns

module bit_register 
  #(parameter M = 16) // dimension of the register
  (input clk, rst_n, w_en, //asynchronous reset
   input [$clog2(M)+1:0] inr,
   output reg [$clog2(M)+1:0] outr);
	

	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (!rst_n) begin
		outr <= 0;
	end else if (w_en) begin
		outr <= inr;
	end
end


endmodule 