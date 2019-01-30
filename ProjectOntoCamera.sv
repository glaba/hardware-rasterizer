module POC_s1(
	input logic clock, reset, data_in,
	input logic[17:0] camera_origin[2:0], point[2:0],

	output logic[17:0] camera_to_point[2:0],
	output logic data_out
);
	logic[17:0] immediate_result[2:0];

	DataValidBuffer data_valid_buffer(.*);
	DelayResult delay_result[2:0] (.clock, .reset, .result(immediate_result), .delayed_result(camera_to_point));

	always_comb begin 
		for (int i = 0; i < 3; i++) immediate_result[i] = point[i] - camera_origin[i];
	end
endmodule 

module DotProduct(
	input logic[17:0] v1[2:0], v2[2:0],
	output logic[17:0] result
);
	logic[35:0] terms_full[2:0];
	logic[17:0] terms[2:0];

	LPMMult18_18 multipliers[2:0] (.dataa(v1), .datab(v2), .result(terms_full));

	always_comb begin 
		for (int i = 0; i < 3; i++) terms[i] = terms_full[i][29:12];
	end 

	assign result = terms[2] + terms[1] + terms[0];
endmodule 

module POC_s2(
	input logic clock, reset, data_in,
	input logic[17:0] u_vec[2:0], v_vec[2:0], n_vec[2:0],
	input logic[17:0] camera_to_point[2:0],

	output logic[17:0] u_comp, v_comp, n,
	output logic data_out
);
	logic[17:0] u_comp_imm, v_comp_imm, n_imm;

	DataValidBuffer data_valid_buffer(.*);

	DotProduct u_dp(.v1(u_vec), .v2(camera_to_point), .result(u_comp_imm));
	DotProduct v_dp(.v1(v_vec), .v2(camera_to_point), .result(v_comp_imm));
	DotProduct n_dp(.v1(n_vec), .v2(camera_to_point), .result(n_imm));

	DelayResult delay_u(.clock, .reset, .result(u_comp_imm), .delayed_result(u_comp));
	DelayResult delay_v(.clock, .reset, .result(v_comp_imm), .delayed_result(v_comp));
	DelayResult delay_n(.clock, .reset, .result(n_imm), .delayed_result(n));

endmodule 

module POC_s3(
	input logic clock, reset, data_in,
	input logic[17:0] u_comp, v_comp, n_in,

	output logic[17:0] u_scaled, v_scaled, n_out,
	output logic data_out
);
	logic[29:0] u_scaled_full, v_scaled_full;

	DataValidBuffer #(.LATENCY(8)) data_valid_buffer(.*);

	LPMDiv30_18 u_div(.clock, .numer({u_comp, 12'd0}), .denom(n_in), .quotient(u_scaled_full));
	LPMDiv30_18 v_div(.clock, .numer({v_comp, 12'd0}), .denom(n_in), .quotient(v_scaled_full));
	DelayResult #(.LATENCY(8)) delay_n(.clock, .reset, .result(n_in), .delayed_result(n_out));

	assign u_scaled = u_scaled_full[17:0];
	assign v_scaled = v_scaled_full[17:0];
endmodule 

module POC_s4(
	input logic clock, reset, data_in,
	input logic[17:0] u_scaled, v_scaled, n_in,

	output logic[17:0] u, v, n_out,
	output logic data_out
);

	DataValidBuffer data_valid_buffer(.*);

	// To multiply u_scaled and v_scaled by 2^9 to convert them to camera scale
	// We just pretend that they are not Q6.12 but Q15.3
	// Now, add 320 and 240 respectively
	logic[14:0] u_shifted;
	assign u_shifted = u_scaled[17:3] + 15'd320;
	logic[14:0] v_shifted;
	assign v_shifted = v_scaled[17:3] + 15'd240;

	// Sign extend to 18 bits
	logic[17:0] u_imm;
	assign u_imm = {{3{u_shifted[14]}}, u_shifted};
	logic[17:0] v_imm;
	assign v_imm = {{3{v_shifted[14]}}, v_shifted};

	DelayResult delay_u(.clock, .reset, .result(u_imm), .delayed_result(u));
	DelayResult delay_v(.clock, .reset, .result(v_imm), .delayed_result(v));
	DelayResult delay_n(.clock, .reset, .result(n_in), .delayed_result(n_out));
endmodule 

module ProjectOntoCamera(
	input logic clock, reset, data_in,
	input logic[11:0] triangle_index_in,
	input logic[17:0] camera_origin[2:0], point[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0],

	output logic[17:0] u, v, n,
	output logic data_out,
	output logic[11:0] triangle_index_out
);
	logic data_out_s1, data_out_s2, data_out_s3;
	// Stage 1 output
	logic[17:0] camera_to_point[2:0];
	// Stage 2 output
	logic[17:0] u_comp, v_comp, n_s2;
	// Stage 3 output
	logic[17:0] u_scaled, v_scaled, n_s3;

	POC_s1 s1(.clock, .reset, .data_in, .camera_origin, .point, .camera_to_point, .data_out(data_out_s1));
	POC_s2 s2(.clock, .reset, .data_in(data_out_s1), .u_vec, .v_vec, .n_vec, .camera_to_point, 
		                                             .u_comp, .v_comp, .n(n_s2), .data_out(data_out_s2));
	POC_s3 s3(.clock, .reset, .data_in(data_out_s2), .u_comp, .v_comp, .n_in(n_s2),
		                                             .u_scaled, .v_scaled, .n_out(n_s3), .data_out(data_out_s3));
	POC_s4 s4(.clock, .reset, .data_in(data_out_s3), .u_scaled, .v_scaled, .n_in(n_s3),
		                                             .u, .v, .n_out(n), .data_out);

	DelayResult #(.LATENCY(11), .WORD_SIZE(12)) delay_triangle_index(.clock, .reset, .result(triangle_index_in), .delayed_result(triangle_index_out));
endmodule 