/*
 * mac_streamer.sv
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

import mac_package::*;
import hwpe_stream_package::*;

module mac_streamer
#(
  parameter int unsigned MP = 4, // number of master ports
  parameter int unsigned FD = 8  // FIFO depth: try 8 slots and check how it works
)
(
  // global signals
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic                   test_mode_i,
  // local enable & clear
  input  logic                   enable_i,
  input  logic                   clear_i,

  // input a stream + handshake
  hwpe_stream_intf_stream.source a_o, // 128 bit 
  // output d stream + handshake
  hwpe_stream_intf_stream.sink   d_i, // 128 bit

  // TCDM ports
  hwpe_stream_intf_tcdm.master tcdm [MP-1:0], //this is [3:0] hence 4 master ports

  // control channel
  input  ctrl_streamer_t  ctrl_i,
  output flags_streamer_t flags_o
);

  //	 		 | |      | |
  //a_prefifo -->| | FIFO | |--> a_o
  //	 		 | |      | |  
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 128 ) // here you decide the 128 bit width 
  ) a_prefifo ( 		// a_prefifo means the signal is "a" before the fifo and  "a_o" when it passed through the fifo
    .clk ( clk_i )
  );
  //	 		  | |      | |
  //d_postfifo <--| | FIFO | |<-- d_i
  //	 		  | |      | | 
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 128 )
  ) d_postfifo (
    .clk ( clk_i )
  );
  
  //"virtual_tcdm" because if you are istantiating 8 ports but only 4 of these are physically there. All these 8 ports think they are attached to the memory but they actually are not. This is necessary if you are trying to handle 128 bit stream at the input and at the output!
  hwpe_stream_intf_tcdm virtual_tcdm [7:0] (
    .clk ( clk_i )
  );
  // mode 1 - meno efficiente
  hwpe_stream_tcdm_mux #(
    .NB_IN_CHAN  ( 8 ),
    .NB_OUT_CHAN ( 4 )
  ) i_mux (
    .clk_i,
    .rst_ni,
    .clear_i,
    .in  ( virtual_tcdm[7:0] ),
    .out ( tcdm[3:0]         )
  );

  hwpe_stream_source #(
    .DATA_WIDTH ( 128 )
  ) i_a_source (
    .clk_i              ( clk_i                  ),
    .rst_ni             ( rst_ni                 ),
    .test_mode_i        ( test_mode_i            ),
    .clear_i            ( clear_i                ),
    .tcdm               ( virtual_tcdm[3:0]      ), // this syntax is necessary as hwpe_stream_source expects an array of interfaces
    .stream             ( a_prefifo.source       ),
    .ctrl_i             ( ctrl_i.a_source_ctrl   ),
    .flags_o            ( flags_o.a_source_flags )
  );


  hwpe_stream_sink #(
    .DATA_WIDTH ( 128 )
  ) i_d_sink (
    .clk_i       ( clk_i                ),
    .rst_ni      ( rst_ni               ),
    .test_mode_i ( test_mode_i          ),
    .clear_i     ( clear_i              ),
    .tcdm        ( virtual_tcdm[7:4]    ), 
    .stream      ( d_postfifo.sink      ),
    .ctrl_i      ( ctrl_i.d_sink_ctrl   ),
    .flags_o     ( flags_o.d_sink_flags )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH( 128 ),
    .FIFO_DEPTH( 8  ),
    .LATCH_FIFO( 0  )
  ) i_a_fifo (
    .clk_i   ( clk_i          ),
    .rst_ni  ( rst_ni         ),
    .clear_i ( clear_i        ),
    .push_i  ( a_prefifo.sink ),
    .pop_o   ( a_o            ),
    .flags_o (                )
  );

 
  hwpe_stream_fifo #(
    .DATA_WIDTH( 128 ),
    .FIFO_DEPTH( 8  ),
    .LATCH_FIFO( 0  )
  ) i_d_fifo (
    .clk_i   ( clk_i             ),
    .rst_ni  ( rst_ni            ),
    .clear_i ( clear_i           ),
    .push_i  ( d_i               ),
    .pop_o   ( d_postfifo.source ),
    .flags_o (                   )
  );

endmodule // mac_streamer
