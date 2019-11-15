`timescale 1ns/1ns

module SMAC_par 
  #(parameter M = 64,
	parameter Pa = 8,
	parameter Pw = 4) 
   (input clk, rst_n, w_en,
    input [M-1:0][Pa-1:0] in_act,
    input [M-1:0][Pw-1:0] in_wei,//M input wires of lentgh Pa+Pw
    output reg [Pa+Pw+$clog2(M)-1:0] par_sum); //if M=16 it will be from 4:0 so you  have 6 bits
	
    wire [M-1:0][Pw-1:0] wei_to_mul;
	wire [M-1:0][Pa-1:0] act_to_mul;
	wire [M-1:0][Pa+Pw-1:0] mul_to_ba;
	wire [Pa+Pw+$clog2(M)-1:0] to_par_sum;
	
    //generate M input reg for weights
    generate  
 		for (genvar index=0; index < M; index=index+1)  
			begin: in_regs_wei  
			input_register #(.RP(Pw)) inr_wei (  
			.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en),
			.inr(in_wei[index][Pw-1:0]), 
			.outr(wei_to_mul[index][Pw-1:0])
			);  
		end  
	endgenerate 
	
	//generate M input reg for activations
    generate  
 		for (genvar index1=0; index1 < M; index1=index1+1)  
			begin: in_regs_act 
			input_register #(.RP(Pa)) inr_act (  
			.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en),
			.inr(in_act[index1][Pa-1:0]), 
			.outr(act_to_mul[index1][Pa-1:0])
			);  
		end  
	endgenerate 
	
	//generate M multipliers
	generate  
 		for (genvar index2=0; index2 < M; index2=index2+1)  
			begin: mults 
			multip #(.Pa(Pa), .Pw(Pw)) in_mul ( 
			.in2_mul(wei_to_mul[index2][Pw-1:0]), 
			.in1_mul(act_to_mul[index2][Pa-1:0]),
			.out_mul(mul_to_ba[index2][Pa+Pw-1:0])
			);  
		end  
	endgenerate 
	
	//bit adder
	bit_adder #(.M(M), .Pa(Pa), .Pw(Pw)) tree_add (
		.in_ba(mul_to_ba),
		.out_ba(to_par_sum)
	);
	
	//final_reg
	input_register #(.RP(Pa+Pw+$clog2(M))) out_reg (
			.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en),
			.inr(to_par_sum), 
			.outr(par_sum)
	);
	
endmodule 
