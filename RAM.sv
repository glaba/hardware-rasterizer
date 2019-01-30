module V1RAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[53:0] data,
	output logic[53:0] q
);
	logic[53:0] mem[0:4095];
	initial begin
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/v1.mem", mem);
	end 
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule 

module V2RAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[53:0] data,
	output logic[53:0] q
);
	logic[53:0] mem[0:4095];
	initial begin
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/v2.mem", mem);
	end 
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule 

module V3RAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[53:0] data,
	output logic[53:0] q
);
	logic[53:0] mem[0:4095];
	initial begin
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/v3.mem", mem);
	end 
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule 

module NormalRAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[53:0] data,
	output logic[53:0] q
);
	logic[53:0] mem[0:4095];
	initial begin
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/normal.mem", mem);
	end 
	always_ff @ (posedge clock) begin 
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule 

module ColorRAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[15:0] data,
	output logic[15:0] q
);
	logic[15:0] mem[0:4095];
	initial begin
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/color.mem", mem);
	end 
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule

module ShadedColorRAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[15:0] data,
	output logic[15:0] q
);
	logic[15:0] mem[0:4095];
	initial begin 
		$readmemb("/home/glaba/Desktop/School/Semester 3/ECE 385/ece385/final_project/shadedcolor.mem", mem);
	end 
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule

module ProjectedVertexRAM(
	input logic clock, we,
	input logic[11:0] read_addr, write_addr,
	input logic[53:0] data,
	output logic[53:0] q
);
	logic[53:0] mem[0:4095];
	always_ff @ (posedge clock) begin
		if (we)	mem[write_addr] <= data;
		q <= mem[read_addr];
	end 
endmodule

