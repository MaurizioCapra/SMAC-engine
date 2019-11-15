`timescale 1ns/1ns

//this module detects when a positive edge occurs and rises asserts a signal for one cycle after
//the positive edge has been detected

//20/02/2019 a new block to aid FSM

module pos_edge_det	
   (input clk, rst_n, data_in,
    output reg data_out);

reg FF_out;	
  
always_ff @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) begin
		FF_out <= 0;
	end else if (data_in) begin
		FF_out <= 1;
	end else begin
		FF_out <= 0;
	end
end

//output signal generation
assign data_out = data_in & (!FF_out);

endmodule 