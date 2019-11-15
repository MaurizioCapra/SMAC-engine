`timescale 1ns/1ns

//multiplexer used in the accumulator AC1 which allows to write 
//a new value in the AC1_SR.sv coming directly from the Bit_Register.sv
//thus allowing "continuous mode"

//18/02/2019 reduced parallelism

module ac1_mux 
  #(parameter M = 16) 
  (input [$clog2(M):0] in_from_add_ac1,
   input [$clog2(M):0] in_from_breg,
   input sel_cl_en,
   output reg [$clog2(M):0] out_to_reg);
	
always_comb 
  begin
	if (sel_cl_en) begin
		out_to_reg <= in_from_breg;
	end else begin
		out_to_reg <= in_from_add_ac1;
	end
end

endmodule 