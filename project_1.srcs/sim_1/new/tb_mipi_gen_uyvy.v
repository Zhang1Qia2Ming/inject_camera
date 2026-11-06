`timescale 1ns / 1ps

module tb_mipi_gen_uyvy;
	reg clk = 0;
	wire tlast;
	wire [95:0] tuser;
	wire [95:0] pg_tuser;
	wire tvalid;
	wire [95:0] tdata;
	reg tready = 1;
	reg frame_ok = 0;
	wire frame_start;
	wire frame_done;
	reg [63:0] pix_data = 64'h0123456789abcdef;
	reg pix_valid = 1;
	wire pix_ready;
	integer beats = 0;
	integer lines = 0;
	integer pixels = 0;

	always #5 clk = ~clk;
	// Model the generated AXIS subset converter between this generator and
	// PG260. Its configured remap sources DT from input TUSER[69:64].
	assign pg_tuser = {
		tuser[95:70], 6'b0, tuser[63:16],
		9'b0, tuser[69:64], tuser[0]
	};

	mipi_gen_uyvy_lane #(
		.H_TOTAL(3), .H_ACTIVE(2),
		.V_TOTAL(9), .V_ACTIVE(8),
		.BYTE_NUM(16), .USE_RESERVED_ROM(0)
	) dut (
		.clk(clk), .tlast(tlast), .tuser(tuser),
		.tvalid(tvalid), .tdata(tdata), .tready(tready),
		.frame_ok(frame_ok), .frame_start(frame_start),
		.frame_done(frame_done), .pix_data(pix_data),
		.pix_valid(pix_valid), .pix_ready(pix_ready)
	);

	always @(posedge clk) begin
		if (tvalid && tready) begin
			beats <= beats + 1;
			if (pg_tuser[6:1] !== 6'h1e ||
			    pg_tuser[63:48] !== 16'd16) begin
				$display("FAIL UYVY line=%0d dt=%h wc=%0d",
					lines + 1, pg_tuser[6:1],
					pg_tuser[63:48]);
				$fatal;
			end
			if ((lines >= 2) && (lines < 4) &&
			    (tdata !==
			    96'h0000000023016745ab89efcd)) begin
				$display("FAIL MAX_BPC8 UYVY mapping %h", tdata);
				$fatal;
			end
			if (pg_tuser[95:64] !== 32'd0 ||
			    pg_tuser[15:7] !== 9'd0) begin
				$display("FAIL reserved bits upper=%h lower=%h",
					pg_tuser[95:64], pg_tuser[15:7]);
				$fatal;
			end
			if (pg_tuser[47:32] !== (lines + 1)) begin
				$display("FAIL line number %0d expected %0d",
					pg_tuser[47:32], lines + 1);
				$fatal;
			end
			if (pg_tuser[31:16] !== 16'd1) begin
				$display("FAIL frame number %0d",
					pg_tuser[31:16]);
				$fatal;
			end
			if (tlast) lines <= lines + 1;
		end
		if (pix_ready) pixels <= pixels + 1;
	end

	initial begin
		repeat (3) @(posedge clk);
		frame_ok <= 1;
		@(posedge clk);
		frame_ok <= 0;
		wait (frame_done);
		@(posedge clk);
		if (beats != 16 || lines != 8 || pixels != 4) begin
			$display("FAIL beats=%0d lines=%0d pixels=%0d",
				beats, lines, pixels);
			$fatal;
		end
		$display("PASS tb_mipi_gen_uyvy");
		$finish;
	end

	initial begin
		#5000;
		$display("FAIL timeout");
		$fatal;
	end
endmodule
