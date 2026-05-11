#include "SPI.h"

hBtn_t hBtnStart;


void SPI_Init() {
	Button_Init(&hBtnStart, GPIOD, GPIO_PIN_5);
	switch_Init();
	SPI_SetMode(0, 4);
}

void SPI_SetMode(uint8_t ModeNum, uint8_t clk_div) {
	switch (ModeNum) {
	case 0:
		SPI_SET_SIG = (clk_div << 3) | CPHA_0 | CPOL_0;
		break;
	case 1:
		SPI_SET_SIG = (clk_div << 3) | CPHA_1 | CPOL_0;
		break;
	case 2:
		SPI_SET_SIG = (clk_div << 3) | CPHA_0 | CPOL_1;
		break;
	case 3:
		SPI_SET_SIG = (clk_div << 3) | CPHA_1 | CPOL_1;
		break;
	default:
		SPI_SET_SIG = (clk_div << 3) | CPHA_0 | CPOL_0;
		break;
	}
	return;
}


void SPI_Excute() {
	if (Button_GetState(&hBtnStart) == ACT_PUSHED) {
		SPI_Start();
	}
}

void SPI_Start() {
	SPI_TX_DATA = switch_GetData();
	SPI_SET_SIG |= START;
	while(!(SPI_BUSY_DONE & BUSY));
	SPI_SET_SIG &= ~START;
	while(SPI_BUSY_DONE & BUSY);
}

