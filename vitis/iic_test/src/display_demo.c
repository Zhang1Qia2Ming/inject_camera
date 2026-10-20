
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


#define CAM_EMIO	78
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
	xil_printf("build Oct 16 2026 - 20:11:08\r\n");

	i2c_init(&ps_i2c0, XPAR_XIICPS_0_DEVICE_ID,100000);
	
	/* Initialize CSIRXSS  */
	Status = InitializeCsiRxSs();
	if (Status != XST_SUCCESS) {
		xil_printf("CSI Rx Ss Init failed status = %x.\r\n", Status);
		return XST_FAILURE;
	}

	xil_printf("ch1!\r\n");
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


