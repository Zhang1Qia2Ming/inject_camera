`timescale 1ns / 1ps

module tb_mipi_gen_uyvy_reserved_rom;
	reg clk = 0;
	wire tlast;
	wire [95:0] tuser;
	wire [95:0] pg_tuser;
	wire tvalid;
	wire [95:0] tdata;
	reg frame_ok = 0;
	wire frame_done;
	wire pix_ready;
	integer reserved_beats = 0;
	integer image_beats = 0;
	integer lines = 0;
	integer line_beats = 0;
	integer frames = 0;
	integer golden_index;
	reg [15:0] golden_997 [0:23039];
	reg [63:0] expected_source;
	reg [95:0] expected_axis;

	always #5 clk = ~clk;
	assign pg_tuser = {
		tuser[95:70], 6'b0, tuser[63:16],
		9'b0, tuser[69:64], tuser[0]
	};

	initial $readmemh("997_sensor8_ebd_u16.mem", golden_997);

	mipi_gen_uyvy_lane #(
		.H_TOTAL(961), .H_ACTIVE(960),
		.V_TOTAL(7), .V_ACTIVE(7),
		.BYTE_NUM(7680),
		.USE_RESERVED_ROM(1),
		.RESERVED_MEM_FILE("997_uyvy_reserved_64.mem")
	) dut (
		.clk(clk), .tlast(tlast), .tuser(tuser),
		.tvalid(tvalid), .tdata(tdata), .tready(1'b1),
		.frame_ok(frame_ok), .frame_start(),
		.frame_done(frame_done), .pix_data(64'h0123456789abcdef),
		.pix_valid(1'b1), .pix_ready(pix_ready)
	);

	always @(posedge clk) begin
		if (tvalid) begin
			line_beats = line_beats + 1;
			if (pg_tuser[6:1] !== 6'h1e ||
			    pg_tuser[63:48] !== 16'd7680) begin
				$display("FAIL UYVY DT=%h WC=%0d",
					pg_tuser[6:1], pg_tuser[63:48]);
				$fatal;
			end
			if ((pg_tuser[47:32] <= 16'd2) ||
			    (pg_tuser[47:32] > 16'd3)) begin
				golden_index = (reserved_beats % 5760) * 4;
				expected_source = {
					golden_997[golden_index + 3],
					golden_997[golden_index + 2],
					golden_997[golden_index + 1],
					golden_997[golden_index]
				};
				// OX08D EBD frame counter is the big-endian value of
				// registers 0x462A..0x462D. It must follow the CSI frame
				// number instead of replaying the captured ROM value 12.
				if (pg_tuser[47:32] == 16'd1) begin
					case (line_beats)
						17: expected_source[63:56] = 8'd0;
						18: expected_source[63:56] = 8'd0;
						19: expected_source[63:56] =
							pg_tuser[31:24];
						20: expected_source[63:56] =
							pg_tuser[23:16];
					endcase
				end
				expected_axis = {
					32'd0,
					expected_source[55:48],
					expected_source[63:56],
					expected_source[39:32],
					expected_source[47:40],
					expected_source[23:16],
					expected_source[31:24],
					expected_source[7:0],
					expected_source[15:8]
				};
				if (tdata !== expected_axis) begin
					$display(
						"FAIL reserved beat=%0d got=%h expected=%h",
						reserved_beats, tdata, expected_axis);
					$fatal;
				end
				reserved_beats = reserved_beats + 1;
			end
			else begin
				if (pg_tuser[47:32] !== 16'd3) begin
					$display("FAIL image line=%0d",
						pg_tuser[47:32]);
					$fatal;
				end
				image_beats = image_beats + 1;
			end
			if (tlast) begin
				if (line_beats != 960) begin
					$display("FAIL line %0d beats=%0d",
						lines + 1, line_beats);
					$fatal;
				end
				lines = lines + 1;
				line_beats = 0;
			end
		end
		if (frame_done)
			frames = frames + 1;
	end

	initial begin
		repeat (3) @(posedge clk);
		frame_ok <= 1;
		wait (frames == 1);
		frame_ok <= 0;
		wait (frames == 2);
		@(posedge clk);
		if ((reserved_beats != 11520) || (image_beats != 1920) ||
		    (lines != 14)) begin
			$display("FAIL reserved=%0d image=%0d lines=%0d",
				reserved_beats, image_beats, lines);
			$fatal;
		end
		$display("PASS tb_mipi_gen_uyvy_reserved_rom");
		$finish;
	end

	initial begin
		#200000;
		$display("FAIL timeout");
		$fatal;
	end
endmodule
