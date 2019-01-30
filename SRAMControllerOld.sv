module SRAMControllerOld(
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

	// These are registers which store write and read requests which will be fulfilled on a later cycle
	logic[19:0] write_buffer_addr, read_buffer_addr;
	logic[15:0] write_buffer_data;
	// On states Write_1 and Read_1, the respective item is set to the addr/data being written / read
	logic[19:0] write_choose_addr, read_choose_addr;
	logic[15:0] write_choose_data;
	// Indicates whether there is a pending request to read or write that must be carried out
	logic write_buffer_on, read_buffer_on;

	// Contains the data and address that was written during the last write operation 
	logic[19:0] prev_write_addr;
	logic[15:0] prev_write_data;
	// Indicates whether or not data was written during the most recent state Write_1
	logic prev_write_on;

	// Contains the address that was read from during the last read operation 
	logic[19:0] prev_read_addr;
	// Indicates whether or not data was read during state Read_1
	logic prev_read_on;

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
				prev_write_addr <= write_choose_addr;
				prev_write_data <= write_choose_data;
				prev_write_on <= write_enable | write_buffer_on;
			end 
			// Otherwise, store the addr and data as they are to prevent duplicate writes 
			else begin 
				prev_write_addr <= prev_write_addr;
				prev_write_data <= prev_write_data;
				prev_write_on <= 1'b0;
			end 

			// Store into the write_buffer if we are not on state Write_1 and if the data is different from before
			if (State != Write_1 & write_enable) begin 
				if ((prev_write_addr == write_addr) & (prev_write_data == write_data)) begin 
					// We don't care about the values of write_buffer_addr and write_buffer_data
					write_buffer_on <= 1'b0;
				end 
				else begin
					write_buffer_addr <= write_addr;
					write_buffer_data <= write_data;
					write_buffer_on <= 1'b1;
				end 
			end 
			else if (~write_enable) begin 
				// Again, we don't care about the data in the buffer here
				write_buffer_on <= 1'b0;
			end 
			else begin 
				write_buffer_addr <= write_buffer_addr;
				write_buffer_data <= write_buffer_data;
				write_buffer_on <= write_buffer_on;
			end 

			/****************************/
			/*********** READ ***********/
			/****************************/
			// Store the address read from during the current Read_1 cycle (if at all)
			if (State == Read_1) begin 
				prev_read_addr <= read_choose_addr;
				prev_read_on <= read_enable | read_buffer_on;
			end 
			// Otherwise, store the addr as it is to prevent duplicate reads 
			else begin 
				prev_read_addr <= prev_read_addr;
				prev_read_on <= 1'b0;
			end 

			// Store into the read_buffer if we are not on state Read_1 and if the address is different from before
			if (State != Read_1 & read_enable) begin 
				if (prev_read_addr == read_addr) begin 
					// We don't care about the value of read_buffer_addr
					read_buffer_on <= 1'b0;
				end 
				else begin
					read_buffer_addr <= read_addr;
					read_buffer_on <= 1'b1;
				end 
			end 
			else if (~read_enable) begin 
				// Again, we don't care about the data in the buffer here
				read_buffer_on <= 1'b0;
			end 
			else begin 
				read_buffer_addr <= read_buffer_addr;
				read_buffer_on <= read_buffer_on;
			end 

			// Read the data from the bus on Read_2, hold the value otherwise
			if (State == Read_2 & prev_read_on) read_data <= Data;
			else                                read_data <= read_data;
		end
	end

	logic[15:0] data_bus;
	always_comb begin
		WE = 1'b1;
		
		write_choose_addr = {20{1'bZ}};
		write_choose_data = {16{1'bZ}};
		read_choose_addr = {20{1'bZ}};

		case (State)
			Waiting:
				begin 
					WE = 1'b1;
					ADDR = {20{1'bZ}};
					data_bus = {16{1'bZ}};
				end 
			Write_1: 
				begin
					if (write_buffer_on) begin
						write_choose_addr = write_buffer_addr;
						write_choose_data = write_buffer_data;
					end
					else if (write_enable) begin
						write_choose_addr = write_addr;
						write_choose_data = write_data;
					end
					// Set output signals
					WE = ~(write_enable | write_buffer_on);
					ADDR = write_choose_addr;
					data_bus = (write_enable | write_buffer_on) ? write_choose_data : {16{1'bZ}};
				end
			Write_2: 
				begin
					// Set output signals
					WE = ~prev_write_on;
					ADDR = prev_write_addr;
					data_bus = prev_write_on ? prev_write_data : {16{1'bZ}};				
				end
			Read_1: 
				begin
					if (read_buffer_on)
						read_choose_addr = read_buffer_addr;
					else if (read_enable)
						read_choose_addr = read_addr;
					// Set output signals 
					WE = 1'b1;
					ADDR = read_choose_addr;
					data_bus = {16{1'bz}};
				end
			Read_2: 
				begin
					WE = 1'b1;
					ADDR = prev_read_addr;
					data_bus = {16{1'bz}};
				end
		endcase
	end

	assign Data = data_bus;
endmodule
	
	