`timescale 1ns/1ns

module ac2_mux 
  #(parameter M = 16, // dimension of the register
    parameter Pa = 8)
  (input [$clog2(M)+Pa:0] in0, in1, in2, in3,
   input [1:0] sel_w_en,
   output reg [$clog2(M)+Pa:0] out_to_reg);
	
  
always_comb 
  begin
	if (sel_w_en == 2'b00) begin
		out_to_reg <= in0;
	end else if (sel_w_en == 2'b01) begin
		out_to_reg <= in1;
	end else if (sel_w_en == 2'b10) begin
		out_to_reg <= in2;
	end else if (sel_w_en == 2'b11) begin
		out_to_reg <= in3;
	end
end

endmodule 