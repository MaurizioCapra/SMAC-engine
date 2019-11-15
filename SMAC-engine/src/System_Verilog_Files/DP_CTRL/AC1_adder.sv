`timescale 1ns/1ns

//This is the adder used for the first accumulator

//18/02/2019 reduced parallelism 

module ac1_adder 
  #(parameter M = 16) 
  (input [$clog2(M):0] in_from_ba,
   input [$clog2(M):0] in_from_sr,
   output reg [$clog2(M):0] out_to_reg); //no overflow because +1 bit has already been considered
  
always_comb 
  begin
    out_to_reg <= in_from_ba + in_from_sr;
end

endmodule 