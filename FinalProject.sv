module FinalProject(
	input logic clock, reset, cont,
	input logic[15:0] S,

	output logic[7:0] VGA_R, // VGA Red
                      VGA_G, // VGA Green
                      VGA_B, // VGA Blue
	output logic VGA_SYNC_N,  // VGA Sync signal
                 VGA_BLANK_N, // VGA Blank signal
                 VGA_VS,      // VGA virtical sync signal
                 VGA_HS,      // VGA horizontal sync signal
                 VGA_CLK,

    output logic[19:0] ADDR,
    output logic CE, UB, LB, OE, WE,
	inout wire[15:0] Data,
	output logic[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);
	logic reset_v, cont_v;
	assign reset_v = ~reset;
	assign cont_v = ~cont;

	logic rf_completed_frame, dc_completed_frame;
	logic[17:0] camera_origin[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0], light_vec[2:0];
	Motion motion(.clock, .reset(reset_v), .update_position(dc_completed_frame & ~cont_v),
		          .move_left(S[1]), .move_right(S[0]), .move_up(S[3]), .move_down(S[2]), 
	              .turn_left(S[7]), .turn_right(S[6]), .turn_up(1'b0), .turn_down(1'b0),
	              .move_forward(S[5]), .move_backward(S[4]),
		          .camera_origin, .u_vec, .v_vec, .n_vec, .light_vec);

	logic clock_25, clock_100;
	PLL25 pll25(.inclk0(clock), .c0(clock_25));
	PLL100 pll100(.inclk0(clock), .c0(clock_100));
	assign VGA_CLK = clock_25;

	logic write_enable, read_enable;
	logic[15:0] write_data, read_data;
	logic[19:0] write_addr, read_addr;
	SRAMController sram_controller(.clock_100, .reset(reset_v), .read_enable, .write_enable, .write_data, .write_addr, .read_addr,
		                           .CE, .UB, .LB, .OE, .WE, .ADDR, .Data, .read_data);

	logic[19:0] front_buffer_addr, back_buffer_addr;
	logic swapped;
	SwapBuffer sb(.clock, .reset(reset_v), .pause(cont_v), .rf_completed_frame, .dc_completed_frame, .front_buffer_addr, .back_buffer_addr, .swapped);

	DisplayController dc(.clock, .clock_25, .reset(reset_v), .front_buffer_addr, .read_data,
		                 .VGA_R, .VGA_G, .VGA_B, .VGA_SYNC_N, .VGA_BLANK_N, .VGA_VS, .VGA_HS,
		                 .read_enable, .read_addr, .completed_frame(dc_completed_frame));

	logic[31:0] out;
	RenderFrame rf(.clock, .reset(reset_v), .begin_frame(swapped), .SRAM_address_offset(back_buffer_addr), 
		           .camera_origin, .u_vec, .v_vec, .n_vec, .light_vec,
		           .SRAM_write_enable(write_enable), .SRAM_address(write_addr), .SRAM_data(write_data), 
		           .completed_frame(rf_completed_frame));

	HexDriver h7(.In0(out[31:28]), .Out0(HEX7));
	HexDriver h6(.In0(out[27:24]), .Out0(HEX6));
	HexDriver h5(.In0(out[23:20]), .Out0(HEX5));
	HexDriver h4(.In0(out[19:16]), .Out0(HEX4));
	HexDriver h3(.In0(out[15:12]), .Out0(HEX3));
	HexDriver h2(.In0(out[11:8]),  .Out0(HEX2));
	HexDriver h1(.In0(out[7:4]),   .Out0(HEX1));
	HexDriver h0(.In0(out[3:0]),   .Out0(HEX0));
endmodule
