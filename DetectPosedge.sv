module DetectPosedge(
	input clock, reset, signal,
	output signal_posedge
);
	logic prev;
	always_ff @ (posedge clock) begin 
		if (reset)
			prev <= 1'b0;
		prev <= signal;
	end 
	assign signal_posedge = signal & ~prev;
endmodule 