module SRAM_testbench();

timeunit 10ns;

timeprecision 1ns;

logic Clk_100, read_enable, write_enable, reset;
logic [15:0] write_data;
logic [19:0] write_addr, read_addr;
logic CE, UB, LB, OE, WE; //outputs
logic [15:0] read_data;
logic [19:0] ADDR;
wire [15:0] Data;

SRAMController inst(.*);

always begin : CLOCK_GENERATION
#1	Clk_100 = ~Clk_100;
end 

initial begin : CLOCK_INITIALIZATION 
	Clk_100 = 1;
end 

logic[15:0] data_bus;
assign Data = data_bus;

// Tested instructions:
// - ADDi
// - ADD
initial begin : TEST 
	reset <= 1'b1;
	data_bus <= {16{1'bz}};

	repeat (1) @ (posedge Clk_100);
	reset <= 1'b0;

	/***********************/
	/***     WRITE_1     ***/
	/***********************/	
	write_enable <= 1'b1;
	read_enable <= 1'b1;
	write_data <= 16'd10;
	write_addr <= 20'd2;
	read_addr <= 20'd3;

	repeat (3) @ (posedge Clk_100);
	data_bus <= 16'd42;

	repeat (1) @ (posedge Clk_100);
	data_bus <= {16{1'bz}};

	write_enable <= 1'b0;
	read_enable <= 1'b0;

	/***********************/
	/***     WRITE_2     ***/
	/***********************/
	// Delay by 1 to input on Write_2
	repeat (1) @ (posedge Clk_100);

	write_enable <= 1'b1;
	read_enable <= 1'b1;

	write_data <= 16'd10;
	write_addr <= 20'd2;
	read_addr <= 20'd3;

	repeat (4) @ (posedge Clk_100);

	write_data <= 16'd11;
	write_addr <= 20'd3;
	read_addr <= 20'd4;

	repeat (4) @ (posedge Clk_100);
	write_enable <= 1'b0;
	read_enable <= 1'b0;

	/***********************/
	/***     READ_1      ***/
	/***********************/
	// Delay by 1 to input on Read_1
	repeat (1) @ (posedge Clk_100);

	write_enable <= 1'b1;
	read_enable <= 1'b1;

	write_data <= 16'd12;
	write_addr <= 20'd4;
	read_addr <= 20'd5;

	repeat (4) @ (posedge Clk_100);

	write_data <= 16'd13;
	write_addr <= 20'd5;
	read_addr <= 20'd6;

	repeat (4) @ (posedge Clk_100);
	write_enable <= 1'b0;
	read_enable <= 1'b0;

	/***********************/
	/***     READ_2      ***/
	/***********************/
	// Delay by 1 to input on Read_2
	repeat (1) @ (posedge Clk_100);

	write_enable <= 1'b1;
	read_enable <= 1'b1;

	write_data <= 16'd14;
	write_addr <= 20'd6;
	read_addr <= 20'd7;

	repeat (4) @ (posedge Clk_100);

	write_data <= 16'd15;
	write_addr <= 20'd7;
	read_addr <= 20'd8;

	repeat (4) @ (posedge Clk_100);
	write_enable <= 1'b0;
	read_enable <= 1'b0;
end 

endmodule