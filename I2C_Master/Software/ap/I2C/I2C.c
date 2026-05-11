#include "I2C.h"

hBtn_t hBtnStart, hBtnRW;

void I2C_Init() {
	switch_Init();
	FND_init();
	Button_Init(&hBtnStart, GPIOD, GPIO_PIN_6);
	//Button_Init(&hBtnRW, GPIOD, GPIO_PIN_5);
	I2C_CMD_ACK = 0;
	I2C_TX = 0;
}

void I2C_Excute() {
	//IDLE
	I2C_CMD_ACK = 0;
	I2C_TX = 0;
	while (!(Button_GetState(&hBtnStart) == ACT_PUSHED));
	xil_printf("Start Button Pushed!\n");

	//START
	I2C_CMD_ACK = CMD_START;
	while (!(I2C_IN_SIG & BUSY));
	xil_printf("DONE\n");
	//I2C_CMD_ACK = 0;

	//ADDR_RW
	//I2C_TX = 0;
	I2C_TX = (SLV_ADDR<<1) | 0;	//7bit slave 주소 + read mode
	xil_printf("tx_data : %02x\n", I2C_TX);
	I2C_CMD_ACK = CMD_WRITE;
	while (!(I2C_IN_SIG & BUSY));
	xil_printf("DONE\n");
	if(!(I2C_IN_SIG & ACK_OUT)) {
		I2C_CMD_ACK = 0;
	} else {
		I2C_CMD_ACK = CMD_STOP;
		while (!(I2C_IN_SIG & BUSY));
		I2C_CMD_ACK = 0;
		return;
	}

	//WRITE
	if(!(I2C_TX & (1<<0))) {
	I2C_TX = switch_GetData();
	xil_printf("tx_data : %02x\n", I2C_TX);
	I2C_CMD_ACK = CMD_WRITE;
	while (!(I2C_IN_SIG & BUSY));
	//Stop. Don't care ACK/NACK.
	I2C_CMD_ACK = CMD_STOP;
	while (!(I2C_IN_SIG & BUSY));
	I2C_CMD_ACK = 0;
	return;
	}

	//READ 읽어온 rx_data 전달하는 부분 추가해야 함
	else {
	//static uint16_t rx_data = I2C_RX;
	I2C_CMD_ACK = CMD_READ;
	xil_printf("rx_data : %02x\n", I2C_RX);
	FND_SetNum(I2C_RX);
	//FND_DispDigit();
	while (!(I2C_IN_SIG & BUSY));
	//Stop. Don't care ACK/NACK.
	I2C_CMD_ACK = CMD_STOP;
	while (!(I2C_IN_SIG & BUSY));
	I2C_CMD_ACK = 0;
	return;
	}

}
