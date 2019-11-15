`timescale 1ns/1ns

module ac1_reg 
  #(parameter M = 16,
    parameter Pa = 8) // activation operand parallelism
  (input clk, rst_n, w_and_s, cl_en,
   input [$clog2(M):0] inr_ac1, //log2M+2 parallelism
   output reg [$clog2(M)+Pa-1:0] outr_ac1);
	


///*	
always_ff @(posedge clk or negedge rst_n)
begin 
	if (!rst_n) begin
		outr_ac1 <= 0;
	end else if (cl_en == 1 && w_and_s == 0) begin
		outr_ac1 <= 0;
	end else if (cl_en == 1 && w_and_s == 1) begin
		outr_ac1 <= {inr_ac1[$clog2(M):0],{(Pa-1){1'b0}}};
	//end else if (w_en == 1 && s_en ==0 && cl_en == 0) begin //probably useless condition
	//	outr_ac1[$clog2(M)+Pa:Pa-1] = inr_ac1;
	end else if (w_and_s ==1 && cl_en == 0) begin
		outr_ac1 <= {inr_ac1[$clog2(M):0],outr_ac1[Pa-1:1]};
	end	
end
//*/

/*
always_ff @(posedge clk or negedge rst_n)
begin 
	if (~rst_n) begin
		outr_ac1 <= 0;
	end else if (cl_en == 1 && w_en == 0) begin
		outr_ac1 <= 0;
	end else if (cl_en == 1 && w_en == 1) begin
		outr_ac1 <= {inr_ac1,{(Pa-1){1'b0}}};
	//end else if (w_en == 1 && s_en ==0 && cl_en == 0) begin //probably useless condition
	//	outr_ac1[$clog2(M)+Pa:Pa-1] = inr_ac1;
	end else if (w_en == 1 && s_en ==1 && cl_en == 0) begin
		outr_ac1 <= {inr_ac1[$clog2(M)+1],inr_ac1,outr_ac1[Pa-1:1]};
	end	 
end
*/

endmodule 