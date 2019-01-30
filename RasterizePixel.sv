// Latency: 1 cycle
module RP_s1(
	input logic clock, reset, data_in,
	// Index 1 is x, index 0 is y
	input logic[17:0] point[1:0], v1[1:0], v2[1:0], v3[1:0],

	output logic[35:0] numerator1, numerator2,
	output logic data_out
);
	DataValidBuffer data_valid_buffer(.*);

	logic[17:0] x_diff, y_diff;
	assign x_diff = point[1] - v3[1];
	assign y_diff = point[0] - v3[0];

	logic[35:0] partial1_1, partial1_2, partial2_1, partial2_2;
	LPMMult18_18 mult1_1(.dataa(x_diff), .datab(v2[0] - v3[0]), .result(partial1_1));
	LPMMult18_18 mult1_2(.dataa(y_diff), .datab(v3[1] - v2[1]), .result(partial1_2));
	LPMMult18_18 mult2_1(.dataa(x_diff), .datab(v3[0] - v1[0]), .result(partial2_1));
	LPMMult18_18 mult2_2(.dataa(y_diff), .datab(v1[1] - v3[1]), .result(partial2_2));

	logic[35:0] num1_imm, num2_imm;
	assign num1_imm = partial1_1 + partial1_2;
	assign num2_imm = partial2_1 + partial2_2;

	DelayResult #(.WORD_SIZE(36)) delay_num1(.clock, .reset, .result(num1_imm), .delayed_result(numerator1));
	DelayResult #(.WORD_SIZE(36)) delay_num2(.clock, .reset, .result(num2_imm), .delayed_result(numerator2));
endmodule 

module TruncateNums3(
	// The first 3 bits of n2 must contain at least one 1
	input logic[9:0] n1, n2,
	output logic[7:0] t1, t2
);
	logic is_zero_first, is_zero_second;

	always_comb begin 
		is_zero_first = ~n2[9];
		is_zero_second = ~n2[8];

		unique case ({is_zero_first, is_zero_second})
			2'b11:
				begin
					t1 = n1[7:0];
					t2 = n2[7:0];
				end 
			2'b10:
				begin 
					t1 = n1[8:1];
					t2 = n2[8:1];
				end 
			default:
				begin
					t1 = n1[9:2];
					t2 = n2[9:2];
				end
		endcase
	end 
endmodule 

module TruncateNums9(
	// The first 9 bits of n2 must contain at least one 1
	input logic[15:0] n1, n2,
	output logic[7:0] t1, t2
);
	logic[9:0] trunc3_in1;
	logic[9:0] trunc3_in2;

	TruncateNums3 trunc(.n1(trunc3_in1), .n2(trunc3_in2), .t1, .t2);

	logic is_zero_first_3, is_zero_second_3;
	always_comb begin 
		is_zero_first_3 = (n2[15:13] == 3'd0);
		is_zero_second_3 = (n2[12:10] == 3'd0);

		unique case ({is_zero_first_3, is_zero_second_3})
			2'b11: 
				begin
					trunc3_in1 = n1[9:0];
					trunc3_in2 = n2[9:0];
				end
			2'b10:
				begin
					trunc3_in1 = n1[12:3];
					trunc3_in2 = n2[12:3];
				end 
			default:
				begin
					trunc3_in1 = n1[15:6];
					trunc3_in2 = n2[15:6];
				end 
		endcase 
	end 
endmodule 

module TruncateNums18(
	// The first 18 bits of n2 must contain at least one 1
	input logic[24:0] n1, n2,
	output logic[7:0] t1, t2
);
	logic[15:0] trunc9_in1;
	logic[15:0] trunc9_in2;
	
	TruncateNums9 trunc(.n1(trunc9_in1), .n2(trunc9_in2), .t1, .t2);

	always_comb begin 
		if (n2[24:16] == 9'd0) begin 
			trunc9_in1 = n1[15:0];
			trunc9_in2 = n2[15:0];
		end
		else begin 
			trunc9_in1 = n1[24:9];
			trunc9_in2 = n2[24:9];
		end 
	end 
endmodule 

// This returns truncated versions of the absolute values of n1 and n2 if |n1| < |n2| to contain as many significant digits as possible
module TruncateNums36(
	input logic[35:0] n1, n2,
	output logic[7:0] t1, t2
);
	// Compute the absolute values of the inputs
	logic[35:0] n1_a, n2_a;
	assign n1_a = n1[35] ? (~n1 + 36'b1) : n1;
	assign n2_a = n2[35] ? (~n2 + 36'b1) : n2;

	logic[24:0] trunc18_in1;
	logic[24:0] trunc18_in2;

	TruncateNums18 trunc(.n1(trunc18_in1), .n2(trunc18_in2), .t1, .t2);

	always_comb begin 
		if (n2_a[35:18] == 18'd0) begin
			trunc18_in1 = {n1_a[17:0], 7'd0};
			trunc18_in2 = {n2_a[17:0], 7'd0};
		end
		else begin 
			trunc18_in1 = n1_a[35:11];
			trunc18_in2 = n2_a[35:11];
		end
	end
endmodule 

// Performs "partially signed" division with unsigned result, with precision Q36.0 / Q36.0 = Q0.8 
//   under the assumption that |N| < |D| and that sgn(N) = sgn(D) (hence only "partially signed")
// Latency: 5 cycles
module TruncatedDiv36_36(
	input logic clock, reset,
	input logic[35:0] numer, denom,
	output logic[7:0] quotient,
	output logic quotient_is_one
);
	logic[7:0] numer_t, denom_t, numer_t_b, denom_t_b;
	logic[15:0] full_quotient;

	TruncateNums36 trunc(.n1(numer), .n2(denom), .t1(numer_t), .t2(denom_t));
	DelayResult #(.LATENCY(1), .WORD_SIZE(8)) delay_numer(.clock, .reset, .result(numer_t), .delayed_result(numer_t_b));
	DelayResult #(.LATENCY(1), .WORD_SIZE(8)) delay_denom(.clock, .reset, .result(denom_t), .delayed_result(denom_t_b));
	LPMDiv16_8 div(.clock, .numer({numer_t_b, 8'd0}), .denom(denom_t_b), .quotient(full_quotient));

	logic quotient_is_one_imm;
	assign quotient_is_one_imm = (numer_t_b == denom_t_b);
	DelayResult #(.LATENCY(4), .WORD_SIZE(1)) delay_quotient_is_one(.clock, .reset, .result(quotient_is_one_imm), .delayed_result(quotient_is_one));

	assign quotient = full_quotient[7:0];
endmodule

// Latency: 6 cycles
module RP_s2(
	input logic clock, reset, data_in,
	input logic[35:0] numerator1, numerator2,
	input logic[35:0] denominator,

	output logic[7:0] w1, w2,
	output logic out_of_bounds, 
	output logic data_out
);
	DataValidBuffer #(.LATENCY(6)) data_valid_buffer(.*);

	logic diff_signs1, diff_signs2, diff_signs1_d, diff_signs2_d;
	logic[35:0] num1_minus_denom, num2_minus_denom;
	logic num1_minus_denom_sgn, num2_minus_denom_sgn, num1_minus_denom_sgn_d, num2_minus_denom_sgn_d;
	logic num1_sgn, num2_sgn, num1_sgn_d, num2_sgn_d;

	logic oob1, oob2, oob3;
	logic oob_imm;
	logic[7:0] w1_imm, w2_imm;
	logic w1_is_one, w2_is_one;

	TruncatedDiv36_36 div1(.clock, .reset, .numer(numerator1), .denom(denominator), .quotient(w1_imm), .quotient_is_one(w1_is_one));
	TruncatedDiv36_36 div2(.clock, .reset, .numer(numerator2), .denom(denominator), .quotient(w2_imm), .quotient_is_one(w2_is_one));

	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_diff_signs1(.clock, .reset, .result(diff_signs1), .delayed_result(diff_signs1_d));
	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_diff_signs2(.clock, .reset, .result(diff_signs2), .delayed_result(diff_signs2_d));

	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_n1_m_d_sgn(.clock, .reset, .result(num1_minus_denom_sgn), .delayed_result(num1_minus_denom_sgn_d));
	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_n2_m_d_sgn(.clock, .reset, .result(num2_minus_denom_sgn), .delayed_result(num2_minus_denom_sgn_d));

	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_n1_sgn(.clock, .reset, .result(num1_sgn), .delayed_result(num1_sgn_d));
	DelayResult #(.LATENCY(5), .WORD_SIZE(1)) delay_n2_sgn(.clock, .reset, .result(num2_sgn), .delayed_result(num2_sgn_d));

	logic[9:0] w1_plus_w2;
	always_comb begin 
		// Check for coordinate < 0 by seeing if numerator and denominator have opposite signs -> negative result
		diff_signs1 = numerator1[35] ^ denominator[35];
		diff_signs2 = numerator2[35] ^ denominator[35];

		num1_minus_denom = numerator1 - denominator;
		num2_minus_denom = numerator2 - denominator;

		num1_minus_denom_sgn = num1_minus_denom[35];
		num2_minus_denom_sgn = num2_minus_denom[35];

		num1_sgn = numerator1[35];
		num2_sgn = numerator2[35];

		// If numerator and denominator have diff signs, then N/D < 0 which is out of bounds
		if (diff_signs1_d)   oob1 = 1'b1;
		// If both numerator and denominator are negative, then N/D > 1 when N - D < 0
		else if (num1_sgn_d) oob1 = num1_minus_denom_sgn_d;
		// If both numerator and denominator are positive, then N/D > 1 when N - D > 0
		else                 oob1 = ~num1_minus_denom_sgn_d;

		// Same logic for second coordinate
		if (diff_signs2_d)   oob2 = 1'b1;
		else if (num2_sgn_d) oob2 = num2_minus_denom_sgn_d;
		else                 oob2 = ~num2_minus_denom_sgn_d;
	
		// If num ~= denom, then w_imm = 0 due to overflow, so the actual value of w should be 1 0000 0000, rather than 0000 0000
		w1_plus_w2 = {1'b0, w1_is_one, w1_imm} + {1'b0, w2_is_one, w2_imm};
		// Check for w3 < 0, which is true when w1 + w2 > 1 The w3 > 1 case is covered by the w1 < 0 and w2 < 0 checks, so we need not bother
		// w1_plus_w2 is Q2.8, so w1 + w2 > 1 when the 2nd digit is 1
		oob3 = w1_plus_w2[8] | w1_plus_w2[9];

		// Set oob
		oob_imm = oob1 | oob2 | oob3;
	end 

	DelayResult #(.WORD_SIZE(8)) delay_w1(.clock, .reset, .result(w1_imm), .delayed_result(w1));
	DelayResult #(.WORD_SIZE(8)) delay_w2(.clock, .reset, .result(w2_imm), .delayed_result(w2));
	DelayResult #(.WORD_SIZE(1)) delay_oob(.clock, .reset, .result(oob_imm), .delayed_result(out_of_bounds));
endmodule 

// Latency: 1 cycle
module RP_s3(
	input logic clock, reset, data_in,
	input logic[15:0] background_color,
	input logic out_of_bounds,
	input logic[7:0] w1, w2,
	input logic[15:0] color,
	input logic[17:0] d1, d2, d3,

	output logic[15:0] color_out,
	output logic data_out
);
	DataValidBuffer data_valid_buffer(.*);

	logic[35:0] depth_term1, depth_term2, depth_term3;
	// Interpolated depth = w1d1 + w2d2 + (1 - w1 - w2)d3 = w1(d1 - d3) + w2(d2 - d3) + d3
	LPMMult18_18 mult1(.dataa({10'd0, w1}), .datab(d1 - d3), .result(depth_term1));
	LPMMult18_18 mult2(.dataa({10'd0, w2}), .datab(d2 - d3), .result(depth_term2));
	// This is 1 0000 0000 * d3
	assign depth_term3 = {{10{d3[17]}}, d3[17:0], 8'd0};

	logic[35:0] depth;
	logic[35:0] closest_depth;
	logic[35:0] closest_minus_current;
	logic replace_color;

	always_comb begin 
		depth = depth_term1 + depth_term2 + depth_term3;
		closest_minus_current = closest_depth - depth;
		// What each of the terms mean:
		// There is a triangle being processed
		// The current pixel is contained within the triangle
		// The point on the triangle corresponding to the current pixel is not behind the camera
		// The current triangle is closer to the camera than any previous triangle
		replace_color = data_in & ~out_of_bounds & ~depth[35] & ~closest_minus_current[35];
	end

	logic[15:0] closest_color;
	always_ff @ (posedge clock) begin
		if (reset) begin 
			closest_depth <= 36'h7ffffffff;
			closest_color <= background_color;
		end 
		else begin
			closest_depth <= replace_color ? depth : closest_depth;
			closest_color <= replace_color ? color : closest_color;
		end 
	end
	assign color_out = closest_color;
endmodule 

// 7 cycle latency pipeline to rasterize a stream of triangles for a given pixel
// There should be NxN instances of this module, where N is the block size
module RasterizePixel(
	input logic clock, reset, data_in,
	// The color and depths from the triangle provided into the pipeline 6 cycles ago
	input logic[15:0] color,
	input logic[17:0] d1, d2, d3, 	// Depth values in Q6.12
	// The triangle currently being inputted into the pipeline as well as the current point (Q18.0)
	input logic[17:0] point[1:0], v1[1:0], v2[1:0], v3[1:0],
	// Must persist for at least 2 clock cycle past the interval where data_in is high
	input logic[35:0] denominator,

	// These two take the value of the correct color and high 7 cycles after data_in transitions from high to low
	//  which is how the parent module indicates that it is finished streaming triangles
	output logic[15:0] color_out,
	output logic data_out
);
	logic s1_out, s2_out, s3_out;
	
	// Stage 1 output
	logic[35:0] numerator1, numerator2;
	// Stage 2 output
	logic[7:0] w1, w2;
	logic out_of_bounds;

	logic[15:0] color_d;
	logic[17:0] d1_d, d2_d, d3_d;
	logic[35:0] denominator_d;
	DelayResult #(.LATENCY(7), .WORD_SIZE(16)) delay_color(.clock, .reset, .result(color), .delayed_result(color_d));
	DelayResult #(.LATENCY(7)) delay_d1(.clock, .reset, .result(d1), .delayed_result(d1_d));
	DelayResult #(.LATENCY(7)) delay_d2(.clock, .reset, .result(d2), .delayed_result(d2_d));
	DelayResult #(.LATENCY(7)) delay_d3(.clock, .reset, .result(d3), .delayed_result(d3_d));
	DelayResult #(.LATENCY(1), .WORD_SIZE(36)) delay_denominator(.clock, .reset, .result(denominator), .delayed_result(denominator_d));

	RP_s1 s1(.clock, .reset, .data_in, .point, .v1, .v2, .v3, 
                             .data_out(s1_out), .numerator1, .numerator2);
	RP_s2 s2(.clock, .reset, .data_in(s1_out), .numerator1, .numerator2, .denominator(denominator_d),
		                     .data_out(s2_out), .w1, .w2, .out_of_bounds);
	RP_s3 s3(.clock, .reset, .data_in(s2_out), .color(color_d), .d1(d1_d), .d2(d2_d), .d3(d3_d), .background_color(16'd0),
		                                       .w1, .w2, .out_of_bounds,
		                     .data_out(s3_out), .color_out);

	logic prev_data_out;
	always_ff @ (posedge clock) begin
		if (reset)
			prev_data_out <= 1'b0;
		else
			prev_data_out <= s3_out;
	end

	assign data_out = ~s3_out & prev_data_out;
endmodule 