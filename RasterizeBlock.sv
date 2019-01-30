// Latency: 0 cycles, combinational
module ComputeDenominator(
	input logic[17:0] vert1[1:0], vert2[1:0], vert3[1:0],
	output logic[35:0] denominator
);
	logic[35:0] term1, term2;

	LPMMult18_18 mult1(.dataa(vert2[0] - vert3[0]), .datab(vert1[1] - vert3[1]), .result(term1));
	LPMMult18_18 mult2(.dataa(vert1[0] - vert3[0]), .datab(vert3[1] - vert2[1]), .result(term2));

	assign denominator = term1 + term2;
endmodule 

// Reset is a hard reset, but this will also clear its internal registers when one pass of rasterization completes
// Result is left in a buffer, which is outputted serially for SRAM (2 cycles per pixel)
module RasterizeBlock #(parameter[9:0] BLOCK_SIZE = 5) (
	input logic clock, reset, data_in,
	// The color of the current triangle in 16 bit color
	// 5 bits of red, 6 bits of green, 5 bits of blue
	input logic[15:0] color,
	// Depth values in Q6.12
	input logic[17:0] d1, d2, d3,
	// Triangle vertex values in Q18.0
	input logic[17:0] vert1[1:0], vert2[1:0], vert3[1:0],
	// The location of the top left corner of the block in Q10.0
	input logic[9:0] block_location[1:0],

	// Each pixel is outputted in serial, 2 cycles per color (for now?)
	// Color of the current pixel being outputted
	output logic[15:0] color_out,
	// The coordinates of the current pixel being outputted in Q10.0
	output logic[9:0] location_out[1:0],
	// A signal that indicates that data is being outputted to be written to memory
	output logic data_out, 

	// Indicates that the block is ready to accept another stream of triangles
	output logic ready
);
	logic[35:0] denominator;
	ComputeDenominator cd(.*);

	logic[17:0] coords[BLOCK_SIZE*BLOCK_SIZE-1:0][1:0];

	always_comb begin 
		for (logic[9:0] x = 10'd0; x < BLOCK_SIZE; x++) begin
			for (logic[9:0] y = 10'd0; y < BLOCK_SIZE; y++) begin 
				coords[y * BLOCK_SIZE + x][1] = {8'd0, block_location[1]} + {8'd0, x};
				coords[y * BLOCK_SIZE + x][0] = {8'd0, block_location[0]} + {8'd0, y};
			end 
		end 
	end

	logic rasterization_complete;
	logic loaded_rasterized_data;
	logic serialization_complete;

	logic[15:0] color_out_imm[BLOCK_SIZE*BLOCK_SIZE-1:0];
	logic data_out_imm[BLOCK_SIZE*BLOCK_SIZE-1:0];
	logic reset_rp;

	assign reset_rp = loaded_rasterized_data | reset;

	RasterizePixel rp[BLOCK_SIZE*BLOCK_SIZE-1:0] (.clock, .reset(reset_rp), .data_in, .color, .d1, .d2, .d3, 
		                                  .point(coords), .v1(vert1), .v2(vert2), .v3(vert3), .denominator,
		                                  .color_out(color_out_imm), .data_out(data_out_imm));

	logic[15:0] color_buffer[BLOCK_SIZE*BLOCK_SIZE-1:0];
	logic[9:0] prev_block_location[1:0];
	logic[2:0] cur_serialization_offset[1:0];
	logic cur_serialization_cycle;
	logic[5:0] cur_buffer_offset;
	always_ff @ (posedge clock) begin 
		if (reset) begin 
			serialization_complete <= 1'b1;
			rasterization_complete <= 1'b0;
			loaded_rasterized_data <= 1'b0;
		end
		else begin 
			serialization_complete <= serialization_complete;
			// The rasterized data is loaded into the color buffer when both rasterization and serialization are complete
			loaded_rasterized_data <= rasterization_complete & serialization_complete;

			// If data is being outputted by rp, rasterization is complete
			// We reset this back to 0 when the data is loaded into the color buffero
			if (data_out_imm[0])             rasterization_complete <= 1'b1;
			else if (loaded_rasterized_data) rasterization_complete <= 1'b0;
			else                             rasterization_complete <= rasterization_complete;

			for (int i = 0; i < BLOCK_SIZE * BLOCK_SIZE; i++) begin 
				// If both rasterization and serialization are complete, load the color buffer with the next set of data
				if (rasterization_complete & serialization_complete) begin 
					color_buffer[i] <= color_out_imm[i];
				end 
				else begin
					color_buffer[i] <= color_buffer[i];
				end 
			end

			// The circuit is ready to accept more data when the current block's data has been loaded into the color buffer
			ready <= loaded_rasterized_data & ~ready;

			// Initialization serialization process
			if (loaded_rasterized_data) begin 
				prev_block_location <= block_location;
				cur_serialization_offset <= '{3'd0, 3'd0};
				cur_serialization_cycle <= 1'b0;
				serialization_complete <= 1'b0;
				cur_buffer_offset <= 6'd0;
			end

			// Perform serialization
			if (~serialization_complete) begin 
				data_out <= 1'b1;
				cur_serialization_cycle <= ~cur_serialization_cycle;

				// Update location for next cycle
				if (cur_serialization_cycle == 1'b1) begin
					cur_buffer_offset <= cur_buffer_offset + 6'b1;

					if ({7'd0, cur_serialization_offset[1]} == BLOCK_SIZE - 1'd1) begin 
						if ({7'd0, cur_serialization_offset[0]} == BLOCK_SIZE - 1'd1) begin 
							// We don't care what happens to the offset here
							serialization_complete <= 1'b1;
						end 
						else begin 
							serialization_complete <= 1'b0;
							cur_serialization_offset[1] <= 3'd0;
							cur_serialization_offset[0] <= cur_serialization_offset[0] + 3'd1;
						end 
					end 
					else begin 
						serialization_complete <= 1'b0;
						cur_serialization_offset[1] <= cur_serialization_offset[1] + 3'd1;
						cur_serialization_offset[0] <= cur_serialization_offset[0];
					end 
				end 
				else begin 
					// Keep the same location if we are not done writing
					serialization_complete <= 1'b0;
					cur_buffer_offset <= cur_buffer_offset;
					cur_serialization_offset[1] <= cur_serialization_offset[1];
					cur_serialization_offset[0] <= cur_serialization_offset[0];
				end 

				// Output the current location
				location_out[1] <= prev_block_location[1] + {7'd0, cur_serialization_offset[1]};
				location_out[0] <= prev_block_location[0] + {7'd0, cur_serialization_offset[0]};			

				// Output the color for the corresponding pixel
				color_out <= color_buffer[cur_buffer_offset];
			end
			else begin 
				data_out <= 1'b0;
			end 
		end
	end 
endmodule