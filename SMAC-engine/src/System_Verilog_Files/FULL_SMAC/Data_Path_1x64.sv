`timescale 1ns/1ns

//This is the top level getting together all the blocks needed for a Data Path with 64 SMAC blocks
//Here there are also the counters generating the status signals necessary

//18/02/2019 made all adjustments required to match everything with the new signals and reduced parallelism

//21/08/2019 changed parallelism of Pw from 4 to 8

module Data_Path_1x64
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 8,
	parameter MNO = 288,
	parameter BW = 128)
   (//******SHARED CONTROL SIGNALS***********//
    input clk, rst_n,  
	 
	//The following have to be included in the control structure ctrl_i of HWPE and come from the FSM
	
	//******* CONTROL SIGNALS COMING FROM THE FSM *******//
	
	//*******INPUT STAGE CONTROL SIGNALS*******//
	input w_en_mod_a, s_en_mod_a, //control signals for activ_mod_SR 
		  act_load, //signal to enable upload of activations in dp_act_reg
		  cl_en_gen, //signal used to clear some internal registers inside the SMAC structure
	//*******STAGE 0 CONTROL SIGNALS*******//
	input w_en_a, w_en_w, w_en_br, MSB_a,
	
	//*******STAGE 1 CONTROL SIGNALS*******//
	input w_and_s_ac1, cl_en_ac1, MSB_w, w_en_neg, 
	
	//*******STAGE 2 CONTROL SIGNALS*******// 
	input valid_ac2, cl_en_ac2,
	
	//*******STAGE 3 CONTROL SIGNALS*******//
	input valid_ac3,  

	//*******OUTPUT STAGE CONTROL SIGNALS*******//
	input wb,
	
	//******* CONTROL SIGNALS COMING FROM COUNTERS ********//
	input s_en_ac3, cl_en_ac3,
	input [1:0] sel_mux_ac, //works both for ac2 and ac3
	input [1:0] sel_mux_relu,
	input [1:0] sel_mux_out, //this signal enables a group of 16 SMAC to output the activation (used by DP_mux)
	input [7:0] wei_in_SMAC_reg_enables, //these are the wei_load coming from ControlUnit
	
	//*******INPUT DATA SIGNAL***********//	
	input [BW-1:0] in_data, 	
	//*******OUTPUT DATA SIGNAL**********//
	output reg [BW-1:0] out_data//,
	//TEMPORARY SIGNALS
	/*output [63:0][$clog2(M):0] br_to_ac1_view,
	output [63:0][$clog2(M)+Pa-1:0] ac1_to_neg_view,
	output [63:0][$clog2(M)+Pa:0] neg_to_ac2_view,
	output [63:0][3:0][$clog2(M)+Pa+Pw-1:0] ac2_to_ac3_view,
	output [63:0][3:0][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] ac3_to_q_view*/
	); 
	 
	//*********SIGNALS DEFINITION FOR WIRE CONNECTIONS ********************
	
	wire [BW-1:0] in_data_act_reg;
	wire [BW-1:0] out_data_reg_in;
	wire [M-1:0] activ_SR_to_inreg, inreg_to_SMAC; 
	wire [63:0][M-1:0] weights_in;  //[#wires][wire dimension]
	wire [63:0][Pa-1:0] activ_out;
	wire [3:0][BW-1:0] grouped_outs;
	
	
		
	//************* DP BLOCKS FOR ACTUAL COMPUTATION ***********************//
	
	//create an input register just for activation to keep coherent the fetching order during operation
	input_register #(.M(BW)) dp_act_reg(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.w_en(act_load),
		.inr(in_data),
		.outr(in_data_act_reg)
	); 
	 
	//generate M activation shift registers of type activ_mod_SR: 
	generate  
		for (genvar index=0; index < M; index=index+1)  
			begin: activ_sr_gen  
			activ_mod_SR #(.Pa(Pa)) act_sr (  
			.clk(clk),
			.rst_n(rst_n),
			.cl_en(cl_en_gen),
			.w_en(w_en_mod_a),
			.s_en(s_en_mod_a),
			.in_par(in_data_act_reg[(index*Pa + Pa -1):(index*Pa)]), 
			.out_ser(activ_SR_to_inreg[index])
			);  
		end  
	endgenerate 
	
	//input activation register between SMAC blocks and activ_mod_SR registers
	input_register #(.M(M)) reg_a(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.w_en(w_en_a),
		.inr(activ_SR_to_inreg),
		.outr(inreg_to_SMAC)
	);
	
	//generate 64 SMAC blocks 
	generate  
		for (genvar index2=0; index2 < 64; index2=index2+1)  
			begin: SMAC_gen  
			S_MAC_block #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) S_MAC_blocks (  
			.clk(clk),
			.rst_n(rst_n),
			.cl_en_gen(cl_en_gen),
			.w_en_w(w_en_w), 
			.w_en_br(w_en_br),
			.MSB_a(MSB_a),
			.w_and_s_ac1(w_and_s_ac1), 
			.cl_en_ac1(cl_en_ac1), 
			.MSB_w(MSB_w),
			.w_en_neg(w_en_neg), 
			.valid_ac2(valid_ac2),
			.cl_en_ac2(cl_en_ac2),
			.sel_ac2(sel_mux_ac),
			.valid_ac3(valid_ac3), 
			.cl_en_ac3(cl_en_ac3),
			.sel_ac3(sel_mux_ac),
			.s_en_ac3(s_en_ac3),
			.sel_mux_relu(sel_mux_relu),
			.act(inreg_to_SMAC), 
			.wei(weights_in[index2][M-1:0]), 
		    .out_smac(activ_out[index2][Pa-1:0])//,
			//TEMPORARY
			/*.br_to_ac1_view(br_to_ac1_view[index2][$clog2(M):0]),
			.ac1_to_neg_view(ac1_to_neg_view[index2][$clog2(M)+Pa-1:0]),
			.neg_to_ac2_view(neg_to_ac2_view[index2][$clog2(M)+Pa:0]),
			.ac2_to_ac3_view(ac2_to_ac3_view[index2]),
			.ac3_to_q_view(ac3_to_q_view[index2])*/
			);  
		end  
	endgenerate 
		
	//generate 64 16 bit regs out of each SMAC for the weights
	generate 
		for (genvar t=0; t<64; t=t+1) 
			begin: weights_reg_gen
			input_register #(.M(M)) wei_SMAC_registers(
			.clk(clk),
			.rst_n(rst_n),
			.cl_en(cl_en_gen),
			.w_en(wei_in_SMAC_reg_enables[t/8]),
			.inr(in_data[((t%8)*M + M -1):((t%8)*M)]),
			.outr(weights_in[t][M-1:0])
			);
		end
	endgenerate
	
	//group activ_out in groups of 4
	generate
		for (genvar p=0; p < 16; p=p+1) begin
			assign grouped_outs[0][(p*Pa + Pa -1):(p*Pa)] = activ_out[p][Pa-1:0];
			assign grouped_outs[1][(p*Pa + Pa -1):(p*Pa)] = activ_out[p+16][Pa-1:0];
			assign grouped_outs[2][(p*Pa + Pa -1):(p*Pa)] = activ_out[p+32][Pa-1:0];
			assign grouped_outs[3][(p*Pa + Pa -1):(p*Pa)] = activ_out[p+48][Pa-1:0];
		end
	endgenerate
	
	//for the output allocate a 4to1 MUX with 4xBW bits inputs and 1xBW bits output 
	DP_mux #(.BW(BW)) DP_out_mux(
		.in_from_SMACs1(grouped_outs[0][BW-1:0]),
		.in_from_SMACs2(grouped_outs[1][BW-1:0]),
		.in_from_SMACs3(grouped_outs[2][BW-1:0]),
		.in_from_SMACs4(grouped_outs[3][BW-1:0]),
		.act_wb(sel_mux_out),
		.out_mux(out_data)	
	);
	
	//TEMPORARY
	//assign out_data = out_data_reg_in;
	//create an output register for the DP of size BW (takes 4x1 mux output as input)	
	/*input_register #(.M(BW)) dp_output_register(
		.clk(clk),
		.rst_n(rst_n),
		.cl_en(cl_en_gen),
		.w_en(wb),
		.inr(out_data_reg_in),
		.outr(out_data)
	);*/
	
endmodule
