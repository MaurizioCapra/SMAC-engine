`timescale 1ns/1ns

//DP_mux gathers the output of the SMAC blocks that are grouped into four sets. This because the output
//BW is limited to 128 bit.

//18/02/2019 no adjustement required

module DP_mux
  #(parameter BW = 128) // dimension of the register
   (input [BW-1:0] in_from_SMACs1, in_from_SMACs2, in_from_SMACs3, in_from_SMACs4,
    input [1:0] act_wb,
    output reg [BW-1:0] out_mux);
  
always_comb 
  begin
	case( act_wb )
       0 : out_mux = in_from_SMACs1;
       1 : out_mux = in_from_SMACs2;
       2 : out_mux = in_from_SMACs3;
       3 : out_mux = in_from_SMACs4;
   endcase
end

endmodule 