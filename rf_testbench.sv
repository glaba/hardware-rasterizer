module rf_testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, begin_frame;
logic[19:0] SRAM_address_offset;
logic[17:0] camera_origin[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0], light_vec[2:0];
logic SRAM_write_enable;
logic[19:0] SRAM_address;
logic[15:0] SRAM_data;
logic completed_frame;

logic[3:0] debug_select;
logic[31:0] debug;

RenderFrame rf(.*);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1	clock = ~clock;
end

initial begin: CLOCK_INITIALIZATION
	clock = 1;
end 

initial begin: TEST
	light_vec[2] <= 18'd0; light_vec[1] <= {6'd1, 12'd0}; light_vec[0] <= 18'd0;

	// i, k, j
	u_vec[2] <= {6'd1, 12'd0}; u_vec[1] <= 18'd0; u_vec[0] <= 18'd0;
	v_vec[2] <= 18'd0; v_vec[1] <= 18'd0; v_vec[0] <= {6'd1, 12'd0};
	n_vec[2] <= 18'd0; n_vec[1] <= {6'd1, 12'd0}; n_vec[0] <= 18'd0;

	// (0, 0, 0)
	camera_origin[2] <= 18'd0; camera_origin[1] <= 18'd0; camera_origin[0] <= 18'd0;

	SRAM_address_offset <= 20'd0;

	reset <= 1'b1;

	repeat (1) @ (posedge clock);
	reset <= 1'b0;	
	begin_frame <= 1'b0;

	repeat (1) @ (posedge completed_frame);
	repeat (1) @ (posedge clock);
	begin_frame <= 1'b1;
	repeat (1) @ (posedge clock);
	begin_frame <= 1'b0;
end
endmodule