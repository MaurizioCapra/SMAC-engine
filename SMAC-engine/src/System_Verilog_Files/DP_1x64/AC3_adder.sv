`timescale 1ns/1ns

module ac3_adder 
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 4,
	parameter MNO = 288)    //Max Number Operands: 3x3xN_filter_max/16
  (input [$clog2(M)+Pa+Pw+$clog2(MNO):0] in_from_ac2, //log2M+1+Pa
   input [$clog2(M)+Pa+Pw+$clog2(MNO):0] in_from_reg,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO):0] out_to_reg); //oversized parallelism, no overflow should occurr
	
  
always_comb 
	begin
		out_to_reg <= in_from_ac2 + in_from_reg;
	end

endmodule 