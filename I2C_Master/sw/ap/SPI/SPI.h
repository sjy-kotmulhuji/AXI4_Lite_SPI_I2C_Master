
#ifndef SRC_AP_SPI_SPI_H_
#define SRC_AP_SPI_SPI_H_

#include "../../driver/button/button.h"
#include "../../driver/switch/switch.h"

#define SPI_BASE_ADDR 0x44A00000

#define SPI_SET_SIG (*(uint32_t *) (SPI_BASE_ADDR + 0x00))
#define SPI_TX_DATA (*(uint32_t *) (SPI_BASE_ADDR + 0x04))
#define SPI_DISP_RX_DATA (*(uint32_t *) (SPI_BASE_ADDR + 0x08))
#define SPI_BUSY_DONE (*(uint32_t *) (SPI_BASE_ADDR + 0x0c))

//SPI_SET_SIG(slv_reg0)
#define CPOL_0 (0<<0)
#define CPOL_1 (1<<0)
#define CPHA_0 (0<<1)
#define CPHA_1 (1<<1)
#define START (1<<2)

//SPI_BUSY_DONE(slv_reg3)
#define DONE (1<<0)
#define BUSY (1<<1)

void SPI_Init();
void SPI_Excute();
void SPI_Start();

#endif /* SRC_AP_SPI_SPI_H_ */
