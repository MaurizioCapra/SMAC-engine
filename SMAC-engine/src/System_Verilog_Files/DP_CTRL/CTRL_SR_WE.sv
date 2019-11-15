`timescale 1ns/1ns

//shift register out of SMACs determines which group of 8 regs to write (helps moving through states in FSM)
//this does not depend on M... in fact counter counts to 8 regardeless of M=16 or M=32... in the first case it 
//loads 8 16 bit registers per cycle, which in 8 cycles become 64 or it loads 4 32 bit registers per cycle,
//which in 8 cycles become 32 blocks

//18/02/2019 no adjustement required

module ctrl_sr_we
  (input clk, rst_n, s_en, cnt_clear,
   output reg [7:0] par_out);
	
logic [7:0] temp;
  
always_ff @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) begin
		temp <= 1;
	end else if (cnt_clear) begin
		temp <= 1;
	end else if (s_en) begin
		temp <= {temp[6:0],temp[7]};
	end
end

assign par_out = temp;

endmodule 