`timescale 1ns/1ns

//everytime AC2 reg samples something, increase this counter to help moving through states in FSM 

//18/02/2019 added parameter to make it generic

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

//21/08/2019 changed parallelism of Pw from 4 to 8, modified shift register in order to have 3 possible parallelism choices: 4, 6 , 8. Input Selection 
//added (par_sel_Pw): 00 4 bits, 01 6 bits, 10 8 bits, 00 /

module ctrl_cnt_ac2
  #(parameter Pw=8)
   (input clk, rst_n, ac2_cnt, cnt_clear,
    input [1:0] par_sel_Pw,
    output reg term_ac2);

logic [$clog2(Pw):0] temp;   

/*  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp <= 1;
    end else if (cnt_clear) begin
		temp <= 1;
    end else if (ac2_cnt) begin
		if (temp < Pw) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
	end	
end
*/

always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp <= 1;
    end else if (cnt_clear) begin
		temp <= 1;
    end else if (ac2_cnt) begin
	case (par_sel_Pw)
	2'b00 : begin	if (temp < Pw/2) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
		end
	2'b01 : begin	if (temp < Pw-2) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
		end
	2'b10 : begin	if (temp < Pw) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
		end
	default : begin	if (temp < Pw) begin
			temp <= temp + 1;
		end else begin
			temp <= 1; 
		end
		end
	endcase	
	end
end

/*
always_ff @(posedge clk or negedge rst_n)
begin
	//output signal generation process
	if (!rst_n) begin
		term_ac2 <= 0;
    end else if (cnt_clear) begin
		term_ac2 <= 0;
    end else if (temp == Pw) begin 
		term_ac2 <= 1;
	end else begin
		term_ac2 <= 0;
	end
end
*/


always_ff @(posedge clk or negedge rst_n)
begin
	//output signal generation process
	if (!rst_n) begin
		term_ac2 <= 0;
    end else if (cnt_clear) begin
		term_ac2 <= 0;
    end else begin
	case (par_sel_Pw)
	2'b00 : begin if (temp == Pw/2) begin 
			term_ac2 <= 1;
		end else begin
			term_ac2 <= 0;
		end
		end
	2'b01 : begin if (temp == Pw-2) begin 
			term_ac2 <= 1;
		end else begin
			term_ac2 <= 0;
		end
		end
	2'b10 : begin if (temp == Pw) begin 
			term_ac2 <= 1;
		end else begin
			term_ac2 <= 0;
		end
		end
	default : begin if (temp == Pw) begin 
			term_ac2 <= 1;
		end else begin
			term_ac2 <= 0;
		end
		end
	endcase
	end
end

endmodule 
