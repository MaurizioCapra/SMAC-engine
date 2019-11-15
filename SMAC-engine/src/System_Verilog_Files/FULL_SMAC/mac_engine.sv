/*
 * mac_engine.sv
 * Francesco Conti <fconti@iis.ee.ethz.ch>
 *
 * Copyright (C) 2018 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * The architecture that follows is relatively straightforward; it supports two modes:
 *  - in 'simple_mult' mode, the a_i and b_i streams feed the 32b x 32b multiplier (mult).
 *    The output of the multiplier (64b) is registered in a pipeline stage
 *    (r_mult), which is then shifted by ctrl_i.shift to the right and streamed out as d_o.
 *    There is no control local to the module except for handshakes.
 *  - in 'scalar_prod' mode, the c_i stream is first shifted left by ctrl_i.shift, extended
 *    to 64b and saved in r_acc. Then, the a_i and b_i streams feed the 32b x 32b multiplier
 *    (mult) for ctrl_i.len cycles, controlled by a local counter. The output of mult is 
 *    registered in a pipeline stage (r_mult), whose value is used as input to an accumulator
 *    (r_acc) -- the one which was inited by the shifted value of c_i. At the end of the
 *    ctrl_i.len cycles, the output of r_acc is shifted back to the right by ctrl_i.shift
 *    bits and streamed out as d_o.
 */

import mac_package::*;

module mac_engine
(
  // global signals
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic                   test_mode_i,
  // input a stream
  hwpe_stream_intf_stream.sink   a_i, // this has been defined to be on 128 bit in mac_streamer.sv
  // output d stream
  hwpe_stream_intf_stream.source d_o, // this has been defined to be on 128 bit in mac_streamer.sv
  // control channel
  input  ctrl_engine_t           ctrl_i,
  output flags_engine_t          flags_o
);
	
  //*******SIGNALS ********
  logic [BW-1:0] r_out;   //this is the output of mac_engine, connected to d_0.data
  logic [BW-1:0] out_DP;  //this is the output of the DP
  logic [BW-1:0] out_in_reg;
  logic r_out_valid; 
  logic r_out_ready; 
	
  // A design choice of this accelerator is that at the interface of modules only a few categories
  // of signals are exposed:
  //  - global signals (clk, rst_n)
  //  - HWPE-Stream or TCDM interfaces (a_i, ...)
  //  - a control packed struct (ctrl_i) and a state packed struct (flags_o)
  // The flags_o packed struct encapsulates all of the information about the internal state
  // of the module that must be exposed to the controller, and the ctrl_i all the control
  // information necessary for configuring the current module. In this way, it is possible to
  // make significant changes to the control interface (which can typically propagate through
  // a big hierarchy of modules) without manually modifying the interface in all modules; it
  // is sufficient to change the packed struct definition in the package where it is defined.
  // Packed structs are essentially bit vectors where bit fields have a name, and as such
  // are easily synthesizable and much more readable than Verilog-2001-ish code.
 
  //signal declaration for local (only used inside here) interconnections
  logic local_w_en_mod_a, local_s_en_mod_a, local_act_load, local_w_en_a, local_w_en_w, local_w_en_br, local_MSB_a,
        local_w_and_s_ac1, local_cl_en_ac1, local_MSB_w, local_w_en_neg, local_valid_ac2, local_cl_en_ac2, local_valid_ac3,
        local_cl_en_ac3, local_s_en_ac3, local_wb, local_cl_en_gen, local_op_done, local_wb_ext;
  logic [1:0] local_sel_mux_ac, local_sel_mux_relu, local_sel_mux_out;
  logic [7:0] local_wei_in_SMAC_reg_enables;
 
	//if input input data is valid, store it in this register	
	always_ff @(posedge clk_i or negedge rst_ni)
	begin : out_in_reg_gen
		if(~rst_ni) begin
			out_in_reg <= '0;
		end
		//left out this condition otherwise the low lvl FSM was not behaving well at the startup,
		//may later on introduce a clear enable signal though atm it should not be really needed
		//else if (local_cl_en_gen) begin
		//	out_in_reg <= '0;
		//end
		else if (a_i.valid) begin
			out_in_reg <= a_i.data; 
		end
	end

  //************ALLOCATE DP **************	
  Data_Path_1x64 #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO), .BW(BW)) DP(
		.clk(clk_i),
		.rst_n(rst_ni), 
		.w_en_mod_a(local_w_en_mod_a), 
		.s_en_mod_a(local_s_en_mod_a), 
		.wei_in_SMAC_reg_enables(local_wei_in_SMAC_reg_enables), 
		.act_load(local_act_load), 
		.cl_en_gen(local_cl_en_gen),
		.w_en_a(local_w_en_a), 
		.w_en_w(local_w_en_w), 
		.w_en_br(local_w_en_br), 
		.MSB_a(local_MSB_a), 
		.w_and_s_ac1(local_w_and_s_ac1),
		.cl_en_ac1(local_cl_en_ac1), 
		.MSB_w(local_MSB_w), 
		.w_en_neg(local_w_en_neg), 
		.valid_ac2(local_valid_ac2), 
		.cl_en_ac2(local_cl_en_ac2),
		.sel_mux_ac(local_sel_mux_ac),
		.valid_ac3(local_valid_ac3), 
		.cl_en_ac3(local_cl_en_ac3), 
		.s_en_ac3(local_s_en_ac3),
		.sel_mux_relu(local_sel_mux_relu),
		.wb(local_wb),
		.sel_mux_out(local_sel_mux_out), 
		.in_data(out_in_reg), 
	    .out_data(out_DP)
	);	
	
	// The control counter is implemented directly inside this module; as the control is
  // minimal, it was not deemed convenient to move it to another submodule. For bigger
  // FSMs that is typically the most advantageous choice.
  
	//**********ALLOCATE LOW LEVEL CONTROL*********
	CTRL_unit #(.Pa(Pa), .Pw(Pw), .MNO(MNO), .MNV(MNV)) control_low (
		.clk(clk_i), 
		.rst_n(rst_ni), 
		.core_stall_n(a_i.valid),
		//.start(ctrl_i.start),
		.max_val_cnt_done(ctrl_i.max_val_cnt_done),
		.max_val_cnt_quant(ctrl_i.max_val_cnt_quant),
		.max_val_cnt_out(ctrl_i.max_val_cnt_out), 
		.max_val_cnt_relu(ctrl_i.max_val_cnt_relu_and_fil_group), 
		.max_val_fil_group(ctrl_i.max_val_cnt_relu_and_fil_group),
		.max_val_in_vol(ctrl_i.max_val_in_vol),
		.par_sel_Pa(ctrl_i.par_sel_Pa),
		.par_sel_Pw(ctrl_i.par_sel_Pw),
		.act_load(local_act_load), 
		.w_en_mod_a(local_w_en_mod_a), 
		.s_en_mod_a(local_s_en_mod_a), 
		.w_en_a(local_w_en_a), 
		.w_en_w(local_w_en_w), 
		.w_en_br(local_w_en_br), 
		.MSB_a(local_MSB_a), 
		.w_and_s_ac1(local_w_and_s_ac1), 
		.cl_en_ac1(local_cl_en_ac1), 
		.MSB_w(local_MSB_w),
		.w_en_neg(local_w_en_neg), 
		.valid_ac2(local_valid_ac2), 
		.cl_en_ac2(local_cl_en_ac2), 
		.valid_ac3(local_valid_ac3), 
		.cl_en_ac3(local_cl_en_ac3), 
		.wb(local_wb), 
		.cl_en_gen(local_cl_en_gen), 
		.s_en_ac3(local_s_en_ac3),
		.update_in(flags_o.update_in), 			//this signal is sent to the higher level FSM
		.update_out(flags_o.update_out),		//this signal is sent to the higher level FSM
		.sel_mux_out(local_sel_mux_out), 
		.sel_mux_relu(local_sel_mux_relu), 
		.sel_mux_ac(local_sel_mux_ac),
		.wei_in_SMAC_reg_enables(local_wei_in_SMAC_reg_enables)
	);	

	
	//generating the output	
	always_ff @(posedge clk_i or negedge rst_ni)
	begin : r_out_gen
		if(~rst_ni) begin
			r_out <= '0;
		end
		else if (local_cl_en_gen) begin
			r_out <= '0;
		end
		else if (local_wb) begin
			r_out <= out_DP; 
		end
	end
	
	//generating the valid condition for the output	
	always_ff @(posedge clk_i or negedge rst_ni)
	begin : r_out_valid_gen
		if(~rst_ni) begin
			r_out_valid <= '0;
		end
		else if (local_cl_en_gen) begin
			r_out_valid <= '0;
		end
		else if (local_wb) begin
			r_out_valid <= local_wb; 
		end else begin
			r_out_valid <= '0;
		end
	end

		
	always_comb
	begin
		d_o.data  = r_out; 
		d_o.valid = r_out_valid;
		d_o.strb  = '1; // needed?
    end

  
  /********** ADD FLAG SIGNALS GENERATION HERE AND TAKE THEM OUT TO THE HIGHER LEVEL FSM *****************/
	//shouldn't be needed
  //assign flags_o.core_stall_n = a_i.valid;
  

  // Ready signals have to be propagated backwards through pipeline stages (combinationally).
  // To avoid deadlocks, the following rules have to be followed:
  //  1) transition of ready CAN depend on the current state of valid
  //  2) transition of valid CANNOT depend on the current state of ready
  //  3) transition 1->0 of valid MUST depend on (previous) ready (i.e., once the valid goes
  //     to 1 it cannot go back to 0 until there is a valid handshake)
  // In the following:
  // R_valid & R_ready denominate the handshake at the *output* (Q port) of pipe register R

  //Considering handshaking only performed at the boundary there can't be back propagation 
  //of ready signals... so is it ok if performed as follows?
  
  // output accepts new value from accumulators when the output is ready or r_out is invalid
  assign r_out_ready  = d_o.ready | ~r_out_valid;
  // DP accepts new value from a_i when r_out is ready and a_i is valid, or when a_i is invalid?
  assign a_i.ready = (r_out_ready & a_i.valid) | (~a_i.valid);
  
  
  // The following assertions help in getting the rules on ready & valid right.
  // They are copied from the general stream rules in hwpe_stream_interfaces.sv
  // and adapted to the internal r_out signal.
  `ifndef SYNTHESIS
    // The data and strb can change their value 1) when valid is deasserted,
    // 2) in the cycle after a valid handshake, even if valid remains asserted.
    // In other words, valid data must remain on the interface until
    // a valid handshake has occurred.
    property r_out_change_rule;
      @(posedge clk_i)
      ($past(r_out_valid) & ~($past(r_out_valid) & $past(r_out_ready))) |-> (r_out == $past(r_out));
    endproperty;
  
	
    // The deassertion of valid (transition 1í0) can happen only in the cycle
    // after a valid handshake. In other words, valid data produced by a source
    // must be consumed on the sink side before valid is deasserted.
    property r_out_valid_deassert_rule;
      @(posedge clk_i)
      ($past(r_out_valid) & ~r_out_valid) |-> $past(r_out_valid) & $past(r_out_ready);
    endproperty;
	
	
    R_OUT_VALUE_CHANGE:    assert property(r_out_change_rule)
      else $fatal("ASSERTION FAILURE: R_OUT_VALUE_CHANGE", 1);

    R_OUT_VALID_DEASSERT:  assert property(r_out_valid_deassert_rule)
      else $fatal("ASSERTION FAILURE R_OUT_VALID_DEASSERT", 1);
	
  `endif /* SYNTHESIS */

endmodule // mac_engine
