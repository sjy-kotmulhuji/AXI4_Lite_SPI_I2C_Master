
#ifndef SRC_AP_I2C_I2C_H_
#define SRC_AP_I2C_I2C_H_

#include <stdint.h>
#include "../../driver/button/button.h"
#include "../../driver/switch/switch.h"
#include "../../driver/FND/FND.h"
#include "xil_printf.h"

#define SLV_ADDR 0x25

#define I2C_BASE_ADDR 0x44A00000

#define I2C_CMD_ACK (*(uint32_t *) (I2C_BASE_ADDR + 0x00))
#define I2C_TX (*(uint32_t *) (I2C_BASE_ADDR + 0x04))
#define I2C_RX (*(uint32_t *) (I2C_BASE_ADDR + 0x08))
#define I2C_IN_SIG (*(uint32_t *) (I2C_BASE_ADDR + 0x0c))

#define CMD_START (1<<0)
#define CMD_WRITE (1<<1)
#define CMD_READ (1<<2)
#define CMD_STOP (1<<3)
#define ACK_IN 	(1<<4)

#define DONE (1<<0)
#define ACK_OUT (1<<1)
#define BUSY (1<<2)

void I2C_Init();
void I2C_Excute();

#endif /* SRC_AP_I2C_I2C_H_ */
