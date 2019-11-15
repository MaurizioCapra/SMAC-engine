`timescale 1ns/1ns

module multip 
  #(parameter Pa = 8,
  parameter Pw =4) 
  (input signed [Pa-1:0] in1_mul, 
   input signed [Pw-1:0] in2_mul,
   output reg signed [Pa+Pw-1:0] out_mul); 
  
always_comb 
  begin
    out_mul = in1_mul*in2_mul;
end

endmodule 