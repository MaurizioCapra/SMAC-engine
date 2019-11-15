/* 
 * mac_fsm.sv
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
 */
 
 //removed signals to engine because handled by low level FSM

import mac_package::*;
import hwpe_ctrl_package::*;

module mac_fsm (
  // global signals
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                test_mode_i,
  input  logic                clear_i,
  // ctrl & flags
  output ctrl_streamer_t      ctrl_streamer_o,
  input  flags_streamer_t     flags_streamer_i,
  //output ctrl_engine_t        ctrl_engine_o, //not needed 
  input  flags_engine_t       flags_engine_i,
  output ctrl_ucode_t         ctrl_ucode_o,
  input  flags_ucode_t        flags_ucode_i,
  output ctrl_slave_t         ctrl_slave_o,
  input  flags_slave_t        flags_slave_i,
  input  ctrl_regfile_t       reg_file_i,
  input  ctrl_fsm_t           ctrl_i
);

  state_fsm_t curr_state, next_state;
  logic update_sink_flag;

  always_ff @(posedge clk_i or negedge rst_ni)
  begin : main_fsm_seq
    if(~rst_ni) begin
      curr_state <= FSM_IDLE;
    end
    else if(clear_i) begin
      curr_state <= FSM_IDLE;
    end
    else begin
      curr_state <= next_state;
    end
  end

  always_comb
  begin : main_fsm_comb
    // direct mappings - these have to be here due to blocking/non-blocking assignment
    // combination with the same ctrl_engine_o/ctrl_streamer_o variable
    // shift-by-3 due to conversion from bits to bytes
	
	//only two streams are used 
    // a stream when features are fetched
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.trans_size  = 1; //you fetch a single packet of 16 activations in a cycle
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_length = 1; //you fetch a single packet of 16 activations in a cycle
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_X_ADDR] + (flags_ucode_i.offs[MAC_UCODE_X_OFFS]);
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.realign_type = '0;
    
    // d stream (ouput stream)
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.trans_size  = ctrl_i.len_out; //during write back you send (4*num filtri/64) to be written to memory
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.line_length = ctrl_i.len_out;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_Y_ADDR] + (flags_ucode_i.offs[MAC_UCODE_Y_OFFS]);
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.d_sink_ctrl.addressgen_ctrl.realign_type = '0;

    // ucode
    ctrl_ucode_o.accum_loop = '0; // this is not relevant for this simple accelerator, and it should be moved from
                                  // ucode to an accelerator-specific module


    // slave
    ctrl_slave_o.done = '0;
    ctrl_slave_o.evt  = '0;

    // real finite-state machine
    next_state   = curr_state;
    ctrl_streamer_o.a_source_ctrl.req_start = '0;
    ctrl_streamer_o.d_sink_ctrl.req_start   = '0;
    ctrl_ucode_o.enable                     = '0;
    ctrl_ucode_o.clear                      = '0;

    //NOTE: flag_ready_start is a streamer signal that will go low as soon as a req_start is received and it will be
    //asserted again as soon as the called streamer ends its job, that is it reaches the trans_size. Hence, be aware of where such condition
    //in the evolution of the FSM's states is used
    case(curr_state)
		FSM_IDLE: begin
			// wait for a start signal
			ctrl_ucode_o.clear = '1;
			if(flags_slave_i.start) begin
				next_state = FSM_START;
			end
		end
		FSM_START: begin
			// update the indeces, then load the first feature
			if(flags_streamer_i.a_source_flags.ready_start &
			   flags_streamer_i.d_sink_flags.ready_start) begin
				next_state  = FSM_LOAD_ACT;
				ctrl_streamer_o.a_source_ctrl.req_start = 1'b1; //program streamer source to fetch activations
				ctrl_streamer_o.d_sink_ctrl.req_start   = 1'b1; //program streamer sink to write back activations later
			end
			else begin
				next_state = FSM_WAIT_IN;
			end
		end
		FSM_LOAD_ACT: begin
			//by default streamer address is changed again to feature one 
			//condition to fetch weights?
			if(flags_streamer_i.a_source_flags.ready_start) begin
				next_state  = FSM_COMPUTE_LOAD_WEI;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.trans_size  = ctrl_i.len_wei; //(4*8*numfil/64)
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_stride = '0;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_length = ctrl_i.len_wei;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_stride = '0;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_length = 1;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_W_ADDR] + (flags_ucode_i.offs[MAC_UCODE_W_OFFS]);
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_roll   = '0;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.loop_outer  = '0;
				ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.realign_type = '0;
				
				ctrl_streamer_o.a_source_ctrl.req_start = 1'b1; //program streamer to fetch weights
			end
		end
		FSM_COMPUTE_LOAD_WEI: begin
			// change stream address definition because here weights need to be fetched
			//does this code already overwrite?		
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.trans_size  = ctrl_i.len_wei; //(4*8*numfil/64)
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_stride = '0;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.line_length = ctrl_i.len_wei;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_stride = '0;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_length = 1;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_W_ADDR] + (flags_ucode_i.offs[MAC_UCODE_W_OFFS]);
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.feat_roll   = '0;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.loop_outer  = '0;
			ctrl_streamer_o.a_source_ctrl.addressgen_ctrl.realign_type = '0;
			// compute, then update the indeces (and write output if necessary)
			if(flags_engine_i.update_in == 1'b1) begin
				next_state = FSM_UPDATEIDX_IN;
			end else if (flags_engine_i.update_out == 1'b1) begin
				next_state = FSM_UPDATEIDX_OUT;
			end			
		end
		FSM_UPDATEIDX_IN: begin
			// update the input indeces, then go back to load or idle
			if(flags_ucode_i.valid == 1'b0) begin
				ctrl_ucode_o.enable = 1'b1;
			end else if(flags_ucode_i.done) begin
			  	next_state = FSM_TERMINATE; //this condition should actually never happen in this state
			end	
			else if(flags_streamer_i.a_source_flags.ready_start) begin
				next_state = FSM_LOAD_ACT;
			  	ctrl_streamer_o.a_source_ctrl.req_start = 1'b1; 
			end
			else begin
			  	next_state = FSM_WAIT_IN;
			end
		end
		FSM_WAIT_IN: begin
			// wait for the flags to be ok then go back to load
			if(flags_streamer_i.a_source_flags.ready_start) begin
			  	next_state = FSM_LOAD_ACT; 
			  	ctrl_streamer_o.a_source_ctrl.req_start = 1'b1;
			end
		end
		FSM_UPDATEIDX_OUT: begin
			//update the output indeces, then go back to load or idle
			if(flags_ucode_i.valid == 1'b0) begin
				ctrl_ucode_o.enable = 1'b1;
			end else if (flags_ucode_i.done) begin
				next_state = FSM_TERMINATE;
			end
			else if (flags_streamer_i.d_sink_flags.ready_start) begin
				next_state = FSM_LOAD_ACT;
				ctrl_streamer_o.a_source_ctrl.req_start = 1'b1;
				ctrl_streamer_o.d_sink_ctrl.req_start	= 1'b1;
			end
			else begin
				next_state = FSM_WAIT_OUT;
			end
		end
		FSM_WAIT_OUT: begin
			//wait for flags to be ok then go back to load
			if (flags_streamer_i.d_sink_flags.ready_start) begin
				next_state = FSM_LOAD_ACT;
				ctrl_streamer_o.a_source_ctrl.req_start = 1'b1;
				ctrl_streamer_o.d_sink_ctrl.req_start  	= 1'b1;
			end
		end
		FSM_TERMINATE: begin
			// wait for the flags to be ok then go back to idle
			if(flags_streamer_i.a_source_flags.ready_start &
			   flags_streamer_i.d_sink_flags.ready_start) begin
			  next_state = FSM_IDLE;
			  ctrl_slave_o.done = 1'b1;
			end
		end
    endcase // curr_state
  end

endmodule // mac_fsm
