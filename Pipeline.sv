module DataValidBuffer #(parameter LATENCY = 1) (
	input logic clock, reset, data_in,
	output logic data_out
);

	DelayResult #(.LATENCY(LATENCY), .WORD_SIZE(1)) delay(.clock, .reset, .result(data_in), .delayed_result(data_out));
endmodule 

// Delays result by either LATENCY cycles
module DelayResult #(parameter LATENCY = 1, parameter WORD_SIZE = 18) (
	input logic clock, reset,
	input logic[WORD_SIZE-1:0] result,
	output logic[WORD_SIZE-1:0] delayed_result
);
	logic[WORD_SIZE-1:0] delay_regs[LATENCY-1:0];

	always_ff @ (posedge clock) begin
		if (LATENCY > 0) begin
			if (reset) begin
				for (int i = 0; i < LATENCY; i++) delay_regs[i] <= {WORD_SIZE{1'b0}};
			end
			else begin
				delay_regs[LATENCY - 1] <= result;
				for (int i = 0; i < LATENCY - 1; i++) delay_regs[i] <= delay_regs[i + 1];
			end
		end 
	end

	assign delayed_result = (LATENCY > 0) ? delay_regs[0] : result;
endmodule 
