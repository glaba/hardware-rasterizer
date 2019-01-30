module SerializeBlock(
	// The offset in SRAM of the current frame buffer
	input logic data_in,
	input logic[19:0] address_offset,
	input logic[9:0] location[1:0],
	input logic[15:0] color,

	output logic write_enable,
	output logic[19:0] address,
	output logic[15:0] data 
);
	logic[35:0] row_offset;
	// y * width + x
	LPMMult18_18 loc_mult(.dataa({8'd0, location[0]}), .datab(18'd640), .result(row_offset));
	
	assign write_enable = data_in;
	assign address = address_offset + row_offset[19:0] + {10'd0, location[1]};
	assign data = color;
endmodule