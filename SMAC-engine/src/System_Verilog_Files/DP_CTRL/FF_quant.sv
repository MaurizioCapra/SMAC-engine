`timescale 1ns/1ns

//this module detects when done_quant is asserted and keeps the value at the output high
//until a clear signal that tells the write back is finished arrives

//20/02/2019 a new block to aid FSM

module quant_ff	
   (input clk, rst_n, done_quant, clear,
    output reg data_out);
  
always_ff @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) begin
		data_out <= 0;
	end else if (clear) begin
		data_out <= 0;
	end else if (done_quant) begin
		data_out <= 1;
	end
end


endmodule 