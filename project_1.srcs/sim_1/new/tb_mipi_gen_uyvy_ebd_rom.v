`timescale 1ns / 1ps

module tb_mipi_gen_uyvy_ebd_rom;
	reg clk = 0;
	wire tlast;
	wire [95:0] tuser;
	wire tvalid;
	wire [167:0] tdata;
	reg frame_ok = 0;
	wire frame_done;
	wire pix_ready;
	integer ebd_beats = 0;
	integer image_beats = 0;
	integer lines = 0;
	integer line_beats = 0;
	integer slot;
	integer golden_index;
	reg [15:0] golden_997 [0:23039];
	reg [11:0] expected_sample;

	always #5 clk = ~clk;

	initial $readmemh("997_sensor8_ebd_u16.mem", golden_997);

	mipi_gen_uyvy_lane #(
		.H_TOTAL(961), .H_ACTIVE(960),
		.V_TOTAL(7), .V_ACTIVE(7),
		.BYTE_NUM(7680), .EBD_BYTE_NUM(5760),
		.USE_EBD_ROM(1),
		.EBD_MEM_FILE("997_rx_ebd_axis_64.mem")
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
			if ((tuser[47:32] <= 16'd2) ||
			    (tuser[47:32] > 16'd3)) begin
				if (tuser[6:1] !== 6'h2c ||
				    tuser[63:48] !== 16'd5760) begin
					$display("FAIL EBD DT=%h WC=%0d",
						tuser[6:1], tuser[63:48]);
					$fatal;
				end
				for (slot = 0; slot < 4; slot = slot + 1) begin
					golden_index = ebd_beats * 4 + slot;
					expected_sample =
						{golden_997[golden_index][15:8], 4'b0};
					if (golden_index == 75)
						expected_sample = 12'h000;
					else if (golden_index == 79)
						expected_sample = 12'h010;
					if (tdata[(slot * 14) + 2 +: 12] !==
					    expected_sample) begin
						$display(
							"FAIL 997 RAW12 beat=%0d slot=%0d got=%03h expected=%03h",
							ebd_beats, slot,
							tdata[(slot * 14) + 2 +: 12],
							expected_sample);
						$fatal;
					end
				end
				ebd_beats = ebd_beats + 1;
			end
			else begin
				if (tuser[6:1] !== 6'h1e ||
				    tuser[63:48] !== 16'd7680) begin
					$display("FAIL image DT=%h WC=%0d",
						tuser[6:1], tuser[63:48]);
					$fatal;
				end
				if (tuser[47:32] !== 16'd3) begin
					$display("FAIL image line=%0d",
						tuser[47:32]);
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
	end

	initial begin
		repeat (3) @(posedge clk);
		frame_ok <= 1;
		@(posedge clk);
		frame_ok <= 0;
		wait (frame_done);
		@(posedge clk);
		if ((ebd_beats != 5760) || (image_beats != 960) ||
		    (lines != 7)) begin
			$display("FAIL EBD=%0d image=%0d lines=%0d",
				ebd_beats, image_beats, lines);
			$fatal;
		end
		$display("PASS tb_mipi_gen_uyvy_ebd_rom");
		$finish;
	end

	initial begin
		#200000;
		$display("FAIL timeout");
		$fatal;
	end
endmodule
