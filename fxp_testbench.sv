module fxp_testbench();

timeunit 10ns;

timeprecision 1ns;

logic add_sub;
logic clock;
logic[31:0] dataa;
logic[31:0] datab;
logic[31:0] result_addsub0;
logic[31:0] result_addsub1;
logic[31:0] result_addsub2;
logic[31:0] result_addsub3;

logic[31:0] result_mult1;
logic[31:0] result_mult2;
logic[31:0] result_mult3;

logic[31:0] result_div1;
logic[31:0] result_div2;
logic[31:0] result_div3;

FXPAddSub #(.LATENCY(0)) addsub0(.clock, .add_sub, .dataa, .datab, .result(result_addsub0));
FXPAddSub #(.LATENCY(1)) addsub1(.clock, .add_sub, .dataa, .datab, .result(result_addsub1));
FXPAddSub #(.LATENCY(2)) addsub2(.clock, .add_sub, .dataa, .datab, .result(result_addsub2));
FXPAddSub #(.LATENCY(3)) addsub3(.clock, .add_sub, .dataa, .datab, .result(result_addsub3));

FXPMult #(.LATENCY(1)) mult1(.clock, .dataa, .datab, .result(result_mult1));
FXPMult #(.LATENCY(2)) mult2(.clock, .dataa, .datab, .result(result_mult2));
FXPMult #(.LATENCY(3)) mult3(.clock, .dataa, .datab, .result(result_mult3));

FXPDiv #(.LATENCY(1)) div1(.clock, .dataa, .datab, .result(result_div1));
FXPDiv #(.LATENCY(2)) div2(.clock, .dataa, .datab, .result(result_div2));
FXPDiv #(.LATENCY(3)) div3(.clock, .dataa, .datab, .result(result_div3));

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1	clock = ~clock;
end

initial begin: CLOCK_INITIALIZATION
	clock = 1;
end 

initial begin: TEST
// FXPAddSub
#2	add_sub = 1'b1;
	// In fixed point: 0B21.642D = 2849.391311646
	dataa = 32'd186737709;
	// In fixed point: 0.000228881836
	datab = 32'd15;

#2	add_sub = 1'b0;

// #1	// Offset for assertion
// #2 	assert (result_addsub == 32'd186737724);
// #2 	assert (result_addsub == 32'd186737694);
// #1  // Fix offset

#6

	// 2849.391311646
#2	dataa = 32'd186737709;
	// In fixed point: 3.583969116
	datab = 32'd234879;

end
endmodule