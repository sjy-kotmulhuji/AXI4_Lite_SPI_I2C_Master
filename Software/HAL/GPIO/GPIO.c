
#include "GPIO.h"

void GPIO_SetMode(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN, int GPIO_Dir) {
	   if(GPIO_Dir == OUTPUT) {
		   GPIOx->CR |= GPIO_PIN;
	   }
	   else{
		   GPIOx->CR &= ~(GPIO_PIN);
	   }
	   return;
}

void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN, int level) {
	if(level == SET) {
		GPIOx->ODR |= GPIO_PIN;
	}
	else {
		GPIOx->ODR &= ~(GPIO_PIN);
	}
	return;
}

uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, int GPIO_PIN) {
	return (GPIOx->IDR & GPIO_PIN) ? 1 : 0;
}

void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data) {
	GPIOx->ODR = data;
}

uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx) {
	return GPIOx->IDR;
}
