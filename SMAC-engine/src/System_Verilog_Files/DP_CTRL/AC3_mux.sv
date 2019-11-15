`timescale 1ns/1ns

//two of these 4x1 will be used in the AC3 block, one taking the inputs coming from AC2 
//the other taking the outputs from the output registers of AC3

//18/02/2019 reduced parallelism

module ac3_mux 
  #(parameter M = 16, // dimension of the register
    parameter Pa = 8,
	parameter Pw = 4,
	parameter MNO = 288)
  (input [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] in0, in1, in2, in3,
   input [1:0] sel_w_en,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] out_mux);
  
always_comb 
  begin
	if (sel_w_en == 2'b00) begin
		out_mux <= in0;
	end else if (sel_w_en == 2'b01) begin
		out_mux <= in1;
	end else if (sel_w_en == 2'b10) begin
		out_mux <= in2;
	end else if (sel_w_en == 2'b11) begin
		out_mux <= in3;
	end
end

endmodule 