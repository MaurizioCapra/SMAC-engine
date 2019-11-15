`timescale 1ns/1ns

//This Accumulator accumulates all the partial sums until the final output activation has been obtained
//the value saved in the output registers is then shifted of a pre-programmed value
//to apply quantization down to Pa bits

//18/02/2019 reduced parallelism, internal structure changes
//21/08/2019 changed parallelism of Pw from 4 to 8

module ac3 
  #(parameter M = 16,
    parameter Pa = 8,
    parameter Pw = 8,
    parameter MNO = 288) //Max Number Operands: 3x3xN_filter_max/16 
  (input clk, rst_n, valid, cl_en, s_en,
   input [1:0] w_en,	//used to select among the 4 different registers and muxes inputs
   input [$clog2(M)+Pa+Pw-1:0]  in_from_ac2_0, in_from_ac2_1, in_from_ac2_2, in_from_ac2_3,
   output reg [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] out_ac3_0, out_ac3_1, out_ac3_2, out_ac3_3);
	
	//signal delcaration
	wire [$clog2(M)+Pa+Pw-1:0] in_mux_to_add;
	wire [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] out_to_reg, out_to_reg_mux0, out_to_reg_mux1, out_to_reg_mux2,
	out_to_reg_mux3;
	wire [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] reg_mux_to_add; 	//extended inputs to perform addition
	wire [$clog2(M)+Pa+Pw+$clog2(MNO)-1:0] ex_in_from_ac2;
	logic we_r0, we_r1, we_r2, we_r3;
	
	//MAPPING
	
	//mapping from output to regmux to make things clearer
	assign out_ac3_0 = out_to_reg_mux0;
	assign out_ac3_1 = out_to_reg_mux1;
	assign out_ac3_2 = out_to_reg_mux2;
	assign out_ac3_3 = out_to_reg_mux3;
	
	//generate write enables for registers
	assign we_r0 = (~w_en[1]) & (~w_en[0]) & (valid);
	assign we_r1 = (~w_en[1]) & (w_en[0]) & (valid);
	assign we_r2 = (w_en[1]) & (~w_en[0]) & (valid);
	assign we_r3 = (w_en[1]) & (w_en[0]) & (valid);
	
	//adder 
	ac3_adder #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_a0(
	.in_from_ac2(ex_in_from_ac2),
	.in_from_reg(reg_mux_to_add),
	.out_to_reg(out_to_reg)
	);
	
	//reg0
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register0(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r0),
	.s_en(s_en),
	.cl_en(cl_en),
	.inr(out_to_reg),
	.outr(out_to_reg_mux0)
	);

	//reg1
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register1(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r1),
	.s_en(s_en),
	.cl_en(cl_en),
	.inr(out_to_reg),
	.outr(out_to_reg_mux1)
	);

	//reg2
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register2(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r2),
	.s_en(s_en),
	.cl_en(cl_en),
	.inr(out_to_reg),
	.outr(out_to_reg_mux2)
	);

	//reg3
	ac3_reg #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_register3(
	.clk(clk),
	.rst_n(rst_n),
	.w_en(we_r3),
	.s_en(s_en),
	.cl_en(cl_en),
	.inr(out_to_reg),
	.outr(out_to_reg_mux3)
	);
	
	//input_mux
	ac3_mux #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(1)) ac3_in_mux(
	.in0(in_from_ac2_0),
	.in1(in_from_ac2_1),
	.in2(in_from_ac2_2),
	.in3(in_from_ac2_3),
	.sel_w_en(w_en),
	.out_mux(in_mux_to_add)
	);
	
	//extend the input to match ac3 parallelism
	assign ex_in_from_ac2 = {{($clog2(MNO)){in_mux_to_add[$clog2(M)+Pa+Pw-1]}},in_mux_to_add};

	//reg_mux
	ac3_mux #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) ac3_reg_mux(
	.in0(out_to_reg_mux0),
	.in1(out_to_reg_mux1),
	.in2(out_to_reg_mux2),
	.in3(out_to_reg_mux3),
	.sel_w_en(w_en),
	.out_mux(reg_mux_to_add)
	);


endmodule 
