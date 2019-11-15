`timescale 1ns/1ns

module ac2 
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4) // activation operand parallelism
  (input clk, rst_n, valid, s_en, cl_en,
   input [1:0] w_en, // used to select among the 4 different shift registers
   input [$clog2(M)+Pa:0] in_ac2,
   output reg [$clog2(M)+Pa+Pw:0] out_ac2_0, out_ac2_1, out_ac2_2, out_ac2_3);
	
	wire [$clog2(M)+Pa:0] out_to_reg;
	wire [$clog2(M)+Pa:0] out_to_add, out_to_add0, out_to_add1, out_to_add2, out_to_add3;
	logic we_r0, we_r1, we_r2, we_r3;
	
	assign out_to_add0 = out_ac2_0[$clog2(M)+Pa+Pw:Pw];
	assign out_to_add1 = out_ac2_1[$clog2(M)+Pa+Pw:Pw];
	assign out_to_add2 = out_ac2_2[$clog2(M)+Pa+Pw:Pw];
	assign out_to_add3 = out_ac2_3[$clog2(M)+Pa+Pw:Pw]; //{out_ac2_3[$clog2(M)+Pa+Pw],out_ac2_3[$clog2(M)+Pa+Pw:Pw+1];
	assign we_r0 = (~w_en[1]) && (~w_en[0]);
	assign we_r1 = (~w_en[1]) && (w_en[0]);
	assign we_r2 = (w_en[1]) && (~w_en[0]);
	assign we_r3 = (w_en[1]) && (w_en[0]);
	
	ac2_adder #(.M(M), .Pa(Pa)) ac2_a(
	.in_from_neg(in_ac2),
	.in_from_sr(out_to_add),
	.out_to_reg(out_to_reg)
	);
	
	ac2_mux #(.M(M), .Pa(Pa)) ac2_multiplexer(
	.in0(out_to_add0),
	.in1(out_to_add1),
	.in2(out_to_add2),
	.in3(out_to_add3),
	.sel_w_en(w_en),
	.out_to_reg(out_to_add)
	);
	
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register0(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r0),
	.s_en(s_en),
	.cl_en(cl_en),
	.valid(valid),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_0)
	);

	
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register1(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r1),
	.s_en(s_en),
	.cl_en(cl_en),
	.valid(valid),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_1)
	);

	
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register2(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r2),
	.s_en(s_en),
	.cl_en(cl_en),
	.valid(valid),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_2)
	);

	
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register3(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r3),
	.s_en(s_en),
	.cl_en(cl_en),
	.valid(valid),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_3)
	);


endmodule 