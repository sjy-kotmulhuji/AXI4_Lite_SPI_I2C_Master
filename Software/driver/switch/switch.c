
#include "switch.h"

hSwitch_t hSw_0, hSw_1, hSw_2, hSw_3, hSw_4, hSw_5, hSw_6, hSw_7;

void switch_Pin_Init(hSwitch_t *hSw, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin) {
	hSw->GPIOx = GPIOx;
	hSw->GPIO_Pin = GPIO_Pin;
	hSw->state = OFF;
}

void switch_Init() {
	GPIO_SetMode(SWITCH_PORT, SWITCH_0 | SWITCH_1 | SWITCH_2 | SWITCH_3 | SWITCH_4 | SWITCH_5 | SWITCH_6 | SWITCH_7, INPUT);
	switch_Pin_Init(&hSw_0, SWITCH_PORT, SWITCH_0);
	switch_Pin_Init(&hSw_1, SWITCH_PORT, SWITCH_1);
	switch_Pin_Init(&hSw_2, SWITCH_PORT, SWITCH_2);
	switch_Pin_Init(&hSw_3, SWITCH_PORT, SWITCH_3);
	switch_Pin_Init(&hSw_4, SWITCH_PORT, SWITCH_4);
	switch_Pin_Init(&hSw_5, SWITCH_PORT, SWITCH_5);
	switch_Pin_Init(&hSw_6, SWITCH_PORT, SWITCH_6);
	switch_Pin_Init(&hSw_7, SWITCH_PORT, SWITCH_7);
}

switch_state_t switch_GetState(hSwitch_t *hSw) {
	return (GPIO_ReadPin(hSw->GPIOx, hSw->GPIO_Pin)) ? ON : OFF;
}

uint8_t switch_GetData() {
	uint8_t swNum = 0;
	if(switch_GetState(&hSw_0) == ON) {
		swNum |= (1<<0);
	}
	if(switch_GetState(&hSw_1) == ON) {
		swNum |= (1<<1);
	}
	if(switch_GetState(&hSw_2) == ON) {
		swNum |= (1<<2);
	}
	if(switch_GetState(&hSw_3) == ON) {
		swNum |= (1<<3);
	}
	if(switch_GetState(&hSw_4) == ON) {
		swNum |= (1<<4);
	}
	if(switch_GetState(&hSw_5) == ON) {
		swNum |= (1<<5);
	}
	if(switch_GetState(&hSw_6) == ON) {
		swNum |= (1<<6);
	}
	if(switch_GetState(&hSw_7) == ON) {
		swNum |= (1<<7);
	}
	return swNum;
	//Another Solution
	//return (uint8_t) GPIO_ReadPort(SWITCH_PORT);
}
