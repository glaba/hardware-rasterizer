module SwapBuffer(
	input logic clock, reset, pause, rf_completed_frame, dc_completed_frame,
	output logic[19:0] front_buffer_addr, back_buffer_addr,
	output logic swapped
);
	parameter[19:0] BUFFER_1 = 20'd0;
	parameter[19:0] BUFFER_2 = 20'd614400;

	// This is an offset to make the glitches caused by the slow SRAM slots to only last for a fraction of a second
	// at any given location 
	logic [19:0] cur_total_offset, prev_total_offset;

	logic cur_buffer_state;
	logic swap, swap_posedge;
	// We should swap if both the rasterizer and the VGA controller are finished with their frame
	assign swap = rf_completed_frame & dc_completed_frame;
	DetectPosedge detect_swap_posedge(.clock, .reset, .signal(swap), .signal_posedge(swap_posedge));

	always_ff @ (posedge clock) begin 
		if (reset) begin 
			cur_buffer_state <= 1'b0;
			prev_total_offset <= 20'd0;
			cur_total_offset <= 20'd0;
			swapped <= 1'b1;
		end 
		else if (pause) begin 
			cur_buffer_state <= cur_buffer_state;
			prev_total_offset <= prev_total_offset;
			cur_total_offset <= cur_total_offset;
			swapped <= 1'b0;
		end 
		else begin 
			if (swap_posedge) begin
				cur_buffer_state <= ~cur_buffer_state;
				prev_total_offset <= cur_total_offset;

				if (cur_total_offset[15] == 1'b1) cur_total_offset <= 20'd0;
				else                              cur_total_offset <= cur_total_offset + 20'd2300;
			end 
			else begin
				cur_buffer_state <= cur_buffer_state;
				prev_total_offset <= prev_total_offset;
				cur_total_offset <= cur_total_offset;
			end 

			swapped <= swap_posedge;
		end 
	end 

	assign front_buffer_addr = (cur_buffer_state ? BUFFER_1 : BUFFER_2) + prev_total_offset;
	assign back_buffer_addr =  (cur_buffer_state ? BUFFER_2 : BUFFER_1) + cur_total_offset;
endmodule 