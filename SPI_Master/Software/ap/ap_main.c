#include "ap_main.h"

void ap_init() {
	SPI_Init();
}

void ap_Excute() {
	while(1) {
		SPI_Excute();
	}
}



