`timescale 1ns/1ns

//multiplexer used to apply ReLU

//18/02/2019 reduced parallelism

module ReLU_mux 
  #(parameter Pa = 8) 
  (input [Pa-1:0] in_from_quant_mux,
   output reg [Pa-1:0] out_to_reg);
	
always_comb 
  begin
	if (in_from_quant_mux[Pa-1]==0) begin
		out_to_reg <= in_from_quant_mux;
	end else begin
		out_to_reg <= 0;
	end
end

endmodule 