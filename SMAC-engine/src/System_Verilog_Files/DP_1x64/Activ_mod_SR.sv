`timescale 1ns/1ns

module activ_mod_SR 
  #(parameter Pa = 8) // dimension of the register
  (input clk, rst_n, w_en, s_en, //asynchronous reset
   input [Pa-1:0] in_par, //parallel input
   output reg out_ser); //serial output
	
logic [Pa-1:0] temp_val; 
	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (~rst_n) begin
		temp_val <= 0;
		out_ser <=0;
	end else if (w_en==1 && s_en==0) begin
		temp_val <= in_par;
	end else if (w_en==1 && s_en==1) begin
		out_ser <= temp_val[0];
		temp_val <= {temp_val[0],temp_val[Pa-1:1]};
	end
end


endmodule 