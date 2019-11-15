`timescale 1ns/1ns

module SMAC_noAC3_single 
  #(parameter M = 64,
    parameter Pa = 8,
	parameter Pw = 4) // activation operand parallelism
  (input clk, rst_n, we_w, we_a, we_br, we_neg, MSB_a, MSB_w, we_ac1, we_ac2, cl_en_ac1, cl_en_ac2,
   input [M-1:0] in_act, in_wei,
   output [$clog2(M)+Pa+Pw-1:0] out_ac2);
	
	wire [M-1:0] wei_to_and, and_to_ba, act_to_and;
	wire [$clog2(M):0] out_to_br, br_to_ac1;
	wire [$clog2(M)+Pa-1:0] ac1_to_neg;
	wire [$clog2(M)+Pa:0] neg_to_ac2;
	
	
	//input reg for activations
	input_register #(.M(M)) in_act_reg (
		.clk(clk), 
		.rst_n(rst_n), 
		.w_en(we_a), 
		.inr(in_act),
		.outr(act_to_and)
	);
	
	//input reg for weights
	input_register #(.M(M)) in_wei_reg (
		.clk(clk), 
		.rst_n(rst_n), 
		.w_en(we_w), 
		.inr(in_wei),
		.outr(wei_to_and)
	);
	
	//bitwise and operation
	assign and_to_ba = act_to_and & wei_to_and;
	
	//bit adder
	bit_adder #(.M(M)) bitadder (
		.MSB_a(MSB_a),
		.in_ba(and_to_ba),
		.out_ba(out_to_br)
	);
	
	//"bit register"
	bit_register #(.M(M)) br (
		.clk(clk), 
		.rst_n(rst_n), 
		.w_en(we_br),
		.inr(out_to_br),
		.outr(br_to_ac1)
	);
	
	//ac1
	ac1 #(.M(M), .Pa(Pa)) acc1 (
		.clk(clk), 
		.rst_n(rst_n), 
		.w_and_s(we_ac1), 
		.cl_en(cl_en_ac1),
		.in_ac1(br_to_ac1),
		.out_ac1(ac1_to_neg)
	);
	
	//neg_Reg
	neg_block #(.M(M), .Pa(Pa)) neg_reg (
		.clk(clk),
		.rst_n(rst_n),
		.w_en(we_neg),
		.MSB_w(MSB_w),
		.in_neg_block(ac1_to_neg),
		.out_neg_block(neg_to_ac2)
	);
	
	//ac2
	ac2 #(.M(M), .Pa(Pa), .Pw(Pw)) acc2 (
		.clk(clk), 
		.rst_n(rst_n), 
		.valid(we_ac2), 
		.cl_en(cl_en_ac2),
		.in_ac2(neg_to_ac2),
		.out_ac2_0(out_ac2)
	);
	
	
	
endmodule 
