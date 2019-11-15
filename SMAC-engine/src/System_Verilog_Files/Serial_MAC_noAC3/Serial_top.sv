`timescale 1ns/1ns

module SMAC_top
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4,
	parameter BW = 128) // activation operand parallelism
  (input clk, rst_n, we_ar_mod, se_ar_mod, we_a, we_w, we_br, we_neg, MSB_a, MSB_w, we_ac1, we_ac2, cl_en_ac1, cl_en_ac2,
   input [BW-1:0] in_data_act,
   input [4*(BW)-1:0] in_data_wei,
   output [Pa*Pw-1:0][$clog2(M)+Pa+Pw-1:0] out_ac2);
	
	wire [M-1:0] activ_SR_to_SMAC, act_to_and;
	
	//generate M activation shift registers of type activ_mod_SR: 
	generate  
		for (genvar index=0; index < M; index=index+1)  
			begin: activ_sr_gen  
			activ_mod_SR #(.Pa(Pa)) act_sr (  
			.clk(clk),
			.rst_n(rst_n),
			.w_en(we_ar_mod),
			.s_en(se_ar_mod),
			.in_par(in_data_act[(index*Pa + Pa -1):(index*Pa)]), 
			.out_ser(activ_SR_to_SMAC[index])
			);  
		end  
	endgenerate 
	
	//input reg for activations
	input_register #(.M(M)) in_act_reg (
		.clk(clk), 
		.rst_n(rst_n), 
		.w_en(we_a), 
		.inr(activ_SR_to_SMAC),
		.outr(act_to_and)
	);
	
	
	//generate 32 SMAC blocks in vertical direction, weights wrongly conntected, just used for area analysis
	generate  
		for (genvar index2=0; index2 < 32; index2=index2+1)  
			begin: SMAC_gen  
			SMAC_noAC3 #(.M(M), .Pa(Pa), .Pw(Pw)) S_MAC_blocks (  
			.clk(clk),
			.rst_n(rst_n),
			.we_w(we_w), 
			.MSB_a(MSB_a),
			.we_br(we_br),
			.we_ac1(we_ac1), 
			.cl_en_ac1(cl_en_ac1), 
			.MSB_w(MSB_w),
			.we_neg(we_neg), 
			.we_ac2(we_ac2),
			.cl_en_ac2(cl_en_ac2),
			.in_act(act_to_and), 
			.in_wei(in_data_wei[(M)*(index2+1)-1:(M)*(index2)]), 
		    .out_ac2(out_ac2[index2][$clog2(M)+Pa+Pw-1:0])
			);  
		end  
	endgenerate
	
endmodule 