`timescale 1ns/1ns

//This counter is used both to switch among the muxes in AC2 and AC3 as well as to genereate a remW signal 
//that is used to help the FSM evole through states by telling whether there are any remaining states or not

//20/02/2019 new block to aid FSM

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_fil_group	
   (input clk, rst_n, valid_ac3, cnt_clear, cnt_load,
    input [2:0] max_val, //no parameter because max value is 4 by construction
    output reg remW,
	output reg [1:0] sel_mux_ac); //selection signal to the output mux

reg [2:0] temp, temp_max;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp = 1;
		temp_max = 0; 
    end else if (cnt_clear) begin
		temp = 1;
		temp_max = 0;
	end else if (cnt_load) begin
		temp_max = max_val; //max value is 4 if all 4 mux in are needed
	end else if (valid_ac3) begin
		if (temp < temp_max) begin
			temp = temp + 1;
		end else begin
			temp = 1; 
		end
	end 
end

always_ff @(posedge clk or negedge rst_n) 
begin
	//output signal generation process
    if (!rst_n) begin
		remW = 1;
		//sel_mux_ac = 2'b00;
    end else if (cnt_clear) begin
		remW = 1;
		//sel_mux_ac = 2'b00;
	end else if (temp == temp_max) begin 
		remW = 0;
	end else begin
		remW = 1;
	end	
		
end

always_comb
begin
	//output signal to AC2 and AC3 muxes generation process
	case(temp)
		3'b001 : sel_mux_ac = 2'b00;
		3'b010 : sel_mux_ac = 2'b01;
		3'b011 : sel_mux_ac = 2'b10;
		3'b100 : sel_mux_ac = 2'b11;
		default: sel_mux_ac = 2'b00;
	endcase	
end

endmodule 