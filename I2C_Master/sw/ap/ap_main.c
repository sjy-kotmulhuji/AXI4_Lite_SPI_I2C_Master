
#include "ap_main.h"

void ap_init() {
	I2C_Init();
}


void ap_excute() {
	while(1) {
		I2C_Excute();

	}
}

