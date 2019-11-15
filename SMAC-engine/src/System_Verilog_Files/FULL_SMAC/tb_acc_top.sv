/*
 * tb_acc_top.sv
 * Francesco Conti <fconti@iis.ee.ethz.ch>
 *
 * Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * Unit testbench for acc_top.
 */

timeunit 1ps;
timeprecision 1ps;


//`include "mac_package.sv"


import mac_package::*;

module tb_acc_top;

  // parameters
  parameter PROB_STALL = 0.0;
  parameter TP = 128;
  parameter MEMORY_SIZE = 2*8192*3;
  parameter BASE_ADDR = 0;

  // global signals
  logic                         clk_i  = '0;
  logic                         rst_ni = '1;
  logic                         test_mode_i = '0;
  // local enable
  logic                         enable_i = '1;
  logic                         clear_i  = '0;

  logic randomize_conv     = 1'b0;
  logic force_ready_feat   = 1'b0;
  logic force_ready_weight = 1'b0;
  logic randomize_mem      = 1'b0;
  logic enable_conv   = 1'b1;
  logic enable_feat   = 1'b1;
  logic enable_weight = 1'b1;
  logic enable_mem    = 1'b1;
  int in_len;
  int out_len;
  int threshold_shift;

  hwpe_stream_intf_tcdm tcdm  [TP/32-1:0] (.clk(clk_i));
  hwpe_ctrl_intf_periph periph (.clk(clk_i));

  logic [7:0][1:0] evt;

  logic [TP/32-1:0]       tcdm_req;
  logic [TP/32-1:0]       tcdm_gnt;
  logic [TP/32-1:0][31:0] tcdm_add;
  logic [TP/32-1:0]       tcdm_wen;
  logic [TP/32-1:0][3:0]  tcdm_be;
  logic [TP/32-1:0][31:0] tcdm_data;
  logic [TP/32-1:0][31:0] tcdm_r_data;
  logic [TP/32-1:0]       tcdm_r_valid;

  logic        periph_req;
  logic        periph_gnt;
  logic [31:0] periph_add;
  logic        periph_wen;
  logic [3:0]  periph_be;
  logic [31:0] periph_data;
  logic [15:0] periph_id;
  logic [31:0] periph_r_data;
  logic        periph_r_valid;
  logic [15:0] periph_r_id;

  generate
    for(genvar ii=0; ii<TP/32; ii++) begin : tcdm_binding
      assign tcdm[ii].req  = tcdm_req  [ii];
      assign tcdm[ii].add  = tcdm_add  [ii];
      assign tcdm[ii].wen  = tcdm_wen  [ii];
      assign tcdm[ii].be   = tcdm_be   [ii];
      assign tcdm[ii].data = tcdm_data [ii];
      assign tcdm_gnt     [ii] = tcdm[ii].gnt;
      assign tcdm_r_data  [ii] = tcdm[ii].r_data;
      assign tcdm_r_valid [ii] = tcdm[ii].r_valid;
    end
  endgenerate

  always_comb
  begin
    periph_req  = periph.req;
    periph_add  = periph.add;
    periph_wen  = periph.wen;
    periph_be   = periph.be;
    periph_data = periph.data;
    periph_id   = periph.id;
    periph.gnt     = periph_gnt;
    periph.r_data  = periph_r_data;
    periph.r_valid = periph_r_valid;
    periph.r_id    = periph_r_id;
  end

  `include "tb_acc_common.sv"

  mac_top_wrap #(
    .N_CORES ( 2			),
    .MP  	 ( TP/32        ),
    .ID      ( 16           )
  ) i_dut (
    .clk_i          ( clk_i          ),
    .rst_ni         ( rst_ni         ),
    .test_mode_i    ( test_mode_i    ),
    .evt_o          ( evt            ),
    .tcdm_req       ( tcdm_req       ),
    .tcdm_add       ( tcdm_add       ),
    .tcdm_wen       ( tcdm_wen       ),
    .tcdm_be        ( tcdm_be        ),
    .tcdm_data      ( tcdm_data      ), //data word to be stored Master -> Slave
    .tcdm_gnt       ( tcdm_gnt       ),
    .tcdm_r_data    ( tcdm_r_data    ), //loaded data word Slave -> Master
    .tcdm_r_valid   ( tcdm_r_valid   ),
    .periph_req     ( periph_req     ),
    .periph_gnt     ( periph_gnt     ),
    .periph_add     ( periph_add     ),
    .periph_wen     ( periph_wen     ),
    .periph_be      ( periph_be      ),
    .periph_data    ( periph_data    ),
    .periph_id      ( periph_id      ),
    .periph_r_data  ( periph_r_data  ),
    .periph_r_valid ( periph_r_valid ),
    .periph_r_id    ( periph_r_id    )
  );

  tb_dummy_memory #(
    .MP              ( TP/32       ),
    .MEMORY_SIZE     ( MEMORY_SIZE ),
    .BASE_ADDR       ( BASE_ADDR   ),
    .PROB_STALL      ( PROB_STALL  ),
    .TCP             ( TCP         ),
    .TA              ( TA          ),
    .TT              ( TT          ),
    .INSTRUMENTATION ( 0           )
  ) i_dummy_memory (
    .clk_i       ( clk_i         ),
    .randomize_i ( randomize_mem ),
    .enable_i    ( enable_mem    ),
    .tcdm        ( tcdm          )
  );

  initial begin
    #(20*TCP);

    // Reset phase.
    rst_ni <= #TA 1'b0;
    #(20*TCP);
    rst_ni <= #TA 1'b1;

    for (int i = 0; i < 10; i++)
      cycle();
    rst_ni <= #TA 1'b0;
    for (int i = 0; i < 10; i++)
      cycle();
    rst_ni <= #TA 1'b1;

    randomize_mem <= #TA 1'b1;
    cycle();
    randomize_mem <= #TA 1'b0;

    while(1) begin
      cycle();
    end

  end

  integer f_t0, f_t1;
  integer f_x, f_W, f_y, f_tau;
  logic start;
  initial begin

    integer id;

    f_t0 = $fopen("time_start.txt");
    f_t1 = $fopen("time_stop.txt");
    start = 1'b1;

    periph.req  <= #TA '0;
    periph.add  <= #TA '0;
    periph.wen  <= #TA '0;
    periph.be   <= #TA '0;
    periph.data <= #TA '0;
    periph.id   <= #TA '0;

    #(100*TCP);

    clear_i <= #TA 1'b1;
    #(3*TCP);
    clear_i <= #TA 1'b0;
    #(TCP);

    acc_soft_clear();

    do begin
      acc_acquire_job(id);
    end
	
    while (id < 0);

    out_len <= 2*TP;
    in_len  <= 2*TP;
    threshold_shift <= 8;

    
    // job-independent registers
    acc_set_generic_register(7, 0);
    acc_set_generic_register(6, 32'h62443222); // loops [47:16]
    acc_set_generic_register(5, 32'h12020000); // { loops [15:0], bytecode [175:160] }
    acc_set_generic_register(4, 32'h02324450); // bytecode [159:128]
    acc_set_generic_register(3, 32'h46026324); // bytecode [127:96]
    acc_set_generic_register(2, 32'h45085122); // bytecode [95:64]
    acc_set_generic_register(1, 32'h05426815); // bytecode [63:32]
    acc_set_generic_register(0, 32'h09e05427); // bytecode [31:0]

    // job-dependent registers
    acc_set_register(MAC_REG_X_ADDR, 		32'h00000000);
    acc_set_register(MAC_REG_W_ADDR, 		32'h00004000);
    acc_set_register(MAC_REG_Y_ADDR, 		32'h00012000);
    acc_set_register(MAC_REG_NIF, 		32'h00000080);
    acc_set_register(MAC_REG_NOF, 		32'h00000080);
    acc_set_register(MAC_REG_IW_X_NIF, 		32'h00000010);
    acc_set_register(MAC_REG_NFA, 		32'h00000010);
    acc_set_register(MAC_REG_NWA, 		32'h00000080);
    acc_set_register(MAC_REG_ZERO, 		32'h00000000);
    acc_set_register(MAC_REG_NFW, 		32'h00000400); //00000400
    acc_set_register(MAC_REG_LOOP1_LOOP0, 	32'h00020007); //f , nif/nfa REMEBER +1 added in HW in mac_ctrl.sv
    acc_set_register(MAC_REG_LOOP3_LOOP2, 	32'h00000002); //nof/nwa, f
    acc_set_register(MAC_REG_LOOP5_LOOP4, 	32'h00000000); //oh, ow
    acc_set_register(MAC_REG_CNT_PROG1, 	32'h88000001); //out_mux, relu_mux, max_vol
    acc_set_register(MAC_REG_CNT_PROG2, 	32'h1c000048); //quant_done, done_cnt
    acc_set_register(MAC_REG_ITER_LEN_WEI_OUT, 	32'h00080040);
    acc_set_register(MAC_REG_PAR_SEL , 		32'h00000004); //parallelism selection

	
    acc_trigger_job(); //triggers start

//changed fullstops with _ in the first if condition below
//`ifndef POSTSYNTH
//      if((start==1'b1) && (i_dut_i_mac_top_i_ctrl_i_fsm_curr_state!='0)) begin
//`else
//      if((start==1'b1) && (|(tcdm_req & tcdm_gnt))) begin
//`endif
        $fwrite(f_t0, "%0t\n", $time);
        start = 1'b0;
      //end
      #(TCP);
    end
	
    //while (evt[0][0] != 1'b1);

    //$fwrite(f_t1, "%0t\n", $time);
    //$fclose(f_t0);
    //$fclose(f_t1);

    // // stream out the content of the memory
    // f_x = $fopen("acc_stimuli_x.h");
    // $fwrite(f_x, "__attribute__((section(\".heapsram\"))) __attribute__((aligned(16))) uint8_t stim_x[] = {\n");
    // for(int i=0; i<(in_len)/8; i++) begin
    //   automatic logic [31:0] data = i_dummy_memory.memory[i/4];
    //   case(i%4)
    //     0: begin
    //       $fwrite(f_x, "  0x%02x,\n", data[ 7: 0]);
    //     end
    //     1: begin
    //       $fwrite(f_x, "  0x%02x,\n", data[15: 8]);
    //     end
    //     2: begin
    //       $fwrite(f_x, "  0x%02x,\n", data[23:16]);
    //     end
    //     3: begin
    //       $fwrite(f_x, "  0x%02x,\n", data[31:24]);
    //     end
    //   endcase
    // end
    // $fwrite(f_x, "  0,\n};\n\n");
    // $fclose(f_x);

    // f_y = $fopen("acc_stimuli_y.h");
    // $fwrite(f_y, "__attribute__((section(\".heapsram\"))) __attribute__((aligned(16))) uint8_t stim_y[] = {\n");
    // for(int i=0; i<(out_len)/8; i++) begin
    //   automatic logic [31:0] data = i_dummy_memory.memory[('h2000 >> 2) + i/4];
    //   case(i%4)
    //     0: begin
    //       $fwrite(f_y, "  0x%02x,\n", data[ 7: 0]);
    //     end
    //     1: begin
    //       $fwrite(f_y, "  0x%02x,\n", data[15: 8]);
    //     end
    //     2: begin
    //       $fwrite(f_y, "  0x%02x,\n", data[23:16]);
    //     end
    //     3: begin
    //       $fwrite(f_y, "  0x%02x,\n", data[31:24]);
    //     end
    //   endcase
    // end
    // $fwrite(f_y, "  0,\n};\n\n");
    // $fclose(f_y);

    // f_W = $fopen("acc_stimuli_W.h");
    // $fwrite(f_W, "__attribute__((section(\".heapsram\"))) __attribute__((aligned(16))) uint8_t stim_W[] = {\n");
    // for(int i=0; i<(in_len*out_len)/8; i++) begin
    //   automatic logic [31:0] data = i_dummy_memory.memory[('h1000 >> 2) + i/4];
    //   case(i%4)
    //     0: begin
    //       $fwrite(f_W, "  0x%02x,\n", data[ 7: 0]);
    //     end
    //     1: begin
    //       $fwrite(f_W, "  0x%02x,\n", data[15: 8]);
    //     end
    //     2: begin
    //       $fwrite(f_W, "  0x%02x,\n", data[23:16]);
    //     end
    //     3: begin
    //       $fwrite(f_W, "  0x%02x,\n", data[31:24]);
    //     end
    //   endcase
    // end
    // $fwrite(f_W, "  0,\n};\n\n");
    // $fclose(f_W);

    // f_tau = $fopen("acc_stimuli_tau.h");
    // $fwrite(f_tau, "__attribute__((section(\".heapsram\"))) __attribute__((aligned(16))) uint8_t stim_tau[] = {\n");
    // for(int i=0; i<out_len; i++) begin
    //   automatic logic [31:0] data = i_dummy_memory.memory[('h3000 >> 2) + i/4];
    //   case(i%4)
    //     0: begin
    //       $fwrite(f_tau, "  0x%02x,\n", data[ 7: 0]);
    //     end
    //     1: begin
    //       $fwrite(f_tau, "  0x%02x,\n", data[15: 8]);
    //     end
    //     2: begin
    //       $fwrite(f_tau, "  0x%02x,\n", data[23:16]);
    //     end
    //     3: begin
    //       $fwrite(f_tau, "  0x%02x,\n", data[31:24]);
    //     end
    //   endcase
    // end
    // $fwrite(f_tau, "  0,\n};\n\n");
    // $fclose(f_tau);

    //$finish;

  //end
/*
  tb_acc_memory_observer #(
    .TP  ( TP  ),
    .TCP ( TCP ),
    .TA  ( TA  ),
    .TT  ( TT  )
  ) i_memory_observer (
    .clk_i           ( clk_i           ),
    .clear_i         ( clear_i         ),
    .in_len          ( in_len          ),
    .out_len         ( out_len         ),
    .threshold_shift ( threshold_shift ),
    .tcdm_req        ( tcdm_req        ),
    .tcdm_gnt        ( tcdm_gnt        ),
    .tcdm_add        ( tcdm_add        ),
    .tcdm_wen        ( tcdm_wen        ),
    .tcdm_be         ( tcdm_be         ),
    .tcdm_data       ( tcdm_data       ),
    .tcdm_r_data     ( tcdm_r_data     ),
    .tcdm_r_valid    ( tcdm_r_valid    )
  );
  */
/*
`ifndef POSTSYNTH

  // the engine observer cannot work in post-synthesis, as it requires access to internal signals
  tb_acc_engine_observer #(
    .TP  ( TP  ),
    .TCP ( TCP ),
    .TA  ( TA  ),
    .TT  ( TT  )
  ) i_engine_observer (
    .clk_i             ( clk_i                                                       ),
    .clear_i           ( clear_i                                                     ),
    .ctrl_feat_buf_i   ( tb_acc_top.i_dut.i_acc_top.i_engine.ctrl_i.feat_buf_ctrl    ),
    .ctrl_sop_i        ( tb_acc_top.i_dut.i_acc_top.i_engine.ctrl_i.sop_ctrl         ),
    .feat_valid_i      ( tb_acc_top.i_dut.i_acc_top.i_engine.feat_i.valid            ),
    .feat_data_i       ( tb_acc_top.i_dut.i_acc_top.i_engine.feat_i.data             ),
    .feat_ready_i      ( tb_acc_top.i_dut.i_acc_top.i_engine.feat_i.ready            ),
    .weight_valid_i    ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[0].valid ),
    .weight_data_i     ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[0].data  ),
    .weight_ready_i    ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[0].ready ),
    .threshold_valid_i ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[1].valid ),
    .threshold_data_i  ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[1].data  ),
    .threshold_ready_i ( tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[1].ready ),
    .conv_valid_i      ( tb_acc_top.i_dut.i_acc_top.i_engine.conv_o.valid            ),
    .conv_data_i       ( tb_acc_top.i_dut.i_acc_top.i_engine.conv_o.data             ),
    .conv_ready_i      ( tb_acc_top.i_dut.i_acc_top.i_engine.conv_o.ready            )
  );

  integer f,g,h,l,k,m;
  string str_f, str_g, str_h, str_l, str_k, str_m;

  initial
  begin
    f = $fopen("acc_trace_xnor_data.log");
    g = $fopen("acc_trace_xnor_data_observer.log");
    h = $fopen("acc_trace_acc_data.log");
    l = $fopen("acc_trace_acc_data_observer.log");
    k = $fopen("acc_trace_conv_data.log");
    m = $fopen("acc_trace_conv_data_observer.log");
  end
  final
  begin
    $fclose(f);
  end

  logic sop_hs;
  always_ff @(posedge clk_i)
  begin
    sop_hs <= tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.handshake_pipe[2];
  end

  always_ff @(posedge clk_i)
  begin
    if(tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[0].valid &
       tb_acc_top.i_dut.i_acc_top.i_engine.weight_demuxed[0].ready &
       tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.feat_i.valid &
       tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.feat_i.ready)
    begin
      case(TP)
        32: begin
          $sformat( str_f, "0x%08x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data); $fwrite(f, str_f);
        end
        64: begin
          $sformat( str_f, "0x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data); $fwrite(f, str_f);
        end
        128: begin
          $sformat( str_f, "0x%016x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[127:64], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[63:0]); $fwrite(f, str_f);
        end
        256: begin
          $sformat( str_f, "0x%016x%016x%016x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[255:192], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[191:64], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[127:64], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.xnor_data[63:0]); $fwrite(f, str_f);
        end
      endcase
    end
    if(sop_hs)
    begin
      $fwrite(h, "{");
      for(int i=0; i<TP; i++) begin
        $sformat( str_h, "%04x,", 16'hffff & int'($signed(tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.popcount[i]))); $fwrite(h, str_h);
      end
      $fwrite(h, "}\n");
    end
    if(tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.valid &
       tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.ready)
    begin
      case(TP)
        32: begin
          $sformat( str_k, "0x%08x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data); $fwrite(k, str_k);
        end
        64: begin
          $sformat( str_k, "0x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data); $fwrite(k, str_k);
        end
        128: begin
          $sformat( str_k, "0x%016x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[127:64], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[63:0]); $fwrite(k, str_k);
        end
        256: begin
          $sformat( str_k, "0x%016x%016x%016x%016x\n", tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[255:192], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[191:128], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[127:64], tb_acc_top.i_dut.i_acc_top.i_engine.i_sop.conv_o.data[63:0]); $fwrite(k, str_k);
        end
      endcase
    end
  end

  always_ff @(posedge clk_i)
  begin
    if(tb_acc_top.i_engine_observer.xnor_conv_sample) begin
      case(TP)
        32: begin
          $sformat( str_g, "0x%08x\n", tb_acc_top.i_engine_observer.xnor_conv); $fwrite(g, str_g);
        end
        64: begin
          $sformat( str_g, "0x%016x\n", tb_acc_top.i_engine_observer.xnor_conv); $fwrite(g, str_g);
        end
        128: begin
          $sformat( str_g, "0x%016x%016x\n", tb_acc_top.i_engine_observer.xnor_conv[127:64], tb_acc_top.i_engine_observer.xnor_conv[63:0]); $fwrite(g, str_g);
        end
        256: begin
          $sformat( str_g, "0x%016x%016x%016x%016x\n", tb_acc_top.i_engine_observer.xnor_conv[255:192], tb_acc_top.i_engine_observer.xnor_conv[191:128], tb_acc_top.i_engine_observer.xnor_conv[127:64], tb_acc_top.i_engine_observer.xnor_conv[63:0]); $fwrite(g, str_g);
        end
      endcase
    end
    if(tb_acc_top.i_engine_observer.current_mac_sample) begin
      $fwrite(l, "{");
      for(int i=0; i<TP; i++) begin
        $sformat( str_l, "%04x,", 16'hffff & int'($signed(tb_acc_top.i_engine_observer.current_mac[i]))); $fwrite(l, str_l);
      end
      $fwrite(l, "}\n");
    end
    if(tb_acc_top.i_engine_observer.acc_clr)
    begin
      case(TP)
        32: begin
          $sformat( str_m, "0x%08x\n", tb_acc_top.i_engine_observer.current_pred_conv); $fwrite(m, str_m);
        end
        64: begin
          $sformat( str_m, "0x%016x\n", tb_acc_top.i_engine_observer.current_pred_conv); $fwrite(m, str_m);
        end
        128: begin
          $sformat( str_m, "0x%016x%016x\n", tb_acc_top.i_engine_observer.current_pred_conv[127:64], tb_acc_top.i_engine_observer.current_pred_conv[63:0]); $fwrite(m, str_m);
        end
        256: begin
          $sformat( str_m, "0x%016x%016x%016x%016x\n", tb_acc_top.i_engine_observer.current_pred_conv[255:192], tb_acc_top.i_engine_observer.current_pred_conv[191:128], tb_acc_top.i_engine_observer.current_pred_conv[127:64], tb_acc_top.i_engine_observer.current_pred_conv[63:0]); $fwrite(m, str_m);
        end
      endcase
    end
  end
`endif
*/
endmodule // tb_acc_top
