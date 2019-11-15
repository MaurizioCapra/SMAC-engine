`timescale 1ns/1ns

//multiplexer used to choose one of AC3 output to be sent to ReLU

//18/02/2019 just added to support ReLU

module quant_mux
  #(parameter Pa = 8) 
  (input [Pa-1:0] in0, in1, in2, in3,
   input [1:0] sel,
   output reg [Pa-1:0] out_mux);
	
always_comb 
  begin
	if (sel == 2'b00) begin
		out_mux <= in0;
	end else if (sel == 2'b01) begin
		out_mux <= in1;
	end else if (sel == 2'b10) begin
		out_mux <= in2;
	end else if (sel == 2'b11) begin
		out_mux <= in3;
	end
end

endmodule 