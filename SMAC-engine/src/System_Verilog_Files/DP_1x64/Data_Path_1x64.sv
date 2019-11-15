module Data_Path_1x64
	#(parameter M = 16,
	  parameter Pa = 8,
	  parameter Pw = 4,
	  parameter MNO = 288,
	  parameter BW = 128)
	(input clk, rst_n, // control signals common to all batches 
	 
	 //The following have to be included in the control structure ctrl_i
	 // Activ_mod_regs control signals
	 input w_en_mod_a, s_en_mod_a, 
	 // batch 0 control signals
	 input w_en_a, w_en_w, w_en_br, MSB_a, 
	 // batch 1 control signals
	 input w_en_ac1, s_en_ac1, cl_en_ac1, MSB_w, w_en_neg, 
	 // batch 2 control signals 
	 input valid_ac2, s_en_ac2, cl_en_ac2,
	 input [1:0] sel_ac2_ac3, //works both for ac2 and ac3
	 //batch 3 control signals
	 input valid_ac3, cl_en_ac3, 
	 
	 //Signals to enable upload of activations or weights
	 input act_load,
	 input [2:0] wei_load, //this signal enables a group of 8 SMAC to upload values from streamer
	 
	 //signal for writing back to memory
	 input wb,
	 input [1:0] act_wb, //this signal enables a group of 16 SMAC to output the activation values
	 
	 input [BW-1:0] in_data, 
	 //should be on 8 bits as the input activations
	 output reg [BW-1:0] out_data); 

	reg [BW-1:0] activ_in;
	wire [M-1:0] activ_SR_to_SMAC; 
	reg [64-1:0][M-1:0] weights_in;//[#wires][wire dimension]
	wire [64-1:0][$clog2(M)+Pa+Pw+$clog2(MNO):0] SMAC_outs;
	wire [64-1:0][Pa-1:0] activ_out;
	
	//temporary reduction of output to 8 bits to match requirements
	genvar i;
	generate
			for (i=0; i < 64; i=i+1) begin
				assign activ_out[i][Pa-1:0] = SMAC_outs[i][Pa-1:0];
			end
	endgenerate
	
	 
	//generate M activation shift registers: 
	genvar index;  
	generate  
		for (index=0; index < M; index=index+1)  
			begin: activ_sr_gen  
			activ_mod_SR #(.Pa(Pa)) act_sr (  
			.clk(clk),
			.rst_n(rst_n),
			.w_en(w_en_mod_a),
			.s_en(s_en_mod_a),
			.in_par(activ_in[(index*Pa + Pa -1):(index*Pa)]), 
			.out_ser(activ_SR_to_SMAC[index])
			);  
		end  
	endgenerate 
	
	//generate 64 SMAC blocks in vertical direction
	genvar index2;  
	generate  
		for (index2=0; index2 < 64; index2=index2+1)  
			begin: SMAC_gen  
			S_MAC_block #(.M(M), .Pa(Pa), .Pw(Pw), .MNO(MNO)) S_MAC_blocks (  
			.clk(clk),
			.rst_n(rst_n),
			.w_en_a(w_en_a),
			.w_en_w(w_en_w), 
			.w_en_br(w_en_br),
			.MSB_a(MSB_a),
			.w_en_ac1(w_en_ac1),
			.s_en_ac1(s_en_ac1), 
			.cl_en_ac1(cl_en_ac1), 
			.MSB_w(MSB_w),
			.w_en_neg(w_en_neg), 
			.valid_ac2(valid_ac2), 
			.s_en_ac2(s_en_ac2), 
			.cl_en_ac2(cl_en_ac2),
			.sel_ac2_ac3(sel_ac2_ac3),
			.valid_ac3(valid_ac3), 
			.cl_en_ac3(cl_en_ac3), 
			.act(activ_SR_to_SMAC), 
			.wei(weights_in[index2][M-1:0]), 
		    .out_smac(SMAC_outs[index2][$clog2(M)+Pa+Pw+$clog2(MNO):0])
			);  
		end  
	endgenerate 
	 
	 
	genvar j;
	generate
		for (j=0 ; j<16 ; j=j+1) begin
			always_ff @(posedge clk) begin
				if ((act_load == 1) && (wb == 0)) begin
					activ_in[(j*Pa + Pa -1):(j*Pa)] <= in_data[(j*Pa + Pa -1):(j*Pa)];
				end
			end	
		end
	endgenerate
	
	genvar k;
	generate
		for (k=0 ; k<8 ; k=k+1) begin
			always_ff @(posedge clk) begin
				if ((act_load == 0) && (wb == 0)) begin
					if (wei_load == 3'b000) begin
						weights_in[k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end	else if (wei_load == 3'b001) begin
						weights_in[8+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end	else if (wei_load == 3'b010) begin		
						weights_in[16+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end else if (wei_load == 3'b011) begin
						weights_in[24+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end else if (wei_load == 3'b100) begin
						weights_in[32+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end else if (wei_load == 3'b101) begin
						weights_in[40+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end else if (wei_load == 3'b110) begin
						weights_in[48+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end else if (wei_load == 3'b111) begin
						weights_in[56+k][M-1:0] <= in_data[(k*M + M -1):(k*M)];
					end
				end
			end	
		end			
	endgenerate	
	
	genvar h;
	generate
		for (h=0 ; h<16 ; h=h+1) begin
			always_ff @(posedge clk) begin
				if ((act_load == 0) && (wb == 1)) begin
					if (act_wb == 2'b00) begin
						out_data[(h*Pa + Pa -1):(h*Pa)] <= activ_out[h][Pa-1:0];
					end	else if (act_wb == 2'b01) begin
						out_data[(h*Pa + Pa -1):(h*Pa)] <= activ_out[h + 16][Pa-1:0];
					end	else if (act_wb == 2'b10) begin		
						out_data[(h*Pa + Pa -1):(h*Pa)] <= activ_out[h + 32][Pa-1:0];
					end else if (act_wb == 2'b11) begin
						out_data[(h*Pa + Pa -1):(h*Pa)] <= activ_out[h + 48][Pa-1:0];
					end 
				end
			end	
		end			
	endgenerate
	
endmodule
