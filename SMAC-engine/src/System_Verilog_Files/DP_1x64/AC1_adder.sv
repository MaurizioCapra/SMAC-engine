`timescale 1ns/1ns

module ac1_adder 
  #(parameter M = 16) // dimension of the register
  (input [$clog2(M)+1:0] in_from_ba,
   input [$clog2(M)+1:0] in_from_sr,
   output reg [$clog2(M)+1:0] out_to_reg);
	
  
always_comb 
  begin
    out_to_reg <= in_from_ba + in_from_sr;
end

endmodule 