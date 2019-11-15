`timescale 1ns/1ns

module ac1 //actually requires a mux to work in "continuous mode"
  #(parameter M = 16,
    parameter Pa = 8) // activation operand parallelism
  (input clk, rst_n, w_and_s, cl_en,
   input [$clog2(M):0] in_ac1,
   output [$clog2(M)+Pa-1:0] out_ac1);
	
	wire [$clog2(M):0] out_to_add;
	wire [$clog2(M):0] out_to_reg;
	
	//assign out_to_add = {{(1){1'b0}},out_ac1[$clog2(M)+Pa-1:Pa]};
	assign out_to_add = {out_ac1[$clog2(M)+Pa-1],out_ac1[$clog2(M)+Pa-1:Pa]};
	
	ac1_adder #(.M(M)) ac1_a(
	.in_from_ba(in_ac1),
	.in_from_sr(out_to_add),
	.out_to_reg(out_to_reg)
	);
	
	ac1_reg #(.M(M), .Pa(Pa)) ac1_register(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(w_and_s),
	.cl_en(cl_en),
	.inr_ac1(out_to_reg),
	.outr_ac1(out_ac1)
	);


endmodule 