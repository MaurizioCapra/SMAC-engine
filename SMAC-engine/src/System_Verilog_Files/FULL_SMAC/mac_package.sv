/*
 * mac_package.sv
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

import hwpe_stream_package::*;

package mac_package;
	//needed?
  parameter int unsigned MAC_CNT_LEN = 1024; // maximum length of the vectors for a scalar product

  // registers in register file (job_dependant registers in the documentation?)
  //the following are the registers which should hold the base address for the input activations, weights and output activations
  //differently from the provided example, one has been taken out as not needed 
  parameter int unsigned MAC_REG_X_ADDR           = 0; // this is the address for x in TCDM (input act)
  parameter int unsigned MAC_REG_W_ADDR           = 1; // this is the address for W in TCDM (input wei)
  parameter int unsigned MAC_REG_Y_ADDR           = 2; // this is the address for y in TCDM (output act)
  //the following are the addresses containing data to be sent to the 12 RO RF registers in the ucode
  parameter int unsigned MAC_REG_NIF              = 3; // address where number of input features is stored
  parameter int unsigned MAC_REG_NOF              = 4; // address where number of output features is stored
  //parameter int unsigned MAC_REG_OW_X_NOF         = 5; // address where stride to move one pixel down the output is stored
  parameter int unsigned MAC_REG_IW_X_NIF         = 5; // address where stride to move one pixel down conv or input volume is stored
  parameter int unsigned MAC_REG_NFA 	          = 6; // address where the number of fecthed activations per cycle*Pa is stored
  parameter int unsigned MAC_REG_NWA 	          = 7; // address where the number of written activations per cycle*Pa*4*nfil/64 is stored
  parameter int unsigned MAC_REG_ZERO 	          = 8;// address where zero number is stored
  parameter int unsigned MAC_REG_NFW 	          = 9;// address where the number of fecthed weights per cycle is stored: Pw*8*nfil/64
  //the following are the addresses to the RO RF registers (reg_file.hwpe_params in mac_ctrl.sv) where loop ranges are stored
  //in groups of 2 to save space (from inner most to outer most). These don't need to be sent to the ucode RF
  parameter int unsigned MAC_REG_LOOP1_LOOP0	  = 10;//address where loop ranges for loop filter_x and loop_stream_inner are stored
  parameter int unsigned MAC_REG_LOOP3_LOOP2	  = 11;//address where loop ranges for loop_stream_outer and loop_filter_y are stored
  parameter int unsigned MAC_REG_LOOP5_LOOP4	  = 12;//address where loop ranges for loop_spatial_y and loop_spatial_x are stored
  //these are address for quantities in IO_RF to be sent to the lower level control
  parameter int unsigned MAC_REG_CNT_PROG1	  = 13;//address where the values to program low level control counters are stored
  parameter int unsigned MAC_REG_CNT_PROG2	  = 14;//address where the values to program low level control counters are stored
  //the following address of IO RF will contain info concerning how many packets of 128 one expect to send/fetch to/from memory
  //this is not used for input activations as they are fetched one at a time
  parameter int unsigned MAC_REG_ITER_LEN_WEI_OUT = 15; //length of the iteration, this quantity is used by mac_ctrl and sent to top level FSM 
  parameter int unsigned MAC_REG_PAR_SEL 	  = 16;
  
  // microcode offset indeces -- this should be aligned to the microcode compiler of course!
  //again, because of the differences from the provided example, here you just have three offsets instead of 1
  //careful at how you program them, the addresses have to match the code.yml!
  parameter int unsigned MAC_UCODE_W_OFFS = 0;
  parameter int unsigned MAC_UCODE_X_OFFS = 1;
  parameter int unsigned MAC_UCODE_Y_OFFS = 2;
  //this should not be needed
  //parameter int unsigned MAC_UCODE_D_OFFS = 3;

  // microcode mnemonics -- this should be aligned to the microcode compiler of course! WHY -3? because it is readjusted to the 
  // ucode_registers_read definition in mac_ctrl.sv, so here just add the name of your mnemonics and the value will be the 
  //corresponding index for ucode_registers_read in mac_ctrl.sv
  parameter int unsigned MAC_UCODE_MNEM_NIF       = 3 - 3;
  parameter int unsigned MAC_UCODE_MNEM_NOF	  = 4 - 3;
 // parameter int unsigned MAC_UCODE_MNEM_OW_X_NOF  = 5 - 3;
  parameter int unsigned MAC_UCODE_MNEM_IW_X_NIF  = 5 - 3;
  parameter int unsigned MAC_UCODE_MNEM_NFA	  = 6 - 3;
  parameter int unsigned MAC_UCODE_MNEM_NWA  	  = 7 - 3;
  parameter int unsigned MAC_UCODE_MNEM_ZERO	  = 8 - 3;
  parameter int unsigned MAC_UCODE_MNEM_NFW 	  = 9 - 3;

  // the following are parameters used inside mac_engine.sv
  parameter int unsigned Pa  = 8;		 //activations parallelism
  parameter int unsigned Pw  = 8;		 //weights parallelism
  parameter int unsigned M   = 16;		 //number of operands computed by a single SMAC simultaneously
  parameter int unsigned BW  = 128;		 //available bandwidth
  parameter int unsigned MNO = 288;		 //max number of possible 1x1xM volumes during a CONV/FC layer, for VGG 3x3x512/M
  parameter int unsigned MNV = 224*224;  //max number of convolutional volumes to compute for the reference network, here VGG16
   
  // the following two structures are used by mac_engine.sv
  
  typedef struct packed {
	//start signal to trigger the start of the low level FSM
	//logic start;
	// input stage control signals from mac_ctrl.sv to program the low-level FSM counters
	logic [$clog2(MNO)-1:0] max_val_cnt_done;
	logic [$clog2(Pa*Pw)-1:0] max_val_cnt_quant;
	logic [2:0] max_val_cnt_out;
	logic [2:0] max_val_cnt_relu_and_fil_group; //even if used for two different counters they are programmed in the same way
	logic [$clog2(MNV)-1:0] max_val_in_vol;
  logic par_sel_Pa; //activation parallelism selsction
  logic [1:0] par_sel_Pw; //weights parallelism seletion
  } ctrl_engine_t; 

  typedef struct packed {
    // GENERATED BY mac_engine (this is basically the input a_i.valid handshake)
	// the following signal helps higher level FSM to move from UPDATE_IDX state to COMPUTE state
	logic update_in;
	logic update_out;
	//this should not be needed
	// the following signal tells the higher level FSM whether DP is computing something or it is waiting for data
    //logic core_stall_n; 	
  } flags_engine_t;

  //removed b and c streams cause ther're not used here
  typedef struct packed {
    hwpe_stream_package::ctrl_sourcesink_t a_source_ctrl;
    hwpe_stream_package::ctrl_sourcesink_t d_sink_ctrl;
  } ctrl_streamer_t;

  //removed b and c streams cause ther're not used here
  typedef struct packed {
    hwpe_stream_package::flags_sourcesink_t a_source_flags;
    hwpe_stream_package::flags_sourcesink_t d_sink_flags;
  } flags_streamer_t;

  //what is this used for? to generate transaction size and line lenght in the top FSM
  typedef struct packed {
    logic unsigned [$clog2(MAC_CNT_LEN):0] len_wei; // 1 bit more as cnt starts from 1, not 0
	logic unsigned [$clog2(MAC_CNT_LEN):0] len_out; // 1 bit more as cnt starts from 1, not 0
  } ctrl_fsm_t;

  //you could subsitute the following with what is in you basic package
  typedef enum {
    FSM_IDLE,
    FSM_START,
    FSM_LOAD_ACT,
    FSM_COMPUTE_LOAD_WEI,
    FSM_WAIT_IN,
    FSM_WAIT_OUT,
    FSM_UPDATEIDX_IN,
    FSM_UPDATEIDX_OUT,
    FSM_TERMINATE
  } state_fsm_t;

endpackage // mac_package
