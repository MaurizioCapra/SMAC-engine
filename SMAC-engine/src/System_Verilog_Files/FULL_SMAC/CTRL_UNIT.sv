`timescale  1ns/1ns

//this module will group all the components needed for the control

//21/02/2019

//21/08/2019 changed parallelism of Pw from 4 to 8,introduce two new signals: par_sel_Pa and par_sel_Pw sent to the internal modul in order to selec the right parallelism

//import basic_package::*;

module CTRL_unit 
  #(parameter Pa = 8,
	parameter Pw = 8,
	parameter MNO = 288,
	parameter MNV = 224*224)
   (input clk, rst_n, core_stall_n, //start,
   
	//input to program counters
	input [$clog2(MNO)-1:0] max_val_cnt_done,
	input [$clog2(Pa*Pw)-1:0] max_val_cnt_quant,
	input [2:0] max_val_cnt_out, max_val_cnt_relu, max_val_fil_group,
	input [$clog2(MNV)-1:0] max_val_in_vol,
	//prallelism selection signals
	input par_sel_Pa,
	input [1:0] par_sel_Pw,
	//to data path or higher level FSM
        output logic act_load, w_en_mod_a, s_en_mod_a, w_en_a, w_en_w, w_en_br, MSB_a, w_and_s_ac1, cl_en_ac1, MSB_w,
		   w_en_neg, valid_ac2, cl_en_ac2, valid_ac3, cl_en_ac3, wb, cl_en_gen, s_en_ac3, update_in, update_out,
	output [1:0] sel_mux_out, sel_mux_relu, sel_mux_ac,
	output [7:0] wei_in_SMAC_reg_enables//,
	//TEMPORARY OUTPUT
	//output ctrl_states out_state
	);
	
	//internal signal declaration
	logic remW_int, cnt_sr_w7_int, cnt_sr_w6_int, cnt_sr_w2_int, bit_1_int, bit_m_int, term_ac1_int, term_ac2_int,
	      done_quant_int, op_done_int, relu_done_int, last_fil_int, act_wb_int, cnt_load_int, cnt_clear_start_int, 
	      cnt_clear_finish_int, cnt_clear_vol_int, cnt_in_vol_int, w_and_s_ac1_int, valid_ac2_int, valid_ac3_int, wei_load_int, 
	      update_source, update_sink;
	logic [7:0] wei_in_SMAC_reg_enables_int;	 	

	//THE FOLLOWING MAY BE TEMPORARY FOR THE LOWER PERFORMANCE ACCELERATOR MODE (may need changes to support continuous mode)	
	//signal helping higher level FSM to move from COMPUTE to either UPDATE_IDX_IN or UPDATE_IDX_OUT state: 
	//requires posedge detector to move to that state just once
	//output assignment
	assign update_in  = update_source; 
	assign update_out = update_sink;
	pos_edge_det posedge_update_out (	
		.clk(clk), 
		.rst_n(rst_n), 
		.data_in(cnt_in_vol_int),
		.data_out(update_sink)
	);
	//signal sent to DP active only when data is valid to avoid
	assign wei_in_SMAC_reg_enables[7:0] = wei_in_SMAC_reg_enables_int[7:0];

	//internal assignment	
	assign cl_en_ac3 = cnt_clear_finish_int;	
	assign w_and_s_ac1 = w_and_s_ac1_int;
	assign valid_ac2 = valid_ac2_int;
	assign valid_ac3 = valid_ac3_int;
	
	
	ctrl_FSM FSM_lowe_level (
		.clk(clk), 
		.rst_n(rst_n), 
		.core_stall_n(core_stall_n), //this is the handshake signal, basically working as a start
		.remW(remW_int), //signal saying if there are remaining filters before fetching new activations
		//.start(start),
		.cnt_sr_w7(cnt_sr_w7_int), 
		.cnt_sr_w6(cnt_sr_w6_int), 
		.cnt_sr_w2(cnt_sr_w2_int),
		.bit_1(bit_1_int), 
		.bit_m(bit_m_int),
		.term_ac1(term_ac1_int), 
		.term_ac2(term_ac2_int), 
		.done_quant(done_quant_int), 
		.op_done(op_done_int), 
		.relu_done(relu_done_int), 
		.last_fil(last_fil_int),
		.act_load(act_load), 
		.w_en_mod_a(w_en_mod_a), 
		.s_en_mod_a(s_en_mod_a), 
		.wei_load(wei_load_int), 
		.w_en_a(w_en_a), 
		.w_en_w(w_en_w), 
		.w_en_br(w_en_br), 
		.MSB_a(MSB_a),
		.w_and_s_ac1(w_and_s_ac1_int), 
		.cl_en_ac1(cl_en_ac1), 
		.MSB_w(MSB_w), 
		.w_en_neg(w_en_neg), 
		.valid_ac2(valid_ac2_int), 
		.cl_en_ac2(cl_en_ac2),
		.valid_ac3(valid_ac3_int), 
		.wb(wb), 
		.act_wb(act_wb_int),
		.cnt_load(cnt_load_int), 
		.cnt_clear_start(cnt_clear_start_int),
		.cnt_clear_finish(cnt_clear_finish_int), 
		.cnt_clear_vol(cnt_clear_vol_int), 
		.cnt_in_vol(cnt_in_vol_int), 
		.cl_en_gen(cl_en_gen)//,
		//temporary
		//.out_state(out_state)
	);
	
	ctrl_cnt_top #(.Pa(Pa), .Pw(Pw), .MNO(MNO), .MNV(MNV)) counters (
		.clk(clk), 
		.rst_n(rst_n), 
		.cnt_clear_start(cnt_clear_start_int), 
		.cnt_clear_finish(cnt_clear_finish_int), 
		.cnt_load(cnt_load_int),
		.wei_load(wei_load_int), 
		.w_en_w(w_en_w), 
		.w_and_s_ac1(w_and_s_ac1_int), 
		.valid_ac2(valid_ac2_int), 
		.valid_ac3(valid_ac3_int), 
		.act_wb(act_wb_int), 
		.cnt_in_vol(cnt_in_vol_int), 
		.cnt_clear_vol(cnt_clear_vol_int),
		//inputs to program the programmable counters
		.max_val_cnt_done(max_val_cnt_done),
		.max_val_cnt_quant(max_val_cnt_quant),
		.max_val_cnt_out(max_val_cnt_out), 
		.max_val_cnt_relu(max_val_cnt_relu), 
		.max_val_fil_group(max_val_fil_group),
		.max_val_in_vol(max_val_in_vol),
		.par_sel_Pa(par_sel_Pa),
		.par_sel_Pw(par_sel_Pw),
		.bit_1(bit_1_int), 
		.bit_m(bit_m_int),
		.update(update_source),
		.cnt_sr_w7(cnt_sr_w7_int), 
		.cnt_sr_w6(cnt_sr_w6_int), 
		.cnt_sr_w2(cnt_sr_w2_int), 
		.term_ac1(term_ac1_int), 
		.term_ac2(term_ac2_int), 
		.last_fil(last_fil_int), 
		.s_en_ac3(s_en_ac3), 
		.done_quant(done_quant_int), 
		.relu_done(relu_done_int), 
		.remW(remW_int), 
		.op_done(op_done_int),
		.wei_in_SMAC_reg_enables(wei_in_SMAC_reg_enables_int),
		.sel_mux_out(sel_mux_out), 
		.sel_mux_relu(sel_mux_relu), 
		.sel_mux_ac(sel_mux_ac)
		);
		
endmodule
