`timescale 1ns/1ns

//everytime AC1 reg samples something, increase this counter to help moving through states in FSM

//18/02/2019 added parameter to make it generic

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

//21/08/2019 Input Selection added (par_sel_Pa): 0 4 bits, 1 8 bits. This signal allows to chose the maximum value of the counter

module ctrl_cnt_ac1
   #(parameter Pa = 8)
   (input clk, rst_n, ac1_cnt, cnt_clear,
    input par_sel_Pa,
    output logic term_ac1);

logic [$clog2(Pa):0] temp;   

/*  
always_ff @(posedge clk or negedge rst_n) 
begin
	//internal counting process
    if (!rst_n) begin
		temp <= 1;
    end else if (cnt_clear) begin
		temp <= 1;
    end else if (ac1_cnt) begin
		if (temp < Pa) begin
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
    end else if (ac1_cnt) begin
		if (par_sel_Pa) begin
			if (temp < Pa) begin
				temp <= temp + 1;
			end else begin
				temp <= 1; 
			end
		end else begin
			if (temp < Pa/2) begin
				temp <= temp + 1;
			end else begin
				temp <= 1; 
			end
		end
	end 
end

/*
always_ff @(posedge clk or negedge rst_n)
begin
	//output signal generation process
	if (!rst_n) begin		
		term_ac1 <= 0;
	end else if (cnt_clear) begin
		term_ac1 <= 0;
	end else if (temp == Pa-1) begin 
		term_ac1 <= 1;
	end else begin
		term_ac1 <= 0;
	end
end
*/

always_ff @(posedge clk or negedge rst_n)
begin
	//output signal generation process
	if (!rst_n) begin		
		term_ac1 <= 0;
	end else if (cnt_clear) begin
		term_ac1 <= 0;
	end else if (par_sel_Pa) begin 
		if (temp == Pa-1) begin 
			term_ac1 <= 1;
		end
		else begin
			term_ac1 <= 0;
		end
	end else begin
		if (temp == Pa/2-1) begin 
			term_ac1 <= 1;
		end
		else begin
			term_ac1 <= 0;
		end
	end
end


endmodule 
