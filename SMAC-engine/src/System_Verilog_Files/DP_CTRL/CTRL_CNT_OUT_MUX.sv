`timescale 1ns/1ns

//during writing back this counter is incremented to get the outputs from the SMAC blocks in order
//this is programmable to support the case when less than 64 filters are used

//20/02/2019 new block to aid FSM

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_out_mux	
   (input clk, rst_n, act_wb, cnt_clear, cnt_load,
    input [2:0] max_val, //no parameter because max value is 4 by construction
    output reg inc_relu_mux_cnt,
	output reg [1:0] sel_mux_out); //selection signal to the output mux

reg [2:0] temp, temp_max;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp = 1;
		temp_max = 0;
    end else if (cnt_clear) begin
		temp = 1;
	end else if (cnt_load) begin
		temp_max = max_val; //max value is 4 if all 4 mux in are needed
	end else if (act_wb) begin
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
	//output signal to CTRL_CNT_ReLU_MUX generation
    if (!rst_n) begin
		inc_relu_mux_cnt = 0;
		//sel_mux_out = 2'b00;
    end else if (cnt_clear) begin
		inc_relu_mux_cnt = 0;
	end else if (temp == max_val) begin 
		inc_relu_mux_cnt = 1;
	end else begin
		inc_relu_mux_cnt = 0;
	end	
	
end

always_comb
begin
	//output signal to output mux generation process
	case(temp)
		3'b001 : sel_mux_out = 2'b00;
		3'b010 : sel_mux_out = 2'b01;
		3'b011 : sel_mux_out = 2'b10;
		3'b100 : sel_mux_out = 2'b11;
		default: sel_mux_out = 2'b00;
	endcase	
end


endmodule 