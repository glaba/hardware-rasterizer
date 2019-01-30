module testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, data_in;
logic[17:0] camera_origin[2:0], point[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0];

logic[17:0] u, v, n;
logic data_out;

logic[9:0] triangle_index_in;
logic[9:0] triangle_index_out;

ProjectOntoCamera fp(.*);

logic[7:0] angle, angle_in;
logic[17:0] x, y;
UnitCircle uc(.clock, .angle, .x, .y);

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
	data_in <= 1'b0;

	repeat (1) @(posedge clock);
	reset <= 1'b0;

	angle <= 8'hd6;
	v_vec[2] <= 18'd0; v_vec[1] <= 18'd0; v_vec[0] <= {6'b111111, 12'd0};
	camera_origin[2] <= 18'h3f050; camera_origin[1] <= 18'h01f4c; camera_origin[0] <= 18'h00780;

	repeat (2) @ (posedge clock);
	u_vec[2] <= x; u_vec[1] <= y; u_vec[0] <= 18'd0;
	n_vec[2] <= ~y + 18'd1; n_vec[1] <= x; n_vec[0] <= 18'd0;	

	// (0, 0, 0)
	camera_origin[0] <= 18'd0;
	camera_origin[1] <= 18'd0;
	camera_origin[2] <= 18'd0;

	repeat (1) @ (posedge clock);
	data_in <= 1'b1;
	// (0, 4, 1)
	point[2] <= 18'd0; point[1] <= {6'd4, 12'd0}; point[0] <= {6'd1, 12'd0};

	repeat (1) @ (posedge clock);
	// (0, 4, 0)
	point[2] <= 18'd0; point[1] <= {6'd4, 12'd0}; point[0] <= 18'd0;

	repeat (1) @ (posedge clock);
	// (1, 3, 0)
	point[2] <= {6'd1, 12'd0}; point[1] <= {6'd3, 12'd0}; point[0] <= 18'd0;

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;
end
endmodule