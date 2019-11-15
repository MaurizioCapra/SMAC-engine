`timescale 1ns/1ns

//This is the FSM controlling how computation evolves inside a 3x3 CONV volume. It behaves like a Moore 
//FSM but because of the handshake signal "core_stall_n" it is actually a Mealy FSM

//18/02/2019 additional control signals, handshake signal in input to evolve through states, updated stuff
//20/02/2019 reduced number of states, made all slightly more readable
import basic_package::*;

module ctrl_FSM
   (
    //******GENERAL CONTROL SIGNALS***********//
	input clk, rst_n, 
	
	//******STATUS SIGNALS FROM SOME OUTER BLOCK***********//	
	input core_stall_n, //this is the handshake signal, basically working as a start
		  remW, //signal saying if there are remaining filters before fetching new activations
	
	//******STATUS SIGNALS FROM COUNTERS***********//
  	input cnt_sr_w7, cnt_sr_w6, cnt_sr_w2,
		  bit_1, bit_m,
		  term_ac1, term_ac2, done_quant, op_done, relu_done, last_fil,
		  
	//******CONTROL SIGNALS TO DATA PATH OR COUNTERS***********//
	// input_stage control signals
	output reg act_load, w_en_mod_a, s_en_mod_a, wei_load, 
	//stage_0 control signals
	output reg w_en_a, w_en_w, w_en_br, MSB_a, 
	//stage_1 control signals
	output reg w_and_s_ac1, cl_en_ac1, MSB_w, w_en_neg, 
	//stage_2 control signals
	output reg valid_ac2, cl_en_ac2, 
	//stage_3 control signals
	output reg valid_ac3,   
	//output stage signal
	output reg wb, act_wb,
	//signals to the counters 
	output reg cnt_load, cnt_clear_vol, cnt_in_vol, cl_en_gen, cnt_clear_start, cnt_clear_finish//, 
	//******TEMPORARY SIGNAL TO PRINT OUT PRESENT STATE***********//
	//output ctrl_states out_state
	);


//declare FSM states
ctrl_states present_state, next_state;  

//The following are signals needed to be saved in some FFs and will act as an extension of the memory after the next state evaluation
//so that they will help in the output evaluation without forcing a Mealy behaviour that is intended only for the hanshake signal

//this signal is asserted when B1 stage is entered and deasserted when from B12 one goes to NEG_WRITE, at the NEG_WRITE sate. This
//is the only one that is internally generated
reg bubble, bubble_flag;
//other signals:
reg remW_flag, bit_1_flag, bit_m_flag, last_fil_flag, op_done_flag;

//******TEMPORARY SIGNAL TO PRINT OUT PRESENT STATE***********// 
//assign out_state = present_state; 
  
//***********NEXT STATE EVALUATION*********************

always @(present_state, core_stall_n, cnt_sr_w2, cnt_sr_w6, cnt_sr_w7, term_ac1, term_ac2, done_quant, op_done, relu_done, last_fil, remW)
begin: next_state_eval
	//for every state, if handshake is not valid, hence core_stall_n == 0, then state stays the same
	case(present_state)
		IDLE: 
			if (core_stall_n == 1) begin
				next_state = S1;
			end else begin
				next_state = IDLE;
			end
		S1: 
			if (core_stall_n == 1) begin 
				next_state = S2;
			end else begin
				next_state = S1;
			end
		S2: 
			if (core_stall_n == 1) begin 
				if (cnt_sr_w7 == 0) begin
					next_state = S2;
				end else begin
					next_state = S3;
				end				
			end else begin
				next_state = S2;
			end 
		S3: 
			if (core_stall_n == 1) begin 
				next_state = S4;
			end else begin
				next_state = S3;
			end
		S4:	
			if (core_stall_n == 1) begin	
				next_state = AC1_WRITE;
			end else begin
				next_state = S4;
			end
		AC1_WRITE:
			//writing back is not dependent on handshake
			if (done_quant == 1) begin 
				next_state = WRITE_BACK;
			end 
			//this condition is true only during the very last conv_volume and so no other data must be 
			//fetched and no handshake is needed:
			else if (last_fil == 1 && op_done == 1 && cnt_sr_w7 == 1) begin
				next_state = UPLOAD_DATA;
			end else if (last_fil == 1 && op_done && term_ac1 == 1) begin
				next_state = NEG_WRITE;
			end 
			// when handshake is needed:
			else if (core_stall_n == 1) begin	
				if (cnt_sr_w7 == 0 && term_ac1 == 0) begin
					next_state = AC1_WRITE;
				end else if (cnt_sr_w7 == 1) begin
					next_state = UPLOAD_DATA;
				end  else if (term_ac1 == 1) begin
					next_state = NEG_WRITE;
				end
			end else begin
				next_state = AC1_WRITE; 
			end
		UPLOAD_DATA:
			//when no handshake is needed:
			if (last_fil == 1 && op_done == 1) begin
				next_state = AC1_WRITE;	
			end
			//when handshake is needed:
			else if (core_stall_n == 1) begin
				next_state = AC1_WRITE;				
			end else begin
				next_state = UPLOAD_DATA;
			end
		NEG_WRITE:
			//when hanshake is not needed
			if (last_fil == 1 && op_done == 1) begin
				next_state = AC2_WRITE;
			end
			//when handshake is needed:
			else if (core_stall_n == 1) begin
				next_state = AC2_WRITE;				
			end else begin
				next_state = NEG_WRITE;
			end
		AC2_WRITE: 
			//when no handshake is needed:
			if (last_fil == 1 && op_done == 1 && term_ac2 == 0) begin
				next_state = AC1_WRITE;
			end else if (last_fil == 1 && op_done == 1 && term_ac2 == 1) begin
				next_state = AC3_WRITE;
			end
			//when handshake is needed: 
			else if (core_stall_n == 1) begin
				if (cnt_sr_w2 == 0 && term_ac2 == 0) begin
					next_state =  AC1_WRITE;
				end else if (cnt_sr_w2 == 1 && term_ac2 == 0 ) begin
					next_state = B1;
				end else if (term_ac2 == 1) begin
					next_state = AC3_WRITE;
				end
			end else begin
				next_state = AC2_WRITE;
			end
		B1:
			if (core_stall_n == 1) begin
				if (cnt_sr_w6 == 0) begin
				next_state = B1;				
				end else if (cnt_sr_w6 == 1) begin
				next_state = B2;
				end
			end else begin
				next_state = B1;
			end
		B2: 
			if (core_stall_n == 1) begin 
				next_state = B3;
			end else begin
				next_state = B2;
			end
		B3: 
			if (core_stall_n == 1) begin	
				next_state = NEG_WRITE;
			end else begin
				next_state = B3;
			end
		AC3_WRITE:
			//when no handshake is needed
			if (last_fil == 1 && op_done == 1 && remW == 0) begin
				next_state = WAIT_END;
			end
			//when handshake is needed:
			else if (core_stall_n == 1) begin	
				next_state = AC1_WRITE;
			end else begin
				next_state = AC3_WRITE;
			end
		//from this state on no handshake should be verified to write back in memory	
		WAIT_END:
			if (done_quant == 1) begin
				next_state = WRITE_BACK;
			end else begin
				next_state = WAIT_END;
			end	
		WRITE_BACK:
			if (relu_done == 1) begin
				next_state = FINISH;
			end else begin
				next_state = WRITE_BACK;
			end
		FINISH:
			if (op_done == 1) begin 
				next_state = IDLE;
			end else begin
				next_state = AC1_WRITE;
			end
		default: next_state = IDLE; //If all comparisons fail and the default section is given, then its statements are executed. 
	endcase
end: next_state_eval

//***********SATE UPDATE*******************************

always @(posedge clk or negedge rst_n)
begin: state_update
	if (!rst_n) begin
		present_state <= IDLE;
		bubble_flag <= 0;
		remW_flag <= 0;
		bit_1_flag <= 0;
		bit_m_flag <= 0;
		last_fil_flag <= 0;
		op_done_flag <= 0;
	end else begin
		present_state <= next_state;
		bubble_flag <= bubble;
		remW_flag <= remW;
		bit_1_flag <= bit_1;
		bit_m_flag <= bit_m;
		last_fil_flag <= last_fil;
		op_done_flag <= op_done;
	end
end : state_update

//***********OUTPUT EVALUATION*************************
always @(present_state, core_stall_n) //core_stall_n in sensitivity list makes it a Mealy FSM
begin: output_update
	// set default output values:
	
	cl_en_gen <= 0;
	act_load <= 0;
	w_en_mod_a <= 0;
	s_en_mod_a <= 0;
	wei_load <= 0;
	w_en_a <= 0;
	w_en_w <= 0;
	w_en_br <= 0;
	MSB_a <= 0;
	w_and_s_ac1 <= 0;
	cl_en_ac1 <= 0;
	MSB_w <= 0;
	w_en_neg <=0;
	valid_ac2 <=0;
	cl_en_ac2 <= 0;
	valid_ac3 <= 0;
	act_wb <= 0;
	wb <= 0;
	cnt_load <= 0;
	cnt_clear_vol <= 0;
	cnt_in_vol <= 0;
	cnt_clear_start <= 0; 
	cnt_clear_finish <= 0;
	//only signals to update registers will be deasserted when handshake does not occurr
	
	case(present_state) 
		IDLE: //clear to all important registers and counters
			begin //does not depend on handshake
				cl_en_ac1 <= 1;
				cl_en_ac2 <= 1;
				cl_en_gen <= 1;
				cnt_clear_start <= 1; 
				cnt_clear_finish <= 1;
				cnt_clear_vol <= 1;
				bubble <= 0; // initialize the bubble flag
			end
		S1: 
			begin
				if (core_stall_n == 1) begin
					act_load <= 1;
					cnt_load <= 1;
				end
			end
		S2: 
			begin
				if (core_stall_n == 1) begin
					w_en_mod_a <=1;
					wei_load <=1;
				end
			end
		S3: 
			begin
				if (core_stall_n == 1) begin 
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_w <=1;
					wei_load <=1;
				end
			end
		S4: 
			begin
				if (core_stall_n == 1) begin 
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
				end
			end
		AC1_WRITE:
			begin
				//when hanshake is not needed:
				if (last_fil_flag == 1 && op_done_flag == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1; //in this case it is just needed for counters but not as w_en for weight registers 
					w_and_s_ac1 <= 1;
				end
				//when handshake is needed: 
				else if (core_stall_n == 1) begin 
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
				end
			end
		UPLOAD_DATA: 
			begin
				MSB_a <= 1; 
				//when no handshake is needed
				if (last_fil_flag == 1 && op_done_flag == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_w <= 1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
				end				
				//when handshake is needed
				else if (core_stall_n == 1) begin 
					//upload new weight
					if (remW_flag == 1 || (remW_flag == 0 && bit_m_flag == 0)) begin
						s_en_mod_a <=1;
						w_en_a <=1;
						w_en_w <= 1;
						w_en_br <= 1;
						wei_load <= 1;
						w_and_s_ac1 <= 1;
					end 
					//upload new activation
					else if (remW_flag == 0 && bit_m_flag ==1) begin
						act_load <= 1;
						s_en_mod_a <=1;
						w_en_a <=1;
						w_en_w <= 1;
						w_en_br <= 1;
						w_and_s_ac1 <= 1;
					end
				end
			end	
		NEG_WRITE: 
			begin
				//when no handshake is needed:
				if (last_fil_flag == 1 && op_done_flag == 1) begin
					if (bit_1_flag == 0) begin				
						s_en_mod_a <=1;
						w_en_a <=1;
						w_en_br <= 1;
						wei_load <= 1;
						w_and_s_ac1 <= 1; //"clean write"
						cl_en_ac1 <= 1;
						w_en_neg <= 1;
					end else if (bit_1_flag == 1) begin
						s_en_mod_a <= 1;
						w_en_a <= 1;
						w_en_br <= 1;
						wei_load <= 1;
						w_and_s_ac1 <= 1;
						cl_en_ac1 <= 1;
						w_en_neg <= 1;
						MSB_w <= 1;
					end
				end
				//when handshake is needed:
				else if (core_stall_n == 1) begin
					if (bubble_flag == 1) begin
						s_en_mod_a <= 1;	
						w_en_a <= 1;
						w_en_br <= 1;
						wei_load <= 1;
						cl_en_ac1 <= 1;
						w_en_neg <= 1;
						MSB_w <= 1;
						bubble <= 0; //remove the bubble flag
					end else if (bit_1_flag == 0) begin				
						s_en_mod_a <=1;
						w_en_a <=1;
						w_en_br <= 1;
						wei_load <= 1;
						w_and_s_ac1 <= 1; //"clean write"
						cl_en_ac1 <= 1;
						w_en_neg <= 1;
					end else if (bit_1_flag == 1) begin
						s_en_mod_a <= 1;
						w_en_a <= 1;
						w_en_br <= 1;
						wei_load <= 1;
						w_and_s_ac1 <= 1;
						cl_en_ac1 <= 1;
						w_en_neg <= 1;
						MSB_w <= 1;
					end
				end
			end
		AC2_WRITE: 
			begin
				//when no handshake is needed:
				if (last_fil_flag == 1 && op_done_flag == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
					valid_ac2 <=1;
				end	
				//when handshake is needed:
				else if (core_stall_n == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
					valid_ac2 <=1;
				end	
			end
		//bubble handling states do not occurr when no handshake is needed	
		B1:
			begin
				if (core_stall_n == 1) begin 
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
					bubble <= 1; //set the bubble flag
				end
			end
		B2:
			begin 
				MSB_a <= 1;
				if (core_stall_n == 1) begin
					w_en_mod_a <= 1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
				end
			end
		B3:
			begin
				if (core_stall_n == 1) begin 
					s_en_mod_a <= 1;
					w_en_a <= 1;
					w_en_w <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
				end
			end
		AC3_WRITE:
			begin
				//when no handshake is needed:
				if (last_fil_flag == 1 && op_done_flag == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
					valid_ac3 <= 1;
					cl_en_ac2 <= 1;
				end
				//when handshake is needed:
				else if (core_stall_n == 1) begin
					s_en_mod_a <=1;
					w_en_a <=1;
					w_en_br <= 1;
					wei_load <= 1;
					w_and_s_ac1 <= 1;
					valid_ac3 <= 1;
					cl_en_ac2 <= 1;
				end
			end
		//states where output is written back should not depend on handshake
		WRITE_BACK:
			begin
				act_wb <= 1;
				wb <= 1;
			end
		FINISH:
			begin
				cnt_clear_finish <= 1;
				cnt_in_vol <= 1;
			end
		WAIT_END: // here default values are taken
			begin
			end
	endcase
end: output_update


endmodule 