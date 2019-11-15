`timescale 1ns/1ns

module input_register 
  #(parameter RP = 16) // dimension of the register
  (input clk, rst_n, w_en, //asynchronous reset
   input [RP-1:0] inr,
   output reg [RP-1:0] outr);
	
reg [RP-1:0] temp;
	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (!rst_n) begin
		temp <= 0;
		outr <= 0;
	end else if (w_en) begin
		temp <= inr;
		outr <= inr;
	end else begin
		outr <= temp;
	end	
end


endmodule 