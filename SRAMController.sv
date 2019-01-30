module SRAMController(
	input logic clock_100, reset,
	input logic read_enable, write_enable,
	input logic[15:0] write_data,
	input logic[19:0] write_addr, read_addr,
	output logic CE, UB, LB, OE, WE,
	output logic[15:0] read_data,
	output logic[19:0] ADDR,
	inout wire[15:0] Data
);
	enum logic[2:0] {Waiting, Write_1, Write_2, Read_1, Read_2} State; 
	assign CE = 1'b0;
	assign OE = 1'b0;
	assign UB = 1'b0;
	assign LB = 1'b0;

	// Contains the data and address that was written during the last write operation 
	logic[19:0] prev_write_addr;
	logic[15:0] prev_write_data;
	// Indicates whether or not data was written during the most recent state Write_1
	logic prev_write_en;

	// Contains the address that was read from during the last read operation 
	logic[19:0] prev_read_addr;
	// Indicates whether or not data was read during state Read_1
	logic prev_read_en;

	always_ff @ (posedge clock_100) begin
		if (reset) begin 
			State <= Waiting;
		end 
		else begin 
			// Update state
			unique case (State)
				Waiting: State <= Write_1;
				Write_1: State <= Write_2;
				Write_2: State <= Read_1;
				Read_1: State <= Read_2;
				Read_2: State <= Write_1;
			endcase

			/*****************************/
			/*********** WRITE ***********/
			/*****************************/
			// Store the data written during the current Write_1 cycle (if at all)
			if (State == Write_1) begin 
				prev_write_addr <= write_addr;
				prev_write_data <= write_data;
				prev_write_en <= write_enable;
			end 
			// Otherwise, store the addr and data as they are to prevent duplicate writes 
			else begin 
				prev_write_addr <= prev_write_addr;
				prev_write_data <= prev_write_data;
				prev_write_en <= 1'b0;
			end 

			/****************************/
			/*********** READ ***********/
			/****************************/
			// Store the address read from during the current Read_1 cycle (if at all)
			if (State == Read_1) begin 
				prev_read_addr <= read_addr;
				prev_read_en <= read_enable;
			end 
			// Otherwise, store the addr as it is to prevent duplicate reads 
			else begin 
				prev_read_addr <= prev_read_addr;
				prev_read_en <= 1'b0;
			end 

			// Read the data from the bus on Read_2, hold the value otherwise
			if (State == Read_2 & prev_read_en) read_data <= Data;
			else                                read_data <= read_data;
		end
	end

	logic[15:0] data_bus;
	always_comb begin
		case (State)
			Waiting:
				begin 
					WE = 1'b1;
					ADDR = {20{1'bZ}};
					data_bus = {16{1'bZ}};
				end 
			Write_1: 
				begin
					WE = ~write_enable;
					ADDR = write_enable ? write_addr : {20{1'bZ}};
					data_bus = write_enable ? write_data : {16{1'bZ}};
				end
			Write_2: 
				begin
					WE = ~prev_write_en;
					ADDR = prev_write_en ? prev_write_addr : {20{1'bZ}};
					data_bus = prev_write_en ? prev_write_data : {16{1'bZ}};				
				end
			Read_1: 
				begin
					WE = 1'b1;
					ADDR = read_enable ? read_addr : {20{1'bZ}};
					data_bus = {16{1'bz}};
				end
			Read_2: 
				begin
					WE = 1'b1;
					ADDR = prev_read_en ? prev_read_addr : {20{1'bZ}};
					data_bus = {16{1'bz}};
				end
		endcase
	end

	assign Data = data_bus;
endmodule
	
	