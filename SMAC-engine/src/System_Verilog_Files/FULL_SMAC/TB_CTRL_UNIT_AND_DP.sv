`timescale 1ns/1ns
import basic_package::*;
						 
module CTRL_UNIT_AND_DP_tb #(parameter Pa = 8, 
							 parameter Pw = 4,
							 parameter M = 16,
							 parameter BW = 128,
							 parameter MNO = 288, 
							 parameter MNV = 224*224);	
	
	
	ctrl_states out_state;					 
			
	reg clk;
	reg rst_n;
	reg core_stall_n;
	reg  w_en_mod_a, s_en_mod_a, act_load, w_en_a, w_en_w, w_en_br, MSB_a, w_and_s_ac1, cl_en_ac1, MSB_w, 
	     w_en_neg, valid_ac2, cl_en_ac2, valid_ac3, wb, cl_en_gen, s_en_ac3, cl_en_ac3; 
	reg [1:0] sel_mux_ac, sel_mux_out, sel_mux_relu;
	reg [$clog2(MNO)-1:0] max_val_cnt_done;
	reg [$clog2(Pa*Pw)-1:0] max_val_cnt_quant;
	reg [2:0] max_val_cnt_out, max_val_cnt_relu, max_val_fil_group;
	reg [$clog2(MNV)-1:0] max_val_in_vol;
	reg [7:0] wei_in_SMAC_reg_enables;
	reg [BW-1:0] in_data, out_data;
	//TEMPORARY
	reg [63:0][$clog2(M):0] br_to_ac1_view;
	reg [63:0][$clog2(M)+Pa-1:0] ac1_to_neg_view;
	reg [63:0][$clog2(M)+Pa:0] neg_to_ac2_view;
	reg [63:0][3:0][$clog2(M)+Pa+Pw-1:0] ac2_to_ac3_view;
	reg [63:0][3:0][$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] ac3_to_q_view;
	

	CTRL_unit #(.Pa(Pa), .Pw(Pw), .MNO(MNO), .MNV(MNV)) controllo (
		.clk(clk), 
		.rst_n(rst_n), 
		.core_stall_n(core_stall_n),
		.max_val_cnt_done(max_val_cnt_done),
		.max_val_cnt_quant(max_val_cnt_quant),
		.max_val_cnt_out(max_val_cnt_out), 
		.max_val_cnt_relu(max_val_cnt_relu), 
		.max_val_fil_group(max_val_fil_group),
		.max_val_in_vol(max_val_in_vol),
		.act_load(act_load), 
		.w_en_mod_a(w_en_mod_a), 
		.s_en_mod_a(s_en_mod_a), 
		.w_en_a(w_en_a), 
		.w_en_w(w_en_w), 
		.w_en_br(w_en_br), 
		.MSB_a(MSB_a), 
		.w_and_s_ac1(w_and_s_ac1), 
		.cl_en_ac1(cl_en_ac1), 
		.MSB_w(MSB_w),
		.w_en_neg(w_en_neg), 
		.valid_ac2(valid_ac2), 
		.cl_en_ac2(cl_en_ac2), 
		.valid_ac3(valid_ac3), 
		.cl_en_ac3(cl_en_ac3), 
		.wb(wb), 
		.cl_en_gen(cl_en_gen), 
		.s_en_ac3(s_en_ac3),
		.sel_mux_out(sel_mux_out), 
		.sel_mux_relu(sel_mux_relu), 
		.sel_mux_ac(sel_mux_ac),
		.wei_in_SMAC_reg_enables(wei_in_SMAC_reg_enables),
		//temporary
		.out_state(out_state)
	);
	
	Data_Path_1x64 #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO), .BW(BW)) Data_Path (
		.clk(clk), 
		.rst_n(rst_n),  
		.w_en_mod_a(w_en_mod_a), 
		.s_en_mod_a(s_en_mod_a), 
		.act_load(act_load),
		.cl_en_gen(cl_en_gen), 
		.w_en_a(w_en_a), 
		.w_en_w(w_en_w), 
		.w_en_br(w_en_br), 
		.MSB_a(MSB_a),
		.w_and_s_ac1(w_and_s_ac1), 
		.cl_en_ac1(cl_en_ac1), 
		.MSB_w(MSB_w), 
		.w_en_neg(w_en_neg), 
		.valid_ac2(valid_ac2), 
		.cl_en_ac2(cl_en_ac2),
		.valid_ac3(valid_ac3),  
		.wb(wb), 
		.s_en_ac3(s_en_ac3), 
		.cl_en_ac3(cl_en_ac3),
		.sel_mux_ac(sel_mux_ac),
		.sel_mux_relu(sel_mux_relu),
		.sel_mux_out(sel_mux_out), 
		.wei_in_SMAC_reg_enables(wei_in_SMAC_reg_enables),
		.in_data(in_data),
		.out_data(out_data),
		//TEMPORARY
		.br_to_ac1_view(br_to_ac1_view),
		.ac1_to_neg_view(ac1_to_neg_view),
		.neg_to_ac2_view(neg_to_ac2_view),
		.ac2_to_ac3_view(ac2_to_ac3_view),
		.ac3_to_q_view(ac3_to_q_view)
	); 
	
	
	//reset Generation
    initial begin
		rst_n = 0;
		clk = 0;
		#5 rst_n =1;
    end
	
	//CLK generation
		
	always 
		begin 
			 #5  clk = ~clk;
		end
	
	initial 
		begin
            // Dump waves
    		//$dumpfile("dump.vcd");
    		//$dumpvars(1);
			//done <= 0;
			//in_data <= -1; 
			//SET-UP FSM
			
			//values to load on counters
			max_val_in_vol <= 16'b0000000000000100;
			max_val_cnt_relu <= 3'b010;
			max_val_cnt_out <= 3'b100;
			max_val_fil_group <= 3'b010;
			max_val_cnt_done <= 9'b001001001;
			max_val_cnt_quant <= 5'b01111;
			
			//in_data <=128'b11100110111001101110011011100110111001101110011011100110111001101110011011100110111001101110011011100110111001101110011011100110;
			//in_data <=128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111; 	
			in_data <= 128'b01111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111;
			
			//wait a bit before starting
			#20;
			core_stall_n <= 1;
			
			//after some cycles hanshake fails
			#372518; // with 4 fils
			//#93180; with 2 fils
		end
		

	
endmodule
			
			