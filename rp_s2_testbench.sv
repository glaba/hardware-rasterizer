module rp_s2_testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, data_in;
logic[35:0] numerator1, numerator2;
logic[35:0] denominator;

logic[7:0] w1, w2;
logic out_of_bounds;
logic data_out;

RP_s2 rp(.*);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1	clock = ~clock;
end

initial begin: CLOCK_INITIALIZATION
	clock = 1;
end 


initial begin: TEST	
	reset <= 1'b1;

	repeat (1) @(posedge clock);
	reset <= 1'b0;

	data_in <= 1'b1;
	denominator <= 36'h731f3c3d8; // 30902830040

	numerator1 <= 36'h4e9ea761f; // 21104326175
	numerator2 <= 36'h4e9ea761f; // 21104326175

	// Exact result should be 0.682925355
	// In Q0.8, this rounds to 0xAE = 0.6796875
	// This should be out of bounds because w3 < 0

	repeat (1) @(posedge clock);
	numerator1 <= 36'h39464E5DC; // 15374542300
	numerator2 <= 36'h39464E5DC; // 15374542300

	assert (data_out == 1'b0);

	// Exact result should be 0.497512438
	// In Q0.8 this rounds to 0x7F, but due to loss of precision, we actually get 0x7E...
	// This should be within bounds because w1 and w2 are between 0 and 1, and w3 > 0

	repeat (1) @(posedge clock);
	denominator <= 36'b100011001110000011000011110000101000; // -30902830040
	numerator1 <= 36'h4e9ea761f; // 21104326175
	numerator2 <= 36'h4e9ea761f; // 21104326175

	assert (data_out == 1'b0);

	// We should get out of bounds

	repeat (1) @(posedge clock);
	denominator <= 36'b100011001110000011000011110000101000; // -30902830040
	numerator1 <= 36'hc6b9b1a24; // -15374542300
	numerator2 <= 36'hc6b9b1a24; // -15374542300

	assert (data_out == 1'b0);

	// We expect the same result as the second input

	repeat (1) @(posedge clock);
	denominator <= 36'h731f3c3d8; // 30902830040
	numerator1 <= 36'hb161589e1; // -21104326175
	numerator2 <= 36'hb161589e1; // -21104326175

	assert (data_out == 1'b0);

	// We should get out of bounds

	repeat (1) @(posedge clock);
	numerator1 <= 36'h985ffa7d8; // 40902830040
	numerator2 <= 36'h985ffa7d8; // 40902830040

	assert (data_out == 1'b0);

	// We should get out of bounds

	// Conveniently, 5 cycles have passed...
	
	// Begin asserts
#1	assert (w1 == 8'hae);
	assert (w2 == 8'hae);
	assert (out_of_bounds == 1'b1);
	assert (data_out == 1'b1);

#2	assert (w1 == 8'h7e);
	assert (w2 == 8'h7e);
	assert (out_of_bounds == 1'b0);
	assert (data_out == 1'b1);

#2	assert (out_of_bounds == 1'b1);
	assert (data_out == 1'b1);

#2	assert (w1 == 8'h7e);
	assert (w2 == 8'h7e);
	assert (out_of_bounds == 1'b0);
	assert (data_out == 1'b1);

#2	assert (out_of_bounds == 1'b1);
	assert (data_out == 1'b1);
	
#2	assert (out_of_bounds == 1'b1);
	assert (data_out == 1'b1);

end
endmodule