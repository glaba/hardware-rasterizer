module rp_testbench();

timeunit 10ns;

timeprecision 1ns;

logic clock, reset, data_in;
// The color and depths from the triangle provided into the pipeline 6 cycles ago
logic[15:0] color;
logic[17:0] d1, d2, d3; 	// Depth values in Q6.12
// The triangle currently being inputted into the pipeline as well as the current point (Q18.0)
logic[17:0] point[1:0], v1[1:0], v2[1:0], v3[1:0];

// These two take the value of the correct color and high 7 cycles after data_in transitions from high to low
//  which is how the parent module indicates that it is finished streaming triangles
logic[15:0] color_out;
logic data_out;

logic[35:0] denominator;

ComputeDenominator cd(.*);
RasterizePixel rp(.*);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1	clock = ~clock;
end

initial begin: CLOCK_INITIALIZATION
	clock = 1;
end 

initial begin: TEST
	/*********************************/
	/***** CHOOSES CLOSEST DEPTH *****/
	/*********************************/

	reset <= 1'b1;
	data_in <= 1'b0;
	point <= '{18'd50, 18'd50};

	repeat (1) @ (posedge clock);
	reset <= 1'b0;

	data_in <= 1'b1;
	color <= 16'd0;
	d1 <= {6'd31, 12'd0};    d2 <= {6'd31, 12'd0};    d3 <= {6'd31, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd1;
	d1 <= {6'd27, 12'd0};    d2 <= {6'd27, 12'd0};    d3 <= {6'd27, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd2;
	d1 <= {6'd28, 12'd0};    d2 <= {6'd28, 12'd0};    d3 <= {6'd28, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	color <= 16'd3;
	d1 <= {6'd30, 12'd0};    d2 <= {6'd30, 12'd0};    d3 <= {6'd30, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;
	// This data should specifically not be considered or have an effect because data_in is 0
	color <= 16'd4;
	d1 <= {6'd0, 12'd0};     d2 <= {6'd0, 12'd0};     d3 <= {6'd0, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};

	// Wait for the triangles to be processed
	repeat (7) @ (posedge clock);
#1	assert (data_out == 1'b1);
	assert (color_out == 16'd1);
#1	repeat (1) @ (posedge clock);

	/***********************************/
	/***** CORRECTLY CHECKS BOUNDS *****/
	/***********************************/

	reset <= 1'b1;
	data_in <= 1'b0;
	point <= '{18'd50, 18'd50};

	repeat (1) @ (posedge clock);
	reset <= 1'b0;

	data_in <= 1'b1;
	color <= 16'd5;
	d1 <= {6'd30, 12'd0};    d2 <= {6'd30, 12'd0};    d3 <= {6'd30, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd40, 18'd40};
	// Does not contain point

	repeat (1) @ (posedge clock);
	color <= 16'd6;
	d1 <= {6'd30, 12'd0};    d2 <= {6'd30, 12'd0};    d3 <= {6'd30, 12'd0};
	v1 <= '{18'd50, 18'd40}; v2 <= '{18'd40, 18'd60}; v3 <= '{18'd60, 18'd60};
	// Does contain point

	repeat (1) @ (posedge clock);
	data_in <= 1'b0;

	repeat (7) @ (posedge clock);
#1	assert (data_out == 1'b1);
	assert (color_out == 16'd6);
#1	repeat (1) @ (posedge clock);	
end
endmodule