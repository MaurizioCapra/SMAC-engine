`timescale 1ns/1ns

//This module encapsulate the computational block for a Serial MAC 

//18/02/2019 reduced parallelism, included quantization and ReLU, modified internal signals

module S_MAC_block
	#(parameter M = 16,
	  parameter Pa = 8,
	  parameter Pw = 4,
	  parameter MNO = 288)
	(// control signals common to all batches 
	 input clk, rst_n, cl_en_gen,
	 // batch 0 control signals
	 input w_en_w, w_en_br, MSB_a, 
	 // batch 1 control signals
	 input w_and_s_ac1, cl_en_ac1, MSB_w, w_en_neg, 
	 // batch 2 control signals 
	 input valid_ac2, cl_en_ac2,
	 input [1:0] sel_ac2, //works both for ac2 and ac3
	 //batch 3 control signals
	 input valid_ac3, cl_en_ac3, s_en_ac3,
	 input [1:0] sel_ac3,
	 //output stage control signal
	 input [1:0] sel_mux_relu,
	 //input data
	 input [M-1:0] act, wei, 
	 //output on 8 bits as the input activations
	 output [Pa-1:0] out_smac//,
	 
	 //TEMPORARY OUTPUTS
	 /*output [$clog2(M):0] br_to_ac1_view,
	 output [$clog2(M)+Pa-1:0] ac1_to_neg_view,
	 output [$clog2(M)+Pa:0] neg_to_ac2_view,
	 output [3:0][$clog2(M)+Pa+Pw-1:0] ac2_to_ac3_view,
	 output [3:0][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] ac3_to_q_view*/
	 ); 
	
	//signal declaration
	wire [M-1:0] in_and_w;
	reg  [M-1:0] out_and; 
	wire [$clog2(M):0] ba_to_br, br_to_ac1;
	wire [$clog2(M)+Pa-1:0] ac1_to_neg;
	wire [$clog2(M)+Pa:0] neg_to_ac2;
	wire [$clog2(M)+Pa+Pw-1:0] ac2_to_ac3_0, ac2_to_ac3_1, ac2_to_ac3_2, ac2_to_ac3_3;
	wire [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] ac3_to_q_0, ac3_to_q_1, ac3_to_q_2, ac3_to_q_3;
	
	//TEMPORY ASSIGNMENTS
	/*assign br_to_ac1_view = br_to_ac1;
	assign ac1_to_neg_view = ac1_to_neg;
	assign neg_to_ac2_view = neg_to_ac2;
	assign ac2_to_ac3_view[0][$clog2(M)+Pa+Pw-1:0] = ac2_to_ac3_0;
	assign ac2_to_ac3_view[1][$clog2(M)+Pa+Pw-1:0] = ac2_to_ac3_1;
	assign ac2_to_ac3_view[2][$clog2(M)+Pa+Pw-1:0] = ac2_to_ac3_2;
	assign ac2_to_ac3_view[3][$clog2(M)+Pa+Pw-1:0] = ac2_to_ac3_3;
	assign ac3_to_q_view[0][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] = ac3_to_q_0;
	assign ac3_to_q_view[1][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] = ac3_to_q_1;
	assign ac3_to_q_view[2][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] = ac3_to_q_2;
	assign ac3_to_q_view[3][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] = ac3_to_q_3;*/
	
	
	//compute the bitwise AND between actiavtions' bits and weights' bits	
	always_comb begin
		out_and <= act & in_and_w;// in_and_a & in_and_w;
	end 
	 
	//***********BATCH 0 MAPPINGS***************//
	
	//activations reg: moved to data path module
	/*input_register #(.M(M)) reg_a(
		.clk(clk),
		.rst_n(rst_n),
		.w_en(w_en_a),
		.inr(act),
		.outr(in_and_a)
	);*/
	
	//weights reg:
	input_register #(.M(M)) reg_w(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.w_en(w_en_w),
		.inr(wei),
		.outr(in_and_w)
	);
	
	//bit_adder_tree
	bit_adder #(.M(M)) bit_add(
		.MSB_a(MSB_a),
		.in_ba(out_and),
		.out_ba(ba_to_br)
	);
	
	//register after bit adder
	bit_register #(.M(M)) bit_reg(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.w_en(w_en_br),
		.inr(ba_to_br),
		.outr(br_to_ac1)
	);
	
	//***********BATCH 1 MAPPINGS***************//
	
	//accumulator AC1
	ac1 #(.M(M), .Pa(Pa)) ac1(
		.clk(clk),
		.rst_n(rst_n),
		.w_and_s(w_and_s_ac1),
		.cl_en(cl_en_ac1),
		.in_ac1(br_to_ac1),
		.out_ac1(ac1_to_neg)
	);
	
	//neg register
	neg_block #(.M(M), .Pa(Pa)) negb(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.MSB_w(MSB_w),
		.w_en(w_en_neg),
		.in_neg_block(ac1_to_neg),
		.out_neg_block(neg_to_ac2)
	);
	
	//***********BATCH 2 MAPPINGS***************//
	
	//accumulator AC2
	ac2 #(.M(M), .Pa(Pa), .Pw(Pw)) ac2(
		.clk(clk),
		.rst_n(rst_n),
		.valid(valid_ac2),
		.cl_en(cl_en_ac2),
		.w_en(sel_ac2),
		.in_ac2(neg_to_ac2),
		.out_ac2_0(ac2_to_ac3_0),
		.out_ac2_1(ac2_to_ac3_1),
		.out_ac2_2(ac2_to_ac3_2),
		.out_ac2_3(ac2_to_ac3_3)
	);
	
	//***********BATCH 3 MAPPINGS***************//
	
	//accumulator AC3
	ac3 #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3(
		.clk(clk),
		.rst_n(rst_n),
		.valid(valid_ac3),
		.cl_en(cl_en_ac3),
		.w_en(sel_ac3),
		.s_en(s_en_ac3),
		.in_from_ac2_0(ac2_to_ac3_0),
		.in_from_ac2_1(ac2_to_ac3_1),
		.in_from_ac2_2(ac2_to_ac3_2),
		.in_from_ac2_3(ac2_to_ac3_3),
		.out_ac3_0(ac3_to_q_0), 
		.out_ac3_1(ac3_to_q_1), 
		.out_ac3_2(ac3_to_q_2), 
		.out_ac3_3(ac3_to_q_3)
	);
	
	//quantization+ReLU
	quant_ReLU #(.Pa(Pa)) q_and_relu(
		.sel(sel_mux_relu),	
		.qin_from_ac3_0(ac3_to_q_0[Pa-1:0]), 
		.qin_from_ac3_1(ac3_to_q_1[Pa-1:0]), 
		.qin_from_ac3_2(ac3_to_q_2[Pa-1:0]), 
		.qin_from_ac3_3(ac3_to_q_3[Pa-1:0]),
		.out_ReLU(out_smac)
	);
	
endmodule
