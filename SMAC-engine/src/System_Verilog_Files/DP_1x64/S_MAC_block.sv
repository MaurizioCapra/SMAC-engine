module S_MAC_block
	#(parameter M = 16,
	  parameter Pa = 8,
	  parameter Pw = 4,
	  parameter MNO = 288)
	(input clk, rst_n, // control signals common to all batches 
	 // batch 0 control signals
	 input w_en_a, w_en_w, w_en_br, MSB_a, 
	 // batch 1 control signals
	 input w_en_ac1, s_en_ac1, cl_en_ac1, MSB_w, w_en_neg, 
	 // batch 2 control signals 
	 input valid_ac2, s_en_ac2, cl_en_ac2,
	 input [1:0] sel_ac2_ac3, //works both for ac2 and ac3
	 //batch 3 control signals
	 input valid_ac3, cl_en_ac3, 
	 input [M-1:0] act, wei, 
	 //should be on 8 bits as the input activations
	 output [$clog2(M)+Pa+Pw+$clog2(MNO):0] out_smac); 

	wire [M-1:0] in_and_a, in_and_w;
	reg [M-1:0] out_and; 
	wire [$clog2(M)+1:0] ba_to_br, br_to_ac1;
	wire [$clog2(M)+Pa:0] ac1_to_neg, neg_to_ac2;
	wire [$clog2(M)+Pa+Pw:0] ac2_to_ac3_0, ac2_to_ac3_1, ac2_to_ac3_2, ac2_to_ac3_3;
	
	always_comb begin
		out_and <= in_and_a & in_and_w;
	end 
	 
	//batch 0 
	input_register #(.M(M)) reg_a(
		.clk(clk),
		.rst_n(rst_n),
		.w_en(w_en_a),
		.inr(act),
		.outr(in_and_a)
	);
	

	input_register #(.M(M)) reg_w(
		.clk(clk),
		.rst_n(rst_n),
		.w_en(w_en_w),
		.inr(wei),
		.outr(in_and_w)
	);
	
	
	bit_adder #(.M(M)) bit_add(
		.MSB_a(MSB_a),
		.in_ba(out_and),
		.out_ba(ba_to_br)
	);
	
	bit_register #(.M(M)) bit_reg(
		.clk(clk),
		.rst_n(rst_n),
		.w_en(w_en_br),
		.inr(ba_to_br),
		.outr(br_to_ac1)
	);
	
	//batch 1
	
	ac1 #(.M(M), .Pa(Pa)) ac1(
		.clk(clk),
		.rst_n(rst_n),
		.w_en(w_en_ac1),
		.s_en(s_en_ac1),
		.cl_en(cl_en_ac1),
		.in_ac1(br_to_ac1),
		.out_ac1(ac1_to_neg)
	);
	
	neg_block #(.M(M), .Pa(Pa)) negb(
		.clk(clk),
		.rst_n(rst_n),
		.MSB_w(MSB_w),
		.w_en(w_en_neg),
		.in_neg_block(ac1_to_neg),
		.out_neg_block(neg_to_ac2)
	);
	
	//batch 2
	
	ac2 #(.M(M), .Pa(Pa), .Pw(Pw)) ac2(
		.clk(clk),
		.rst_n(rst_n),
		.valid(valid_ac2),
		.s_en(s_en_ac2),
		.cl_en(cl_en_ac2),
		.w_en(sel_ac2_ac3),
		.in_ac2(neg_to_ac2),
		.out_ac2_0(ac2_to_ac3_0),
		.out_ac2_1(ac2_to_ac3_1),
		.out_ac2_2(ac2_to_ac3_2),
		.out_ac2_3(ac2_to_ac3_3)
	);
	
	//batch 3
	ac3 #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3(
		.clk(clk),
		.rst_n(rst_n),
		.valid(valid_ac3),
		.cl_en(cl_en_ac3),
		.w_en(sel_ac2_ac3),
		.in_from_ac2_0(ac2_to_ac3_0),
		.in_from_ac2_1(ac2_to_ac3_1),
		.in_from_ac2_2(ac2_to_ac3_2),
		.in_from_ac2_3(ac2_to_ac3_3),
		.out_smac(out_smac)
	);
	
	
endmodule
