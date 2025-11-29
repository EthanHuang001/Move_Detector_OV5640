module altshift_taps 
#(
	parameter	RAM_Length = 10'd640	//640*480
)(clk, shift, sr_in, sr_out, taps );
	input clk, shift;
	input [0:0] sr_in;
	output [0:0] sr_out;
    output [1:0] taps;
	reg sr [2*RAM_Length-1:0];
	integer n;
	always @ (posedge clk)
		begin
		if (shift == 1'b1)
			begin
			for (n=2*RAM_Length-1; n>0; n = n-1)
				begin
				sr[n] <= sr[n-1];
				end
			sr[0] <= sr_in;
		end
	end
	assign taps[0] = sr[RAM_Length-1];
	assign taps[1] = sr[2*RAM_Length-1];
	assign sr_out = sr[2*RAM_Length-1];
endmodule