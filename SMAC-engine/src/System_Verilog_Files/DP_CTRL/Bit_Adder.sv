`timescale 1ns/1ns

//This is the adder tree whose input are the outputs of the AND gates

//18/02/2019 reduced parallelism on the output

module bit_adder 
  #(parameter M = 16) // dimension of the register
  (input MSB_a,
   input [M-1:0] in_ba,
   output reg [$clog2(M):0] out_ba); //if M=16 it will be from 4:0 so you  have 5 bits
	
logic [$clog2(M):0] temp_add; 
integer i;
  
always_comb 
  begin
    temp_add = 0;
  if (MSB_a==0)begin
	for (i=0; i<M; i=i+1) begin
		temp_add = temp_add + in_ba[i];
	end
  end else begin
	for (i=0; i<M; i=i+1) begin
		temp_add = temp_add - in_ba[i];
	end
  end
    out_ba = temp_add;
end

endmodule 