`timescale 1ns / 1ps

module tb_pcie_diag;
	reg dbg_clk = 1'b0;
	reg axi_aclk = 1'b0;
	reg axi_clk_en = 1'b0;
	reg pcie_rst_n = 1'b0;
	reg user_lnk_up = 1'b0;
	reg [47:0] lane_dbg_bus = 48'd0;
	wire [47:0] dbg_bus;

	always #5 dbg_clk = ~dbg_clk;
	always #2 begin
		if (axi_clk_en)
			axi_aclk = ~axi_aclk;
	end

	pcie_diag dut (
		.dbg_clk(dbg_clk),
		.axi_aclk(axi_aclk),
		.pcie_rst_n(pcie_rst_n),
		.user_lnk_up(user_lnk_up),
		.lane_dbg_bus(lane_dbg_bus),
		.dbg_bus(dbg_bus)
	);

	initial begin
		#1000;
		if (dbg_bus[47:32] !== 16'd0 || dbg_bus[12] !== 1'b0)
			$fatal(1, "lane diagnostics asserted while source clock was stopped");
		if (dbg_bus[31:16] != 16'd0 || dbg_bus[11])
			$fatal(1, "XDMA clock heartbeat appeared while axi_aclk was stopped");
		if (dbg_bus[15] || dbg_bus[14] || dbg_bus[13])
			$fatal(1, "status bits asserted before reset/link release");

		pcie_rst_n = 1'b1;
		user_lnk_up = 1'b1;
		axi_clk_en = 1'b1;
		lane_dbg_bus[0] = 1'b1;
		#20;
		lane_dbg_bus[0] = 1'b0;
		lane_dbg_bus[6] = 1'b1;
		lane_dbg_bus[7] = 1'b1;
		lane_dbg_bus[8] = 1'b1;
		lane_dbg_bus[5] = 1'b1;
		lane_dbg_bus[15] = 1'b1;
		lane_dbg_bus[11] = 1'b1;
		lane_dbg_bus[3] = 1'b1;
		lane_dbg_bus[12] = 1'b1;
		lane_dbg_bus[13] = 1'b1;
		lane_dbg_bus[14] = 1'b1;
		lane_dbg_bus[9] = 1'b1;
		#8;
		lane_dbg_bus[3] = 1'b0;
		lane_dbg_bus[12] = 1'b0;
		lane_dbg_bus[13] = 1'b0;
		lane_dbg_bus[14] = 1'b0;
		lane_dbg_bus[9] = 1'b0;
		#1000;

		if (dbg_bus[31:16] == 16'd0 || !dbg_bus[11])
			$fatal(1, "XDMA clock heartbeat was not detected");
		if (!dbg_bus[15] || !dbg_bus[14] || !dbg_bus[13])
			$fatal(1, "reset/link status was not synchronized");
		if (dbg_bus[10:0] != 11'd0)
			$fatal(1, "reserved diagnostic bits are not zero");
		if (dbg_bus[47:32] !== 16'b0_1_1_1_1_1_1_1_1_1_1_1_1_1_1_0)
			$fatal(1, "lane diagnostics missing: %04h", dbg_bus[47:32]);

		$display("TB_PASS dbg_bus=%012h", dbg_bus);
		$finish;
	end
endmodule
