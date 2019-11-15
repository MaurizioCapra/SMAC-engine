/* 
 * tb_acc_common.sv
 * Francesco Conti <fconti@iis.ee.ethz.ch>
 *
 * Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * Testbench common stuff package.
 */

// ATI timing parameters.
localparam TCP = 3.5ns; // clock period, 1 GHz clock
localparam TA  = 0.7ns; // application time
localparam TT  = 2.8ns; // test time

// Performs one entire clock cycle.
task cycle();
  clk_i <= #(TCP/2) 0;
  clk_i <= #TCP 1;
  #TCP;
endtask

// The following task schedules the clock edges for the next cycle and
// advances the simulation time to that cycles test time (localparam TT)
// according to ATI timings.
task cycle_start();
  clk_i <= #(TCP/2) 0;
  clk_i <= #TCP 1;
  #TT;
endtask

// The following task finishes a clock cycle previously started with
// cycle_start by advancing the simulation time to the end of the cycle.
task cycle_end;
  #(TCP-TT);
endtask

// acc hardware abstraction for testbench
task acc_acquire_job (
  output logic [31:0] id
);
  periph.read (32'h4, id, TCP, TA);
endtask

task acc_soft_clear();
  periph.write(32'h14, 4'hf, 32'h0, TCP, TA);
endtask

task acc_trigger_job;
  periph.write (32'h0, 4'hf, 32'h0, TCP, TA);
endtask

task acc_set_register(
  input int id,
  input logic [31:0] val
);
  logic [31:0] reg_id;
  reg_id = 16*4 + id * 4;
  periph.write (reg_id, 4'hf, val, TCP, TA);
endtask

task acc_set_register_be(
  input int id,
  input logic [3:0]  be,
  input logic [31:0] val
);
  logic [31:0] reg_id;
  reg_id = 16*4 + id * 4;
  periph.write (reg_id, be, val, TCP, TA);
endtask

task acc_set_generic_register(
  input int id,
  input logic [31:0] val
);
  logic [31:0] reg_id;
  reg_id = 8*4 + id * 4;
  periph.write (reg_id, 4'hf, val, TCP, TA);
endtask
