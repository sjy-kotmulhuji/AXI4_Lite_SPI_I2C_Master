

#ifndef SRC_DRIVER_SWITCH_SWITCH_H_
#define SRC_DRIVER_SWITCH_SWITCH_H_

#include "../../HAL/GPIO/GPIO.h"

#define SWITCH_PORT GPIOA

#define SWITCH_0 GPIO_PIN_0
#define SWITCH_1 GPIO_PIN_1
#define SWITCH_2 GPIO_PIN_2
#define SWITCH_3 GPIO_PIN_3
#define SWITCH_4 GPIO_PIN_4
#define SWITCH_5 GPIO_PIN_5
#define SWITCH_6 GPIO_PIN_6
#define SWITCH_7 GPIO_PIN_7

typedef enum {
	OFF = 0,
	ON
}switch_state_t;

typedef struct {
	GPIO_Typedef_t *GPIOx;
	uint32_t GPIO_Pin;
	switch_state_t state;
} hSwitch_t;

void switch_Pin_Init(hSwitch_t *hSw, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin);
void switch_Init();
switch_state_t switch_GetState(hSwitch_t *hSw);
uint8_t switch_GetData();


#endif /* SRC_DRIVER_SWITCH_SWITCH_H_ */
