`timescale 1ns/1ns

//This blocks apply the activation function to the input quantized data. 

//18/02/2019 Just introduced to apply ReLU to quantized inputs

module quant_ReLU  
  #(parameter Pa = 8) 
	(input [1:0] sel,	//used to select among the 4 different muxes inputs
    input [Pa-1:0]  qin_from_ac3_0, qin_from_ac3_1, qin_from_ac3_2, qin_from_ac3_3,
    output reg [Pa-1:0] out_ReLU);
	
	wire [Pa-1:0] mux_to_ReLU;
	
	quant_mux #(.Pa(Pa)) quantiz_mux ( 
	.in0(qin_from_ac3_0), //qin = quantized input
	.in1(qin_from_ac3_1), 
	.in2(qin_from_ac3_2), 
	.in3(qin_from_ac3_3),
	.sel(sel),
	.out_mux(mux_to_ReLU)
    );
	
	ReLU_mux #(.Pa(Pa)) mux_ReLU (
	.in_from_quant_mux(mux_to_ReLU),
	.out_to_reg(out_ReLU)
	);


endmodule 