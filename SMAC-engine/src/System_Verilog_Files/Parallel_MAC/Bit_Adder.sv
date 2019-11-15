`timescale 1ns/1ns

module bit_adder 
  #(parameter M = 16,
	parameter Pa = 8,
	parameter Pw = 4) 
  (input [M-1:0][Pa+Pw-1:0] in_ba, //M input wires of lentgh Pa+Pw
   output reg [Pa+Pw+$clog2(M)-1:0] out_ba); //if M=16 it will be from 4:0 so you  have 6 bits
	
logic [Pa+Pw+$clog2(M)-1:0] temp_add; 
integer i;
  
always_comb 
  begin
    temp_add = 0;
	for (i=0; i<M; i=i+1) begin
		temp_add = temp_add + in_ba[i][Pa+Pw-1:0];
	end
    out_ba = temp_add;
end

endmodule 