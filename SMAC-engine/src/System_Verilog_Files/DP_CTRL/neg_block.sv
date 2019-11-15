`timescale 1ns/1ns

//This register is placed after the first accumulator AC1, it works as a 
//normal register, but when the weight MSB is computed, the value coming out of
//the AC1 accumulator will be inverted. This is controlled with the signal MSB_w

//18/02/2019 reduced input parallelism, small adjustments to the process

module neg_block
	#(parameter M=16,
	  parameter Pa=8)
	(input clk, rst_n, MSB_w, w_en, cl_en,
	 input [$clog2(M)+Pa-1:0] in_neg_block,
	 output reg [$clog2(M)+Pa:0] out_neg_block);
 
always_ff @(posedge clk or negedge rst_n)
	begin
		if (~rst_n) begin
			out_neg_block <= 0;
		end else if (cl_en) begin
			out_neg_block <= 0;
		end else if (w_en == 1 & MSB_w == 0) begin
			out_neg_block <= {in_neg_block[$clog2(M)+Pa-1],in_neg_block};
		end else if (w_en == 1 & MSB_w == 1) begin
			out_neg_block <= -{in_neg_block[$clog2(M)+Pa-1],in_neg_block};
		end
	end

endmodule