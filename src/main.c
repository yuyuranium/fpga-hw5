/*
 * 
 * main.c
 *  
 */

#include <stdio.h>
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"

void exec(u32 ins)
{
	// Write instruction to GPIO 3
	Xil_Out32(XPAR_AXI_GPIO_3_BASEADDR, ins);

	// Write enable signal to GPIO 2
	Xil_Out32(XPAR_AXI_GPIO_2_BASEADDR, 1);

	// Busy waiting for execution complete (while valid == 0)
	while (Xil_In32(XPAR_AXI_GPIO_1_BASEADDR) == 0);

	// Reset enable signal to GPIO 2
	Xil_Out32(XPAR_AXI_GPIO_2_BASEADDR, 0);

	return;
}

u32 codegen(unsigned alumode, unsigned opmode, unsigned inmode,
			unsigned bram1waddr, unsigned bram1raddr, unsigned bram0raddr)
{
	u32 ins = 0;
	ins |= (alumode & 0b1111) << 27;
	ins |= (opmode & 0b1111111) << 20;
	ins |= (inmode & 0b11111) << 15;
	ins |= (bram1waddr & 0b11111) << 10;
	ins |= (bram1raddr & 0b11111) << 5;
	ins |= (bram0raddr & 0b11111) << 0;
	ins |= 0x80000000;  // set Execute
	return ins;
}

int main()
{
	printf("Program Start.\n\n");
	// BRAM1[3] <= BRAM0[0] * BRAM1[2];
	exec(codegen(0b0000, 0b0000101, 0b10001, 3, 2, 0)); 
	// BRAM1[7] <= BRAM0[11] * BRAM1[3];
	exec(codegen(0b0000, 0b0000101, 0b10001, 7, 3, 11));
	// BRAM1[10] <= BRAM0[31] * BRAM1[7] + C;
	exec(codegen(0b0000, 0b0110101, 0b10001, 10, 7, 31));
	// BRAM1[13] <= C - BRAM0[1] * BRAM1[6] ;
	exec(codegen(0b0011, 0b0110101, 0b10001, 13, 6, 1));
	// BRAM1[15] <= BRAM0[0] * BRAM1[31] - C - 1;
	exec(codegen(0b0001, 0b0110101, 0b10001, 15, 31, 0));
	
	printf("Step1\n");
	for (int i = 0; i < 32; i++) {
		printf("BRAM1[%d] = 0x%lx\n", i,
			   Xil_In32(XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR + i * 4));
	}

	/* write data in BRAM0 by C code */
	for (int i = 0; i < 32; i++) {
		u32 wdata = (i + 1) * (i + 1);
		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + i * 4, wdata);
	}
	
	// BRAM1[16] <= BRAM0[0] * BRAM1[2];
	exec(codegen(0b0000, 0b0000101, 0b10001, 16, 2, 0));
	// BRAM1[17] <= BRAM0[11] * BRAM1[3];
	exec(codegen(0b0000, 0b0000101, 0b10001, 17, 3, 11));
	// BRAM1[18] <= BRAM0[31] * BRAM1[7] + C;
	exec(codegen(0b0000, 0b0110101, 0b10001, 18, 7, 31));
	// BRAM1[19] <= C - BRAM0[1] * BRAM1[6];
	exec(codegen(0b0011, 0b0110101, 0b10001, 19, 6, 1));
	// BRAM1[20] <= BRAM0[0] * BRAM1[31] - C - 1;
	exec(codegen(0b0001, 0b0110101, 0b10001, 20, 31, 0));
	
	printf("\nStep2\n");
	for (int i = 0; i < 32; i++) {
		printf("BRAM1[%d] = 0x%lx\n", i,
			   Xil_In32(XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR + i * 4));
	}
	
	printf("Program End.\n\r");
	return 0;
}
