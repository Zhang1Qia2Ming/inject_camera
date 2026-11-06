`timescale 1ns / 1ps

module tb_mipi_line_gap_diag;
	reg clk = 0;
	reg tx1_v = 0, tx1_r = 0, tx1_l = 0;
	reg [95:0] tx1_u = 0;
	reg tx1_start = 0, tx1_done = 0;
	reg tx2_v = 0, tx2_r = 0, tx2_l = 0;
	reg tx2_start = 0, tx2_done = 0;
	reg tx4_v = 0, tx4_r = 0, tx4_l = 0;
	reg tx4_start = 0, tx4_done = 0;
	wire [47:0] dbg_bus;

	always #5 clk = ~clk;

	mipi_ila_diag dut (
		.clk(clk),
		.tx1_v(tx1_v), .tx1_r(tx1_r), .tx1_l(tx1_l),
		.tx1_u(tx1_u), .tx1_start(tx1_start), .tx1_done(tx1_done),
		.tx2_v(tx2_v), .tx2_r(tx2_r), .tx2_l(tx2_l),
		.tx2_start(tx2_start), .tx2_done(tx2_done),
		.tx4_v(tx4_v), .tx4_r(tx4_r), .tx4_l(tx4_l),
		.tx4_start(tx4_start), .tx4_done(tx4_done),
		.dbg_bus(dbg_bus)
	);

	initial begin
		// First accepted beat opens a CSI long packet.
		@(negedge clk);
		tx1_v = 1;
		tx1_r = 1;
		@(posedge clk);

		// A ready cycle without valid before TLAST is a payload underrun.
		@(negedge clk);
		tx1_v = 0;
		@(posedge clk);
		#1;
		if (dbg_bus[3] !== 1'b1) begin
			$display("FAIL missing TX1 in-line gap indication dbg=%h", dbg_bus);
			$fatal;
		end

		$display("PASS tb_mipi_line_gap_diag dbg=%h", dbg_bus);
		$finish;
	end
endmodule
