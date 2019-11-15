`timescale 1ns/1ns

module neg_block
	#(parameter M=16,
	  parameter Pa=8)
	(input clk, rst_n, MSB_w, w_en, 
	 input [$clog2(M)+Pa:0] in_neg_block,
	 output reg [$clog2(M)+Pa:0] out_neg_block);

	always_ff @(posedge clk or negedge rst_n)
		begin
			if (~rst_n) begin
				out_neg_block <= 0;
			end else if (w_en == 1 & MSB_w == 0) begin
				out_neg_block <= in_neg_block;
			end else if (w_en == 1 & MSB_w == 1) begin
				out_neg_block <= ~in_neg_block + 1;
			end
		end

endmodule