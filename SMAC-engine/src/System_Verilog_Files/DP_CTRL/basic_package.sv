package basic_package;

//define the FSM states:  
//S is an abbreviation for start-up phase
//B is an abbreviation for bubble handling
typedef enum logic[3:0] {IDLE, S1, S2, S3, S4, AC1_WRITE, UPLOAD_DATA, NEG_WRITE, AC2_WRITE, B1, B2, B3,  
						 AC3_WRITE, WRITE_BACK, WAIT_END, FINISH}ctrl_states;	
						 
endpackage