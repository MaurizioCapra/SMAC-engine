`timescale 1ns/1ns

module ac2_adder 
  #(parameter M = 16,
	parameter Pa = 8)    
  (input [$clog2(M)+Pa:0] in_from_neg, //log2M+1+Pa
   input [$clog2(M)+Pa:0] in_from_sr,
   output reg [$clog2(M)+Pa:0] out_to_reg);
	
  
always_comb 
	begin
		out_to_reg <= in_from_neg + in_from_sr;
	end

endmodule 