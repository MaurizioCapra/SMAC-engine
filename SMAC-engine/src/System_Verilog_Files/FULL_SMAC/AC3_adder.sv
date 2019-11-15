`timescale 1ns/1ns

//AC3 is the accumulator containing one adder, two 4x1 mux and 4 shift registers. These
//shift registers are used differently from the ones in the previous accumulators
//here they are used when the operation is done to serially shift of a certain number
//to apply quantization

//18/02/2019 reduced parallelism on output
//21/08/2019 changed parallelism of Pw from 4 to 8

module ac3_adder 
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 8,
	parameter MNO = 288)    //Max Number Operands: 3x3xN_filter_max/16
  (input [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] in_from_ac2, //log2M+1+Pa
   input [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] in_from_reg,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] out_to_reg); 
   
always_comb 
	begin
		out_to_reg <= in_from_ac2 + in_from_reg;
	end

endmodule 
