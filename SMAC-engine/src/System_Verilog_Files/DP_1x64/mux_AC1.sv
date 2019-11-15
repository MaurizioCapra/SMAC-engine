`timescale 1ns/1ns

module ac1_mux 
  #(parameter M = 16) // dimension of the register
  (input [$clog2(M)+1:0] in_from_add_ac1,
   input [$clog2(M)+1:0] in_from_breg,
   input sel_cl_en,
   output reg [$clog2(M)+1:0] out_to_reg);
	
  
always_comb 
  begin
	if (sel_cl_en) begin
		out_to_reg <= in_from_breg;
	end else begin
		out_to_reg <= in_from_add_ac1;
	end
end

endmodule 