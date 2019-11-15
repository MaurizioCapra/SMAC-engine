`timescale 1ns/1ns

//everytime AC3 reg samples something, increase this counter to help moving through states in FSM (p sig)
//this counter must be programmable because its max count depends on the number of convolutional volumes
//to compute when moving from one layer to another

//18/02/2019 added parameter to make it generic and a signal to make it programmable

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_done
  #(parameter MNO = 288)	
   (input clk, rst_n, valid_ac3, cnt_load, cnt_clear,
    input [$clog2(MNO)-1:0] max_val, //max value the counter should count to
    output reg done_ac3, last_fil);

reg [$clog2(MNO)-1:0] temp, temp_max;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp = 1;
		temp_max = 0; //only when reset you reset also the max value!
    end else if (cnt_clear) begin
		temp = 1;
	end else if (cnt_load) begin
		temp_max = max_val; //+1 added because the result was stopping one valid_ac3 before the result in the DP
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
		done_ac3 = 0;
		last_fil = 0;
    end else if (cnt_clear) begin
		done_ac3 = 0;
		last_fil =0;
	end else if (temp == max_val - 1) begin 
		last_fil = 1;
		done_ac3 = 0;
	end else if (temp == max_val) begin
		done_ac3 = 1;
		last_fil = 0;
	end else begin
		done_ac3 = 0;
		last_fil = 0;
	end		
end


endmodule 