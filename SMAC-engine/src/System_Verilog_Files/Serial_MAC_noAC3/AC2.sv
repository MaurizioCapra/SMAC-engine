`timescale 1ns/1ns

module ac2 
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4) // activation operand parallelism
  (input clk, rst_n, valid, cl_en,
   input [$clog2(M)+Pa:0] in_ac2,
   output [$clog2(M)+Pa+Pw-1:0] out_ac2_0);
	
	wire [$clog2(M)+Pa:0] out_to_reg;
	wire [$clog2(M)+Pa:0] out_to_add;
	
	
	//assign out_to_add = {{(1){1'b0}},out_ac2_0[$clog2(M)+Pa+Pw-1:Pw]};
	assign out_to_add = {out_ac2_0[$clog2(M)+Pa+Pw-1],out_ac2_0[$clog2(M)+Pa+Pw-1:Pw]};
	
	
	ac2_adder #(.M(M), .Pa(Pa)) ac2_a(
	.in_from_neg(in_ac2),
	.in_from_sr(out_to_add),
	.out_to_reg(out_to_reg)
	);
	
	
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(valid),
	.cl_en(cl_en),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_0)
	);

	


endmodule 