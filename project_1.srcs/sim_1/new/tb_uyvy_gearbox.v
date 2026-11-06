`timescale 1ns / 1ps

module tb_uyvy_gearbox;
	reg clk = 0;
	reg rst = 1;
	reg [127:0] s_tdata = 0;
	reg s_tvalid = 0;
	wire s_tready;
	wire [63:0] m_tdata;
	wire m_tvalid;
	reg m_tready = 0;
	integer seen = 0;

	reg [63:0] expected [0:3];
	initial begin
		expected[0] = 64'h0706050403020100;
		expected[1] = 64'h0f0e0d0c0b0a0908;
		expected[2] = 64'h1716151413121110;
		expected[3] = 64'h1f1e1d1c1b1a1918;
	end

	always #5 clk = ~clk;

	uyvy_gearbox dut (
		.clk(clk), .rst(rst),
		.s_tdata(s_tdata), .s_tvalid(s_tvalid), .s_tready(s_tready),
		.m_tdata(m_tdata), .m_tvalid(m_tvalid), .m_tready(m_tready)
	);

	always @(posedge clk) begin
		if (m_tvalid && m_tready) begin
			if (m_tdata !== expected[seen]) begin
				$display("FAIL beat %0d got %h expected %h",
					seen, m_tdata, expected[seen]);
				$fatal;
			end
			seen <= seen + 1;
		end
	end

	initial begin
		repeat (3) @(posedge clk);
		rst <= 0;
		m_tready <= 1;

		@(posedge clk);
		s_tdata <= 128'h0f0e0d0c0b0a09080706050403020100;
		s_tvalid <= 1;
		while (!s_tready) @(posedge clk);
		@(posedge clk);
		s_tvalid <= 0;

		// Stall while the high half of word 0 is pending.
		@(posedge clk);
		m_tready <= 0;
		repeat (2) @(posedge clk);
		m_tready <= 1;
		s_tdata <= 128'h1f1e1d1c1b1a19181716151413121110;
		s_tvalid <= 1;
		while (!s_tready) @(posedge clk);
		@(posedge clk);
		s_tvalid <= 0;

		wait (seen == 4);
		@(posedge clk);
		if (m_tvalid) begin
			$display("FAIL m_tvalid stuck high");
			$fatal;
		end
		$display("PASS tb_uyvy_gearbox");
		$finish;
	end

	initial begin
		#2000;
		$display("FAIL timeout seen=%0d", seen);
		$fatal;
	end
endmodule
