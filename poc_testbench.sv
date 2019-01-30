module poc_testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, data_in;
logic[17:0] camera_origin[2:0], point[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0];

logic[17:0] u, v, n;
logic data_out;

ProjectOntoCamera fp(.*);

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

	// (0, 0, 0)
	camera_origin[0] <= 18'd0;
	camera_origin[1] <= 18'd0;
	camera_origin[2] <= 18'd0;

	// (0, 1, -2) -> (1 / (2 rt 2), 1 / (2 rt 2), 2) -> (501.019336, 421.019336)
	point[2] <= 18'd0; point[1] <= {6'd1, 12'd0}; point[0] <= 18'b111110000000000000;
	// (1/rt(2), 1/rt(2), 0)
	u_vec[2] <= 18'b000000101101010000; u_vec[1] <= 18'b000000101101010000; u_vec[0] <= 18'd0;
	// (-1/rt(2), 1/rt(2), 0)
	v_vec[2] <= 18'b111111010010110000; v_vec[1] <= 18'b000000101101010000; v_vec[0] <= 18'd0;
	// (0, 0, -1)
	n_vec[2] <= 18'd0; n_vec[1] <= 18'd0; n_vec[0] <= {6'b111111, 12'd0};

	data_in <= 1'b1;

	repeat (1) @(posedge clock);

	data_in <= 1'b0;

	repeat (4) @(posedge clock);

	// (1, 1, -3) -> (rt 2 / 3, 0, 3)
	point[2] <= {6'd1, 12'd0}; point[1] = {6'd1, 12'd0}; point[0] = {6'b111101, 12'd0};
	data_in <= 1'b1;

	repeat (1) @(posedge clock);

	data_in <= 1'b0;

	repeat (4) @(posedge clock);

#1	// Offset for assert
	assert (data_out == 1'b1);
	assert (u == 18'b000000000111110101);
	assert (v == 18'b000000000110100101);
	assert (n == 18'b000010000000000000);

#10	assert (data_out == 1'b1);
	assert (u == 18'b000000001000110001);
	assert (v == 18'b000000000011110000);
	assert (n == 18'b000011000000000000);

end
endmodule