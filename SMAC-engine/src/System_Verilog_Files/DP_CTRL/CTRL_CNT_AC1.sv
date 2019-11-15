`timescale 1ns/1ns

//everytime AC1 reg samples something, increase this counter to help moving through states in FSM

//18/02/2019 added parameter to make it generic

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_ac1
   #(parameter Pa = 8)
   (input clk, rst_n, ac1_cnt, cnt_clear,
	output reg term_ac1);

reg [$clog2(Pa):0] temp;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp = 1;
    end else if (cnt_clear) begin
		temp = 1;
    end else if (ac1_cnt) begin
		if (temp < Pa) begin
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
		term_ac1 = 0;
	end else if (cnt_clear) begin
		term_ac1 = 0;
	end else if (temp == Pa) begin 
		term_ac1 = 1;
	end else begin
		term_ac1 = 0;
	end
end


endmodule 