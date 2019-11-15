`timescale 1ns/1ns

//When AC3 has done with its computation, it generates a done signal that acts as cnt_start
//after count starts, this block generates the shift enable signal that go to the AC3 register to perform
//quantization. When quantiation is done, a done_quant signal is asserted and sent to the control as status
//Only when the FSM will write back the results the count will be reset

//20/02/2019 new block to apply quantization and aid FSM

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_done_quant
  #(parameter Pa = 8,
	parameter Pw = 4)
   (input clk, rst_n, cnt_start, cnt_load, cnt_clear,
    input [$clog2(Pa*Pw)-1:0] max_val, //shifting can't be more than Pa*Pw
    output reg done_quant, s_en_ac3);

reg [$clog2(Pa*Pw)-1:0] temp, temp_max; 
reg hold;  
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal setup process
    if (!rst_n) begin
		temp_max = 0; //only when reset you reset also the max value!
		hold = 0;
    end else if (cnt_clear) begin
		hold = 0;
	end	else if (cnt_load) begin
		temp_max = max_val+1;
	end else if (cnt_start) begin
		hold = 1;
	end	
end

always_ff @(posedge clk or negedge rst_n)
begin
	//internal counting &shift enable assertion process
	if (!rst_n) begin
		temp = 1;
		s_en_ac3 = 0;
    end else if (cnt_clear) begin
		temp = 1;
		s_en_ac3 = 0;
	end else if (hold == 1) begin 
		if (temp < temp_max) begin
			temp = temp + 1;
			s_en_ac3 = 1;
		end else begin
			temp = 1; 
			s_en_ac3 = 0;
		end
	end 
end

always_ff @(posedge clk or negedge rst_n)
begin
	//output signal generation process
	if (!rst_n) begin
		done_quant = 0;
    end else if (cnt_clear) begin
		done_quant = 0;
	end else if (temp == temp_max) begin 
		done_quant = 1;
	end else begin
		done_quant = 0;
	end	
end

endmodule 