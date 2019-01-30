module RenderFrame(
	input logic clock, reset, begin_frame,
	input logic[19:0] SRAM_address_offset,
	input logic[17:0] camera_origin[2:0], u_vec[2:0], v_vec[2:0], n_vec[2:0], light_vec[2:0],
	output logic SRAM_write_enable,
	output logic[19:0] SRAM_address,
	output logic[15:0] SRAM_data,
	output logic completed_frame
);
	parameter[9:0] BLOCK_SIZE = 10'd5;

	// Inclusive bounds
	parameter[9:0] FIRST_COLUMN = 10'd0; //10'd320;  
	parameter[9:0] FIRST_ROW = 10'd0; //10'd400;  
	parameter[9:0] FINAL_COLUMN = 10'd640 - BLOCK_SIZE; //10'd335; 
	parameter[9:0] FINAL_ROW = 10'd480 - BLOCK_SIZE; //10'd410; 

	// The index of the current triangle being read from RAM / finished reading from RAM, respectively
	logic[11:0] cur_triangle, cur_read_triangle;
	// The current state of the state machine that flip flops between projection and rasterization
	enum logic[1:0] {Projection, FinishingProjection, Rasterization, FinishingRasterization} state;
	// The raw triangle data read from the RAMs
	logic[53:0] vert1, vert2, vert3, normal;
	logic[15:0] raw_color;

	// These RAMs store the raw triangle data 
	V1RAM vert1_ram(.clock, .we(1'b0), .read_addr(cur_triangle), .q(vert1));
	V2RAM vert2_ram(.clock, .we(1'b0), .read_addr(cur_triangle), .q(vert2));
	V3RAM vert3_ram(.clock, .we(1'b0), .read_addr(cur_triangle), .q(vert3));
	NormalRAM normal_ram(.clock, .we(1'b0), .read_addr(cur_triangle), .q(normal));
	ColorRAM color_ram(.clock, .we(1'b0), .read_addr(cur_triangle), .q(raw_color));

	DelayResult #(.WORD_SIZE(12)) delay_cur_triangle(.clock, .reset, .result(cur_triangle), .delayed_result(cur_read_triangle));

	// The data_in signal for the ProjectOnCamera pipeline, which is high when the state is Projection (delayed by 1 cycle)
	//  and the color isn't 0
	logic poc_data_in; 
	logic raw_triangle_being_read;
	assign poc_data_in = raw_triangle_being_read & ~(raw_color == 16'd0);

	logic poc_data_out;
	// The index of the triangle currently being outputted from the ProjectOnCamera pipeline
	logic[11:0] poc_triangle_index;
	// The coordinates of the three vertices in camera coordinates that are being outputted from the POC pipeline
	logic[17:0] u1, v1, n1, u2, v2, n2, u3, v3, n3;
	ProjectOntoCamera poc1(.clock, .reset, .data_in(poc_data_in), .triangle_index_in(cur_read_triangle),
	                       .camera_origin, .u_vec, .v_vec, .n_vec,
	                       .point('{vert1[53:36], vert1[35:18], vert1[17:0]}),
		                   .u(u1), .v(v1), .n(n1), .data_out(poc_data_out), .triangle_index_out(poc_triangle_index));
	ProjectOntoCamera poc2(.clock, .reset, .data_in(poc_data_in), .triangle_index_in(cur_read_triangle),
	                       .camera_origin, .u_vec, .v_vec, .n_vec,
	                       .point('{vert2[53:36], vert2[35:18], vert2[17:0]}),
		                   .u(u2), .v(v2), .n(n2));
	ProjectOntoCamera poc3(.clock, .reset, .data_in(poc_data_in), .triangle_index_in(cur_read_triangle),
	                       .camera_origin, .u_vec, .v_vec, .n_vec,
	                       .point('{vert3[53:36], vert3[35:18], vert3[17:0]}),
		                   .u(u3), .v(v3), .n(n3));

	// The shaded color computed combinationally based on the light source and the current triangle normal
	// This entire process from source RAM to destination RAM takes 4 cycles (2 for delaying RAM input, 2 for ComputeColor pipeline)
	logic[15:0] raw_color_d, shaded_color, shaded_color_d;
	logic[53:0] normal_d;
	DelayResult #(.WORD_SIZE(16)) delay_raw_color(.clock, .reset, .result(raw_color), .delayed_result(raw_color_d));
	DelayResult #(.WORD_SIZE(54)) delay_normal(.clock, .reset, .result(normal), .delayed_result(normal_d));
	ComputeColor cc(.clock, .reset, .color_in(raw_color_d), .normal('{normal_d[53:36], normal_d[35:18], normal_d[17:0]}), .light_vec, .color_out(shaded_color));
	DelayResult #(.WORD_SIZE(16)) delay_shaded_color(.clock, .reset, .result(shaded_color), .delayed_result(shaded_color_d));

	// The index of the current projected triangle being read from RAM
	logic[11:0] cur_proj_triangle;
	// The projected triangle data being outputted from RAM
	logic[53:0] pvert1, pvert2, pvert3;
	// The shaded color associated with the projected triangle data currently being read out
	logic[15:0] shaded_color_out;
	ProjectedVertexRAM pv1_ram(.clock, .we(poc_data_out), .write_addr(poc_triangle_index), .data({u1, v1, n1}),
		                                                  .read_addr(cur_proj_triangle), .q(pvert1));
	ProjectedVertexRAM pv2_ram(.clock, .we(poc_data_out), .write_addr(poc_triangle_index), .data({u2, v2, n2}),
		                                                  .read_addr(cur_proj_triangle), .q(pvert2));
	ProjectedVertexRAM pv3_ram(.clock, .we(poc_data_out), .write_addr(poc_triangle_index), .data({u3, v3, n3}),
		                                                  .read_addr(cur_proj_triangle), .q(pvert3));

	logic shaded_color_data_in;
	logic[11:0] shaded_color_addr;
	// Delayed control signals because the input to the RAM is delayed by 2 clock cycles to meet timing
	DelayResult #(.LATENCY(4), .WORD_SIZE(1)) delay_poc_data_in(.clock, .reset, .result(poc_data_in), .delayed_result(shaded_color_data_in));
	DelayResult #(.LATENCY(4), .WORD_SIZE(12)) delay_cur_read_triangle(.clock, .reset, .result(cur_read_triangle), .delayed_result(shaded_color_addr));
	ShadedColorRAM shaded_color_ram(.clock, .we(shaded_color_data_in), .write_addr(shaded_color_addr), .data(shaded_color_d),
		                                                               .read_addr(cur_proj_triangle), .q(shaded_color_out));

	// Coordinates of projected vertices in camera space
	logic[17:0] pu1, pv1, pn1, pu2, pv2, pn2, pu3, pv3, pn3;
	assign {pu1, pv1, pn1} = pvert1;
	assign {pu2, pv2, pn2} = pvert2;
	assign {pu3, pv3, pn3} = pvert3;

	// The top right coordinates in screen space of the current block being rasterized
	logic[9:0] block_location[1:0];
	// This is set by the logic that streams the triangles in 
	logic proj_triangle_being_read;
	logic rb_data_in;
	assign rb_data_in = proj_triangle_being_read & ~(shaded_color_out == 16'd0);
	// The signal outputted by RasterizeBlock that indicates that it is ready to be fed a stream of triangles
	// The signal outputted by RasterizeBlock that indicates that there is pixel data ready to be written to SRAM
	logic rb_ready, rb_data_out;
	// The color that should be written to SRAM 
	logic[15:0] rb_color_out;
	// The location of the current pixel to be written to in SRAM
	logic[9:0] rb_location_out[1:0];
	// This module rasterizes a stream of incoming triangles in a 5x5 block, and in serial, outputs the colors of the pixels
	// within that block in row major order (although it doesn't matter, since there is a location_out signal)
	RasterizeBlock #(.BLOCK_SIZE(BLOCK_SIZE)) rb(.clock, .reset, .data_in(rb_data_in),
		              .color(shaded_color_out), .d1(pn1), .d2(pn2), .d3(pn3), 
		              .vert1('{pu1, pv1}), .vert2('{pu2, pv2}), .vert3('{pu3, pv3}), .block_location,
		              .color_out(rb_color_out), .location_out(rb_location_out), .data_out(rb_data_out), .ready(rb_ready));
	// Takes the output of RasterizeBlock and puts it into a format that can be directly passed into the memory controller
	SerializeBlock sb(.color(rb_color_out), .location(rb_location_out), .data_in(rb_data_out), .address_offset(SRAM_address_offset),
		              .write_enable(SRAM_write_enable), .address(SRAM_address), .data(SRAM_data));

	// Indicates whether we have completed streaming one set of projected triangles through RasterizeBlock
	logic proj_triangles_completed;
	always_ff @ (posedge clock) begin
		block_location[1] <= FIRST_COLUMN;
		block_location[0] <= FIRST_ROW;
		cur_triangle <= 12'd0;
		raw_triangle_being_read <= 1'b0;
		cur_proj_triangle <= 12'd0;
		proj_triangle_being_read <= 1'b0;
		proj_triangles_completed <= 1'b0;

		if (reset) begin 
			state <= Projection;
		end 
		else begin 
			unique case (state)
				// Triangles are actively being streamed out and processed by POC pipeline
				Projection:
					begin
						// Color = 0 is the flag to indicate that there are no more triangles, so go to next state
						if (raw_color == 16'd0) state <= FinishingProjection;
						else begin 
							state <= Projection;
							cur_triangle <= cur_triangle + 12'd1; 
							raw_triangle_being_read <= 1'b1;
						end
					end 
				// Final few cycles while data is still being outputted from POC but no triangles are being inputted
				FinishingProjection: state <= ((poc_data_out) ? Rasterization : FinishingProjection);
				// Triangles are being actively streamed through each block, and each block is pressed sequentially
				Rasterization:
					begin 
						// If RasterizeBlock is ready for another stream of triangles, update the block location
						if (rb_ready) begin 
							// Assuming that the previous block was not the last block, prepare to output triangles next cycle
							// Set this to 1, because the RAM will still be outputting triangle 0 next cycle
							cur_proj_triangle <= 12'd1;
							proj_triangle_being_read <= 1'b1;
							proj_triangles_completed <= 1'b0;

							// If we're on the final column
							if (block_location[1] == FINAL_COLUMN) begin 
								// And we're on the final row, we are finished with rasterization (pending the last few cycles)
								// No more triangles are being streamed
								if (block_location[0] == FINAL_ROW) begin 
									state <= FinishingRasterization;
									proj_triangle_being_read <= 1'b0;
								end 
								// Otherwise, continue rasterization and go to the next row
								else begin
									state <= Rasterization;
									block_location[1] <= FIRST_COLUMN;
									block_location[0] <= block_location[0] + BLOCK_SIZE;
								end 
							end 
							// If we're not on the final column, simply move one column over
							else begin 
								state <= Rasterization;
								block_location[1] <= block_location[1] + BLOCK_SIZE;
								block_location[0] <= block_location[0];
							end
						end 
						// If it is not ready for a new stream of triangles (or it's the first block)
						else begin 
							state <= Rasterization;
							block_location[1] <= block_location[1];
							block_location[0] <= block_location[0];
							// Check to see if the triangle list is completed
							proj_triangles_completed <= (shaded_color_out == 16'd0) | proj_triangles_completed;
							if (shaded_color_out == 16'd0 | proj_triangles_completed) begin
								// If so, set the current triangle back to 0 for the next block, and proj_triangle_being_read to 0
								cur_proj_triangle <= 12'd0;
								proj_triangle_being_read <= 1'b0;
							end 
							else begin 
								// Otherwise, increment triangle and set proj_triangle_being_read to 1
								cur_proj_triangle <= cur_proj_triangle + 12'd1;
								proj_triangle_being_read <= 1'b1;
							end 
						end 
					end 
				// Final few cycles while data for the final block is still being processed but no triangles are being inputted
				FinishingRasterization:	state <= begin_frame ? Projection : FinishingRasterization;
				default: state <= Projection;
			endcase 
		end 
	end 	

	// The frame is complete when we are in the FinishingRasterization state and RB isn't outputting any more data to SRAM
	assign completed_frame = (state == FinishingRasterization) & ~rb_data_out;
endmodule
