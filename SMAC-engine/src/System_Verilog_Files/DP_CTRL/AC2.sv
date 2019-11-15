`timescale 1ns/1ns

//AC2 is the accumulator containing one adder, one 4x1 mux and 4 shift registers

//18/02/2019 reduced parallelism on output, changed some stuff and made some order

module ac2 
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4) 
  (input clk, rst_n, valid, cl_en,
   input [1:0] w_en, // used to select among the 4 different shift registers
   input [$clog2(M)+Pa:0] in_ac2,
   output reg [$clog2(M)+Pa+Pw-1:0] out_ac2_0, out_ac2_1, out_ac2_2, out_ac2_3);
	
	wire [$clog2(M)+Pa:0] out_to_reg;
	wire [$clog2(M)+Pa:0] out_to_add, out_to_mux0, out_to_mux1, out_to_mux2, out_to_mux3;
	logic we_r0, we_r1, we_r2, we_r3;
	logic ce_r0, ce_r1, ce_r2, ce_r3;
	
	//get the signals to send to the mux
	assign out_to_mux0 = {out_ac2_0[$clog2(M)+Pa+Pw-1],out_ac2_0[$clog2(M)+Pa+Pw-1:Pw]};
	assign out_to_mux1 = {out_ac2_1[$clog2(M)+Pa+Pw-1],out_ac2_1[$clog2(M)+Pa+Pw-1:Pw]};
	assign out_to_mux2 = {out_ac2_2[$clog2(M)+Pa+Pw-1],out_ac2_2[$clog2(M)+Pa+Pw-1:Pw]};
	assign out_to_mux3 = {out_ac2_3[$clog2(M)+Pa+Pw-1],out_ac2_3[$clog2(M)+Pa+Pw-1:Pw]};

	//gerenate the write enables for the registers	
	assign we_r0 = (~w_en[1]) & (~w_en[0]) & (valid);
	assign we_r1 = (~w_en[1]) & (w_en[0]) & (valid);
	assign we_r2 = (w_en[1]) & (~w_en[0]) & (valid);
	assign we_r3 = (w_en[1]) & (w_en[0]) & (valid);
	
	//gerenate the clean enables for the registers	
	assign ce_r0 = (~w_en[1]) & (~w_en[0]) & (cl_en);
	assign ce_r1 = (~w_en[1]) & (w_en[0]) & (cl_en);
	assign ce_r2 = (w_en[1]) & (~w_en[0]) & (cl_en);
	assign ce_r3 = (w_en[1]) & (w_en[0]) & (cl_en);
	
	//adder
	ac2_adder #(.M(M), .Pa(Pa)) ac2_a(
	.in_from_neg(in_ac2),
	.in_from_sr(out_to_add),
	.out_to_reg(out_to_reg)
	);
	
	//mux 4x1
	ac2_mux #(.M(M), .Pa(Pa)) ac2_multiplexer(
	.in0(out_to_mux0),
	.in1(out_to_mux1),
	.in2(out_to_mux2),
	.in3(out_to_mux3),
	.sel_w_en(w_en),
	.out_to_add(out_to_add)
	);
	
	//allocating 4 shift registers
	//reg0
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register0(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(we_r0),
	.cl_en(ce_r0),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_0)
	);
	
	//reg1
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register1(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(we_r1),
	.cl_en(ce_r1),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_1)
	);

	//reg2
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register2(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(we_r2),
	.cl_en(ce_r2),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_2)
	);

	//reg3
	ac2_reg #(.M(M), .Pa(Pa), .Pw(Pw)) ac2_register3(
	.clk(clk),
	.rst_n(rst_n),
	.w_and_s(we_r3),
	.cl_en(ce_r3),
	.inr_ac2(out_to_reg),
	.outr_ac2(out_ac2_3)
	);


endmodule 