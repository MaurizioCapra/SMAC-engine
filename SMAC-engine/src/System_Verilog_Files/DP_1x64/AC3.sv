`timescale 1ns/1ns

module ac3 
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4,
	parameter MNO = 288) //Max Number Operands: 3x3xN_filter_max/16 
  (input clk, rst_n, valid, cl_en,
   input [1:0] w_en,	//used to select among the 4 different accumulators
   input [$clog2(M)+Pa+Pw:0]  in_from_ac2_0, in_from_ac2_1, in_from_ac2_2, in_from_ac2_3,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO):0]  out_smac);
	
	wire [$clog2(M)+Pa+Pw+$clog2(MNO):0] out_to_reg_0, out_to_reg_1, out_to_reg_2, out_to_reg_3;
	wire [$clog2(M)+Pa+Pw+$clog2(MNO):0] out_to_add0, out_to_add1, out_to_add2, out_to_add3;
	wire [$clog2(M)+Pa+Pw+$clog2(MNO):0]  out_ac3_0, out_ac3_1, out_ac3_2, out_ac3_3;
	//extended inputs to perform the addition correctly
	wire [$clog2(M)+Pa+Pw+$clog2(MNO):0] ex_in_from_ac2_0, ex_in_from_ac2_1, ex_in_from_ac2_2, ex_in_from_ac2_3;
	logic we_r0, we_r1, we_r2, we_r3;
	
	assign ex_in_from_ac2_0 = {{($clog2(MNO)){in_from_ac2_0[$clog2(M)+Pa+Pw]}},in_from_ac2_0};
	assign ex_in_from_ac2_1 = {{($clog2(MNO)){in_from_ac2_1[$clog2(M)+Pa+Pw]}},in_from_ac2_1};
	assign ex_in_from_ac2_2 = {{($clog2(MNO)){in_from_ac2_2[$clog2(M)+Pa+Pw]}},in_from_ac2_2};
	assign ex_in_from_ac2_3 = {{($clog2(MNO)){in_from_ac2_3[$clog2(M)+Pa+Pw]}},in_from_ac2_3}; 
	assign out_ac3_0 = out_to_add0;
	assign out_ac3_1 = out_to_add1;
	assign out_ac3_2 = out_to_add2;
	assign out_ac3_3 = out_to_add3;
	assign we_r0 = (~w_en[1]) && (~w_en[0]);
	assign we_r1 = (~w_en[1]) && (w_en[0]);
	assign we_r2 = (w_en[1]) && (~w_en[0]);
	assign we_r3 = (w_en[1]) && (w_en[0]);
	
	//adder 0
	ac3_adder #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_a0(
	.in_from_ac2(ex_in_from_ac2_0),
	.in_from_reg(out_to_add0),
	.out_to_reg(out_to_reg_0)
	);
	
	//adder 1
	ac3_adder #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_a1(
	.in_from_ac2(ex_in_from_ac2_1),
	.in_from_reg(out_to_add1),
	.out_to_reg(out_to_reg_1)
	);
	
	//adder 2
	ac3_adder #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_a2(
	.in_from_ac2(ex_in_from_ac2_2),
	.in_from_reg(out_to_add2),
	.out_to_reg(out_to_reg_2)
	);
	
	//adder 3
	ac3_adder #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_a3(
	.in_from_ac2(ex_in_from_ac2_3),
	.in_from_reg(out_to_add3),
	.out_to_reg(out_to_reg_3)
	);
	
	//reg0
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register0(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r0),
	.cl_en(cl_en),
	.valid(valid),
	.inr(out_to_reg_0),
	.outr(out_to_add0)
	);

	//reg1
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register1(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r1),
	.cl_en(cl_en),
	.valid(valid),
	.inr(out_to_reg_1),
	.outr(out_to_add1)
	);

	//reg2
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register2(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r2),
	.cl_en(cl_en),
	.valid(valid),
	.inr(out_to_reg_2),
	.outr(out_to_add2)
	);

	//reg3
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register3(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r3),
	.cl_en(cl_en),
	.valid(valid),
	.inr(out_to_reg_3),
	.outr(out_to_add3)
	);
	
	//mux
	ac3_mux #(.M(M), .Pa(Pa)) ac3_multiplexer(
	.in0(out_to_add0),
	.in1(out_to_add1),
	.in2(out_to_add2),
	.in3(out_to_add3),
	.sel_w_en(w_en),
	.out_final(out_smac)
	);


endmodule 