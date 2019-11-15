`timescale 1ns/1ns

//This is a counter keeping track of the number of conv volumes computed so that at the FINISH state the FSM knows
//if it needs to continue or go back to IDLE waiting for a new layer to be computed

//20/02/2019 added parameter to make it generic and a signal to make it programmable

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_in_vol
  #(parameter MNV = 224*224)	//max number of conv volumes
   (input clk, rst_n, cnt_in_vol, cnt_load, cnt_clear_vol,
    input [$clog2(MNV)-1:0] max_val, //max value the counter should count to
    output logic op_done); //operations done

logic [$clog2(MNV)-1:0] temp, temp_max;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    	if (!rst_n) begin
		temp     <= 1;
		temp_max <= 0;
    	end else if (cnt_clear_vol) begin
		temp     <= 1;
		temp_max <= 0;
	end else if (cnt_load) begin
		temp_max <= max_val;
	end else if (cnt_in_vol) begin
		if (temp < temp_max) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
	end 	
end

always_ff @(posedge clk or negedge rst_n) 
begin
	//output signal generation process
    	if (!rst_n) begin
		op_done <= 0;
    	end else if (cnt_clear_vol) begin
		op_done <= 0;	
	end else if (temp == max_val) begin 
		op_done <= 1;
	end else begin
		op_done <= 0;
	end		
end

endmodule 
