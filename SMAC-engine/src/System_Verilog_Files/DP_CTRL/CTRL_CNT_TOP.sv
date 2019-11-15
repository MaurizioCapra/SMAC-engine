`timescale 1ns/1ns

//This module is intended as a top level one which gathers all the counters employed

//20/02/2019 created a top module to gather all used counters

module ctrl_cnt_top
  #(parameter Pw = 4,
    parameter Pa = 8,
	parameter MNO = 288,
	parameter MNV = 224*224)
   (//general inputs
	input clk, rst_n, cnt_load,
	//specific inputs 
	input wei_load, w_en_w, w_and_s_ac1, valid_ac2, valid_ac3, act_wb, cnt_in_vol,  cnt_clear_start, cnt_clear_finish, cnt_clear_vol,
	//inputs to program the programmable counters
	input [$clog2(MNO)-1:0] max_val_cnt_done,
	input [$clog2(Pa*Pw)-1:0] max_val_cnt_quant,
	input [2:0] max_val_cnt_out, max_val_cnt_relu, max_val_fil_group, //inputs to max val cnt relu and fil_group can be shared!
	input [$clog2(MNV)-1:0] max_val_in_vol,
	//outputs on 1 bit
	output bit_1, bit_m, cnt_sr_w7, cnt_sr_w6, cnt_sr_w2, term_ac1, term_ac2, 
		   last_fil, s_en_ac3, done_quant, relu_done, remW, op_done,
	//outputs on more than 1 bit
	output [7:0] wei_in_SMAC_reg_enables,
	output [1:0] sel_mux_out, sel_mux_relu, sel_mux_ac);
	
	
	//Internal signals declaration
	wire [7:0] out_ctrl_sr_we;
	wire done_ac3_int, out_posedge_det, done_quant_int, inc_relu_mux_cnt_int, relu_done_int, valid_ac3_int;
	
	//******************** MAPPING *************************************//
	
	//shift register controlling which group of 8 16bit regs out of SMAC block should be written
	ctrl_sr_we ctrl_sr_weights(
		.clk(clk),
		.rst_n(rst_n),
		.cnt_clear(cnt_clear_start),
		.s_en(wei_load),
		.par_out(out_ctrl_sr_we)
	);	
	
	//status signals to FSM
	assign cnt_sr_w2 = out_ctrl_sr_we[2];
	assign cnt_sr_w6 = out_ctrl_sr_we[6];
	assign cnt_sr_w7 = out_ctrl_sr_we[7];
	//generate write enables to weight regs out of the SMAC blocks:
	assign wei_in_SMAC_reg_enables = out_ctrl_sr_we & ~(last_fil & op_done);
	
	
	//counter tracking which bit of the weight is currently loaded in SMAC FF_weights
	ctrl_cnt_wbit #(.Pw(Pw)) ctrl_weibit(
		.clk(clk),
		.rst_n(rst_n),
		.cnt_clear(cnt_clear_start),
		.w_cnt(w_en_w),
		.bit_1(bit_1),
		.bit_m(bit_m)
	);	
	
	//counter tracking when ac1 has done sampling the last operand
	ctrl_cnt_ac1 #(.Pa(Pa)) ctrl_ac1(
		.clk(clk),
		.rst_n(rst_n),
		.cnt_clear(cnt_clear_start),
		.ac1_cnt(w_and_s_ac1),
		.term_ac1(term_ac1)
	);
	
	//counter tracking when ac2 has done sampling the last operand
	ctrl_cnt_ac2 #(.Pw(Pw)) ctrl_ac2(
		.clk(clk),
		.rst_n(rst_n),
		.cnt_clear(cnt_clear_start),
		.ac2_cnt(valid_ac2),
		.term_ac2(term_ac2)
	);

	//ctrl_done counter is incremented only when all regs in AC3 used for a layer are written and valid_ac3 = 1, 
	//otherwise you get the wrong result in DP!
	assign valid_ac3_int = valid_ac3 & (~remW); 
	//counter tracking when ac3 has done sampling the last operand
	ctrl_cnt_done #(.MNO(MNO)) ctrl_done(
		.clk(clk),
		.rst_n(rst_n),
		.cnt_clear(cnt_clear_finish),
		.cnt_load(cnt_load),
		.max_val(max_val_cnt_done),
		.valid_ac3(valid_ac3_int),
		.done_ac3(done_ac3_int),
		.last_fil(last_fil)
	);

	//positive edge trigger used to send a one cycle long signal to the ctrl_done_quant
	pos_edge_det posedge_detector (	
		.clk(clk), 
		.rst_n(rst_n), 
		.data_in(done_ac3_int),
		.data_out(out_posedge_det)
	);

	//counter tracking for how long s_en_ac3 must be enabled to apply quantization
	ctrl_cnt_done_quant #(.Pa(Pa), .Pw(Pw)) ctrl_quant (
		.clk(clk), 
		.rst_n(rst_n), 
		.cnt_start(out_posedge_det), 
		.cnt_load(cnt_load), 
		.cnt_clear(cnt_clear_finish),
		.max_val(max_val_cnt_quant), 
		.done_quant(done_quant_int), 
		.s_en_ac3(s_en_ac3)
	);
	
	//flip flop keeping the done_quant enabled until write back has been completed
	quant_ff ff_quant (	
		.clk(clk), 
		.rst_n(rst_n), 
		.done_quant(done_quant_int), 
		.clear(cnt_clear_finish),
		.data_out(done_quant)
	);
	
	//The following counter keeps track of the current filters batch that is being computed generating useful signals
	//to the FSM
	ctrl_cnt_fil_group cnt_fil_group (
		.clk(clk), 
		.rst_n(rst_n), 
		.valid_ac3(valid_ac3), 
		.cnt_clear(cnt_clear_start), 
		.cnt_load(cnt_load),
		.max_val(max_val_fil_group), 
		.remW(remW),
		.sel_mux_ac(sel_mux_ac)
	); 
	
	//The following two counters are used during WRITE BACK to know how much data must be written back to memory
	ctrl_cnt_out_mux cnt_out_max (	
		.clk(clk), 
		.rst_n(rst_n), 
		.act_wb(act_wb), 
		.cnt_clear(cnt_clear_finish), 
		.cnt_load(cnt_load),
		.max_val(max_val_cnt_out),
		.inc_relu_mux_cnt(inc_relu_mux_cnt_int),
		.sel_mux_out(sel_mux_out)
	); 
	ctrl_cnt_relu_mux cnt_relu_mux (	
		.clk(clk), 
		.rst_n(rst_n), 
		.inc_relu_mux_cnt(inc_relu_mux_cnt_int), 
		.cnt_clear(cnt_clear_finish), 
		.cnt_load(cnt_load),
		.max_val(max_val_cnt_relu), //no parameter because max value is 4 by construction
		.sel_mux_relu(sel_mux_relu),
		.relu_done(relu_done_int)
	); 
	assign relu_done = relu_done_int & inc_relu_mux_cnt_int;

	//This counter keeps track of the number of convolutional volumes that have been computed
	ctrl_cnt_in_vol #(.MNV(MNV)) count_in_vol (
		.clk(clk), 
		.rst_n(rst_n), 
		.cnt_in_vol(cnt_in_vol), 
		.cnt_load(cnt_load), 
		.cnt_clear_vol(cnt_clear_vol),
		.max_val(max_val_in_vol), 
		.op_done(op_done)
		); 

endmodule 