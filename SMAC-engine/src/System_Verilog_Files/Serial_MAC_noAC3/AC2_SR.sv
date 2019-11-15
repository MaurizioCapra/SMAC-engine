`timescale 1ns/1ns

module ac2_reg 
  #(parameter M = 16,
    parameter Pa = 8,
	parameter Pw = 4) // weight operand parallelism
  (input clk, rst_n, w_and_s, cl_en,
   input [$clog2(M)+Pa:0] inr_ac2,
   output reg [$clog2(M)+Pa+Pw-1:0] outr_ac2);
	
always_ff @(posedge clk or negedge rst_n) 
	begin 
		if (!rst_n) begin
			outr_ac2 <= 0;
		end else if (cl_en) begin //for this register there is no need for "clean write"
			outr_ac2 <= 0;
		//end else if (valid == 1 & w_en == 1 & s_en ==0) begin //this is probably an useless conditions
		//	outr_ac2[$clog2(M)+Pa+Pw:Pw] = inr_ac2;
		end else if (w_and_s ==1 & cl_en == 0) begin
			outr_ac2 <= {inr_ac2,outr_ac2[Pw-1:1]};
		end
	end


endmodule 