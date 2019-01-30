// Computes the diffuse factor
module CC_s1(
	input logic clock, reset,
	input logic[17:0] normal[2:0],
	input logic[17:0] light_vec[2:0],

	output logic[7:0] diffuse_factor
);
	parameter[7:0] DIFFUSE_PORTION = 8'd176;

	// Compute normal . light_vec in Q6.12 (really only 1 left bit and 8 right bits matter)
	logic[17:0] cos;
	DotProduct dp(.v1(normal), .v2(light_vec), .result(cos));

	logic[17:0] abs_cos;
	assign abs_cos = cos[17] ? (~cos + 18'd1) : cos;

	logic[35:0] diffuse_factor_raw;
	LPMMult18_18 diffuse_factor_mult(.dataa({9'd0, abs_cos[12:4]}), .datab({10'd0, DIFFUSE_PORTION}), .result(diffuse_factor_raw));
	// If the normal and light_vec are facing the same direction (positive cos), it isn't lit, so make it zero
	// Otherwise, make it the truncated possitive value |dot product * DIFFUSE_PORTION|
	logic[7:0] diffuse_factor_imm;
	assign diffuse_factor_imm = ~cos[17] ? 8'd0 : diffuse_factor_raw[15:8];

	DelayResult #(.WORD_SIZE(8)) delay_diffuse_factor(.clock, .reset, .result(diffuse_factor_imm), .delayed_result(diffuse_factor));
endmodule 

// Computes the diffuse components of the final color
module CC_s2(
	input logic clock, reset,
	input logic[4:0] r_in, b_in,
	input logic[5:0] g_in,
	input logic[7:0] diffuse_factor,

	output logic[4:0] r_diff, b_diff,
	output logic[5:0] g_diff
);
	// Compute diffuse components
	logic[35:0] r_diff_full, g_diff_full, b_diff_full;
	logic[4:0] r_diff_imm, b_diff_imm;
	logic[5:0] g_diff_imm;
	LPMMult18_18 diff_mult_r(.dataa({13'd0, r_in}), .datab({10'd0, diffuse_factor}), .result(r_diff_full));
	LPMMult18_18 diff_mult_g(.dataa({12'd0, g_in}), .datab({10'd0, diffuse_factor}), .result(g_diff_full));
	LPMMult18_18 diff_mult_b(.dataa({13'd0, b_in}), .datab({10'd0, diffuse_factor}), .result(b_diff_full));
	assign r_diff_imm = r_diff_full[12:8];
	assign b_diff_imm = b_diff_full[12:8];
	assign g_diff_imm = g_diff_full[13:8];
	DelayResult #(.WORD_SIZE(5)) delay_r(.clock, .reset, .result(r_diff_imm), .delayed_result(r_diff));
	DelayResult #(.WORD_SIZE(6)) delay_g(.clock, .reset, .result(g_diff_imm), .delayed_result(g_diff));
	DelayResult #(.WORD_SIZE(5)) delay_b(.clock, .reset, .result(b_diff_imm), .delayed_result(b_diff));
endmodule

module ComputeColor(
	input logic clock, reset,
	// 5 bits for red and green, 6 bits for blue
	input logic[15:0] color_in,
	// These two vectors are in Q6.12
	input logic[17:0] normal[2:0],
	input logic[17:0] light_vec[2:0],

	output logic[15:0] color_out
);
	// Q0.8 numbers representing how much of the light is ambient / diffuse
	parameter[7:0] AMBIENT_PORTION = 8'd80;

	// total color = ambient * color + diffuse * (normal . light_vec) * color
	logic[4:0] r_in, b_in, r_out, b_out;
	logic[5:0] g_in, g_out; 

	assign r_in = color_in[15:11];
	assign g_in = color_in[10:5];
	assign b_in = color_in[4:0];

	// Compute the diffuse component with a pipeline
	logic[7:0] diffuse_factor;
	CC_s1 s1(.clock, .reset, .normal, .light_vec, .diffuse_factor);
	
	logic[4:0] r_diff, b_diff;
	logic[5:0] g_diff;
	CC_s2 s2(.clock, .reset, .r_in, .g_in, .b_in, .diffuse_factor, .r_diff, .g_diff, .b_diff);

	// Compute ambient components with a delay of 2 clock cycles to match the calculation of the diffuse components
	logic[35:0] r_amb_full, g_amb_full, b_amb_full;
	logic[4:0] r_amb_imm, b_amb_imm, r_amb, b_amb;
	logic[5:0] g_amb_imm, g_amb;
	LPMMult18_18 amb_mult_r(.dataa({13'd0, r_in}), .datab({10'd0, AMBIENT_PORTION}), .result(r_amb_full));
	LPMMult18_18 amb_mult_g(.dataa({12'd0, g_in}), .datab({10'd0, AMBIENT_PORTION}), .result(g_amb_full));
	LPMMult18_18 amb_mult_b(.dataa({13'd0, b_in}), .datab({10'd0, AMBIENT_PORTION}), .result(b_amb_full));
	assign r_amb_imm = r_amb_full[12:8];
	assign b_amb_imm = b_amb_full[12:8];
	assign g_amb_imm = g_amb_full[13:8];
	DelayResult #(.LATENCY(2), .WORD_SIZE(5)) delay_r_amb(.clock, .reset, .result(r_amb_imm), .delayed_result(r_amb));
	DelayResult #(.LATENCY(2), .WORD_SIZE(6)) delay_g_amb(.clock, .reset, .result(g_amb_imm), .delayed_result(g_amb));
	DelayResult #(.LATENCY(2), .WORD_SIZE(5)) delay_b_amb(.clock, .reset, .result(b_amb_imm), .delayed_result(b_amb));

	assign r_out = r_amb + r_diff;
	assign g_out = g_amb + g_diff;
	assign b_out = b_amb + b_diff;
	assign color_out = {r_out, g_out, b_out};
endmodule 