# 🚌 AXI4-Lite 기반 SoC 설계 및 UVM 검증

> 온디바이스AI 시스템 반도체 설계 1기 | 송주연 | 대한상공회의소 서울기술교육센터 | 2026.05.08

---

## 프로젝트 개요

- MicroBlaze 기반 **SoC 시스템** 구성 (Vivado Block Design)
- MicroBlaze CPU와 **AXI4-Lite** 프로토콜로 통신하는 **SPI Master / I2C Master IP** 설계
- **HAL 기반 Layered Architecture** C Firmware 구현
- FPGA 보드를 이용한 Master – Slave 동작 검증
- SPI 통신에 대한 UVM 구조 검증

---

## 개발 환경

<table>
<tr><td><b>Language</b></td><td>
<img src="https://img.shields.io/badge/-VERILOG-1E88E5?style=for-the-badge&logoColor=white"/>
<img src="https://img.shields.io/badge/C-FFC107?style=for-the-badge&logo=c&logoColor=white"/>
</td></tr>
<tr><td><b>Tool</b></td><td>
<img src="https://img.shields.io/badge/VIVADO-006400?style=for-the-badge&logo=amd&logoColor=white"/>
<img src="https://img.shields.io/badge/VITIS-004B87?style=for-the-badge&logo=amd&logoColor=white"/>
</td></tr>
<tr><td><b>Protocol</b></td><td>
<img src="https://img.shields.io/badge/AXI4--LITE-0B1F3A?style=for-the-badge&logo=amd&logoColor=white"/>
</td></tr>
<tr><td><b>Board</b></td><td>
<img src="https://img.shields.io/badge/BASYS3_(XILINX_ARTIX--7)-5BC0DE?style=for-the-badge&logo=amd&logoColor=white"/>
</td></tr>
</table>

---

## AXI (Advanced eXtensible Interface)

### 개요
| AXI Protocol | 
| ------ |
| <img width="1118" height="215" alt="image" src="https://github.com/user-attachments/assets/b5cb0580-2521-4390-909b-076a06fd1b5d" /> |

- AMBA Bus 프로토콜 중 하나로 SoC 내부에서 CPU와 주변장치 간 고속 통신을 위한 표준 인터페이스
- 동작에 따라 **5개의 채널**로 구성
- 각 채널은 Info + **VALID / READY** 신호로 구성
- **AXI4-Lite** : AXI4의 경량화 버전, 단일 트랜잭션만 처리

---

### 채널 구성

<img width="1772" height="1001" alt="image" src="https://github.com/user-attachments/assets/47a46793-0e3e-47a0-88ae-74c602b72790" />

- **Handshaking** 방식 : 각 채널의 **VALID와 READY가 모두 1**이 되는 클락 엣지에서 해당 채널의 트랜잭션 완료

| 채널 | 방향 | 설명 |
|------|------|------|
| `AW` | Master → Slave | Write Address |
| `W` | Master → Slave | Write Data |
| `B` | Slave → Master | Write Response |
| `AR` | Master → Slave | Read Address |
| `R` | Slave → Master | Read Data & Response |

---

### AXI Master 

#### Write Transaction

| Timing Diagram | FSM |
| ------ | ------ |
| <img width="900" height="496" alt="image" src="https://github.com/user-attachments/assets/3a0368a7-5567-49df-af69-80b60c66666f" /> | <img width="400" height="550" alt="image" src="https://github.com/user-attachments/assets/b02d9101-8981-4015-b0a1-a01c8d8be588" /> |



#### Read Transaction

| Timing Diagram | FSM |
| ------ | ------ |
| <img width="1630" height="656" alt="image" src="https://github.com/user-attachments/assets/332f8e5b-6c2f-47ec-a308-c3d38ce0391d" />| <img width="925" height="890" alt="image" src="https://github.com/user-attachments/assets/f3a7552e-7ff0-4a5d-9ff4-942fbf3f2a34" />|

---

### AXI Slave 

#### Write/Read Transaction

| Write FSM | Read FSM |
| ------ | ------ |
| <img width="400" height="550" alt="image" src="https://github.com/user-attachments/assets/52049aca-5a18-46a7-b9b4-9b5b19915847" /> | <img width="400" height="350" alt="image" src="https://github.com/user-attachments/assets/44b2d7ed-bec1-4725-a54d-5fb67f082bb3" /> |


---

## SoC 구성

### IP 구성

| IP | 설명 |
|----|------|
| **MicroBlaze** | Xilinx Soft Processor IP, AXI Master로 동작 |
| **AXI Uartlite** | `xil_printf`로 시리얼 데이터를 PC로 전송, 디버깅 용도 |
| **AXI Peripheral (Slave) IP** | Vivado AXI Slave 템플릿에 직접 설계한 RTL 로직 연결 |

**설계한 AXI Slave IP 목록**
- GPIO
- FND
- SPI Master
- I2C Master

## Software 설계

### HAL 기반 Layered Architecture
- Software 시스템을 **관심사(기능)** 에 따라 여러 계층으로 분리하여 설계하는 방법
- **HAL (Hardware Abstraction Layer)** : Hardware와 OS 사이의 인터페이스 역할을 하는 Software 계층
- 상위 Software 계층이 하드웨어 동작을 신경 쓸 필요 없이 HAL 함수 호출만으로 동작 가능
- 상위 계층은 바로 아래 계층에만 접근 가능

## AXI SPI IP

### Block Diagram

| Block Diagram 및 레지스터 주소 맵핑 |
|------|
| <img width="1215" height="474" alt="image" src="https://github.com/user-attachments/assets/813019e2-ef01-4db4-8ceb-ff484bc37a18" /> | 

### SoC 구성
<img width="1810" height="811" alt="image" src="https://github.com/user-attachments/assets/87ecaa18-90a4-4f79-8788-651ca4436e6b" />

### GPIO 구성

| 포트 | 연결 |
|------|------|
| `GPIOA[7:0]` | switch[7:0] |
| `GPIOB[7:0]` | LED[7:0] |
| `GPIOC[7:0]` | fnd_data[7:0] |
| `GPIOD[3:0]` | fnd_digit[3:0] |
| `GPIOD[7:4]` | 상하좌우 Button |

---



| SPI Software 계층 구조 |
|------|
| <img width="663" height="328" alt="image" src="https://github.com/user-attachments/assets/e856cac6-094d-4582-a74c-b368430fb8a4" /> |

**계층 별 역할**

| 계층 | 역할 |
|------|------|
| **Application** | Driver를 조합하여 실제 사용자 기능 구현 |
| **Driver** | 각 하드웨어 요소들의 개별 동작 구현 |
| **HAL** | 하드웨어 레지스터에 직접 접근하는 함수 구현 |

---

### FPGA 데모 영상

https://github.com/user-attachments/assets/c0332eb1-d416-4c00-93da-54574db06e53

---

## AXI I2C

### Block Diagram

| Block Diagram 및 레지스터 주소 맵핑 |
|------|
| <img width="1992" height="772" alt="image" src="https://github.com/user-attachments/assets/353eb4a7-1147-4448-b183-9329224c0df3" /> | 


### SoC 구성
<img width="903" height="456" alt="image" src="https://github.com/user-attachments/assets/397cb32f-37dd-4080-aef1-072a437f3d44" />


### GPIO 구성

| 포트 | 연결 |
|------|------|
| `GPIOA[7:0]` | switch[7:0] |
| `GPIOB[7:0]` | LED[7:0] |
| `GPIOC[7:0]` | fnd_data[7:0] |
| `GPIOD[3:0]` | fnd_digit[3:0] |
| `GPIOD[7:4]` | 상하좌우 Button |


---


| I2C Software 계층 구조 |
|------|
| <img width="1550" height="757" alt="image" src="https://github.com/user-attachments/assets/347d5679-ba0a-4b39-ada3-a43d1808f9d1" /> |


---

### FPGA 데모 영상



---

## AXI SPI UVM 검증

### 검증 시나리오

| 시나리오 | 내용 |
|---------|------|
| Write (Master → Slave) | `m_tx_data`가 `s_rx_data`로 정상 전달되는지 확인 |
| Read (Slave → Master) | `s_tx_data`가 `m_rx_data`로 정상 전달되는지 확인 |
| 동작 신호 확인 | SCLK 데이터 송수신 상태에서만 활성화 확인, `done` 신호 펄스 출력 확인 |

### 검증 결과

| 항목 | 결과 |
|------|------|
| Scoreboard | `s_tx_data` ↔ `m_rx_data` 비교 일치 ✅ |
| Coverage | `m_tx_data` / `s_rx_data` / `s_tx_data` / `m_rx_data` 전체 달성 ✅ |
| Log | PASS ✅ |

---

## Trouble Shooting

### I2C Master IP Port 설정 오류

**문제**
Command 신호, `tx_data`, `ack_in` 신호를 AXI Master(MicroBlaze)로부터 AXI Top Module로 입력받아야 한다고 판단해 **외부 port**로 선언

**원인**
AXI Master는 AXI Top Module의 외부 port가 아니라 **내부 레지스터**에 접근해 값을 지정하는 방식으로 동작

**해결**
Command 신호들을 외부 port 대신 **내부 wire**로 선언해 정상 동작 확인
