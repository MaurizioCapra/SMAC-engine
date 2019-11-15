`timescale 1ns/1ns

//everytime weights are sampled in SMACs increase this counter to help moving through states in FSM (d sig)

//18/02/2019 added parameter to make it generic, changed bit_m name

//06/03/2019 Corrected an error in synthesis: The statements in this 'always' block are outside the scope of the synthesis policy. Only an 'if' statement is allowed at the top level in this always block. Hence, the processees have been separated

//21/08/2019 changed parallelism of Pw from 4 to 8, modified shift register in order to have 3 possible parallelism choices: 4, 6 , 8. Input Selection 
//added (par_sel_Pw): 00 4 bits, 01 6 bits, 10 8 bits, 00 /


module ctrl_cnt_wbit
  #(parameter Pw = 8)
   (input clk, rst_n, w_cnt, cnt_clear,
    input [1:0] par_sel_Pw,
    output logic bit_1, bit_m);

    logic [Pw-1:0] temp;   
/*  
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
	end else if (temp == Pw) begin
		bit_1 = 0;
		bit_m = 0;
	end else begin
		bit_1 = 0;
		bit_m = 0;
	end
end */
/*
always_ff @(posedge clk or negedge rst_n) 
begin
    	if (!rst_n) begin
		temp[Pw-1] <= 1;
		temp[Pw-2:0] <= 0;
	end else if (cnt_clear) begin
		temp[Pw-1] <= 1;
		temp[Pw-2:0] <= 0;
	end else if (w_cnt) begin
		temp <= {temp[Pw-2:0],temp[Pw-1]};
	end
end

assign bit_1 = temp[0];
assign bit_m = temp[Pw-2];

endmodule 
*/


always_ff @(posedge clk or negedge rst_n) 
begin
    	if (!rst_n) begin
		case (par_sel_Pw)
			2'b00 : begin
					temp[Pw-5] <= 1; 
					temp[Pw:Pw-4] <= 0; 
					temp[Pw-6:0] <= 0;
				end
			2'b01 : begin
					temp[Pw-3] <= 1; 
					temp[Pw:Pw-2] <= 0; 
					temp[Pw-4:0] <= 0;
				end
			2'b10 : begin 
					temp[Pw-1] <= 1; 
					temp[Pw-2:0] <= 0;
				end
			default : begin 
					temp[Pw-1] <= 1; 
					temp[Pw-2:0] <= 0;
				  end
		endcase
		
	end else if (cnt_clear) begin
		case (par_sel_Pw)
			2'b00 : begin
					temp[Pw-5] <= 1; 
					temp[Pw:Pw-4] <= 0; 
					temp[Pw-6:0] <= 0;
				end
			2'b01 : begin
					temp[Pw-3] <= 1; 
					temp[Pw:Pw-2] <= 0; 
					temp[Pw-4:0] <= 0;
				end
			2'b10 : begin 
					temp[Pw-1] <= 1; 
					temp[Pw-2:0] <= 0;
				end
			default : begin 
					temp[Pw-1] <= 1; 
					temp[Pw-2:0] <= 0;
				  end
		endcase

	end else if (w_cnt) begin

		case (par_sel_Pw)
			2'b00 : temp <= {temp[Pw-1:Pw-4],temp[Pw-6:0], temp[Pw-5]};
			2'b01 : temp <= {temp[Pw-1:Pw-2],temp[Pw-4:0], temp[Pw-3]};
			2'b10 : temp <= {temp[Pw-2:0],temp[Pw-1]};
			default : temp <= {temp[Pw-2:0],temp[Pw-1]};
		endcase

		
	end
end

assign bit_1 = temp[0];
always_comb case (par_sel_Pw)
	2'b00 : bit_m = temp[Pw-6];
	2'b01 : bit_m = temp[Pw-4];
	2'b10 : bit_m = temp[Pw-2];
	default : bit_m = temp[Pw-2];
endcase

endmodule 
