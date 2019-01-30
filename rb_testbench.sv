module rb_testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, data_in;
// The color of the current triangle in 16 bit color
// 5 bits of red, 6 bits of green, 5 bits of blue
logic[15:0] color;
// Depth values in Q6.12
logic[17:0] d1, d2, d3;
// Triangle vertex values in Q18.0
logic[17:0] vert1[1:0], vert2[1:0], vert3[1:0];
// The location of the top left corner of the block in Q10.0
logic[9:0] block_location[1:0];

// Each pixel is outputted in serial, 2 cycles per color (for now?)
// Color of the current pixel being outputted
logic[15:0] color_out;
// The coordinates of the current pixel being ed in Q10.0
logic[9:0] location_out[1:0];
// A signal that indicates that data is being ed to be written to memory
logic data_out;

// Indicates that the block is ready to accept another stream of triangles
logic ready;

logic[3:0] debug_select;
logic[31:0] debug;

RasterizeBlock rb(.*);

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
	block_location <= '{10'd41, 10'd52};

	repeat (1) @ (posedge clock);
	reset <= 1'b0;

	/***********************/
	/***   INITIAL RUN   ***/
	/***********************/
	data_in <= 1'b1;
	color <= 16'd0;
	d1 <= {6'd31, 12'd0};    d2 <= {6'd31, 12'd0};    d3 <= {6'd31, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd1;
	d1 <= {6'd27, 12'd0};    d2 <= {6'd27, 12'd0};    d3 <= {6'd27, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd2;
	d1 <= {6'd28, 12'd0};    d2 <= {6'd28, 12'd0};    d3 <= {6'd28, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd3;
	d1 <= {6'd30, 12'd0};    d2 <= {6'd30, 12'd0};    d3 <= {6'd30, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;

	/**************************/
	/***  CONSECUTIVE RUNS  ***/
	/**************************/
	repeat (1) @ (posedge ready);
	repeat (1) @ (posedge clock);
	data_in <= 1'b1;
	color <= 16'd0;
	d1 <= {6'd31, 12'd0};    d2 <= {6'd31, 12'd0};    d3 <= {6'd31, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd11;
	d1 <= {6'd27, 12'd0};    d2 <= {6'd27, 12'd0};    d3 <= {6'd27, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd2;
	d1 <= {6'd28, 12'd0};    d2 <= {6'd28, 12'd0};    d3 <= {6'd28, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd3;
	d1 <= {6'd30, 12'd0};    d2 <= {6'd30, 12'd0};    d3 <= {6'd30, 12'd0};
	vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;

	/***********************************************/
	/*** RASTERIZATION SLOWER THAN SERIALIZATION ***/
	/***********************************************/
	repeat (1) @ (posedge ready);

	repeat (40) begin
		repeat (1) @ (posedge clock);
		data_in <= 1'b1;
		color <= 16'hffff;
		d1 <= {6'd27, 12'd0};    d2 <= {6'd27, 12'd0};    d3 <= {6'd27, 12'd0};
		vert1 <= '{18'd50, 18'd40}; vert2 <= '{18'd40, 18'd60}; vert3 <= '{18'd60, 18'd60};

		repeat (1) @ (posedge clock);
		data_in <= 1'b1;
		color <= 16'd2;
		d1 <= {6'd28, 12'd0};    d2 <= {6'd28, 12'd0};    d3 <= {6'd28, 12'd0};
		vert1 <= '{18'd42, 18'd48}; vert2 <= '{18'd42, 18'd60}; vert3 <= '{18'd58, 18'd54};
	end

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;

end
endmodule