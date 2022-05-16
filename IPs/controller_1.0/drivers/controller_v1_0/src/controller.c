

/***************************** Include Files *******************************/
#include "controller.h"

void exec(UINTPTR baseAddr, u32 ins)
{
    // Write instruction to control register 1
    CONTROLLER_mWriteReg(baseAddr, 4, ins);    

    // Write start signal to control register 0
    CONTROLLER_mWriteReg(baseAddr, 0, 1);

    // Busy waiting for execution
    while (CONTROLLER_mReadReg(baseAddr, 0));

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

/************************** Function Definitions ***************************/
