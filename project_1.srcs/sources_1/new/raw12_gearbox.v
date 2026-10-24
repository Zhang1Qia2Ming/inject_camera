`timescale 1ns / 1ps

// 128-bit beats to 48-bit RAW12 beats.
// Byte 0 is tdata[7:0]. Four pixels sit in tdata[47:0], and tdata[11:0]
// is the first pixel, matching mipi_gen.
module raw12_gearbox (
	input              clk,
	input              rst,
	input      [127:0] s_tdata,
	input              s_tvalid,
	output             s_tready,
	output reg [47:0]  m_tdata,
	output             m_tvalid,
	input              m_tready
);
	reg [7:0] bmem [0:47];
	reg [5:0] nb = 6'd0;
	integer   i;
	integer   k;
	reg [7:0] tmp [0:47];
	reg [5:0] nn;

	wire pop = (nb >= 6'd6) && m_tready;
	wire room = pop ? (nb <= 6'd38) : (nb <= 6'd32);
	assign s_tready = room && !rst;
	wire push = s_tvalid && s_tready;
	assign m_tvalid = (nb >= 6'd6);

	always @(posedge clk) begin
		if (rst) begin
			nb <= 6'd0;
			m_tdata <= 48'd0;
			for (i = 0; i < 48; i = i + 1)
				bmem[i] <= 8'h00;
		end else begin
			for (i = 0; i < 48; i = i + 1)
				tmp[i] = bmem[i];
			nn = nb;
			if (pop) begin
				for (i = 0; i < 42; i = i + 1)
					tmp[i] = bmem[i + 6];
				for (i = 42; i < 48; i = i + 1)
					tmp[i] = 8'h00;
				nn = nb - 6'd6;
			end
			if (push) begin
				for (k = 0; k < 16; k = k + 1)
					tmp[nn + k] = s_tdata[k * 8 +: 8];
				nn = nn + 6'd16;
			end
			nb <= nn;
			for (i = 0; i < 48; i = i + 1)
				bmem[i] <= tmp[i];
			m_tdata <= {tmp[5], tmp[4], tmp[3], tmp[2], tmp[1], tmp[0]};
		end
	end
endmodule
