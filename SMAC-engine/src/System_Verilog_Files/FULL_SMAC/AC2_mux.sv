`timescale 1ns/1ns

//This mux takes as input one of the outputs of the four shift registers
//and sends it to the AC2_adder

//18/02/2019 changed some signal names to make them clearer

module ac2_mux 
  #(parameter M = 16, // dimension of the register
    parameter Pa = 8)
  (input [$clog2(M)+Pa:0] in0, in1, in2, in3,
   input [1:0] sel_w_en,
   output reg [$clog2(M)+Pa:0] out_to_add);
	
always_comb 
  begin
	if (sel_w_en == 2'b00) begin
		out_to_add <= in0;
	end else if (sel_w_en == 2'b01) begin
		out_to_add <= in1;
	end else if (sel_w_en == 2'b10) begin
		out_to_add <= in2;
	end else if (sel_w_en == 2'b11) begin
		out_to_add <= in3;
	end
end

endmodule 