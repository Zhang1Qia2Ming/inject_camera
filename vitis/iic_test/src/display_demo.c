
/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include "display_demo.h"
#include <stdio.h>
#include "math.h"
#include <ctype.h>
#include <stdlib.h>
#include "xil_types.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "xiicps.h"
#include "i2c/PS_i2c.h"
#include "xgpiops.h"
#include "sleep.h"

#include "maxchip.h"
#include "config.h"
#include "xcsiss.h"
#include <string.h>

#define CAM_EMIO	78

#ifdef XPAR_AXI_VDMA_0_DEVICE_ID
#include "xaxivdma.h"

/* One RAW12 image, no embedded lines. Three slots per lane.
 * HPM0_LPD maps 0x80000000. add_pcie3.tcl leaves the three VDMA
 * register blocks on that aperture, 64K apart, with the CSI RX at 0x80010000. */
#define RAW_FRAME_BYTES 12441600u
#define RAW_HSIZE       5760u
#define RAW_VSIZE       2160u
#define RAW_SLOTS       3u
#define VDMA0_BASE      0x80000000u
#define VDMA1_BASE      0x80020000u
#define VDMA2_BASE      0x80030000u
#define LANE0_BASE      0x10000000u
#define LANE_STRIDE     (RAW_FRAME_BYTES * RAW_SLOTS)

static int frame_vdma_one(u16 device_id, u32 base, u32 buf)
{
	XAxiVdma vdma;
	XAxiVdma_Config *cfg;
	XAxiVdma_DmaSetup wr;
	XAxiVdma_DmaSetup rd;
	u32 addr;
	int i;
	int status;

	cfg = XAxiVdma_LookupConfig(device_id);
	if (!cfg) {
		xil_printf("vdma %u lookup failed\r\n", device_id);
		return XST_DEVICE_NOT_FOUND;
	}

	if (cfg->BaseAddress != base)
		xil_printf("vdma base 0x%08x expected 0x%08x\r\n",
			cfg->BaseAddress, base);

	status = XAxiVdma_CfgInitialize(&vdma, cfg, cfg->BaseAddress);
	if (status != XST_SUCCESS) {
		xil_printf("vdma 0x%08x cfg failed %d\r\n", base, status);
		return status;
	}

	memset(&wr, 0, sizeof(wr));
	wr.VertSizeInput = RAW_VSIZE;
	wr.HoriSizeInput = RAW_HSIZE;
	wr.Stride = RAW_HSIZE;
	wr.FrameDelay = 0;
	wr.EnableCircularBuf = 1;
	wr.EnableSync = 0;
	wr.PointNum = 0;
	wr.EnableFrameCounter = 0;
	wr.FixedFrameStoreAddr = 0;
	status = XAxiVdma_DmaConfig(&vdma, XAXIVDMA_WRITE, &wr);
	if (status != XST_SUCCESS)
		return status;

	memset(&rd, 0, sizeof(rd));
	rd.VertSizeInput = RAW_VSIZE;
	rd.HoriSizeInput = RAW_HSIZE;
	rd.Stride = RAW_HSIZE;
	rd.FrameDelay = 0;
	rd.EnableCircularBuf = 1;
	rd.EnableSync = 0;
	rd.PointNum = 0;
	rd.EnableFrameCounter = 0;
	rd.FixedFrameStoreAddr = 0;
	status = XAxiVdma_DmaConfig(&vdma, XAXIVDMA_READ, &rd);
	if (status != XST_SUCCESS)
		return status;

	addr = buf;
	for (i = 0; i < RAW_SLOTS; i++) {
		wr.FrameStoreStartAddr[i] = addr;
		rd.FrameStoreStartAddr[i] = addr;
		addr += RAW_FRAME_BYTES;
	}
	status = XAxiVdma_DmaSetBufferAddr(&vdma, XAXIVDMA_WRITE, wr.FrameStoreStartAddr);
	if (status != XST_SUCCESS)
		return status;
	status = XAxiVdma_DmaSetBufferAddr(&vdma, XAXIVDMA_READ, rd.FrameStoreStartAddr);
	if (status != XST_SUCCESS)
		return status;

	status = XAxiVdma_DmaStart(&vdma, XAXIVDMA_WRITE);
	if (status != XST_SUCCESS)
		return status;
	status = XAxiVdma_DmaStart(&vdma, XAXIVDMA_READ);
	if (status != XST_SUCCESS)
		return status;

	xil_printf("vdma 0x%08x frames at 0x%08x\r\n", cfg->BaseAddress, buf);
	return XST_SUCCESS;
}

static void frame_vdma_init(void)
{
	u16 ids[3];
	u32 bases[3];
	int i;
	int status;

	ids[0] = XPAR_AXI_VDMA_0_DEVICE_ID;
	ids[1] = XPAR_AXI_VDMA_1_DEVICE_ID;
	ids[2] = XPAR_AXI_VDMA_2_DEVICE_ID;
	bases[0] = VDMA0_BASE;
	bases[1] = VDMA1_BASE;
	bases[2] = VDMA2_BASE;

	for (i = 0; i < 3; i++) {
		status = frame_vdma_one(ids[i], bases[i], LANE0_BASE + i * LANE_STRIDE);
		if (status != XST_SUCCESS)
			xil_printf("lane %d vdma init failed %d\r\n", i, status);
	}
}
#else
static void frame_vdma_init(void)
{
	xil_printf("vdma not in this BSP yet; export the platform after add_pcie3.tcl\r\n");
}
#endif
/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

/*
 * Display Driver structs
 */

XIicPs ps_i2c0;
XGpioPs Gpio;

#define XCSIRXSS_DEVICE_ID	XPAR_CSISS_0_DEVICE_ID
XCsiSs CsiRxSs;


u32 InitializeCsiRxSs(void)
{
	u32 Status = 0;
	XCsiSs_Config *CsiRxSsCfgPtr = NULL;

	CsiRxSsCfgPtr = XCsiSs_LookupConfig(XCSIRXSS_DEVICE_ID);
	if (!CsiRxSsCfgPtr) {
		xil_printf("CSI2RxSs LookupCfg failed\r\n");
		return XST_FAILURE;
	}

	Status = XCsiSs_CfgInitialize(&CsiRxSs, CsiRxSsCfgPtr,
			CsiRxSsCfgPtr->BaseAddr);

	if (Status != XST_SUCCESS) {
		xil_printf("CsiRxSs Cfg init failed - %x\r\n", Status);
		return Status;
	}

	return XST_SUCCESS;
}

int main(void)
{

	int Status;
	int i ;

	Xil_DCacheDisable();
	Xil_ICacheDisable();
	xil_printf("build Oct 23 2026 - pcie3\r\n");

	i2c_init(&ps_i2c0, XPAR_XIICPS_0_DEVICE_ID,100000);
	
	/* Initialize CSIRXSS  */
	Status = InitializeCsiRxSs();
	if (Status != XST_SUCCESS) {
		xil_printf("CSI Rx Ss Init failed status = %x.\r\n", Status);
		return XST_FAILURE;
	}

	xil_printf("ch1!\r\n");
	frame_vdma_init();
#if 1
	sleep(1);
		max_9296_init(&ps_i2c0);
		usleep(20000);
		xil_printf("max_9296_done!\r\n");
		max_717_init(&ps_i2c0);
		xil_printf("max_96717_done!");
		 //sersor_init(&ps_i2c0);
		 xil_printf("sersor_init_done!\r\n");
		 usleep(20000);
		  max_9296_mipien(&ps_i2c0);
		  max_9296_sec_init(&ps_i2c0);
		  max_717_init(&ps_i2c0);
		  max_9296_mipien(&ps_i2c0);
		  xil_printf("max_9296_mipien!\r\n");


			usleep(200000);
			MAX9296_rdid(&ps_i2c0);
			usleep(100);
			MAX717_rdid(&ps_i2c0);
			//senser_rdid(&ps_i2c0);
			xil_printf("gmsl_debug_loop_start!\r\n");
			while (1) {
				MAX9296_rdid(&ps_i2c0);
				usleep(100);
				MAX717_debug_dump(&ps_i2c0);
				sleep(1);
			}
#endif
	return 0;
}


