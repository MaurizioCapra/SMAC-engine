`timescale 1ns/1ns

//everytime weights are sampled in SMACs increase this counter to help moving through states in FSM (d sig)

//18/02/2019 added parameter to make it generic, changed bit_m name

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

module ctrl_cnt_wbit
  #(parameter Pw = 4)
   (input clk, rst_n, w_cnt, cnt_clear,
    output reg bit_1, bit_m);

reg [$clog2(Pw):0] temp;   
  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp = 0;
    end else if (cnt_clear) begin
		temp = 0;
    end else if (w_cnt) begin
		if (temp < Pw) begin
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
		bit_1 = 0;
		bit_m = 0;
    end else if (cnt_clear) begin
		bit_1 = 0;
		bit_m = 0;
    end else if (temp == 1) begin 
		bit_1 = 1;
		bit_m = 0;
	end else if (temp == Pw-1) begin
		bit_1 = 0;
		bit_m = 1;
	end else begin
		bit_1 = 0;
		bit_m = 0;
	end
end

endmodule 